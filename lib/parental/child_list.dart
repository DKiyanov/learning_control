import 'package:flutter/material.dart';
import 'package:learning_control/check_point_list.dart';
import 'package:learning_control/parse/parse_check_point.dart';
import 'app_group_list.dart';
import 'apps_tuner.dart';
import 'coin_list.dart';
import '../common.dart';
import '../app_state.dart';
import 'estimate_add.dart';
import '../estimate_list.dart';
import '../expense_list.dart';
import '../parse/parse_main.dart';
import '../parse/parse_balance.dart';

class ChildList extends StatefulWidget {
  static Future<Object?> navigatorPush(BuildContext context) async {
    return Navigator.push(context, MaterialPageRoute(builder: (_) => const ChildList() ));
  }
  static Future<Object?> navigatorPushReplacement(BuildContext context) async {
    return Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ChildList() ));
  }
  const ChildList({Key? key}) : super(key: key);

  @override
  State<ChildList> createState() => _ChildListState();
}

class _ChildListState extends State<ChildList> {
  final childList   = <Child>[];
  final balanceList = <Balance>[];
  final deviceList  = <Device>[];
  final checkPointManagerList = <CheckPointManager>[];

  bool _isStarting = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _starting();
    });
  }

  void _starting() async {
    childList.addAll(await appState.childManager.getChildList(appState.serverConnect.user!));
    await _refreshBalance();
    deviceList.addAll(await appState.deviceManager.getDeviceList(appState.serverConnect.user!));

    for (var child in childList) {
      await appState.balanceDirector.balanceManager.setChild(child);
      balanceList.add(appState.balanceDirector.balanceManager.balance);

      final checkPointManager = CheckPointManager();
      await checkPointManager.setChild(child);
      checkPointManagerList.add(checkPointManager);
    }

    setState(() {
      _isStarting = false;
    });
  }

  Future<void> _refreshBalance() async {
    for (var balance in balanceList) {
      balance.readFromServer();
    }
  }

  Future<void> _refreshCheckPoint() async {
    for (var checkPointManager in checkPointManagerList) {
      await checkPointManager.readFromServer();
    }
  }

  Future<void> _refresh() async {
    await _refreshBalance();
    await _refreshCheckPoint();
    if (!mounted) return;
    setState(() { });
  }

  @override
  Widget build(BuildContext context) {
    if (_isStarting) {
      return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(TextConst.txtLoading),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (childList.isEmpty){
      return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(TextConst.txtChildrenDevices),
        ),

        body: SafeArea(
          child: Card(
            color: Colors.amberAccent,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Text(TextConst.msgChildList1),
            )
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(TextConst.txtChildrenDevices),
      ),

      body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: ListView.builder(
              itemCount: childList.length,
              itemBuilder: _buildChildItem,
            )
          )
      ),
    );

  }

  Widget _buildChildItem(BuildContext context, int index) {
    final child = childList[index];
    final balance = balanceList.firstWhere((balance) => balance.childID == child.objectId );
    final checkPointManager = checkPointManagerList.firstWhere((checkPointManager) => checkPointManager.child.objectId == child.objectId);

    return ExpansionTile(
      title: Column(
        children: [
          Text(child.name),

          Row(children: [
            Container(
              padding: const EdgeInsets.all(5.0),
              decoration: BoxDecoration(
                color: Colors.lime,
                  border: Border.all(
                    color: Colors.lime,
                  ),
                  borderRadius: const BorderRadius.all(Radius.circular(20))
              ),
              child: Text(' ${TextConst.txtBalanceValue}: ${balance.minutes} '),
            ),

            PopupMenuButton<String>(
              icon: const Icon(Icons.menu, color: Colors.blue),
              itemBuilder: (context) {
                return [
                  TextConst.txtEstimateList,
                  TextConst.txtExpenseList,
                  TextConst.txtCoinTuning,
                  TextConst.txtAppGroupsTuning,
                  TextConst.txtCheckPointList,
                ].map<PopupMenuItem<String>>((value) => PopupMenuItem<String>(
                  value: value,
                  child: Text(value),
                )).toList();
              },
              onSelected: (value) async {
                if (value == TextConst.txtEstimateList){
                  await EstimateList.navigatorPush(context, child);
                  _refresh();
                }
                if (value == TextConst.txtExpenseList && mounted){
                  ExpenseList.navigatorPush(context, child);
                  _refresh();
                }
                if (value == TextConst.txtCoinTuning && mounted){
                  CoinList.navigatorPush(context, child);
                }
                if (value == TextConst.txtAppGroupsTuning && mounted){
                  AppGroupList.navigatorPush(context);
                }
                if (value == TextConst.txtCheckPointList && mounted){
                  await CheckPointList.navigatorPush(context, child, false);
                  _refresh();
                }
              },
            ),

            // Кнопка наличия задач (CheckPoint)
            if (checkPointManager.condition != CheckPointCondition.free) ...[
              IconButton(
                  icon: checkPointManager.condition == CheckPointCondition.lock?
                  const Icon(Icons.lock, color: Colors.deepOrange) :
                  const Icon(Icons.warning, color: Colors.yellow),

                  onPressed: () async {
                    await CheckPointList.navigatorPush(context, child, false);
                    _refresh();
                  },
              ),
            ],

            IconButton(
              icon: const Icon(Icons.add_task, color: Colors.blue,),
              onPressed: () async {
                await EstimateAdd.navigatorPush(context, child);
                _refresh();
              },
            ),
          ]),
        ],
      ),
      initiallyExpanded: true,
      childrenPadding: const EdgeInsets.only(left: 30.0),
      children: deviceList.where((device) => device.childID == child.objectId ).map((device) => ListTile(
        title: Text(device.name),
        onTap: ()=> showDeviceAppsTunerPage(child, device),
      )).toList(),
    );
  }

  void showDeviceAppsTunerPage(Child child, Device device){
    AppsTuner.navigatorPush(context, child, device);
  }
}
import 'package:flutter/material.dart';
import 'package:learning_control/parse/parse_check_point.dart';
import 'package:learning_control/parse/parse_main.dart';
import '../app_state.dart';
import '../common.dart';
import 'check_point_editor.dart';

class CheckPointList extends StatefulWidget {
  static Future<Object?> navigatorPush(BuildContext context, Child child, bool viewOnly) async {
    return Navigator.push(context, MaterialPageRoute(builder: (_) => CheckPointList(child, viewOnly) ));
  }

  const CheckPointList(this.child, this.viewOnly, {Key? key}) : super(key: key);

  final Child child;
  final bool viewOnly;

  @override
  State<CheckPointList> createState() => _CheckPointListState();
}

class _CheckPointListState extends State<CheckPointList> {
  final _checkPointList = <CheckPoint>[];

  bool _isStarting = true;
  DateTime curDate = DateTime.now();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _starting();
    });
  }

  void _starting() async {
    await _refreshCheckPointList();

    setState(() {
      _isStarting = false;
    });
  }

  Future<void> _refreshCheckPointList() async {
    final intDate = dateToInt(curDate);
    _checkPointList.clear();
    _checkPointList.addAll((await appState.checkPointManager.getCheckPointListForDate(widget.child, intDate)));
    _checkPointList.sort((a, b) => a.checkDateTime.compareTo(b.checkDateTime));
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

    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Column(children: [
            Text(
              widget.child.name,
              style: const TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold),
            ),
            Text(
              TextConst.txtCheckPointList,
              style: const TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold),
            ),
          ]),
        ),

        body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 4, right: 4),
              child: Column(children: [
                Row(children: [
                  ElevatedButton(
                      child: const Icon( Icons.arrow_left, ),
                      onPressed : () async {
                        curDate = curDate.subtract(const Duration(days: 1));
                        await _refreshCheckPointList();
                        setState(() { });
                      }
                  ),
                  Expanded(child: ElevatedButton(
                    child: Text(dateToStr(curDate)),
                    onPressed: () async {
                      final DateTime? pickedDate = await showDatePicker(
                        context     : context,
                        initialDate : curDate,
                        firstDate   : widget.child.createdAt!,
                        lastDate    : DateTime.now(),
                      );
                      if (pickedDate == null) return;
                      curDate = pickedDate;
                      await _refreshCheckPointList();
                      setState(() { });
                    },
                  )),
                  ElevatedButton(
                      child: const Icon( Icons.arrow_right, ),
                      onPressed : () async {
                        curDate = curDate.add(const Duration(days: 1));
                        await _refreshCheckPointList();
                        setState(() { });
                      }
                  ),
                ],),
                Expanded(child: ListView.builder(
                  itemCount: _checkPointList.length,
                  itemBuilder: _buildCheckPointItems,
                ))
              ]),
            )
        ),

        floatingActionButton: widget.viewOnly? null : FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () {
            _addCheckPoint();
          },
        ),
    );
  }

  Widget _buildCheckPointItems(BuildContext context, int index) {
    final checkPoint = _checkPointList[index];

    Color tileColor = Colors.white70;
    if (checkPoint.status == CheckPointStatus.expectation) {
      if (checkPoint.condition == CheckPointCondition.lock){
        tileColor = Colors.deepOrange;
      } else if (checkPoint.condition == CheckPointCondition.warning) {
        tileColor = Colors.yellow;
      }
    } else {
      if (checkPoint.status == CheckPointStatus.complete) {
        tileColor = Colors.green;
      }
      if (checkPoint.status == CheckPointStatus.partiallyComplete) {
        tileColor = Colors.lightGreen;
      }
      if (checkPoint.status == CheckPointStatus.canceled) {
        tileColor = Colors.grey;
      }
      if (checkPoint.status == CheckPointStatus.notComplete) {
        tileColor = Colors.brown;
      }
    }


    return ListTile(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
      contentPadding: const EdgeInsets.only(left: 10.0, right: 10.0),
      tileColor: tileColor,
      title: Text(checkPoint.taskText),
      subtitle: Text('${checkPoint.checkTime} ${getCheckPointStatusName(checkPoint.status)}'),
      onTap: (){
        _editCheckPoint(checkPoint);
      },
    );
  }

  Future<void> _addCheckPoint() async {
    await CheckPointEditor.navigatorPush(context, child: widget.child, date: curDate, viewOnly: widget.viewOnly);
    await _refreshCheckPointList();
    setState(() {});
  }

  Future<void> _editCheckPoint(CheckPoint? checkPoint) async {
    await CheckPointEditor.navigatorPush(context, child: widget.child, checkPoint : checkPoint, viewOnly: widget.viewOnly);
    await _refreshCheckPointList();
    setState(() {});
  }

}
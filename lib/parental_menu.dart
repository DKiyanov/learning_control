import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import 'package:learning_control/platform_service.dart';
import 'package:learning_control/skip_app_list_editor.dart';

import 'app_state.dart';
import 'common.dart';
import 'estimate_list.dart';
import 'expense_list.dart';
import 'log_list.dart';
import 'login.dart';

class ParentalMenu extends StatefulWidget {
  static Future<Object?> navigatorPush(BuildContext context) async {
    return Navigator.push(context, MaterialPageRoute(builder: (_) => const ParentalMenu()));
  }

  const ParentalMenu({Key? key}) : super(key: key);

  @override
  State<ParentalMenu> createState() => _ParentalMenuState();
}

class _ParentalMenuState extends State<ParentalMenu> {
  bool _isStarting = true;
  final _menuAppWidgetList   = <PopupMenuItem<String>>[];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _starting();
    });
  }

  void _starting() async {
    await _prepareMenuAppList();

    setState(() {
      _isStarting = false;
    });
  }

  Future<void> _prepareMenuAppList() async {
    final apps = appState.apps.appList;
    if (!mounted) return;

    for (var app in apps) {
      final appGroup = appState.appSettingsManager.getAppGroup(app.packageName);

      if (appGroup.name == TextConst.txtGroupMenuPassword) {
        _menuAppWidgetList.add(
            PopupMenuItem<String>(
              child: Row( children: [
                SizedBox(height: IconTheme.of(context).size, child: Image.memory(app.icon)),
                Container(width: 6),
                Text(app.appName),
              ]),
              onTap: ()=> _openApp(app.packageName),
            )
        );
        return;
      }
    }
  }

  void _openApp(String packageName) {
    appState.log.add('open app: $packageName');
    DeviceApps.openApp(packageName);
  }

  @override
  Widget build(BuildContext context) {
    if (_isStarting) {
      return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(TextConst.txtStarting),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final bgfExists = appState.getBackgroundImageFile().existsSync();

    final widgetList = <Widget>[];
    widgetList.addAll([
      ElevatedButton(
        onPressed: ()=> EstimateList.navigatorPush(context, appState.childManager.child),
        child: Text(TextConst.txtEstimateList),
      ),

      ElevatedButton(
        onPressed: ()=> ExpenseList.navigatorPush(context, appState.childManager.child),
        child: Text(TextConst.txtExpenseList),
      ),

      ElevatedButton(
        onPressed: ()=> Login.navigate(context).then((value) => setState((){})),
        child: Text(TextConst.txtEntryToOptions,),
      ),

      ElevatedButton(
        onPressed: ()=> LogList.navigatorPush(context),
        child: Text(TextConst.txtLogList),
      ),

      Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: (){
                appState.setBackgroundImage().then((value) {
                  setState(() { });
                });
              } ,
              child: Text(TextConst.txtSetBackgroundImage),
            ),
          ),
          Switch(
            value: appState.backGroundImageOn,
            onChanged: !bgfExists? null : (value){
              setState(() {
                appState.backGroundImageOn = value;
              });
            },
          ),
        ],
      ),

      ElevatedButton(
        onPressed: ()=> PlatformService.restartApp(),
        child: Text(TextConst.txtRestartApp),
      ),
    ]);

    if (appState.monitoring.isOn) {
      widgetList.add(
        ElevatedButton(
          onPressed: (){
            appState.passwordDialog(context).then((value) {
              if (!value) return;
              if (!mounted) return;
              setState(() {
                appState.monitoring.stop();
              });
            });
          },
          child: Text(TextConst.txtMonitoringSwitchOff)
        )
      );
    } else {
      widgetList.addAll([
        ElevatedButton(
            onPressed: (){
              setState(() {
                appState.monitoring.start();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange, // Background color
            ),
            child: Text(TextConst.txtMonitoringSwitchOn)
        ),

        ElevatedButton(
          onPressed: ()=> SkipAppListEditor.navigatorPush(context),
          child: Text(TextConst.txtSkipAppListTuning),
        ),
      ]);

      widgetList.addAll(_menuAppWidgetList);
    }

    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Column(
            children: [
              Text(TextConst.txtParentalMenu),
              Text('${TextConst.version}: ${TextConst.versionDateStr}', style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),

        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListView(
              children: widgetList
          ),
        )
    );
  }

}


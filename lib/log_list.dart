import 'package:flutter/material.dart';
import 'package:learning_control/app_state.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';

import 'common.dart';

class LogList extends StatefulWidget {
  static Future<Object?> navigatorPush(BuildContext context) async {
    return Navigator.push(context, MaterialPageRoute(builder: (_) => const LogList() ));
  }

  const LogList({Key? key}) : super(key: key);

  @override
  State<LogList> createState() => _LogListState();
}

class _LogListState extends State<LogList> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(TextConst.txtLogList),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu),
            itemBuilder: (context) {
              final menuItemList = [
                TextConst.txtSaveLog,
                appState.log.extLogging? TextConst.txtExtLoggingOff : TextConst.txtExtLoggingOn,
              ].map<PopupMenuItem<String>>((value) => PopupMenuItem<String>(
                value: value,
                child: Text(value),
              )).toList();

              return menuItemList;
            },
            onSelected: (value) async {
              if (value == TextConst.txtSaveLog) {
                _saveLog();
              }

              if (value == TextConst.txtExtLoggingOff) {
                setState(() {
                  appState.log.extLogging = false;
                });
              }
              if (value == TextConst.txtExtLoggingOn) {
                setState(() {
                  appState.log.extLogging = true;
                });
              }
            },
          )
        ],
      ),

      body: SafeArea(
        child: Scrollbar(
          thumbVisibility: true,
          trackVisibility: true,
          thickness: 20.0,
          interactive: true,
          child: ListView(
            children: appState.log.logList.map((logStr) => ListTile(title: Text(logStr))).toList(),
          ),
        ),
      ),
    );
  }

  Future<void> _saveLog() async {
    final logObject = ParseObject('LogList');
    for (var logLine in appState.log.logList) {
      logObject.setAdd('line', logLine);
    }
    await logObject.save();
  }
}

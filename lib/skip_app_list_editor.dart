import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:learning_control/app_state.dart';

import 'common.dart';

class SkipAppListEditor extends StatefulWidget {
  static Future<Object?> navigatorPush(BuildContext context) async {
    return Navigator.push(context, MaterialPageRoute(builder: (_) => const SkipAppListEditor() ));
  }

  const SkipAppListEditor({Key? key}) : super(key: key);

  @override
  State<SkipAppListEditor> createState() => _SkipAppListEditorState();
}

class _SkipAppListEditorState extends State<SkipAppListEditor> {

  final _appList = <String>[];
  final _skipAppList = <String>[];

  bool _showAllApp = false;

  @override
  void initState() {
    super.initState();

    _refreshAppList(false);
  }

  void _refreshAppList(bool showAllApp){
    _showAllApp = showAllApp;
    _appList.clear();

    _appList.addAll(appState.skipAppCandidateList);
    _skipAppList.addAll(appState.skipAppList);

    for (var packageName in _skipAppList) {
      if (!_appList.contains(packageName)) _appList.add(packageName);
    }

    if (_showAllApp) {
      for (var app in appState.apps.appList) {
        if (!_appList.contains(app.packageName)) _appList.add(app.packageName);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.cancel_outlined, color: Colors.deepOrangeAccent), onPressed: (){
          Navigator.pop(context);
        }),
        centerTitle: true,
        title: Text(TextConst.txtSkipAppListTuning),
        actions: [
          popupMenu(
              icon: const Icon(Icons.menu),
              menuItemList: [
                if (!_showAllApp) ...[
                  SimpleMenuItem(
                      child: Text(TextConst.txtShowAllApp),
                      onPress: () {
                        setState(() {
                          _refreshAppList(true);
                        });
                      }
                  ),
                ] else ...[
                  SimpleMenuItem(
                      child: Text(TextConst.txtShowOnlyCandidateApp),
                      onPress: () {
                        setState(() {
                          _refreshAppList(false);
                        });
                      }
                  ),
                ],

              ]
          ),

          IconButton(icon: const Icon(Icons.check, color: Colors.lightGreen), onPressed: ()=> saveAndExit() )
        ],
      ),

      body: SafeArea(
        child: ListView(
          children: _appList.map((packageName) {

            String appName = '';
            final app = appState.apps.appList.firstWhereOrNull((app) => app.packageName == packageName);
            if (app != null) appName = app.appName;

            return ListTile(
              leading: StatefulBuilder( builder: (context, checkBoxSetState) {
                final checked = _skipAppList.contains(packageName);

                return IconButton(
                    onPressed: (){
                      checkBoxSetState((){
                        if (checked) {
                          _skipAppList.remove(packageName);
                        } else {
                          _skipAppList.add(packageName);
                        }
                      });
                    },
                    icon: Icon(checked?Icons.check_box_outlined :Icons.check_box_outline_blank)
                );
              }),
              title: Text(packageName),
              subtitle: Text(appName),
            );
          }).toList(),
        ),
      ),
    );
  }

  void saveAndExit() {
    appState.saveSkipAppList(_skipAppList);
    Navigator.pop(context);
  }
}

import 'dart:typed_data';
import 'package:collection/collection.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:learning_control/parse/parse_app/app_access.dart';
import 'package:learning_control/parse/parse_app/parse_app_group.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'package:flutter/material.dart';
import '../common.dart';
import '../app_state.dart';
import '../parse/parse_main.dart';
import '../parse/parse_app/parse_app.dart';
import 'package:simple_events/simple_events.dart';
import 'app_group_editor.dart';
import 'app_group_list.dart';

class AppsTuner extends StatefulWidget {
  static Future<Object?> navigatorPush(BuildContext context, Child child, Device device) async {
    return Navigator.push(context, MaterialPageRoute(builder: (_) => AppsTuner(child, device) ));
  }
  static Future<Object?> navigatorPushReplacement(BuildContext context, Child child, Device device) async {
    return Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AppsTuner(child, device) ));
  }

  const AppsTuner(this.child, this.device, {Key? key}) : super(key: key);

  final Child child;
  final Device device;

  @override
  State<AppsTuner> createState() => _AppsTunerState();
}

class _AppIcon {
  _AppIcon(this.packageName, this.iconData);

  final String     packageName;
  final Uint8List? iconData;
}

class _AppsTunerState extends State<AppsTuner> {
  final _appList       = <DevApp>[];
  final _appIconList   = <_AppIcon>[];
  final _groupList     = <AppGroup>[];
  final _groupNameList = <String>[];
  final _multiSelectList = <DevApp>[];

  bool _massAssign = false;

  final _eventRefreshApp = SimpleEvent();

  bool _isStarting = true;

  final _appFilterList        = <String>[];
  final _textControllerFilter = TextEditingController();
  String _filterMode = TextConst.txtAppManualFilter;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _starting();
    });
  }

  void _starting() async {
    await appState.balanceDirector.balanceManager.setChild(widget.child);

    _appList.addAll(await appState.appManager.getObjectList(widget.device, widget.child, appState.usingMode!));
    await appState.appSettingsManager.load(widget.device, widget.child, appState.usingMode!);

    for (var app in _appList) {
      final iconData = await appState.appManager.getAppIcon(widget.device, app.packageName, appState.usingMode!);
      _appIconList.add(_AppIcon(app.packageName, iconData));
      _appFilterList.add(app.packageName);
    }

    await _refreshGroupList();

    setState(() {
      _isStarting = false;
    });
  }

  Future<void> _refreshGroupList() async {
    _groupList.clear();
    _groupList.addAll((await appState.appGroupManager.getObjectList(appState.serverConnect.user!, appState.usingMode!)).where((group) => !group.deleted && !group.individual ));
    appState.appGroupManager.refreshGroupsAccessInfo(); // Выполняет расчёт доступности приложений
    _groupList.sort((a,b)=>a.name.compareTo(b.name));

    _groupNameList.clear();
    _groupNameList.addAll(_groupList.map((appGroup) => appGroup.name));
    _groupNameList.add(TextConst.txtAddNewGroup);
    _groupNameList.add(TextConst.txtAddIndividualGroup);
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
          leading: IconButton(icon: const Icon(Icons.cancel_outlined, color: Colors.deepOrangeAccent), onPressed: (){
            Navigator.pop(context);
          }),
          centerTitle: true,
          title: Column(children: [
            Text(
              '${widget.child.name} ${widget.device.name}',
              style: const TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold),
            ),
            Text(
              TextConst.txtAppTuner,
              style: const TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold),
            ),
          ]),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.menu),
              itemBuilder: (context) {
                return [
                  TextConst.txtAppGroupsTuning,
                  if (_massAssign) ...[
                    TextConst.txtSingleAssignAppGroup,
                  ] else ...[
                    TextConst.txtMassAssignAppGroup,
                  ]
                ].map<PopupMenuItem<String>>((value) => PopupMenuItem<String>(
                  value: value,
                  child: Text(value),
                )).toList();
              },
              onSelected: (value) async {
                if (value == TextConst.txtAppGroupsTuning) {
                  editGroups();
                }
                if (value == TextConst.txtMassAssignAppGroup) {
                  setState(() {
                    _massAssign = true;
                  });
                }
                if (value == TextConst.txtSingleAssignAppGroup) {
                  setState(() {
                    _massAssign = false;
                  });
                }
              },
            ),
            IconButton(icon: const Icon(Icons.check, color: Colors.lightGreen), onPressed: ()=> saveAndExit() )
          ],
        ),

        body: SafeArea(
          child: Column(
            children: [
              // Фильтр панель
              filterWidget(),

              Expanded(
                child: ListView.builder(
                  itemCount: _appFilterList.length,
                  itemBuilder: _buildAppItem,
                )
              ),
            ],
          ),
        ),

        bottomNavigationBar: _massAssign? BottomAppBar(
          child: Padding(
            padding: const EdgeInsets.only(left: 8, right: 8),
            child: Row(
              children: [
                Expanded(child: Text(TextConst.txtSelGroupForApp)),
                PopupMenuButton<String>(
                  itemBuilder: (context) {
                    return _groupNameList.where((item) => item != TextConst.txtAddIndividualGroup).map<PopupMenuItem<String>>((appGroupName) => PopupMenuItem<String>(
                      value: appGroupName,
                      child: Text(appGroupName),
                    )).toList();
                  },
                  onSelected: (appGroupName) async {
                    AppGroup? appGroup;

                    if (appGroupName == TextConst.txtAddNewGroup) {
                      appGroup = await addNewAppGroup();
                    } else {
                      appGroup = _groupList.firstWhere((appGroup) => appGroup.name == appGroupName);
                    }

                    if (appGroup != null) {
                      final appList = List<DevApp>.from(_multiSelectList);
                      _multiSelectList.clear();
                      for (var app in appList) {
                        appState.appSettingsManager.setAppGroup(app.packageName, appGroup);
                      }
                      _eventRefreshApp.sendFor(appList);
                    }
                  },
                ),
              ],
            ),
          )
      ): null,

    );
  }

  Widget _buildAppWidget(DevApp app) {
    final appGroup = appState.appSettingsManager.getAppGroup(app.packageName);

    Widget? appIconWidget;

    final appIcon = _appIconList.firstWhere((appIcon) => appIcon.packageName == app.packageName);
    if (appIcon.iconData != null) {
      final appInfo = getAppAccess(app.packageName);

      if (appInfo.appAccess == AppAccess.disabled) {
        appIconWidget = ColorFiltered(
          colorFilter: greyscaleColorFilter,
          child: Image.memory(appIcon.iconData!),
        );
      }

      if (appInfo.appAccess == AppAccess.allowed) {
        appIconWidget = Image.memory(appIcon.iconData!);
      }

      if (appInfo.appAccess == AppAccess.hidden) {
        appIconWidget = Container(
            decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.black,
                  width: 2,
                )
            ),

            child: appIconWidget = ColorFiltered(
              colorFilter: greyscaleColorFilter,
              child: Image.memory(appIcon.iconData!),
            )
        );
      }
    }

    Widget? trailing;
    if (!_massAssign){
      trailing = PopupMenuButton<String>(
        itemBuilder: (context) {
          return _groupNameList.map<PopupMenuItem<String>>((appGroupName) => PopupMenuItem<String>(
            value: appGroupName,
            child: Text(appGroupName),
          )).toList();
        },
        onSelected: (appGroupName) async {
          AppGroup? appGroup;

          if (appGroupName == TextConst.txtAddNewGroup) {
            appGroup = await addNewAppGroup();
          }
          if (appGroupName == TextConst.txtAddIndividualGroup) {
            appGroup = await addNewAppGroup(app.packageName);
          }

          appGroup ??= _groupList.firstWhereOrNull((appGroup) => appGroup.name == appGroupName);

          if (appGroup != null) {
            appState.appSettingsManager.setAppGroup(app.packageName, appGroup);
            _eventRefreshApp.sendFor([app]);
          }
        },
      );
    } else {
      trailing = StatefulBuilder( builder: (context, checkBoxSetState) {
        final checked = _multiSelectList.contains(app);

        return IconButton(
            onPressed: (){
              checkBoxSetState((){
                if (checked) {
                  _multiSelectList.remove(app);
                } else {
                  _multiSelectList.add(app);
                }
              });
            },
            icon: Icon(checked?Icons.check_box_outlined :Icons.check_box_outline_blank)
        );
      });
    }

    return ListTile(
      contentPadding: const EdgeInsets.only(left: 10.0, right: 10.0),
      leading: appIconWidget,
      title: Text(app.title),
      subtitle: Text('${app.packageName}\n${appGroup.name}'),
      trailing: trailing,
    );
  }

  Widget _buildAppItem(BuildContext context, int index) {
    final packageName = _appFilterList[index];
    final app = _appList.firstWhere((app) => app.packageName == packageName);

    return EventReceiverWidget(
      key    : ValueKey(app.packageName),
      builder: (_) => _buildAppWidget(app),
      events : [_eventRefreshApp],
      id     : app
    );
  }

  Future<AppGroup?> addNewAppGroup([String appPackageName = '']) async {
    final appGroup = await AppGroupEditor.navigatorPush(context, appPackageName: appPackageName);
    if (appGroup == null) return null;

    await _refreshGroupList();

    return appGroup;
  }

  void saveAndExit() async {
    try {
      await appState.appGroupManager.save(appState.usingMode!);
      await appState.appSettingsManager.save(appState.usingMode!);
    } on ParseError catch (e) {
      Fluttertoast.showToast(msg: e.message);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> editGroups() async {
    await AppGroupList.navigatorPush(context);
    await _refreshGroupList();
    setState(() { });
  }


  List<String> _getFilterMenuList() {
    final menuStringList = <String>[];
    menuStringList.add(TextConst.txtAppManualFilter);

    for (var app in _appList) {
      final appGroup = appState.appSettingsManager.getAppGroup(app.packageName);
      if (!menuStringList.contains(appGroup.name)){
        menuStringList.add(appGroup.name);
      }
    }

    return menuStringList;
  }

  Widget filterWidget() {
    return BottomAppBar(
      child: Row(children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 4, right: 4),
            child: TextField(
              controller: _textControllerFilter,
              readOnly: _filterMode != TextConst.txtAppManualFilter,
              decoration: InputDecoration(
                  filled: true,
                  labelText: TextConst.txtAppFilterValueHint,
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(width: 3, color: Colors.blueGrey),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(width: 3, color: Colors.blue),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      // Меню фильтра
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.arrow_drop_down),
                        itemBuilder: (context) {
                          return _getFilterMenuList().map<PopupMenuItem<String>>((value) => PopupMenuItem<String>(
                            value: value,
                            child: Text(value),
                          )).toList();
                        },

                        onSelected: (value) {
                          setState((){
                            _filterMode = value;
                            _textControllerFilter.clear();
                            _setFilter('');
                          });

                        },
                      ),

                    ],
                  )
              ),
              onChanged: ((value) {
                _setFilter(value);
              }),
            ),
          ),
        )
      ]),
    );
  }

  void _setFilter(String filterStr){
    _appFilterList.clear();

    if (_filterMode == TextConst.txtAppManualFilter) {
      if (filterStr.isNotEmpty) {
        final lowFilterStr = filterStr.toLowerCase();

        for (var app in _appList) {
          final appName = app.title.toLowerCase();
          final packageName = app.packageName.toLowerCase();
          if (appName.contains(lowFilterStr) || packageName.contains(lowFilterStr)){
            _appFilterList.add(app.packageName);
          }
        }
      } else {
        for (var app in _appList) {
          _appFilterList.add(app.packageName);
        }
      }

      setState(() { });
      return;
    }

    _textControllerFilter.text = _filterMode;

    for (var app in _appList) {
      final appGroup = appState.appSettingsManager.getAppGroup(app.packageName);
      if (appGroup.name == _filterMode){
        _appFilterList.add(app.packageName);
      }
    }

    setState(() { });
  }

}
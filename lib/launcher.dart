import 'package:learning_control/check_point_list.dart';
import 'package:learning_control/parental_menu.dart';
import 'package:learning_control/parse/parse_app/app_access.dart';
import 'package:learning_control/parse/parse_check_point.dart';
import 'package:learning_control/platform_service.dart';

import 'app_state.dart';
import 'package:flutter/material.dart';
import 'package:device_apps/device_apps.dart';
import 'common.dart';
import 'package:simple_events/simple_events.dart' as event;

class Launcher extends StatefulWidget {
  static Future<Object?> navigatorSet(BuildContext context) async {
    return Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const Launcher()), (route) => false );
  }

  const Launcher({Key? key}) : super(key: key);

  @override
  State<Launcher> createState() => _LauncherState();
}

class _AppWidget {
  final ApplicationWithIcon app;
  final Widget widget;
  final AppAccessInfo accessInfo;
  late String searchStr;
  _AppWidget(this.app, this.widget, this.accessInfo){
    searchStr = '${app.packageName.toLowerCase()}/@/${app.appName.toLowerCase()}';
  }
}

class _LauncherState extends State<Launcher> {
  static const keyAppOrderList = 'AppOrderList';

  final _appWidgetList       = <_AppWidget>[];
  final _appOrderList        = <String>[];
  final _appFilterList       = <String>[];
  bool _filterOn = false;

  final _bottomAppWidgetList = <Widget>[];
  final _topAppWidgetList    = <Widget>[];
  final _menuAppWidgetList   = <SimpleMenuItem>[];

  bool _isStarting = true;
  bool _synchronization = false;

  final _listenerList = <event.Listener>[];

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
    _appOrderList.clear();
    _appOrderList.addAll( (appState.prefs.getStringList(keyAppOrderList))??[] );

    await _refreshAppList();

    _showBalanceInForegroundService(true);
    appState.balanceDirector.balanceManager.registerListener((minutes) {
      _showBalanceInForegroundService(false);
      _refresh();
    });

    _listenerList.addAll([
      appState.launcherRefreshEvent.subscribe((listener, data){
        _refresh();
      }),

      appState.monitoring.checkPointConditionChangedEvent.subscribe((listener, data){
        if (appState.checkPointManager.condition != CheckPointCondition.free) {
          _showCheckPointMessage();
        }
        setState(() { });
      }),
    ]);

    setState(() {
      _isStarting = false;
    });
  }

  void _showBalanceInForegroundService(bool starting) {
    if (appState.deviceType == DeviceType.tv) {
      if (starting){
        PlatformService.foregroundService(TextConst.txtTVServiceTitle, '');
      }
      return;
    }

    PlatformService.foregroundService('${TextConst.txtBalanceValue}: ${appState.balanceDirector.balanceManager.balance.minutes}', '');
  }

  @override
  void dispose(){
    _textControllerFilter.dispose();

    for (var listener in _listenerList) {
      listener.dispose();
    }

    super.dispose();
  }

  _AppWidget? getAppWidget(ApplicationWithIcon app){
    AppAccess appAccess = AppAccess.allowed;

    final appAccessInfo = getAppAccess(app.packageName);
    if (appState.monitoring.isOn){ // мониторинг включен
      appAccess = appAccessInfo.appAccess;
    }

    if (appAccess == AppAccess.hidden) return null;
    Widget? appIconWidget;

    if (appAccess == AppAccess.disabled) {
      appIconWidget = ColorFiltered(
        colorFilter: greyscaleColorFilter,
        child: Image.memory(app.icon),
      );
    }

    if (appAccess == AppAccess.allowed) {
      appIconWidget = Image.memory(app.icon);
    }

    final items = <SimpleMenuItem>[];
    items.addAll([
      SimpleMenuItem(
        child: Text(TextConst.txtDelete),
        onPress: (){
          appState.deleteApp(app.packageName).then((value) => _refresh());
        },
      )
    ]);

    final appIconWidgetEx = longPressMenu(
      context     : context,
      child       : appIconWidget!,
      menuItemList: items,
    );

    final appTile = ListTile(
      contentPadding: const EdgeInsets.all(10.0),
      leading: appIconWidgetEx,
      title: Text(app.appName),
      subtitle: appAccess != AppAccess.allowed? Text(appAccessInfo.message): null,
      enabled: appAccess != AppAccess.disabled,
      onTap: () => _openApp(app.packageName),
    );

    return _AppWidget(app, appTile, appAccessInfo);
  }

  Future<void> _refreshAppList() async {
    _appWidgetList.clear();
    _bottomAppWidgetList.clear();
    _topAppWidgetList.clear();
    _menuAppWidgetList.clear();

    appState.appGroupManager.refreshGroupsAccessInfo();

    final apps = appState.apps.appList;
    for (var app in apps) {
      prepareAppWidget(app);
    }

    for (var app in _appWidgetList) {
      if (!_appOrderList.contains(app.app.packageName)){
        _appOrderList.add(app.app.packageName);
      }
    }

    final appToDel = <String>[];
    for (var packageName in _appOrderList) {
      if (!_appWidgetList.any((app) => app.app.packageName == packageName )) {
        appToDel.add(packageName);
      }
    }

    for (var packageName in appToDel) {
      _appOrderList.remove(packageName);
    }
  }

  void prepareAppWidget(ApplicationWithIcon app){
    final appGroup = appState.appSettingsManager.getAppGroup(app.packageName);

    if (appGroup.name == TextConst.txtGroupBottomPanel) {
      _bottomAppWidgetList.add(IconButton(
        onPressed: ()=> _openApp(app.packageName),
        icon: Image.memory(app.icon),
      ));
      return;
    }
    if (appGroup.name == TextConst.txtGroupTopPanel) {
      _topAppWidgetList.add(IconButton(
        onPressed: ()=> _openApp(app.packageName),
        icon: Image.memory(app.icon),
      ));
      return;
    }
    if (appGroup.name == TextConst.txtGroupMenu) {
      _menuAppWidgetList.add(
        SimpleMenuItem(
          child: Row( children: [
            SizedBox(height: IconTheme.of(context).size, child: Image.memory(app.icon)),
            Container(width: 6),
            Text(app.appName),
          ]),
          onPress: ()=> _openApp(app.packageName),
        )
      );
      return;
    }
    if (appGroup.name == TextConst.txtGroupMenuPassword) {
      return;
    }

    final appWidget = getAppWidget(app);
    if (appWidget != null) _appWidgetList.add(appWidget);
  }

  Future<void> _refresh() async {
    _refreshAppList();

    if (!mounted) return;
    setState(() { });
  }

  Widget _buildAppItems(BuildContext context, int index) {
    String packageName = '';
    if (_filterOn) {
      packageName = _appFilterList[index];
    } else {
      packageName = _appOrderList[index];
    }

    final appWidget = _appWidgetList.firstWhere((appWidget) => appWidget.app.packageName == packageName);

    return Container(
      key: Key(appWidget.app.packageName),
      child: appWidget.widget
    );
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

    Widget appList;
    if (_filterOn) {
      appList = ListView.builder(
          itemBuilder: _buildAppItems,
         itemCount: _appFilterList.length,
      );
    } else {
      appList = ReorderableListView.builder(
        itemBuilder: _buildAppItems,
        itemCount: _appOrderList.length,
        onReorder: (int oldIndex, int newIndex) {
          setState(() {
            if (oldIndex < newIndex) {
              newIndex -= 1;
            }
            final item = _appOrderList.removeAt(oldIndex);
            _appOrderList.insert(newIndex, item);
            appState.prefs.setStringList(keyAppOrderList, _appOrderList);
          });
        },
      );
    }

    DecorationImage? backgroundImageWidget;
    if (appState.backGroundImageOn) {
      backgroundImageWidget = DecorationImage(
          image: appState.backgroundImage!,
          fit: BoxFit.cover
      );
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Container(
        constraints: const BoxConstraints.expand(),
        decoration: BoxDecoration(
          color: Colors.white,
          image: backgroundImageWidget
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              children: [
                // Верхняя панель
                BottomAppBar(
                  color: Colors.transparent,
                  child: Row(children: _topAppWidgetList),
                ),

                // Фильтр панель
                if (_filterOn) ...[
                  filterWidget()
                ],

                Expanded(
                  child: appList,
                ),
              ],
            ),
          ),

          bottomNavigationBar: BottomAppBar(
            color: Colors.transparent,
            child: Row(children: [
              popupMenu(
                  icon: const Icon(Icons.menu, color: Colors.blue),
                  menuItemList: [
                    SimpleMenuItem(
                        child: Text(TextConst.txtAppFilterShow),
                        onPress: () {
                          setState(() {
                            _appFilterList.clear();
                            _appFilterList.addAll(_appOrderList);
                            _filterOn = true;
                            _filterMode = TextConst.txtAppManualFilter;
                          });
                        }
                    ),

                    SimpleMenuItem(
                        child: Text(TextConst.txtCheckPointList),
                        onPress: () {
                          CheckPointList.navigatorPush(context, appState.childManager.child, true);
                        }
                    ),

                    SimpleMenuItem(
                        child: Text(TextConst.txtParentalMenu),
                        onPress: () {
                          ParentalMenu.navigatorPush(context).then((value) {
                            if (mounted) _refresh();
                          });
                        }
                    ),

                    ... _menuAppWidgetList,
                  ]
              ),

              // Баланс:
              Container(
                padding: const EdgeInsets.all(5.0),
                decoration: BoxDecoration(
                    color: Colors.lime,
                    border: Border.all(
                      color: Colors.lime,
                    ),
                    borderRadius: const BorderRadius.all(Radius.circular(20))
                ),
                child: Text(' ${TextConst.txtBalanceValue}: ${appState.balanceDirector.balanceManager.balance.minutes} '),
              ),

              // Кнопка обновления
              IconButton(
                icon: Icon(_synchronization? Icons.timelapse : Icons.refresh, color: Colors.blue),
                onPressed: _synchronization? null : () async {
                  appState.log.add('button synchronize pressed');
                  setState(() {
                    _synchronization = true;
                  });
                  await appState.serverConnect.synchronize(showErrorToast: true, ignoreShortTime: true);
                  _synchronization = false;
                  _refresh();
                }
              ),

              // Кнопка наличия задач (CheckPoint)
              if (appState.checkPointManager.condition != CheckPointCondition.free) ...[
                IconButton(
                    icon: appState.checkPointManager.condition == CheckPointCondition.lock?
                      const Icon(Icons.lock, color: Colors.deepOrange) :
                      const Icon(Icons.warning, color: Colors.yellow),

                    onPressed: ()=> _showCheckPointMessage()
                ),
              ],

              // Приложения из группы "Нижняя панель"
              ..._bottomAppWidgetList
            ],)
          ),

        ),
      ),
    );

  }

  Future<bool> _onWillPop() async {
    return false;
  }

  void _openApp(String packageName) {
    if (_synchronization) return;
    appState.openApp(packageName).then((value) => _refresh());
  }

  List<String> _getFilterMenuList() {
    final menuStringList = <String>[];
    menuStringList.addAll([
      TextConst.txtAppManualFilter,
      TextConst.txtAppAvailableFilter,
    ]);

    for (var appWidget in _appWidgetList) {
      if (!menuStringList.contains(appWidget.accessInfo.appGroup.name)){
        menuStringList.add(appWidget.accessInfo.appGroup.name);
      }
    }

    return menuStringList;
  }

  Widget filterWidget() {
    return BottomAppBar(
      color: Colors.transparent,
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
                      popupMenu(
                          icon: const Icon(Icons.arrow_drop_down),
                          menuItemList: _getFilterMenuList().map<SimpleMenuItem>((value) => SimpleMenuItem(
                            child: Text(value),
                            onPress: () {
                              setState((){
                                _filterMode = value;
                                _textControllerFilter.clear();
                                _setFilter('');
                              });
                            }
                          )).toList()
                      ),

                      IconButton(
                          onPressed: () {
                            setState(() {
                              _filterOn = false;
                            });
                          },
                          icon: const Icon(Icons.close)
                      )
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

        for (var packageName in _appOrderList) {
          final app = _appWidgetList.firstWhere((app) => app.app.packageName == packageName);
          if (app.searchStr.contains(lowFilterStr)){
            _appFilterList.add(packageName);
          }
        }
      } else {
        _appFilterList.addAll(_appOrderList);
      }

      setState(() { });
      return;
    }

    _textControllerFilter.text = _filterMode;

    if (_filterMode == TextConst.txtAppAvailableFilter) {
      for (var packageName in _appOrderList) {
        final app = _appWidgetList.firstWhere((app) => app.app.packageName == packageName);
        if (app.accessInfo.appAccess == AppAccess.allowed){
          _appFilterList.add(packageName);
        }
      }

      setState(() { });
      return;
    }

    for (var packageName in _appOrderList) {
      final app = _appWidgetList.firstWhere((app) => app.app.packageName == packageName);
      if (app.accessInfo.appGroup.name == _filterMode){
        _appFilterList.add(packageName);
      }
    }

    setState(() { });
  }

  void _showCheckPointMessage() {
    appState.checkPointManager.refreshCondition();
    final checkPointList = appState.checkPointManager.getCheckPoints(forWarning: true, forLock: true);

    String titleText = '';
    if (checkPointList.isEmpty) return;

    if (appState.checkPointManager.condition == CheckPointCondition.lock) {
      titleText = TextConst.txtCheckPointLock;
    } else {
      titleText = TextConst.txtCheckPointWarning;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(titleText),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: checkPointList.map((checkPoint) => ListTile(
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                tileColor: checkPoint.condition == CheckPointCondition.lock? Colors.deepOrange : Colors.yellow,
                title: Text(checkPoint.taskText),
              )).toList(),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.check, color: Colors.lightGreen),
              onPressed: () {
                Navigator.pop(context);
              }
            ),
          ],
        );
      }
    );
  }
}


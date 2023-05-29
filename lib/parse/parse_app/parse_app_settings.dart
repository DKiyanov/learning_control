import 'package:collection/collection.dart';
import 'package:learning_control/parse/parse_app/parse_app_group.dart';
import '../../app_state.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import '../parse_main.dart';
import '../parse_util.dart';

/// Настройки приложения
class AppSettings extends ParseObject implements ParseCloneable {
  static const String keyAppSettings = 'AppSettings';

  static const String keyDeviceID       = 'DeviceID';
  static const String keyChildID        = 'ChildID';

  static const String keyPackageName    = 'PackageName';
  static const String keyAppGroupID   = 'AppGroupID';
  static const String keyLastChangeTime = ParseList.lastChangeTimeKey; // millisecondsSinceEpoch в момент изменения

  AppSettings() : super(keyAppSettings);
  AppSettings.clone() : this();

  @override
  AppSettings clone(Map<String, dynamic> map) => AppSettings.clone()..fromJson(map);

  String get packageName    => get<String>(keyPackageName)??'';

  AppGroup get appGroup {
    final appGroupID = get<String>(keyAppGroupID)??'';
    final appGroup = appState.appGroupManager.getFromID(appGroupID);
    if (!appGroup.deleted) return appGroup;
    return appState.appGroupManager.defaultAppGroup;
  }
  set appGroup(AppGroup appGroup){
    set(keyAppGroupID   , appGroup.localObjectID );
    set(keyLastChangeTime , DateTime.now().millisecondsSinceEpoch );
  }

  int get lastChangeTime  => get<int>(keyLastChangeTime)??0;

  static AppSettings createNew(Device device, Child child, String packageName, AppGroup appGroup){
    final newAppSettings = AppSettings();
    newAppSettings.set(keyDeviceID       , device.objectId     );
    newAppSettings.set(keyChildID        , child.objectId      );
    newAppSettings.set(keyPackageName    , packageName         );
    newAppSettings.set(keyAppGroupID     , appGroup.localObjectID );
    newAppSettings.set(keyLastChangeTime , DateTime.now().millisecondsSinceEpoch );
    return newAppSettings;
  }
}

class AppSettingsManager {
  final _appSettingsList  = <AppSettings>[];

  Device? _device;
  Child?  _child;

  int savedLastChangeTime = 0;

  /// Возвращает ограничения настроенные для приложения
  AppGroup getAppGroup(String packageName) {
    final appSettings = _appSettingsList.firstWhereOrNull((app) => app.packageName == packageName);
    if (appSettings != null) return appSettings.appGroup;
    if (appState.apps.hiddenAppList.contains(packageName)) return appState.appGroupManager.hiddenAppGroup;
    return appState.appGroupManager.defaultAppGroup;
  }

  /// Устанавливает ограничения для приложения
  setAppGroup(String packageName, AppGroup appGroup){
    final app = _appSettingsList.firstWhereOrNull((app) => app.packageName == packageName);
    if (app == null) {
      final app = AppSettings.createNew(_device!, _child!, packageName, appGroup);
      _appSettingsList.add(app);
    } else {
      app.appGroup = appGroup;
    }
  }

  Future<void> init(Device device, Child child) async {
    if (_appSettingsList.isNotEmpty) return;
    _device = device;
    _child  = child;
    final localObjectList = await ParseList.getLocal<AppSettings>(AppSettings.keyAppSettings, ()=> AppSettings() );
    _appSettingsList.addAll(localObjectList);

    await _deleteExcessApp();
  }

  /// Синхронизация локальных данных и данных на сервере
  Future<void> synchronize() async {
    await _deleteExcessApp();

    final serverObjectList = await _getServerObjectList(_device!, _child!);

    final localSaveNeed = await ParseList.synchronizeLists(_appSettingsList, serverObjectList);

    if (localSaveNeed) {
      await _saveLocal();
    }

    savedLastChangeTime = ParseList.getMaxLastChangeTime(_appSettingsList);
  }

  Future<void> _saveLocal() async {
    savedLastChangeTime = await ParseList.saveLocal(_appSettingsList, AppSettings.keyAppSettings, savedLastChangeTime);
  }

  /// Удаляет лишние (удалённые) приложения
  Future<void> _deleteExcessApp() async {
    final appList = appState.apps.appList;
    bool localSaveNeed = false;

    final toRemove = <AppSettings>[];

    for (var appSettings in _appSettingsList) {
      if (!appList.any((app) => app.packageName == appSettings.packageName)) {
        await appSettings.unpin();
        toRemove.add(appSettings);
        localSaveNeed = true;
      }
    }

    for (var appSettings in toRemove) {
      _appSettingsList.remove(appSettings);
    }

    if (localSaveNeed) _saveLocal();
  }

  /// возвращает список объектов на сервере
  Future<List<AppSettings>> _getServerObjectList(Device device, Child child) async {
    final query = QueryBuilder<AppSettings>(AppSettings());
    query.whereEqualTo(AppSettings.keyDeviceID, device.objectId);
    query.whereEqualTo(AppSettings.keyChildID , child.objectId);
    return await query.find();
  }

  /// Формирует список настроек для приложений
  Future<void> load(Device device, Child child, UsingMode usingMode) async {
    _device = device;
    _child  = child;
    if (usingMode == UsingMode.child || usingMode == UsingMode.withoutServer){
      return;  // список формируется при вызове synchronize
    }

    _appSettingsList.clear();
    _appSettingsList.addAll(await _getServerObjectList(device, child));

    savedLastChangeTime = ParseList.getMaxLastChangeTime(_appSettingsList);
  }

  Future<void> save(UsingMode usingMode) async {
    if (usingMode == UsingMode.child || usingMode == UsingMode.withoutServer){
      synchronize();
      return;
    }

    savedLastChangeTime = await ParseList.saveServer(_appSettingsList, savedLastChangeTime);
  }
}


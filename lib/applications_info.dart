import 'package:collection/collection.dart';
import 'package:device_apps/device_apps.dart';
import 'log.dart';
import 'platform_service.dart';

class ApplicationsInfo {
  final _appList = <ApplicationWithIcon>[];
  final _hiddenAppList = <String>[];
  final _ignoreAppList = <String>[];

  Iterable<ApplicationWithIcon> get appList => _appList;
  Iterable<String> get hiddenAppList => _hiddenAppList;
  Iterable<String> get ignoreAppList => _ignoreAppList;

  late String _selfPackageName;

  final Log _log;

  ApplicationsInfo(this._log);

  Future<void> init() async {
    _selfPackageName = await PlatformService.getPackageName();
    await _prepareHiddenAppList();
    await _prepareIgnoreAppList();
    await refreshAppList();
  }

  /// подготавливает список скрытых приложений
  /// они не выгружаются, и нигде не видны для настрийки или использования
  /// для этих приложений опрделяется группа приложений "Скрытые" "Hidden"
  Future<void> _prepareHiddenAppList() async {

    final launchers = await PlatformService.getLaunchers();

    _hiddenAppList.clear();
    _hiddenAppList.addAll(launchers.split(';'));

    if (!_hiddenAppList.contains(_selfPackageName)){
      _hiddenAppList.add(_selfPackageName);
    }

    const settings = 'com.android.settings';
    if (!_hiddenAppList.contains(settings)) {
      _hiddenAppList.add(settings);
    }
  }

  /// Обновляет список приложений на устройстве
  Future<void> refreshAppList() async {
    final apps = await DeviceApps.getInstalledApplications(includeAppIcons: true, includeSystemApps: true, onlyAppsWithLaunchIntent: true);
    await _prepareHiddenAppList();
    apps.removeWhere((app) => _hiddenAppList.contains(app.packageName) );

    _appList.clear();
    _appList.addAll( apps.map((app) => app as ApplicationWithIcon) );
  }

  /// Возращает список приложений для которых в мониторинге не должно быть никакой реакции
  Future<void> _prepareIgnoreAppList() async {
    _ignoreAppList.clear();
    _ignoreAppList.addAll([
      _selfPackageName,
      'android',
      'com.google.android.packageinstaller',
//      'com.google.android.apps.nexuslauncher', // TODO remove this
    ]);
  }

  ApplicationWithIcon? getApp(String packageName){
    final app = _appList.firstWhereOrNull((app) => app.packageName == packageName);
    if (app == null){
      _log.add('getApp "$packageName" not found, _appList.length = ${_appList.length}');
    }
    return app;
  }
}

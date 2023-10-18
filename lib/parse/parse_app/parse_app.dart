import 'dart:typed_data';
import 'package:collection/collection.dart';
import '../../app_state.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import '../parse_main.dart';

/// Зпаись приложения установленного на устройстве
class DevApp extends ParseObject implements ParseCloneable {
  static const String keyDevApp      = 'DevApp';

  static const String keyDeviceID    = 'DeviceID';
  static const String keyChildID     = 'ChildID';

  static const String keyPackageName = 'PackageName';
  static const String keyTitle       = 'Title';

  DevApp() : super(keyDevApp);
  DevApp.clone() : this();

  @override
  DevApp clone(Map<String, dynamic> map) => DevApp.clone()..fromJson(map);

  String get packageName => get<String>(keyPackageName)??'';
  String get title       => get<String>(keyTitle)??'';

  static DevApp createNew(Device device, Child child, String packageName, String title) {
    final newDevApp = DevApp();
    newDevApp.set(keyDeviceID    , device.objectId );
    newDevApp.set(keyChildID     , child.objectId  );
    newDevApp.set(keyPackageName , packageName     );
    newDevApp.set(keyTitle       , title           );
    return newDevApp;
  }
}

class DevAppIcon extends ParseObject implements ParseCloneable {
  static const String keyDevAppIcon  = 'DevAppIcon';

  static const String keyDeviceID    = 'DeviceID';
  static const String keyPackageName = 'PackageName';
  static const String keyIcon        = 'Icon';

  DevAppIcon() : super(keyDevAppIcon);
  DevAppIcon.clone() : this();

  @override
  DevAppIcon clone(Map<String, dynamic> map) => DevAppIcon.clone()..fromJson(map);

  String get packageName => get<String>(keyPackageName)!;
  ParseFile get icon => get<ParseFile>(keyIcon)!;

  static DevAppIcon createNew(Device device, String packageName, ParseWebFile icon) {
    final newDevAppIcon = DevAppIcon();
    newDevAppIcon.set(keyDeviceID    , device.objectId );
    newDevAppIcon.set(keyPackageName , packageName     );
    newDevAppIcon.set(keyIcon        , icon            );
    return newDevAppIcon;
  }
}

class AppManager {
  Device? _device;
  Child?  _child;
  final _appIconList = <DevAppIcon>[];

  Future<void> init(Device device, Child child) async {
    _device = device;
    _child  = child;
  }

  /// Синхронизирует список приложений устройство <-> сервер
  Future<void> synchronize() async {
    await appState.apps.refreshAppList();
    final localObjectList  = appState.apps.appList;
    final serverObjectList = await _getServerObjectList(_device!, _child!);

    // удаляем лишние с сервера
    for (var serverObject in serverObjectList) {
      if (!localObjectList.any((localObject) => localObject.packageName == serverObject.packageName)) {
        await serverObject.delete();
      }
    }

    // добавляем недостающие
    for (var localObject in localObjectList) {
      if (!serverObjectList.any((appGroup) => appGroup.packageName == localObject.packageName)) {
        final iconFile = ParseWebFile(localObject.icon, name : localObject.packageName);
        await iconFile.save();
        await DevAppIcon.createNew(_device!, localObject.packageName, iconFile).save();
        await DevApp.createNew(_device!, _child!, localObject.packageName, localObject.appName).save();
      }
    }
  }

  /// возвращает список приложений этого устройства зарегистрированных на сервере
  Future<List<DevApp>> _getServerObjectList(Device device, Child child) async {
    final query = QueryBuilder<DevApp>(DevApp());
    query.whereEqualTo(DevApp.keyDeviceID, device.objectId);
    query.whereEqualTo(DevApp.keyChildID , child.objectId);

    return await query.find();
  }

  /// возвращает список приложений
  Future<List<DevApp>> getObjectList(Device device, Child child, UsingMode usingMode) async {
    if (usingMode == UsingMode.child) {
      final appList = appState.apps.appList;

      return appList.map((app){
        return DevApp.createNew(device, child, app.packageName, app.appName);
      }).toList();
    }

    return await _getServerObjectList(device, child);
  }

  Future<Uint8List?> getAppIcon(Device device, String packageName, UsingMode usingMode) async {
    if (usingMode == UsingMode.child) {
      return appState.apps.getApp(packageName)!.icon;
    }

    // usingMode == UsingMode.parent
    final devAppIcon = _appIconList.firstWhereOrNull((devAppIcon) => devAppIcon.packageName == packageName);
    if (devAppIcon != null) {
      return devAppIcon.icon.file!.readAsBytes();
    }

    final query = QueryBuilder<DevAppIcon>(DevAppIcon());
    query.whereEqualTo(DevAppIcon.keyDeviceID, device.objectId);
    query.whereEqualTo(DevAppIcon.keyPackageName, packageName);

    final iconList = await query.find();
    if (iconList.isEmpty) return null;

    final newDevAppIcon = iconList[0];

    await newDevAppIcon.icon.loadStorage();
    if ( newDevAppIcon.icon.file == null){
      await newDevAppIcon.icon.download();
    }

    _appIconList.add(newDevAppIcon);

    return await newDevAppIcon.icon.file!.readAsBytes();
  }
}


import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../platform_service.dart';

/// Запись ребёнка
class Child extends ParseObject implements ParseCloneable {
  static const String keyChild  = 'Child';

  static const String keyUserID = 'UserID';
  static const String keyName   = 'Name';

  Child() : super(keyChild);
  Child.clone() : this();

  @override
  Child clone(Map<String, dynamic> map) => Child.clone()..fromJson(map);

  String get name => get<String>(keyName)??'';

  static Child createNew(String childName, ParseUser user){
    final newChild = Child();
    newChild.set(keyUserID, user.objectId);
    newChild.set(keyName, childName);
    return newChild;
  }  
  
  void modify(String childName) {
    set(keyName, childName);
  }
}

/// Обеспечивает хранение записи ребёнка как singleton
class ChildManager {
  static const String keyChildID = 'ChildID';

  Child? _child;
  Child get child => _child!; // должно быть иницализировано с помощью initCurrentChild()

  Future<void> initCurrentChild() async {
    if (_child != null) return;

    final prefs = await SharedPreferences.getInstance();
    final childID = prefs.getString(keyChildID)??'';

    if (childID.isEmpty) return;

    _child = await Child().fromPin(childID);
  }

  Child? getCurrentChild() => _child;

  Future<bool> setChildAsCurrent( Child newChild) async {
    if (_child != null) {
      await _child!.unpin();
    }

    if (newChild.objectId == null || newChild.objectId!.isEmpty){
      await newChild.save();
    }

    final childID = newChild.objectId??'';
    if (childID.isEmpty) return false;

    await newChild.pin();

    final prefs = await SharedPreferences.getInstance();
    prefs.setString(keyChildID, childID);

    _child = newChild;

    return true;
  }

  Future<Child?> updateCurrentChild(String childName, ParseUser user) async {
    if (_child != null){
      _child!.modify(childName);
      await _child!.save();
      return _child;
    }

    final newChild = Child.createNew(childName, user);

    if (!(await setChildAsCurrent(newChild))) return null;

    return newChild;
  }

  Future<List<Child>> getChildList(ParseUser user) async {
    final query = QueryBuilder<Child>(Child());
    query.whereEqualTo(Child.keyUserID, user.objectId);
    return await query.find();
  }
}

/// Запись устройства
class Device extends ParseObject implements ParseCloneable {
  static const String keyDevice = 'Device';

  static const String keyUserID     = 'UserID';
  static const String keyChildID    = 'ChildID';
  static const String keyName       = 'Name';
  static const String keyColor      = 'Color';
  static const String keyDeviceOSID = 'DeviceOSID';

  Device() : super(keyDevice);
  Device.clone() : this();

  @override
  Device clone(Map<String, dynamic> map) => Device.clone()..fromJson(map);

  String get name    => get<String>(keyName)??'';
  int    get color   => get<int>(keyColor)??0;
  String get childID => get<String>(keyChildID)??'';

  static Future<Device> createNew(ParseUser user, Child child, String deviceName, int color) async {
    final deviceOSID = await PlatformService.getDeviceID();

    final newDevice = Device();
    newDevice.set(keyUserID  , user.objectId  );
    newDevice.set(keyChildID , child.objectId );
    newDevice.set(keyName    , deviceName     );
    newDevice.set(keyColor   , color          );
    newDevice.set(keyDeviceOSID, deviceOSID   );
    return newDevice;
  }

  void modify(String deviceName, int color) {
    set(keyName    , deviceName     );
    set(keyColor   , color          );
  }
}

/// Обеспечивает хранение записи устройства как singleton
class DeviceManager {
  static const String keyDeviceID = 'DeviceID';

  Device? _device;
  Device get device => _device!; // должно быть инициализировано с помощью initCurrentDevice()

  Future<void> initCurrentDevice() async {
    if (_device != null) return;

    final prefs = await SharedPreferences.getInstance();
    final deviceID = prefs.getString(keyDeviceID)??'';

    if (deviceID.isEmpty) return;

    _device = await Device().fromPin(deviceID);
  }

  Device? getCurrentDevice() => _device;

  Future<Device?> updateCurrentDevice(String deviceName, int color, ParseUser user, Child child) async {
    if (_device != null) {
      _device!.modify(deviceName, color);
      await _device!.save();
      return _device;
    }

    final newDevice = await Device.createNew(user, child, deviceName, color);
    await newDevice.save();

    await setDeviceAsCurrent(newDevice);

    _device = newDevice;
    return newDevice;
  }

  Future<bool> setDeviceAsCurrent(Device newDevice) async {
    if (_device != null) {
      await _device!.unpin();
    }

    if (newDevice.objectId == null || newDevice.objectId!.isEmpty){
      await newDevice.save();
    }

    final deviceID = newDevice.objectId??'';
    if (deviceID.isEmpty) return false;

    await newDevice.pin();

    final prefs = await SharedPreferences.getInstance();
    prefs.setString(keyDeviceID, deviceID);

    _device = newDevice;

    return true;
  }

  Future<List<Device>> getDeviceList(ParseUser user) async {
    final query = QueryBuilder<Device>(Device());
    query.whereEqualTo(Device.keyUserID, user.objectId);
    return await query.find();
  }

  Future<bool> deleteDevice(Device device) async {
    final result = await device.delete();
    // здесь удаляется только заголовок
    // остальные связанные данные должны удаляться по тригеру на сервере

    return result.success;
  }

  Future<Device?> getFromDeviceOSID(ParseUser user) async {
    final deviceOSID = await PlatformService.getDeviceID();

    final query = QueryBuilder<Device>(Device());
    query.whereEqualTo(Device.keyUserID, user.objectId);
    query.whereEqualTo(Device.keyDeviceOSID, deviceOSID);

    return await query.first();
  }
}
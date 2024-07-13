import 'dart:async';

import 'package:collection/collection.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'platform_service.dart';
import 'package:flutter/material.dart';
import 'common.dart';
import 'app_state.dart';
import 'parse/parse_main.dart';


class Options extends StatefulWidget {
  static Future<Object?> navigatorPush(BuildContext context) async {
    return Navigator.push(context, MaterialPageRoute(builder: (_) => const Options()));
  }
  static Future<Object?> navigatorPushReplacement(BuildContext context) async {
    return Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Options()));
  }

  final VoidCallback? onOptionsOk;
  const Options({this.onOptionsOk, Key? key}) : super(key: key);

  @override
  State<Options> createState() => _OptionsState();
}

class _OptionsState extends State<Options> {
  bool _isStarting = true;

  bool _ignoringBatteryOptimizationsOk = false;
  bool _usageAccessOk  = false;
  bool _drawOverlaysOk = false;
  bool _launcherOk     = false;

  Timer? _checkSettingsTimer;

  bool _isControlOn    = false;

  bool _obscurePinCode = true;
  bool _obscurePinCodeChanged = false;

  bool _somethingChanged = false;

  Child? _child;
  Device? _device;

  String _oldDeviceName  = '';
  String _oldChildName   = '';
  
  Child? _selChild;
  bool _addNewChild = false;

  Device? _selDevice;
  bool _addNewDevice = false;
  
  final _childList = <Child>[];
  final _childNameList = <String>[];

  final _deviceList = <Device>[];
  final _deviceNameList = <String>[];  
  
  final _textControllerChildName   = TextEditingController();
  final _textControllerDeviceName  = TextEditingController();
  final _textControllerPinCode     = TextEditingController();
  final _textControllerPinCodeClue = TextEditingController();

  bool _serverAvailable = false;

  @override
  void initState() {
    super.initState();

    appState.log.add('Options page displayed');

    appState.monitoring.stop();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _starting();
    });
  }

  @override
  void dispose() {
    _textControllerChildName.dispose();
    _textControllerDeviceName.dispose();
    _textControllerPinCode.dispose();
    _textControllerPinCodeClue.dispose();

    _checkSettingsTimer?.cancel();

    super.dispose();

    appState.monitoring.setMonitoring();
  }

  void _starting() async {
    _serverAvailable = await appState.serverConnect.isServerAvailable();

    if (_serverAvailable) {
      _childList.addAll(await appState.childManager.getChildList(appState.serverConnect.user!));
      _childNameList.addAll(_childList.map((child) => child.name).toList());
      _childNameList.add(TextConst.txtAddNewChild);

      _deviceList.addAll(await appState.deviceManager.getDeviceList(appState.serverConnect.user!));
      _deviceNameList.addAll(_deviceList.map((device) => device.name).toList());
      _deviceNameList.add(TextConst.txtAddNewDevice);      
    }

    _child  = appState.childManager.getCurrentChild();
    _device = appState.deviceManager.getCurrentDevice();

    if (_child != null) {
      _textControllerChildName.text = _child!.name;
      _oldChildName = _child!.name;
    }
    if (_device != null) {
      _textControllerDeviceName.text = _device!.name;
      _oldDeviceName = _device!.name;
    }

    if (_child == null && _device == null && _deviceList.isNotEmpty) {
      _selDevice = await appState.deviceManager.getFromDeviceOSID(appState.serverConnect.user!);
      if (_selDevice != null) {
        _textControllerDeviceName.text = _selDevice!.name;
        _selChild = _childList.firstWhereOrNull( (child) => child.objectId == _selDevice!.childID);
        if (_selChild != null) {
          _textControllerChildName.text = _selChild!.name;
        }
        _somethingChanged = true;
      }
    }

    _ignoringBatteryOptimizationsOk = await PlatformService.isIgnoringBatteryOptimizations();
    _usageAccessOk  = await PlatformService.isUsageAccessExists();
    _drawOverlaysOk = await PlatformService.isCanDrawOverlays();
    _launcherOk     = await PlatformService.isMyLauncherDefault();

    _isControlOn = appState.monitoring.status;

    _textControllerPinCodeClue.text = appState.pinCodeManager.clue;

    _checkSettingsTimer = Timer.periodic(const Duration(seconds: 1), (timer) => _checkSettings() );

    setState(() {
      _isStarting = false;
    });
  }

  void _checkSettings() {
    if (_isStarting) return;
    if (!mounted) return;

    PlatformService.isIgnoringBatteryOptimizations().then((value) {
      if (_ignoringBatteryOptimizationsOk == value) return;
      setState(() {
        _ignoringBatteryOptimizationsOk = value;
      });
    });

    PlatformService.isUsageAccessExists().then((value) {
      if (_usageAccessOk == value) return;
      setState(() {
        _usageAccessOk = value;
      });
    });

    PlatformService.isCanDrawOverlays().then((value) {
      if (_drawOverlaysOk == value) return;
      setState(() {
        _drawOverlaysOk = value;
      });
    });

    PlatformService.isMyLauncherDefault().then((value) {
      if (_launcherOk == value) return;
      setState(() {
        _launcherOk = value;
      });
    });
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

    final bool controlSwitchEnabled = _usageAccessOk && _drawOverlaysOk && _launcherOk;

    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(TextConst.txtOptions),
        ),

        body: ListView(
          children: [

            // Запуск настройки "Игнорирование оптимизации расхода энергии"
            ExpansionTile(
              leading: conditionIcon(_ignoringBatteryOptimizationsOk, ()=> showBatteryOptimizationsSettings()),
              title: Text(TextConst.txtIgnoringBatteryOptimizationsTitle),
              children: [
                ListTile(
                  title: Text(TextConst.txtIgnoringBatteryOptimizationsText),
                ),
                ElevatedButton(
                    child: Text(TextConst.txtStartSetup),
                    onPressed: ()=> showBatteryOptimizationsSettings()
                ),
              ],
            ),

            // Запуск настройки "Доступ к статистике использования приложений"
            ExpansionTile(
              leading: conditionIcon(_usageAccessOk, ()=> showUsageAccessSettings()),
              title: Text(TextConst.txtUsageAccessTitle),
              children: [
                ListTile(
                  title: Text(TextConst.txtUsageAccessText),
                ),
                ElevatedButton(
                  child: Text(TextConst.txtStartSetup),
                  onPressed: ()=> showUsageAccessSettings()
                ),
              ],
            ),

            // Запуск настройки "Вывод поверх других приложений"
            ExpansionTile(
              leading: conditionIcon(_drawOverlaysOk, ()=> showDrawOverlaysSettings()),
              title: Text(TextConst.txtDrawOverlaysTitle),
              children: [
                ListTile(
                  title: Text(TextConst.txtDrawOverlaysText),
                ),
                ElevatedButton(
                    child: Text(TextConst.txtStartSetup),
                    onPressed: ()=> showDrawOverlaysSettings()
                ),
              ],
            ),

            // Запуск настрйки "Замена рабочего стола..."
            ExpansionTile(
              leading: conditionIcon(_launcherOk, ()=> showLauncherSettings()),
              title: Text(TextConst.txtLauncherTitle),
              children: [
                ListTile(
                  title: Text(TextConst.txtLauncherText),
                ),
                ElevatedButton(
                    child: Text(TextConst.txtStartSetup),
                    onPressed: ()=> showLauncherSettings()
                ),
              ],
            ),

            // Поле ввода "Имя ребёнка"
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: TextField(
                controller: _textControllerChildName,
                readOnly: !_serverAvailable,
                decoration: InputDecoration(
                    filled: true,
                    labelText: TextConst.txtChildName,
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(width: 3, color: Colors.blueGrey),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(width: 3, color: Colors.blue),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    suffixIcon: _childNameList.isNotEmpty?
                    popupMenu(
                        icon: const Icon(Icons.menu),
                        menuItemList: _childNameList.map<SimpleMenuItem>((childName) => SimpleMenuItem(
                          child: Text(childName),
                          onPress: () {
                            setState(() {
                              _textControllerChildName.text = childName != TextConst.txtAddNewChild? childName : '';
                              _addNewChild = false;
                              _selChild    = null;
                              if (childName == TextConst.txtAddNewChild){
                                _addNewChild = true;
                              } else {
                                _selChild = _childList.firstWhere((child) => child.name == childName);
                              }
                              _somethingChanged = true;
                            });
                          }
                        )).toList()
                    ): null
                ),
                onChanged: ((_) {
                  _somethingChanged = true;
                  setState(() { });
                }),
              ),
            ),

            // Поле ввода "Имя устройства"
            Padding(
              padding: const EdgeInsets.only(left: 15, right: 15, bottom: 15),
              child: TextField(
                controller: _textControllerDeviceName,
                readOnly: !_serverAvailable,
                decoration: InputDecoration(
                  filled: true,
                  labelText: TextConst.txtDeviceName,
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(width: 3, color: Colors.blueGrey),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(width: 3, color: Colors.blue),
                    borderRadius: BorderRadius.circular(15),
                  ),

                  suffixIcon: _deviceNameList.isNotEmpty?
                  popupMenu(
                      icon: const Icon(Icons.menu),
                      menuItemList: _deviceNameList.map<SimpleMenuItem>((deviceName) => SimpleMenuItem(
                        child: Text(deviceName),
                        onPress: () {
                          setState(() {
                            _textControllerDeviceName.text = deviceName != TextConst.txtAddNewDevice? deviceName : '';
                            _addNewDevice = false;
                            _selDevice    = null;
                            if (deviceName == TextConst.txtAddNewDevice){
                              _addNewDevice = true;
                            } else {
                              _selDevice = _deviceList.firstWhere((device) => device.name == deviceName);
                            }
                            _somethingChanged = true;
                          });
                        }
                      )).toList()
                  ): null

                ),
                onChanged: ((_) {
                  _somethingChanged = true;
                  setState(() { });
                }),
              ),
            ),

            // Поле ввода "Пин код"
            Padding(
              padding: const EdgeInsets.only(left: 15, right: 15, bottom: 15),
              child: TextField(
                controller: _textControllerPinCode,
                decoration: InputDecoration(
                    filled: true,
                    labelText: TextConst.txtPinCode,
                    hintText: TextConst.txtPinCodeInfo,
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(width: 3, color: Colors.blueGrey),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(width: 3, color: Colors.blue),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    suffixIcon: _obscurePinCodeChanged ? IconButton(
                      onPressed: () {
                        setState(() {
                          _obscurePinCode = !_obscurePinCode;
                        });
                      },
                      icon: Icon(_obscurePinCode?Icons.abc:Icons.password),
                    ) : null,
                ),
                obscureText: _obscurePinCode,
                onChanged: ((_) {
                  _somethingChanged = true;
                  _obscurePinCodeChanged = true;
                  setState((){});
                }),
              ),
            ),

            // Поле ввода "Подсказка к пинкоду"
            Padding(
              padding: const EdgeInsets.only(left: 15, right: 15, bottom: 15),
              child: TextField(
                controller: _textControllerPinCodeClue,
                decoration: InputDecoration(
                  filled: true,
                  labelText: TextConst.txtPinCodeClue,
                  hintText: TextConst.txtPinCodeClue,
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(width: 3, color: Colors.blueGrey),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(width: 3, color: Colors.blue),
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onChanged: ((_) {
                  _somethingChanged = true;
                  _obscurePinCodeChanged = true;
                  setState((){ });
                })
              ),
            ),

            // Выбор типа устройства
            ListTile(
              title: Text(TextConst.txtDeviceType),
              trailing: DropdownButton<DeviceType>(
                  value: appState.deviceType,
                  items: DeviceType.values.map<DropdownMenuItem<DeviceType>>((deviceType) => DropdownMenuItem<DeviceType>(
                    value: deviceType,
                    child: Text(getDeviceTypeName(deviceType)),
                  )).toList(),
                  onChanged: (deviceType){
                    _somethingChanged = true;
                    appState.deviceType = deviceType!;
                    setState((){ });
                  }
              ),
            ),

            // Переключатель "Включить контроль"
            ListTile(
              title: Text(TextConst.txtSwitchControlOn),
              trailing: Switch(
                value: _isControlOn,
                onChanged: controlSwitchEnabled ? (value) {
                  _somethingChanged = true;
                  _isControlOn = value;
                  setState(() {});
                }:null,
              ),
            ),


            // Кнопка "Применить изменения"
            if (_somethingChanged) ...[
              Padding(
                padding: const EdgeInsets.only(left: 15, right: 15),
                child: ElevatedButton(
                  onPressed: () async {
                    await applyChanges();
                    setState(() {});
                  },
                  child: Text(TextConst.txtApplyChanges)
                )
              ),
            ],

            // Кнопка "Дальше"
            if ( widget.onOptionsOk != null ) ...[
              Padding(
                  padding: const EdgeInsets.only(left: 15, right: 15),
                  child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      onPressed: ((_child != null && _device != null ))? () async {
                        if (await applyChanges()) {
                          widget.onOptionsOk!.call();
                        }
                      } : null,
                      child: Text(TextConst.txtNext)
                  )
              ),
            ],

          ],
        )
    );
  }

  Future<bool> applyChanges() async {
    if ( (_obscurePinCodeChanged && _textControllerPinCode.text.isEmpty ) || _textControllerPinCodeClue.text.isEmpty) {
      Fluttertoast.showToast(msg: TextConst.txtInputPinCode);
      return false;
    }

    if (_obscurePinCodeChanged) {
      if (_textControllerPinCode.text.isEmpty || _textControllerPinCodeClue.text.isEmpty) {
        Fluttertoast.showToast(msg: TextConst.txtInputPinCode);
        return false;
      }
      appState.pinCodeManager.setPinCode(_textControllerPinCode.text, _textControllerPinCodeClue.text);
    }

    if (_selChild != null)  await appState.childManager.setChildAsCurrent(_selChild!);
    if (_selDevice != null)  await appState.deviceManager.setDeviceAsCurrent(_selDevice!);

    final childName = _textControllerChildName.text;

    if (_addNewChild) {
      final newChild = Child.createNew(childName, appState.serverConnect.user!);
      await appState.childManager.setChildAsCurrent(newChild);
      _child = appState.childManager.getCurrentChild();
    } else {
      if (childName.toLowerCase() != _oldChildName.toLowerCase() || _selChild != null) await saveChild(childName);
    }
    
    final deviceName = _textControllerDeviceName.text;
    if (_addNewDevice){
      final newDevice = await Device.createNew(appState.serverConnect.user!, _child!, deviceName, 0);
      await appState.deviceManager.setDeviceAsCurrent(newDevice);
      _device = appState.deviceManager.getCurrentDevice();
    } else {
      if (deviceName.toLowerCase() != _oldDeviceName.toLowerCase() || _selDevice != null) await saveDevice(deviceName, 0);
    }


    if (_isControlOn != appState.monitoring.status) {
      await appState.monitoring.saveStatus(_isControlOn);
    }

    if (_child != null && _device != null ) {
      await appState.objectsManager.initChildDevice();
      await appState.objectsManager.synchronize(showErrorToast: true, ignoreShortTime: true);
    }

    _somethingChanged = false;
    _obscurePinCodeChanged = false;

    if (_child != null) {
      _oldChildName = _selChild!.name;
    }
    if (_device != null) {
      _oldDeviceName = _selDevice!.name;
    }

    return true;
  }

  Future<void> saveChild(String childName) async {
    _child = await appState.childManager.updateCurrentChild(childName, appState.serverConnect.user!);
    await appState.balanceDirector.init(appState.childManager.child);
  }

  Future<void> saveDevice(String deviceName, int deviceColor) async {
    _device = await appState.deviceManager.updateCurrentDevice(deviceName, deviceColor, appState.serverConnect.user!, _child!);
  }

  Widget conditionIcon(bool condition,  void Function()? onPressed){
    if (!condition){
      return IconButton(icon: const Icon(Icons.arrow_forward), onPressed: onPressed);
    }

    return IconButton(icon: const Icon(Icons.done, color: Colors.green,), onPressed: onPressed);
  }

  void showUsageAccessSettings() async {
    await PlatformService.showUsageAccessSettings();
    _usageAccessOk  = await PlatformService.isUsageAccessExists();
    setState(() { });
  }

  void showBatteryOptimizationsSettings() async {
   await PlatformService.showBatteryOptimizationsSettings();
   _ignoringBatteryOptimizationsOk  = await PlatformService.isIgnoringBatteryOptimizations();
   setState(() { });
  }

  void showDrawOverlaysSettings() async {
    PlatformService.showDrawOverlaysSettings();
    _drawOverlaysOk = await PlatformService.isCanDrawOverlays();
    setState(() { });
  }

  void showLauncherSettings() async {
    PlatformService.showLauncherSettings();
    _launcherOk = await PlatformService.isMyLauncherDefault();
    setState(() { });
  }
}
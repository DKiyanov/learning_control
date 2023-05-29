import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:device_apps/device_apps.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:flutter_fgbg/flutter_fgbg.dart';
import 'package:learning_control/parse/parse_app/parse_app.dart';
import 'package:learning_control/parse/parse_app/parse_app_group.dart';
import 'package:learning_control/parse/parse_app/parse_app_settings.dart';
import 'package:learning_control/parse/parse_balance.dart';
import 'package:learning_control/parse/parse_check_point.dart';
import 'package:learning_control/parse/parse_connect.dart';
import 'package:learning_control/parse/parse_main.dart';
import 'package:learning_control/platform_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path_util;

import 'applications_info.dart';
import 'package:simple_events/simple_events.dart';
import 'log.dart';
import 'monitoring.dart';
import 'common.dart';

late AppState appState;

/// Режим работы приложения
enum UsingMode{
  parent,
  child,
  withoutServer,
}

enum DeviceType {
  phone,
  tablet,
  tv,
}

class AppState {
  static const String keyUsingMode       = 'UsingMode';
  static const String keyBackGroundImage = 'backGroundImage';
  static const String keyDeviceType      = 'DeviceType';
  static const String keySkipAppList     = 'SkipAppList';

  static final AppState _appState = AppState._internal();

  factory AppState() {
    return _appState;
  }

  AppState._internal();

  SharedPreferences? _prefs;
  SharedPreferences get prefs => _prefs!;

  final log = Log();
  late ApplicationsInfo apps;

  bool _firstRun = true;
  bool get firstRun => _firstRun;

  UsingMode? _usingMode;
  UsingMode? get usingMode => _usingMode;

  late ParseConnect serverConnect;

  final childManager       = ChildManager();
  final deviceManager      = DeviceManager();
  final appManager         = AppManager();
  final appSettingsManager = AppSettingsManager();
  final appGroupManager    = AppGroupManager();
  final coinManager        = CoinManager();
  final balanceDirector    = BalanceDirector();

  final checkPointManager = CheckPointManager();

  final monitoring = Monitoring();

  bool charging = false; // состояние зарядки - влияет на доступность групп

  late String _appDir;
  String get appDir => _appDir;

  bool _backGroundImageOn = false;
  bool get backGroundImageOn => _backGroundImageOn;
  set backGroundImageOn(bool value) {
    _backGroundImageOn = value;
    if (_backGroundImageOn && _backgroundImage == null) {
      _loadBackGroundImage();
    }
    _prefs!.setBool(keyBackGroundImage, _backGroundImageOn);
  }
  ImageProvider?  _backgroundImage;
  ImageProvider? get backgroundImage => _backgroundImage;

  DeviceType _deviceType = DeviceType.phone;

  DeviceType get deviceType => _deviceType;
  set deviceType (DeviceType newDeviceType) {
    _deviceType = newDeviceType;
    _prefs!.setString(keyDeviceType, _deviceType.name);
  }

  final SimpleEvent launcherRefreshEvent = SimpleEvent<void>();

  bool _isForeground = true;
  bool get isForeground => _isForeground;

  final _openAppList = <String>[];
  final _skipAppCandidateList = <String>[];
  final _skipAppList = <String>[];

  List<String> get skipAppList => _skipAppList;
  List<String> get skipAppCandidateList => _skipAppCandidateList;

  /// Инициализация
  Future<bool> initialization() async {
    if (_prefs != null) return true;

    appState = this;

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      _onError(details.exception, details.stack);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      _onError(error, stack);
      return true;
    };

    // Подписка на переход приложения в foreground/background
    FGBGEvents.stream.listen((event) {
      if (event == FGBGType.foreground ) {
        print('is foreground');
        _isForeground = true;
        launcherRefreshEvent.send();
      } else {
        print('is background');
        _isForeground = false;
      }
    });

    final Directory appDocDir = await getApplicationDocumentsDirectory();
    _appDir = appDocDir.path;

    _prefs = await SharedPreferences.getInstance();
//    await _prefs!.clear(); // для отладки - имитация первого запуска

    apps   = ApplicationsInfo(log);
    await apps.init();

    final usingModeStr = _prefs!.getString(keyUsingMode)??'';
    _usingMode = UsingMode.values.firstWhereOrNull((usingMode) => usingMode.name == usingModeStr);

    _firstRun = _usingMode == null;

    serverConnect = ParseConnect(_prefs!, log);

    if (_firstRun) return false;

    _backGroundImageOn = _prefs!.getBool(keyBackGroundImage)??false;
    if (_backGroundImageOn) {
      _loadBackGroundImage();
    }

    final deviceTypeName = _prefs!.getString(keyDeviceType)??DeviceType.phone.name;
    _deviceType = DeviceType.values.firstWhere((deviceType) => deviceType.name == deviceTypeName);

    _skipAppList.addAll(_prefs!.getStringList(keySkipAppList)??[]);
    if (_skipAppList.isNotEmpty) PlatformService.setSkipAppList(_skipAppList);

    await serverConnect.loginFromPrefs();
    if (!serverConnect.loggedIn) return false;

    if (usingMode == UsingMode.child || usingMode == UsingMode.withoutServer ) {
      await serverConnect.initChildDevice();
      await monitoring.readStatus();
    }

    return true;
  }

  _onError(Object exception, StackTrace? stack) {
    log.add('Exception $exception \n $stack');
  }

  Future<bool> passwordDialog(BuildContext context) async {
    final textController = TextEditingController();
    String  password = '';

    final result = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(TextConst.txtMonitoringSwitchingOff),
            content: TextField(
              onChanged: (value) {
                password = value;
              },
              controller: textController,
              decoration: InputDecoration(
                hintText: TextConst.txtPassword,
              ),
              obscureText: true,
            ),
            actions: <Widget>[
              IconButton(icon: const Icon(Icons.cancel_outlined, color: Colors.deepOrangeAccent), onPressed: (){
                Navigator.pop(context, false);
              }),

              IconButton(icon: const Icon(Icons.check, color: Colors.lightGreen), onPressed: () {
                if (serverConnect.checkPasswordLocal(password)) {
                  Navigator.pop(context, true);
                } else {
                  Fluttertoast.showToast(msg: TextConst.errInvalidPassword);
                }
              }),

            ],
          );
        });

    return result??false;
  }

  Future<void> setUsingMode(UsingMode usingMode) async {
    if (_usingMode != null) return;
    _usingMode = usingMode;
    _prefs!.setString(keyUsingMode,_usingMode!.name);
  }

  Future<void> setBackgroundImage() async {
    final filePickerResult = await FilePicker.platform.pickFiles(
       type: FileType.image
    );
    if (filePickerResult == null) return;

    final testFile = getBackgroundImageFile();
    if (await testFile.exists()) {
      await testFile.delete();
    }

    final imageFile = File(filePickerResult.files.single.path!);
    await imageFile.copy(testFile.path);

    backGroundImageOn = await _loadBackGroundImage();
  }

  File getBackgroundImageFile() {
    final path = path_util.join(appDir, keyBackGroundImage);
    return File(path);
  }

  Future<bool> _loadBackGroundImage() async {
    final backgroundFile = getBackgroundImageFile();
    if (!backgroundFile.existsSync() ) {
      _backGroundImageOn = false;
      return false;
    }

    if (_backgroundImage != null) {
      imageCache.evict(_backgroundImage!, includeLive: true);
    }

    _backgroundImage = Image.file(backgroundFile).image;
    return true;
  }

  Future<void> openApp(String packageName) async {
    if (!_openAppList.contains(packageName)) _openAppList.add(packageName);
    log.add('open app: $packageName');
    await DeviceApps.openApp(packageName);
    appState.serverConnect.synchronize(showErrorToast: false, ignoreShortTime: false);
  }

  Future<void> deleteApp(String packageName) async {
    appState.log.add('delete app: $packageName');
    await DeviceApps.uninstallApp(packageName);
  }

  void addSkipAppCandidate(String packageName){
    if (_openAppList.contains(packageName)) return;
    if (!_skipAppCandidateList.contains(packageName)) _skipAppCandidateList.add(packageName);
  }

  void saveSkipAppList(List<String> newSkipAppList){
    _skipAppList.clear();
    _skipAppList.addAll(newSkipAppList);
    PlatformService.setSkipAppList(_skipAppList);

    _prefs!.setStringList(keySkipAppList, _skipAppList);
  }
}

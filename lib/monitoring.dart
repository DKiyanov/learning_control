import 'dart:async';
import 'package:learning_control/parse/parse_app/app_access.dart';
import 'package:learning_control/parse/parse_check_point.dart';
import 'package:simple_events/simple_events.dart';
import 'app_state.dart';
import 'common.dart';
import 'platform_service.dart';
import 'package:flutter_broadcasts/flutter_broadcasts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Monitoring {
  static const String _keyMonitoringStatus = 'MonitoringStatus';

  static const String _keyAddEstimate     = 'com.dkiyanov.learning_control.action.ADD_ESTIMATE';
  static const String _keyScreenOn        = 'android.intent.action.SCREEN_ON';
  static const String _keyScreenOff       = 'android.intent.action.SCREEN_OFF';
  static const String _keyBatteryChanged  = 'android.intent.action.BATTERY_CHANGED';

  static const String _keyPackageAdded    = 'android.intent.action.PACKAGE_ADDED';
  static const String _keyPackageChanged  = 'android.intent.action.PACKAGE_CHANGED';
  static const String _keyPackageRemoved  = 'android.intent.action.PACKAGE_REMOVED';
  static const String _keyPackageReplaced = 'android.intent.action.PACKAGE_REPLACED';

  static final Monitoring _monitoring = Monitoring._internal();

  factory Monitoring() {
    return _monitoring;
  }

  Monitoring._internal();

  final _receiver = BroadcastReceiver(
    names: <String>[
      _keyAddEstimate,
      _keyScreenOn,
      _keyScreenOff,
      _keyBatteryChanged,

      _keyPackageAdded,
      _keyPackageChanged,
      _keyPackageRemoved,
      _keyPackageReplaced,
    ],
  );

  Timer? _monitoringTimer;
  static const int _monitoringTimerInterval = 3; // секунды

  Timer? _synchronizeTimer;
  static const int _synchronizeTimerInterval = 10; // минуты

  bool _status = false;
  bool _eventListening = false;

  bool get status => _status;
  bool get isOn => _monitoringTimer != null;

  String _curTopApp = '';
  int _curAppTime = 0;
  final _curPackageNameList = <String>[];
  bool _goBack  = false;
  String _lastReason = '';

  int _controlTickTime = 0;
  int _checkAccessTickTime = 0;

  static const int _maxControlTickTime = 60;
  static const int _maxCheckAccessTickTime = 30;

  int _curDay = 0;

  bool _charging = false;
  CheckPointCondition _checkPointCondition = CheckPointCondition.free;

  final SimpleEvent checkPointConditionChangedEvent = SimpleEvent<void>();

  double _restMinutes = 0;

  /// считывает из локального хранилища состояние контроля
  /// преключает контроль в соответствии с результатом чтения
  Future<bool> readStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _status = prefs.getBool(_keyMonitoringStatus)??false;

    setMonitoring();

    return _status;
  }

  /// записывет указанное состояние контроля в локальное хранилище
  /// преключает контроль в соответствии с указанным значением
  Future<void> saveStatus(bool monitoringStatus) async {
    final prefs = await SharedPreferences.getInstance();
    _status = monitoringStatus;
    await prefs.setBool(_keyMonitoringStatus, _status);
  }

  void setMonitoring() {
    if (_status) {
      start();
    } else {
      stop();
    }
  }

  /// включает контроль
  void start() {
    if (_monitoringTimer != null) return;
    appState.log.add('start monitoring');

    _prepareForNewDay();

    _monitoringTimer  = Timer.periodic(const Duration(seconds: _monitoringTimerInterval),  (Timer t) => _monitorProcess()     );
    _synchronizeTimer = Timer.periodic(const Duration(minutes: _synchronizeTimerInterval), (Timer t) => _synchronizeProcess() );
    _startEventListening();
  }

  /// выключает контроль
  void stop() {
    if (_monitoringTimer == null) return;
    appState.log.add('stop monitoring');

    _monitoringTimer!.cancel();
    _monitoringTimer = null;
    _synchronizeTimer!.cancel();
    _synchronizeTimer = null;
  }

  void _startEventListening() {
    if (_eventListening) return;

    _receiver.start();
    _receiver.messages.listen(_onEvent);
    _eventListening = true;
  }

  void _onEvent(BroadcastMessage message) {
    if (message.name == _keyScreenOff      ) stop();
    if (message.name == _keyScreenOn       ) {
      setMonitoring();
      appState.launcherRefreshEvent.send();
    }
    if (message.name == _keyAddEstimate    ) _addEstimate(message.data!);
    if (message.name == _keyBatteryChanged ) _lockIfCharging(message.data!);
    if (message.name.contains('.PACKAGE_') ) _packagesChanged();
  }

  void _monitorProcess() async {
    try {
      await __monitorProcess();
    } catch (e, s) {
      appState.log.add('monitoring exception: $e \n $s');
    }
  }

  Future<void> __monitorProcess() async {
    final topApps = await PlatformService.getTopActivityName();
    appState.log.add('monitoring topApps: $topApps; tick = $_controlTickTime', true);

    final topAppList = topApps.split(';');
    final ignoreAppList = appState.apps.ignoreAppList;
    topAppList.removeWhere((packageName) => ignoreAppList.contains(packageName));

    if (topAppList.isEmpty) {
      if (_curTopApp != topApps){
        _curTopApp = topApps;
        appState.log.add('monitoring topApp: $_curTopApp');
        _curPackageNameList.clear();
        _goBack  = false;
      }

      _checkAccessTickTime += _monitoringTimerInterval;
      if (_checkAccessTickTime >= _maxCheckAccessTickTime) {
        _checkAccess();
      }

      return;
    }

    final topApp = topAppList.join(';');

    if (_curTopApp == topApp) {
      if (_goBack) {
        _backToHome(_lastReason);
        return;
      }

      if (_curPackageNameList.isNotEmpty) {
        _controlTickTime += _monitoringTimerInterval;
        if (_controlTickTime >= _maxControlTickTime) {
          final time = DateTime.now().millisecondsSinceEpoch;

          final minutes = (time - _curAppTime) ~/ 60000;
          appState.log.add('monitoring minutes: $minutes', true);

          if (minutes > 0) {
            for (var packageName in _curPackageNameList) {
              final app = appState.apps.getApp(packageName);
              final appName = app != null? app.appName : packageName;

              final appGroup = appState.appSettingsManager.getAppGroup(packageName);

              double calcMinutes = minutes.toDouble();

              if (appGroup.costNumerator == 0) {
                calcMinutes = 0;
              } else  {
                if (appGroup.costNumerator > 0 && appGroup.costDenominator > 0) {
                  calcMinutes = minutes * appGroup.costNumerator / appGroup.costDenominator;
                }
              }

              if (calcMinutes > 0) {
                _restMinutes += calcMinutes;

                final expenseMinutes = _restMinutes.truncate();

                if (expenseMinutes > 0) {
                  _restMinutes -= expenseMinutes;
                  appState.log.add('add expense: $packageName - $appName, $minutes, $expenseMinutes');
                  appState.balanceDirector.expenseManager.addExpense(expenseMinutes, appName, packageName);
                }
              }

              appGroup.fixUsageDuration(minutes);
            }

            _curAppTime += minutes * 60000;
            _controlTickTime = 0;

            _checkAccess();
            return;
          }
        }
      }
    } else {
      appState.log.add('monitoring topApp: $topApp');
      _curTopApp          = topApp;
      _curPackageNameList.clear();

      _controlTickTime     = 0;
      _restMinutes         = 0;
      _goBack              = false;

      for (var packageName in topAppList) {
        _curPackageNameList.add(packageName);
        appState.log.add('monitoring package $packageName - control = On', true);
      }

      _curAppTime = DateTime.now().millisecondsSinceEpoch;

      _checkAccess();
      return;
    }

    _checkAccessTickTime += _monitoringTimerInterval;
    if (_checkAccessTickTime >= _maxCheckAccessTickTime) {
      _checkAccess();
    }
  }

  void _checkAccess() {
    _checkAccessTickTime = 0;

    appState.checkPointManager.refreshCondition();

    if (_checkPointCondition != appState.checkPointManager.condition){
      checkPointConditionChangedEvent.send();
      if (appState.checkPointManager.condition != CheckPointCondition.free){
        _backToHome(TextConst.txtCheckPointWarning);
      }
      _checkPointCondition = appState.checkPointManager.condition;
    }

    if (appState.appGroupManager.refreshGroupsAccessInfo()){
      appState.launcherRefreshEvent.send();
    }

    for (var packageName in _curPackageNameList) {
      final appAccessInfo = getAppAccess(packageName);
      appState.log.add('monitoring package $packageName - appAccess = ${appAccessInfo.appAccess.name}, ${appAccessInfo.message}', true);
      if ( appAccessInfo.appAccess != AppAccess.allowed){
        appState.addSkipAppCandidate(packageName);
        _backToHome('$packageName - appAccess = ${appAccessInfo.appAccess.name}, ${appAccessInfo.message}');
        return;
      }
    }
  }

  void _backToHome(String reason) {
    _goBack = true;
    _lastReason = reason;
    appState.log.add('back to home: $reason');
    PlatformService.backToHome();
  }

  void _synchronizeProcess() async {
    _prepareForNewDay();
    await appState.serverConnect.synchronize(showErrorToast: false, ignoreShortTime: false);
  }

  void _addEstimate(Map<String, dynamic> data) {
    final int coinCount         = data["CoinCount"];
    final String coinSourceName = data["CoinSourceName"];
    final String coinType       = data["CoinType"];
    final String forWhat        = data["ForWhat"]??'';

    final coinPrice = appState.coinManager.getCoinPrice(coinSourceName, coinType);

    final int minutes   = (coinCount * coinPrice).round();

    appState.log.add('add estimate: $coinSourceName, $coinType, $coinCount, $minutes, $forWhat');
    appState.balanceDirector.estimateManager.addEstimate(coinSourceName, coinType, coinCount, forWhat, minutes);
  }

  /// В группах может быть запрещено использование в режиме зарядки устройства
  void _lockIfCharging(Map<String, dynamic> data){
    final curCharging = (data['status'] ?? 0) == 2; // 2 - BATTERY_STATUS_CHARGING
    if (_charging != curCharging) {
      _charging = curCharging;
      appState.charging = _charging;
      appState.log.add('Charging state changed charging = $_charging');
      _checkAccess();
      appState.launcherRefreshEvent.send();
    }
  }

  /// Изменился список установленных пакетов
  void _packagesChanged() {
    appState.log.add('Packages list changed');
    appState.launcherRefreshEvent.send();
  }

  void _prepareForNewDay() {
    final day = dateToInt(DateTime.now());
    if (_curDay == day) return;
    if (_curDay == 0) { // Перезагрузка/старт приложения
      _curDay = day;
      return;
    }

    _curDay = day;

    appState.appGroupManager.prepareForNewDay();
  }

}

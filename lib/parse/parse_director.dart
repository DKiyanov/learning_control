import 'package:fluttertoast/fluttertoast.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';

import '../app_state.dart';

class ParseDirector {
  final AppState appSate;
  ParseDirector(this.appSate);

  bool _synchronizeLock = false;
  int _lastSynchronization = 0;

  bool get synchronizationInProcess => _synchronizeLock;

  String _lastError = '';
  String get lastError => _lastError;

  Future<void> synchronize({required bool showErrorToast, required bool ignoreShortTime}) async {
    if (_synchronizeLock) {
      appState.log.add('synchronization is already in progress');
      return;
    }

    if (!ignoreShortTime) {
      if ((DateTime.now().millisecondsSinceEpoch - _lastSynchronization) < 1000 * 60 * 5) {
        appState.log.add('too little time has passed since the last sync');
        return;
      }
    }

    _synchronizeLock = true;

    String stage = '';
    try {
      appState.log.add('synchronize start');

      stage = 'synchronize App';
      await appState.appManager.synchronize();
      stage = 'synchronize AppGroup';
      await appState.appGroupManager.synchronize();
      stage = 'synchronize AppSettings';
      await appState.appSettingsManager.synchronize();

      stage = 'synchronize Balance';
      await appState.balanceDirector.synchronize();
      stage = 'synchronize Coin';
      await appState.coinManager.synchronize();

      stage = 'synchronize CheckPoint';
      await appState.checkPointManager.synchronize();

      appState.log.add('synchronize finished');
    } catch (e) {
      if (e is ParseError) {
        _lastError = e.message;
      } else {
        _lastError = e.toString();
      }

      appState.log.add('synchronize $stage error: $_lastError');

      if (showErrorToast){
        Fluttertoast.showToast(msg: '$stage error: $_lastError');
      }
    }

    _lastSynchronization = DateTime.now().millisecondsSinceEpoch;
    _synchronizeLock = false;
  }

  Future<void> initChildDevice() async {
    await appState.childManager.initCurrentChild();
    await appState.deviceManager.initCurrentDevice();

    await appState.appManager.init(appState.deviceManager.device, appState.childManager.child);
    await appState.appGroupManager.init(appState.serverConnect.user!);
    await appState.appSettingsManager.init(appState.deviceManager.device, appState.childManager.child);

    await appState.balanceDirector.init(appState.childManager.child);
    await appState.coinManager.init(appState.childManager.child);

    await appState.checkPointManager.init(appState.childManager.child);
  }

}
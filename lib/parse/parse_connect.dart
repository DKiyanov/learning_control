import 'package:fluttertoast/fluttertoast.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_state.dart';
import '../common.dart';

class ParseConnect {
  static const String _applicationId   = 'dk_parental_control';
  static const String _keyServerURL    = 'ServerURL';

  ParseConnect(this._prefs);

  final SharedPreferences _prefs;

  String _serverURL = '';
  String get serverURL => _serverURL;

  String _loginId = '';
  String get loginId => _loginId;

  ParseUser? _user;
  ParseUser? get user => _user;

  String _lastError = '';
  String get lastError => _lastError;

  Future<void> _init() async {
    await Parse().initialize(
        _applicationId,
        _serverURL,
        debug: true,
        coreStore: await CoreStoreSharedPrefsImp.getInstance()
    );
  }

  Future<void> wakeUp() async {
    _serverURL = _prefs.getString(_keyServerURL)??'';
    if (_serverURL.isEmpty) return;

    await _init();

    _user = await ParseUser.currentUser();
    _loginId = _user?.username??'';
  }

  Future<bool> login(String serverURL, String loginID, String password, bool signUp) async {
    await _setServerURL(serverURL);

    _user = ParseUser(loginID, password, loginID);
    bool result;
    if (signUp) {
      result = (await _user!.signUp()).success;
    } else {
      result = (await _user!.login()).success;
    }

    if (result){
      _loginId = loginID;
      return true;
    } else {
      _lastError = TextConst.errFailedLogin;
      return false;
    }
  }

  Future<bool> loginByInvite(String serverURL, String inviteKey) async {
    await _setServerURL(serverURL);

    final ParseResponse response = await ParseUser.loginWith('decard', apple('token', 'id' ) );
    if (response.success) {
      _user = await ParseUser.currentUser();
      _loginId = _user?.username??'';
      return true;
    } else {
      _lastError = TextConst.errFailedLogin;
      return false;
    }
  }

  Future<void> _setServerURL(String serverURL) async {
    _serverURL = serverURL;
    _prefs.setString(_keyServerURL, serverURL);
    await _init();
  }


  Future<bool> sessionHealthOk() async {
    // Parse().healthCheck() - не выдаёт исключение когда сервер доступен но сейсия протухла
    try {
      final query = QueryBuilder<ParseUser>(ParseUser.forQuery());
      query.whereEqualTo('username', user!.username);

      await query.find();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> isServerAvailable() async {
    final result = await Parse().healthCheck();
    return result.success;
  }
}

class ParseObjectsManager{
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

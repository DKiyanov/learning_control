import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_state.dart';
import '../common.dart';
import '../log.dart';

enum ConnectMode{
  wakeUp,
  login,
  signUp,
}

class ParseConnect {
  static const String _applicationId   = 'dk_parental_control';
  static const String _keyServerURL    = 'ServerURL';
  static const String _keyLogin        = 'Login';
  static const String _keyPasswordHash = 'passwordHash';

  ParseConnect(this._prefs, this._log);

  final SharedPreferences _prefs;
  final Log _log;
  
  String _serverURL = '';
  String get serverURL => _serverURL;

  String _login = '';
  String get login => _login;

  bool _loggedIn = false;
  bool get loggedIn => _loggedIn;

  String lastError = '';

  bool _passwordCorrect = false;
  bool get passwordCorrect => _passwordCorrect;

  ParseUser? _user;
  ParseUser? get user {
    if (_loggedIn) return _user;
    return null;
  }

  static const String _salt1 = 'bearKegged';
  static const String _salt2 = 'RadiusBorder';

  Future<bool> loginFromPrefs() async {
    _loggedIn = false;

    _serverURL         = _prefs.getString(_keyServerURL)??'';
    _login             = _prefs.getString(_keyLogin)??'';
    final passwordHash = _prefs.getString(_keyPasswordHash)??'';

    if (_login.isNotEmpty) {
      _loggedIn = await connectToServer(_serverURL, _login, passwordHash, ConnectMode.wakeUp);
    }

    return _loggedIn;
  }

  Future<bool> setConnectionParam(String url, String login, String password, bool signUp) async {
    final ret = await connectToServer(url, login, password, signUp ? ConnectMode.signUp : ConnectMode.login);
    return ret;
  }

  bool checkPasswordLocal(String password){
    final savedPasswordHash = _prefs.getString(_keyPasswordHash)??'';
    final passwordHash = _getHash(login.toLowerCase() + password + _salt1);
    return passwordHash == savedPasswordHash;
  }

  Future<bool> connectToServer(String url, String login, String password, ConnectMode mode) async {
    _loggedIn = false;
    _passwordCorrect = false;

    final savedPasswordHash = _prefs.getString(_keyPasswordHash)??'';

    String passwordHash;
    if (mode != ConnectMode.wakeUp){
      passwordHash = _getHash(login.toLowerCase() + password + _salt1);
    } else {
      passwordHash = password;
    }

    _passwordCorrect = passwordHash == savedPasswordHash;

    if (_user != null) {
      if (_passwordCorrect && _user!.emailAddress!.toLowerCase() == login.toLowerCase()) {
        _loggedIn = true;
        _log.add('entry with out login');
        return true;
      } else {
        try {
          _user!.logout();
        } catch(e) {
          _log.add('error on logout');
        }
        _user = null;
      }
    }

    final realPassword = _getHash(passwordHash + _salt2);

    final ret = await _connectToServer(url, login, realPassword, mode);

    if (!ret) {
      return ret;
    }

    if (mode != ConnectMode.wakeUp){
      _serverURL = url;
      _login     = login;
      _prefs.setString(_keyServerURL    , _serverURL   );
      _prefs.setString(_keyLogin        , _login       );
      _prefs.setString(_keyPasswordHash , passwordHash );
    }

    _loggedIn = true;

    return ret;
  }

  Future<bool> _connectToServer(String url, String login, String password, ConnectMode mode) async {
    lastError = '';

    if (appState.usingMode == UsingMode.withoutServer){
      url = TextConst.defaultURL;
    }

    await Parse().initialize(
        _applicationId,
        url,
        debug: true,
        coreStore: await CoreStoreSharedPrefsImp.getInstance()
    );

    if (appState.usingMode == UsingMode.withoutServer){
      _user = ParseUser(login, password, login);
      _user!.objectId = login;
      await _user!.pin();
      return true;
    }

    // if (!(await Parse().healthCheck()).success){
    //   print('healthCheck invalid');
    //   lastError = TextConst.errServerUnavailable;
    //   return false;
    // }
    //
    // _serverAvailable = true;

    if (mode == ConnectMode.wakeUp) {
      _user = await ParseUser.currentUser();
      if (_user != null) {
        if ( _user!.emailAddress!.toLowerCase() == login.toLowerCase() ){
          _log.add('from currentUser');
          return true;
        }
      }
    }

    _user = ParseUser(login, password, login);

    if (mode == ConnectMode.signUp) {
      if ((await _user!.signUp()).success){
        return true;
      } else {
        lastError = TextConst.errFailedSignUp;
        return false;
      }
    }

    if ((await _user!.login()).success){
      return true;
    } else {
      lastError = TextConst.errFailedLogin;
      return false;
    }
  }

  String _getHash(String str){
    return md5.convert(utf8.encode(str)).toString();
  }

  Future<void> initChildDevice() async {
    await appState.childManager.initCurrentChild();
    await appState.deviceManager.initCurrentDevice();

    await appState.appManager.init(appState.deviceManager.device, appState.childManager.child);
    await appState.appGroupManager.init(user!);
    await appState.appSettingsManager.init(appState.deviceManager.device, appState.childManager.child);

    await appState.balanceDirector.init(appState.childManager.child);
    await appState.coinManager.init(appState.childManager.child);

    await appState.checkPointManager.init(appState.childManager.child);
  }

  bool _synchronizeLock = false;
  int _lastSynchronization = 0;

  Future<void> synchronize({required bool showErrorToast, required bool ignoreShortTime}) async {
    if (_synchronizeLock) {
      _log.add('synchronization is already in progress');
      return;
    }

    if (!ignoreShortTime) {
      if ((DateTime.now().millisecondsSinceEpoch - _lastSynchronization) < 1000 * 60 * 5) {
        _log.add('too little time has passed since the last sync');
        return;
      }
    }

    _synchronizeLock = true;

    String stage = '';
    try {
      _log.add('synchronize start');

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

      _log.add('synchronize finished');
    } catch (e) {
      if (e is ParseError) {
        lastError = e.message;
      } else {
        lastError = e.toString();
      }

      _log.add('synchronize $stage error: $lastError');

      if (showErrorToast){
        Fluttertoast.showToast(msg: '$stage error: $lastError');
      }
    }

    _lastSynchronization = DateTime.now().millisecondsSinceEpoch;
    _synchronizeLock = false;
  }

  Future<bool> isServerAvailable() async {
    final result = await Parse().healthCheck();
    return result.success;
  }
}

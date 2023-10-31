import 'package:google_sign_in/google_sign_in.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../common.dart';
import '../platform_service.dart';

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

  Future<bool> loginWithPassword(String serverURL, String loginID, String password, bool signUp) async {
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

  Future<bool> loginWithGoogle() async {
    final googleSignIn = GoogleSignIn( scopes: ['email', 'https://www.googleapis.com/auth/contacts.readonly'] );

    final account = await googleSignIn.signIn();
    if (account == null) {
      _lastError = TextConst.errFailedLogin;
      return false;
    }

    final authentication = await account.authentication;
    if (authentication.accessToken == null || googleSignIn.currentUser == null || authentication.idToken == null) {
      _lastError = TextConst.errFailedLogin;
      return false;
    }

    final authData = google(authentication.accessToken!, googleSignIn.currentUser!.id, authentication.idToken!);

    final response = await ParseUser.loginWith('google', authData);

    if (response.success) {
      _user = await ParseUser.currentUser();
      await _user!.fetch();
      _loginId = _user?.username??'';
      return true;
    } else {
      _lastError = TextConst.errFailedLogin;
      return false;
    }
  }

  Future<bool> loginWithInvite(String serverURL, String inviteKey, LoginMode loginMode) async {
    await _setServerURL(serverURL);

    final sendKeyStr = inviteKey.replaceAll('\\D', '');
    final sendKeyInt = int.tryParse(sendKeyStr);

    final deviceID = await PlatformService.getDeviceID();
    const uuid  = Uuid();
    final token = uuid.v4();

    final authData1 = <String, dynamic>{
      'id'        : deviceID,
      'token'     : token,
      'invite_key': sendKeyInt,
      'for'       : loginMode.name,
    };

    // первый запуск на стороне сервера выполняется проверка приглашения
    // и выполняет (linkWith) привязку authData2 id + token к учётной записи пользователя
    var response = await ParseUser.loginWith('decard', authData1);
    if (!response.success) {
      // второй запуск должен выполнить вход по уже привязанным данным авторизации
      final authData2 = <String, dynamic>{
        'id'    : deviceID,
        'token' : token,
      };
      response = await ParseUser.loginWith('decard', authData2);
    }

    if (response.success) {
      _user = await ParseUser.currentUser();
      await _user!.fetch();
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
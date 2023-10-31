import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:learning_control/parental/child_list.dart';
import 'package:learning_control/parse/parse_connect.dart';
import 'package:learning_control/select_usage_mode.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_state.dart';
import 'common.dart';
import 'launcher.dart';
import 'login.dart';
import 'login_invite.dart';
import 'options.dart';

class StartPage extends StatefulWidget {
  const StartPage({Key? key}) : super(key: key);

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  static const String _keyLoginMode = 'LoginMode';
  static const String _keyFirstConfigOk = 'FirstConfigOk';

  bool _isStarting = true;
  SharedPreferences? _prefs;
  LoginMode? _loginMode;
  bool _firstRun = false;
  bool _reLogin = false;
  int _appStateInitMode = 0;
  bool _showFirstConfig = false;

  ParseConnect? _serverConnect;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _starting();
    });
  }

  void _starting() async {
    _prefs = await SharedPreferences.getInstance();
    _serverConnect = ParseConnect(_prefs!);

    final loginModeStr = _prefs!.getString(_keyLoginMode)??'';
    _loginMode = LoginMode.values.firstWhereOrNull((loginMode) => loginMode.name == loginModeStr);

    if (_loginMode == null) {
      _firstRun = true;
    }

    if (_loginMode != null) {
      await _serverConnect!.wakeUp();

      if (_loginMode != LoginMode.child) { // any parent
        _reLogin = !(await _serverConnect!.sessionHealthOk());
      }

      if (_loginMode == LoginMode.child) {
        _showFirstConfig = !(_prefs!.getBool(_keyFirstConfigOk)??false);
      }
    }

    setState(() {
      _isStarting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isStarting) {
      return _wait();
    }

    if (_loginMode == null) {
      return LoginModeSelector(onLoginModeSelectOk: (loginMode) {
        setState(() {
          _loginMode = loginMode;
        });
      });
    }

    if (_firstRun) {
      return _login(
        onLoginOk: (){
          _prefs!.setString(_keyLoginMode, _loginMode!.name);

          setState(() {
            _firstRun = false;

            if (_loginMode == LoginMode.child) {
              _showFirstConfig = true;
            }
          });
        },

        onLoginCancel: () {
          setState(() {
            _loginMode = null;
          });
        }
      );
    }

    if (_reLogin) {
      return _login(
          onLoginOk: (){
            setState(() {
              _reLogin = false;
            });
          }
      );
    }

    if (_appStateInitMode == 0) {
      _appStateInitMode = 1;
      AppState().initialization(_serverConnect!, _loginMode!).then((_) {
        setState(() {
          _appStateInitMode = 2;
        });
      });
    }
    if (_appStateInitMode < 2) {
      return _wait();
    }

    if (_showFirstConfig) {
      return Options( onOptionsOk: (){
        _prefs!.setBool(_keyFirstConfigOk, true);
        setState(() {
          _showFirstConfig = false;
        });
      });
    }

    if (_loginMode != LoginMode.child) { // any parent
      return const ChildList();
    }

    if (_loginMode == LoginMode.child) {
      return const Launcher();
    }

    return Container();
  }

  Widget _login({required VoidCallback onLoginOk, VoidCallback? onLoginCancel}) {
    if (_loginMode == LoginMode.masterParent) {
      return Login(connect: _serverConnect!, onLoginOk: onLoginOk, onLoginCancel: onLoginCancel);
    }

    return LoginInvite(connect: _serverConnect!, loginMode: _loginMode!, title: TextConst.txtConnecting, onLoginOk: onLoginOk, onLoginCancel: onLoginCancel);
  }

  Widget _wait() {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(TextConst.txtStarting),
      ),
      body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('${TextConst.version}: ${TextConst.versionDateStr}'),
        Container(height: 10),
        const CircularProgressIndicator(),
      ])),
    );
  }

}
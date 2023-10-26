import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'parse/parse_main.dart';

import 'parental/child_list.dart';
import 'common.dart';
import 'app_state.dart';
import 'options.dart';

class Login extends StatefulWidget {
  static Future<Object> navigate(BuildContext context) async {
    return Navigator.push(context, MaterialPageRoute(builder: (_) => const Login()));
  }

  final VoidCallback? onLoginOk;
  const Login({this.onLoginOk, Key? key}) : super(key: key);

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _tcServerURL = TextEditingController();
  final TextEditingController _tcLogin     = TextEditingController();
  final TextEditingController _tcPassword  = TextEditingController();

  bool _urlReadOnly = false;
  bool _loginReadOnly = false;
  String _displayError = '';

  bool _obscurePassword = true;

  @override
  void dispose() {
    _tcServerURL.dispose();
    _tcLogin.dispose();
    _tcPassword.dispose();

    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _tcServerURL.text = appState.serverConnect.serverURL;
    _tcLogin.text     = appState.serverConnect.login;

    if (_tcServerURL.text.isEmpty){
      _tcServerURL.text = TextConst.defaultURL;
    }

    if (_tcLogin.text.isEmpty){
      _tcLogin.text     = 'DKianov@mail.ru';
    }

    if (_tcServerURL.text.isNotEmpty && !appState.firstRun){
//      _urlReadOnly = true;
    }
    if (_tcLogin.text.isNotEmpty  && !appState.firstRun){
      _loginReadOnly = true;
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(

        appBar: AppBar(
          centerTitle: true,
          title: Text(appState.firstRun? TextConst.txtConnecting : TextConst.txtEntryToOptions),
        ),

        body: Padding(padding: const EdgeInsets.only(top: 8, left: 8, right: 8, bottom: 8), child:
        Column(children: [

          // Адрес сервера
          TextFormField(
            controller: _tcServerURL,
            readOnly: _urlReadOnly,
            decoration: InputDecoration(
              filled: true,
              labelText: TextConst.txtServerURL,
            ),
          ),

          // Логин - Email
          TextFormField(
            controller: _tcLogin,
            readOnly: _loginReadOnly,
            decoration: InputDecoration(
              filled: true,
              labelText: TextConst.txtEmailAddress,
            ),
          ),

          // Пароль
          TextFormField(
            controller: _tcPassword,
            decoration: InputDecoration(
              filled: true,
              labelText: TextConst.txtPassword,
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
                icon: Icon(_obscurePassword?Icons.abc:Icons.password),
              ),
            ),
            obscureText: _obscurePassword,
          ),

          ElevatedButton(child: Text(TextConst.txtSignIn), onPressed: ()=> checkAndGo(false)),

          if (appState.firstRun || (!appState.serverConnect.loggedIn)) ...[
            ElevatedButton(child: Text(TextConst.txtSignUp), onPressed: ()=> checkAndGo(true)),
          ],

          if (_displayError.isNotEmpty) ...[
            Text(_displayError),
          ],

        ])
        )
    );
  }

  Future<void> checkAndGo(bool signUp) async {
    String url      = _tcServerURL.text.trim();
    String login    = _tcLogin.text.trim();
    String password = _tcPassword.text.trim();

    if (url.isEmpty || login.isEmpty || password.isEmpty){
      Fluttertoast.showToast(msg: TextConst.txtInputAllParams);
      return;
    }

    final ret = await appState.serverConnect.setConnectionParam(url, login, password, signUp);

    if (!ret && appState.serverConnect.passwordCorrect && !appState.firstRun) {
      if (!mounted) return;
      Options.navigatorPushReplacement(context);
      return;
    }

    if (!ret) {
      setState(() {
        _displayError = appState.serverConnect.lastError;
      });
      return;
    }

    if (widget.onLoginOk != null) {
      widget.onLoginOk!.call();
      return;
    }

    await appState.serverConnect.synchronize(showErrorToast: true, ignoreShortTime: false);

    if (appState.usingMode == UsingMode.child) {
      if (!mounted) return;
      Options.navigatorPushReplacement(context);
    }

    if (appState.usingMode == UsingMode.parent) {
      if (!mounted) return;
      ChildList.navigatorPushReplacement(context);
    }

  }

  Future<void> prepareUsingModeWithoutServer() async {
    final child = Child.createNew(Child.keyChild, appState.serverConnect.user!);
    child.objectId = Child.keyChild;
    await appState.childManager.setChildAsCurrent(child);


    final device = Device.createNew(appState.serverConnect.user!, child, Device.keyDevice, 0);
    device.objectId = Device.keyDevice;
    await appState.deviceManager.setDeviceAsCurrent(device);
  }
}
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:learning_control/parse/parse_connect.dart';
import 'common.dart';
import 'package:async/async.dart';

class Login extends StatefulWidget {
  static Future<Object> navigate({required BuildContext context, required ParseConnect connect, VoidCallback? onLoginOk, VoidCallback? onLoginCancel}) async {
    return Navigator.push(context, MaterialPageRoute(builder: (_) => Login(connect: connect, onLoginOk: onLoginOk, onLoginCancel: onLoginCancel)));
  }

  final ParseConnect connect;
  final VoidCallback? onLoginOk;
  final VoidCallback? onLoginCancel;

  const Login({required this.connect, this.onLoginOk, this.onLoginCancel, Key? key}) : super(key: key);

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _tcServerURL = TextEditingController();
  final TextEditingController _tcLogin     = TextEditingController();
  final TextEditingController _tcPassword  = TextEditingController();

  bool _loginReadOnly = false;
  String _displayError = '';

  bool _obscurePassword = true;

  CancelableOperation? _loginProcess;

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

    _tcServerURL.text = widget.connect.serverURL;
    _tcLogin.text     = widget.connect.loginId;

    if (_tcServerURL.text.isEmpty){
      _tcServerURL.text = TextConst.defaultURL;
    }

    if (_tcLogin.text.isEmpty){
      _tcLogin.text     = 'DKianov@mail.ru';
    }

    if (_tcLogin.text.isNotEmpty){
      _loginReadOnly = true;
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_loginProcess != null) {
      return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(TextConst.txtConnecting),
        ),
        body: Center(child:
          Column(
            mainAxisSize:  MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              Container(height: 10),

              ElevatedButton(
                  onPressed: (){
                    _loginProcess!.cancel();
                    setState(() {});
                  },
                  child: Text(TextConst.txtCancel)
              ),
            ]
        )),
      );
    }

    return Scaffold(
        appBar: AppBar(
          leading: widget.onLoginCancel == null ? null : InkWell(child: const Icon(Icons.arrow_back), onTap: () {
            widget.onLoginCancel!.call();
          }),
          centerTitle: true,
          title: Text(TextConst.txtConnecting),
        ),

        body: Padding(padding: const EdgeInsets.only(top: 8, left: 8, right: 8, bottom: 8), child:
        Column(children: [

          // Адрес сервера
          TextFormField(
            controller: _tcServerURL,
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

          if (_displayError.isNotEmpty) ...[
            Text(_displayError),
            Container(height: 4),
          ],

          Container(height: 10),

          Padding(
            padding: const EdgeInsets.only(left: 50, right: 50),
            child: Row(
              children: [
                Expanded(child: ElevatedButton(child: Text(TextConst.txtSignIn), onPressed: ()=> checkAndGo(false))),
              ],
            ),
          ),

          if (widget.connect.loginId.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(left: 50, right: 50),
              child: Row(
                children: [
                  Expanded(child: ElevatedButton(child: Text(TextConst.txtSignUp), onPressed: ()=> checkAndGo(true))),
                ],
              ),
            ),
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

    final loginFuture = widget.connect.loginWithPassword(url, login, password, signUp);
//  final loginFuture = widget.connect.loginWithGoogle();

    loginFuture.then((ret) {
      if (_loginProcess == null) {
        return;
      }
      _loginProcess = null;

      if (!ret) {
        setState(() {
          _displayError = widget.connect.lastError;
        });
        return;
      }

      if (ret && widget.onLoginOk != null) {
        widget.onLoginOk!.call();
        return;
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    });

    _loginProcess = CancelableOperation<bool>.fromFuture(
       loginFuture,
       onCancel: () {
         setState(() {
           _loginProcess = null;
         });
       }
    );

    setState(() {});
  }
}
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:learning_control/parse/parse_connect.dart';
import 'common.dart';
import 'package:async/async.dart';

class LoginInvite extends StatefulWidget {
  static Future<Object> navigate({required BuildContext context, required ParseConnect connect, required LoginMode loginMode, required String title, VoidCallback? onLoginOk, VoidCallback? onLoginCancel}) async {
    return Navigator.push(context, MaterialPageRoute(builder: (_) => LoginInvite(connect: connect, loginMode: loginMode, title: title, onLoginOk: onLoginOk, onLoginCancel: onLoginCancel)));
  }

  final ParseConnect  connect;
  final LoginMode     loginMode;
  final String        title;
  final VoidCallback? onLoginOk;
  final VoidCallback? onLoginCancel;

  const LoginInvite({required this.connect, required this.loginMode, required this.title, this.onLoginOk, this.onLoginCancel, Key? key}) : super(key: key);

  @override
  State<LoginInvite> createState() => _LoginInviteState();
}

class _LoginInviteState extends State<LoginInvite> {
  final TextEditingController _tcServerURL = TextEditingController();
  final TextEditingController _tcInviteKey = TextEditingController();

  String _displayError = '';
  CancelableOperation? _loginProcess;

  @override
  void dispose() {
    _tcServerURL.dispose();
    _tcInviteKey.dispose();

    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _tcServerURL.text = widget.connect.serverURL;

    if (_tcServerURL.text.isEmpty){
      _tcServerURL.text = TextConst.defaultURL;
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
          title: Text(widget.title),
        ),

        body: Padding(padding: const EdgeInsets.only(top: 8, left: 8, right: 8, bottom: 8), child:
          Column(children: [

            Row(children: [
              Expanded(
                child: Card(
                  color: Colors.amberAccent,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Text(TextConst.txtInviteLoginHelp,  textAlign: TextAlign.center),
                  ),
                ),
              )
            ]),
            Container(height: 4),

            // Адрес сервера
            TextFormField(
              controller: _tcServerURL,
              decoration: InputDecoration(
                filled: true,
                labelText: TextConst.txtServerURL,
              ),
            ),

            // Код приглашения
            TextFormField(
              controller: _tcInviteKey,
              decoration: InputDecoration(
                filled: true,
                labelText: TextConst.txtInviteKey,
              ),
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
                  Expanded(child: ElevatedButton(child: Text(TextConst.txtSignIn), onPressed: ()=> checkAndGo())),
                ],
              ),
            ),

          ])
        )
    );
  }

  Future<void> checkAndGo() async {
    String url       = _tcServerURL.text.trim();
    String inviteKey = _tcInviteKey.text.trim();

    if (url.isEmpty || inviteKey.isEmpty){
      Fluttertoast.showToast(msg: TextConst.txtInputAllParams);
      return;
    }

    final loginFuture = widget.connect.loginWithInvite(url, inviteKey, widget.loginMode);

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
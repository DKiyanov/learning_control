import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:learning_control/parse/parse_connect.dart';
import 'common.dart';
import 'app_state.dart';

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
    _tcInviteKey.text     = widget.connect.loginId;

    if (_tcServerURL.text.isEmpty){
      _tcServerURL.text = TextConst.defaultURL;
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(

        appBar: AppBar(
          centerTitle: true,
          title: Text(widget.title),
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

            // Код приглашения
            TextFormField(
              controller: _tcInviteKey,
              decoration: InputDecoration(
                filled: true,
                labelText: TextConst.txtInviteKey,
              ),
            ),

            ElevatedButton(child: Text(TextConst.txtSignIn), onPressed: ()=> checkAndGo()),

            if (_displayError.isNotEmpty) ...[
              Text(_displayError),
            ],

            if (widget.onLoginCancel != null) ...[
              ElevatedButton(child: Text(TextConst.txtBack), onPressed: (){
                widget.onLoginCancel!.call();
              }),
            ]

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

    final ret = await widget.connect.loginByInvite(url, inviteKey);

    if (!ret) {
      setState(() {
        _displayError = appState.serverConnect.lastError;
      });
      return;
    }

    if (ret && widget.onLoginOk != null) {
      widget.onLoginOk!.call();
      return;
    }

    if (!mounted) return;
    Navigator.pop(context, true);
  }
}
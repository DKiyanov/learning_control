import 'package:flutter/material.dart';
import 'common.dart';

typedef ValueCallback<T> = void Function(T value);

class LoginModeSelector extends StatefulWidget {
  final ValueCallback<LoginMode> onLoginModeSelectOk;
  const LoginModeSelector({required this.onLoginModeSelectOk, Key? key}) : super(key: key);

  @override
  State<LoginModeSelector> createState() => _LoginModeSelectorState();
}

class _LoginModeSelectorState extends State<LoginModeSelector> {
  LoginMode? _loginMode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(TextConst.txtLoginModeTitle),
        ),

        body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: ListView(
                children: [
                  Card(
                    color: Colors.amberAccent,
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Text(TextConst.txtLoginModeInvitation),
                    )
                  ),

                  ChoiceChip(
                    label: Text(TextConst.txtLoginModeMasterParent),
                    selected: _loginMode == LoginMode.masterParent,
                    selectedColor: Colors.lightGreenAccent,
                    onSelected: (value){
                      setState(() {
                        _loginMode = LoginMode.masterParent;
                      });
                    },
                  ),

                  ChoiceChip(
                    label: Text(TextConst.txtLoginModeSlaveParent),
                    selected: _loginMode == LoginMode.slaveParent,
                    selectedColor: Colors.lightGreenAccent,
                    onSelected: (value){
                      setState(() {
                        _loginMode = LoginMode.slaveParent;
                      });
                    },
                  ),

                  ChoiceChip(
                    label: Text(TextConst.txtLoginModeChild),
                    selected: _loginMode == LoginMode.child,
                    selectedColor: Colors.lightGreenAccent,
                    onSelected: (value){
                      setState(() {
                        _loginMode = LoginMode.child;
                      });
                    },
                  ),

                  ElevatedButton(onPressed: _loginMode != null? ()=> proceed(): null, child: Text(TextConst.txtProceed))

                ],
              )
            )
        )
    );
  }

  Future<void> proceed() async {
      widget.onLoginModeSelectOk.call(_loginMode!);
  }
}
import 'package:flutter/material.dart';
import 'parental/child_list.dart';
import 'common.dart';
import 'app_state.dart';
import 'options.dart';

class UsingModeSelector extends StatefulWidget {
  static Future<Object?> navigatorPush(BuildContext context) async {
    return Navigator.push(context, MaterialPageRoute(builder: (_) => const UsingModeSelector() ));
  }

  const UsingModeSelector({Key? key}) : super(key: key);

  @override
  State<UsingModeSelector> createState() => _UsingModeSelectorState();
}

class _UsingModeSelectorState extends State<UsingModeSelector> {
  UsingMode? _usingMode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(TextConst.txtUsingModeTitle),
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
                      child: Text(TextConst.txtUsingModeInvitation),
                    )
                  ),

                  ChoiceChip(
                    label: Text(TextConst.txtUsingModeParent),
                    selected: _usingMode == UsingMode.parent,
                    selectedColor: Colors.lightGreenAccent,
                    onSelected: (value){
                      setState(() {
                        _usingMode = UsingMode.parent;
                      });
                    },
                  ),

                  ChoiceChip(
                    label: Text(TextConst.txtUsingModeChild),
                    selected: _usingMode == UsingMode.child,
                    selectedColor: Colors.lightGreenAccent,
                    onSelected: (value){
                      setState(() {
                        _usingMode = UsingMode.child;
                      });
                    },
                  ),

                  ElevatedButton(onPressed: _usingMode != null? ()=> proceed(): null, child: Text(TextConst.txtProceed))

                ],
              )
            )
        )
    );
  }

  Future<void> proceed() async {
    appState.setUsingMode(_usingMode!);

    if (_usingMode == UsingMode.parent){
      ChildList.navigatorPushReplacement(context);
    }

    if (_usingMode == UsingMode.child){
      Options.navigatorPushReplacement(context);
    }
  }
}
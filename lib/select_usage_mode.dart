import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'common.dart';
import 'app_state.dart';

class UsingModeSelector extends StatefulWidget {
  final VoidCallback onUsingModeSelectOk;
  const UsingModeSelector({required this.onUsingModeSelectOk, Key? key}) : super(key: key);

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
    try {
      appState.setUsingMode(_usingMode!);
      widget.onUsingModeSelectOk.call();
    } catch(e) {
      Fluttertoast.showToast(msg: e.toString());
    }
  }
}
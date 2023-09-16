import 'package:flutter/material.dart';
import 'parental/child_list.dart';
import 'common.dart';
import 'login.dart';
import 'launcher.dart';
import 'app_state.dart';

class StartPage extends StatefulWidget {
  const StartPage({Key? key}) : super(key: key);

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  bool _isStarting = true;
  Widget? _screen;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _starting();
    });
  }

  void _starting() async {
    await AppState().initialization();
    _screen = await getScreenWidget();

    setState(() {
      _isStarting = false;
    });
  }

  Future<Widget> getScreenWidget() async {
    if (appState.firstRun) {
      return const Login();
    }

    if (appState.usingMode == UsingMode.parent) {
      if (appState.serverConnect.loggedIn) {
        if (await appState.serverConnect.sessionHealthCheck()) {
          return const ChildList();
        } else {
          return const Login();
        }
      } else {
        return const Login();
      }
    }

    if (appState.usingMode == UsingMode.child) {
      return const Launcher();
    }

    return const Login();
  }

  @override
  Widget build(BuildContext context) {
    if (_isStarting) {
      return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(TextConst.txtStarting),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return _screen!;
  }

}
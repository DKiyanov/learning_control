import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:learning_control/platform_service.dart';
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
    try {
      await AppState().initialization();
      _screen = await getScreenWidget();

      setState(() {
        _isStarting = false;
      });
    } catch (e) {
      await appState.prefs.clear();
      Fluttertoast.showToast(msg: TextConst.txtInvalidInstallation);
      PlatformService.restartApp();
      return;
    }
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
        body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('${TextConst.version}: ${TextConst.versionDateStr}'),
          Container(height: 10),
          const CircularProgressIndicator(),
        ])),
      );
    }

    return _screen!;
  }

}
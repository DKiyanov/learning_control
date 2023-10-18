import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:learning_control/platform_service.dart';
import 'package:learning_control/select_usage_mode.dart';
import 'options.dart';
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
  bool _sessionOk = false;
  bool _firstRun  = false;

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

      _firstRun = appState.usingMode == null;

      if (_firstRun) {
        if (appState.usingMode == UsingMode.parent) {
          if (appState.serverConnect.loggedIn) {
            _sessionOk = await appState.serverConnect.sessionHealthCheck();
          }
        }
      }

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

  Widget getScreenWidget() {
    if (appState.usingMode == null) {
      if (!appState.serverConnect.loggedIn) {
        return login();
      }

      return UsingModeSelector(onUsingModeSelectOk: () {
        setState(() {});
      });
    }

    if (appState.usingMode == UsingMode.child && !appState.firstConfigOk){
      return Options( onOptionsOk: (){
        appState.setFirstConfig(true);
        setState(() {});
      });
    }

    if (appState.usingMode == UsingMode.parent) {
      if (appState.serverConnect.loggedIn) {
        if (_sessionOk) {
          return const ChildList();
        } else {
          return login();
        }
      } else {
        return login();
      }
    }

    if (appState.usingMode == UsingMode.child) {
      return const Launcher();
    }

    return login();
  }

  Widget login() {
    return Login( onLoginOk: (){
      setState(() {});
    });
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

    return getScreenWidget();
  }

}
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:learning_control/app_state.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';

import 'common.dart';

class Invite extends StatefulWidget {
  static Future<Object?> navigatorPush(BuildContext context, Duration expirationDuration, {bool forChild = false, bool forParent = false }) async {
    return Navigator.push(context, MaterialPageRoute(builder: (_) => Invite(expirationDuration: expirationDuration, forChild: forChild, forParent: forParent )));
  }

  final bool forChild;
  final bool forParent;
  final Duration expirationDuration;

  const Invite({this.forChild = false, this.forParent = false, required this.expirationDuration, Key? key}) : super(key: key);

  @override
  State<Invite> createState() => _InviteState();
}

class _InviteState extends State<Invite> {
  bool _isStarting = true;

  late int _inviteKey;
  late DateTime _expirationTime;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _starting();
    });
  }

  void _starting() async {
    await _saveInvite( expirationDuration: widget.expirationDuration, forChild: widget.forChild, forParent: widget.forParent);

    setState(() {
      _isStarting = false;
    });
  }

  Future<void> _saveInvite({required Duration expirationDuration, bool forChild = false, forParent = false}) async {
    String forStr = '';
    if (forChild)  forStr = 'Child';
    if (forParent) forStr = 'Parent';
    if (forStr.isEmpty) return;

    var rng = Random();
    _inviteKey = rng.nextInt(100000);

    _expirationTime = DateTime.now().add(expirationDuration);

    final inviteParseObj = ParseObject('Invite');
    inviteParseObj.set<String>('for', forStr);
    inviteParseObj.set<DateTime>('expirationTime', _expirationTime);
    inviteParseObj.set<String>('userID', appState.serverConnect.user!.objectId!);
    inviteParseObj.set<int>('inviteKey', _inviteKey);

    await inviteParseObj.save();
  }

  @override
  Widget build(BuildContext context) {
    if (_isStarting) {
      return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(TextConst.txtLoading),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final str = _inviteKey.toString().padLeft(6, '0');
    final inviteStr = '${str.substring(0,3)}-${str.substring(3)}';

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(TextConst.txtInvite),
      ),

      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column( children: [
          if (widget.forChild) ...[
            Card(
                color: Colors.yellow,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(TextConst.txtInviteForChildTitle),
                )
            ),

            Card(
                color: Colors.yellow,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(TextConst.txtInviteForChildText),
                )
            ),
          ],

          if (widget.forParent) ...[
            Card(
                color: Colors.yellow,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(TextConst.txtInviteForParentTitle),
                )
            ),

            Card(
                color: Colors.yellow,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(TextConst.txtInviteForParentText),
                )
            ),
          ],

          // invite key
          Row( mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                  color: Colors.blue,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(inviteStr, style: const TextStyle(fontSize: 28)),
                  ),
              ),

              ElevatedButton(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: inviteStr));
                  Fluttertoast.showToast(msg: TextConst.txtInviteCopied);
                },
                child: const Padding(
                  padding: EdgeInsets.only(top: 13, bottom: 13),
                  child: Icon(Icons.copy),
                ),
              )
            ],
          ),

          Card(
              color: Colors.orangeAccent,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Text('${TextConst.txtInviteExpiration1} ${_expirationTime.difference(DateTime.now()).inMinutes} ${TextConst.txtInviteExpiration2}'),
                      Text('${TextConst.txtInviteExpiration3} ${dateToStr(_expirationTime)} ${timeToStr(_expirationTime)}'),
                    ],
                  ),
                ),
              )
          ),

        ]),
      ),
    );
  }
}


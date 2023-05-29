import 'package:flutter/material.dart';
import 'package:learning_control/parse/parse_app/parse_app_group.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import '../app_state.dart';
import '../common.dart';
import 'app_group_editor.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AppGroupList extends StatefulWidget {
  static Future<Object?> navigatorPush(BuildContext context) async {
    return Navigator.push(context, MaterialPageRoute(builder: (_) => const AppGroupList() ));
  }

  const AppGroupList({Key? key}) : super(key: key);

  @override
  State<AppGroupList> createState() => _AppGroupListState();
}

class _AppGroupListState extends State<AppGroupList> {
  final _groupList = <AppGroup>[];

  bool _isStarting = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _starting();
    });
  }

  void _starting() async {
    await _refreshGroupList();

    setState(() {
      _isStarting = false;
    });
  }

  Future<void> _refreshGroupList() async {
    _groupList.clear();
    _groupList.addAll((await appState.appGroupManager.getObjectList(appState.serverConnect.user!, appState.usingMode!)).where((group) => !group.deleted && !group.individual ));
    appState.appGroupManager.refreshGroupsAccessInfo();
    _groupList.sort((a,b)=>a.name.compareTo(b.name));
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

    return WillPopScope(
        onWillPop: () async {
          try {
            await appState.appGroupManager.synchronize();
            return true;
          } on ParseError catch (e) {
            Fluttertoast.showToast(msg: e.message);
            return false;
          }
        },
        child: Scaffold(
            appBar: AppBar(
              centerTitle: true,
              title: Text(TextConst.txtAppGroupList),
            ),

            body: SafeArea(
                child: ListView(
                  children: _groupList.map((group) {
                    final subText = group.isDefault? '\n${TextConst.txtDefaultGroup}': "";
                    return Slidable(
                        startActionPane: ActionPane(
                          motion: const ScrollMotion(),
                          children: [
                            SlidableAction(
                              onPressed: (context) {
                                _deleteGroup(group);
                              },
                              backgroundColor: group.isCanEdit
                                  ? Colors.redAccent
                                  : Colors.grey,
                              foregroundColor: Colors.white,
                              icon: Icons.delete,
                              label: TextConst.txtDelete,
                            )
                          ],
                        ),
                        endActionPane: ActionPane(
                          motion: const ScrollMotion(),
                          children: [
                            SlidableAction(
                              onPressed: (context) {
                                _setAsDefaultGroup(group);
                              },
                              backgroundColor: group.isDefault
                                  ? Colors.grey
                                  : Colors.amberAccent,
                              foregroundColor: Colors.blue,
                              icon: Icons.check_circle,
                              label: TextConst.txtSetAsDefault,
                            )
                          ],
                        ),
                        child: ListTile(
                          title: Text(group.name),
                          subtitle: Text('${group.accessInfo.message}$subText'),
                          onTap: () => _editGroup(group),
                        ));
                    }).toList(),
                )
            ),

          floatingActionButton: FloatingActionButton(
            child: const Icon(Icons.add),
            onPressed: ()=> _editGroup(),
          ),
        )
    );
  }

  Future<void> _editGroup([AppGroup? appGroup]) async {
    if (appGroup != null && !appGroup.isCanEdit){
      Fluttertoast.showToast(msg: TextConst.msgAppGroupNoEdit);
      return;
    }

    await AppGroupEditor.navigatorPush(context, appGroup : appGroup);
    await _refreshGroupList();
    setState(() {});
  }

  Future<void> _deleteGroup(AppGroup appGroup) async {
    if (!appGroup.isCanEdit){
      Fluttertoast.showToast(msg: TextConst.msgAppGroupNoDel);
      return;
    }

    AppGroup.setAppGroup(
      appGroup  : appGroup,
      deleted   : true,
    );
    _refreshGroupList();
    setState(() {});
  }

  Future<void> _setAsDefaultGroup(AppGroup group) async {
    if (group.isDefault) return;

    appState.appGroupManager.setGroupAsDefault(group: group, save: true);

    setState(() {});
  }
}
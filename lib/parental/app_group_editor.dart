import 'package:learning_control/parse/parse_app/parse_app_group.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'app_group_day_length_list.dart';
import '../app_state.dart';
import '../common.dart';
import '../day_length.dart';
import '../time.dart';
import 'app_group_timetable.dart';

class AppGroupEditor extends StatefulWidget {
  static Future<AppGroup?> navigatorPush(BuildContext context, { AppGroup? appGroup, String appPackageName = '' }) async {
    return Navigator.push(context, MaterialPageRoute(builder: (_) => AppGroupEditor(appGroup : appGroup) ));
  }

  const AppGroupEditor({this.appGroup, this.appPackageName = '', Key? key}) : super(key: key);

  final AppGroup? appGroup;
  final String appPackageName;

  @override
  State<AppGroupEditor> createState() => _AppGroupEditorState();
}

class _AppGroupEditorState extends State<AppGroupEditor> {
  final _tcName            = TextEditingController();

  final _tcCostNumerator   = TextEditingController();
  final _tcCostDenominator = TextEditingController();

  final _tcWorkingDuration = TextEditingController();
  final _tcRelaxDuration   = TextEditingController();

  final _timetable         = <TimeRange>[];
  bool _timetableChanged   = false;

  final _dayLengthList         = <DayLength>[];
  bool _dayLengthListChanged   = false;

  bool _notDelApp           = false;
  bool _checkPointSensitive = false;
  bool _notUseWhileCharging = false;

  String oldName = '';

  @override
  void initState() {
    super.initState();

    if (widget.appGroup != null) {
      oldName = widget.appGroup!.name;

      _tcName.text            = widget.appGroup!.name;

      _tcCostNumerator.text   = widget.appGroup!.costNumerator.toString();
      _tcCostDenominator.text = widget.appGroup!.costDenominator.toString();

      _tcWorkingDuration.text = widget.appGroup!.workingDuration.toString();
      _tcRelaxDuration.text   = widget.appGroup!.relaxDuration.toString();
      _notDelApp              = widget.appGroup!.notDelApp;
      _checkPointSensitive    = widget.appGroup!.checkPointSensitive;
      _notUseWhileCharging    = widget.appGroup!.notUseWhileCharging;

      _timetable.addAll( widget.appGroup!.getTimetable());
      _dayLengthList.addAll(widget.appGroup!.getDayLengthList());
    }
  }

  @override
  Widget build(BuildContext context) {
    String timetableText = '';
    String dayLengthText = '';

    if (_timetable.length == 1){
      timetableText = ': ${_timetable[0].from.toString()} - ${_timetable[0].to.toString()}';
    }

    if (_dayLengthList.length == 1){
      dayLengthText = ': ${_dayLengthList[0].duration.toString()}';
    }

    return Scaffold(
        appBar: AppBar(
          leading: IconButton(icon: const Icon(Icons.cancel_outlined, color: Colors.deepOrangeAccent), onPressed: (){
            Navigator.pop(context);
          }),
          centerTitle: true,
          title: Text(TextConst.txtAppGroupTuning),
          actions: [
            IconButton(icon: const Icon(Icons.check, color: Colors.lightGreen), onPressed: ()=> saveAndExit() )
          ],
        ),

        body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(10.0),
              children: [

                // Наименование группы
                if (widget.appPackageName.isEmpty)
                  TextField(
                    controller: _tcName,
                    decoration: InputDecoration(
                      filled: true,
                      labelText: TextConst.txtAppGroupName,
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(width: 3, color: Colors.blueGrey),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(width: 3, color: Colors.blue),
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),

                Container(height: 15),

                Row( mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(TextConst.txtAppUsageCost)
                    ]
                ),

                Container(height: 4),

                // Монеты за минуты
                Row(
                  children: [

                    Expanded(child: TextField(
                      controller: _tcCostNumerator,
                      decoration: InputDecoration(
                        filled: true,
                        labelText: TextConst.txtCoins,
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(width: 3, color: Colors.blueGrey),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(width: 3, color: Colors.blue),
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                    )),

                    Text(' ${TextConst.txtPer} '),

                    Expanded(child: TextField(
                      controller: _tcCostDenominator,
                      decoration: InputDecoration(
                        filled: true,
                        labelText: TextConst.txtRealMinutes,
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(width: 3, color: Colors.blueGrey),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(width: 3, color: Colors.blue),
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                    )),

                  ],
                ),

                Container(height: 16),

                // Длительность исмпользования - отдых
                Row(
                  children: [

                    Expanded(child: TextField(
                      controller: _tcWorkingDuration,
                      decoration: InputDecoration(
                        filled: true,
                        labelText: TextConst.txtWorkingDuration,
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(width: 3, color: Colors.blueGrey),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(width: 3, color: Colors.blue),
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                    )),

                    Text(' ${TextConst.txtHyphen} '),

                    Expanded(child: TextField(
                      controller: _tcRelaxDuration,
                      decoration: InputDecoration(
                        filled: true,
                        labelText: TextConst.txtRelaxDuration,
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(width: 3, color: Colors.blueGrey),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(width: 3, color: Colors.blue),
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                    )),

                  ],
                ),

                Container(height: 12),

                // Кнопка раписание доступности
                ElevatedButton(
                  style: const ButtonStyle(alignment: Alignment.centerLeft),
                  child: Text('${TextConst.txtTimetable}$timetableText'),
                  onPressed: () => editTimetable(),
                ),

                // Кнопка раписание длительности
                ElevatedButton(
                  style: const ButtonStyle(alignment: Alignment.centerLeft),
                  child: Text('${TextConst.txtDayLengthList}$dayLengthText'),
                  onPressed: () => editDayLengthList(),
                ),


                Container(height: 8),

                // Переключатель "Не использовать во время заряки устройства"
                ListTile(
                  title: Text(TextConst.txtNotUseWhileCharging),
                  trailing: Switch(
                    value: _notUseWhileCharging,
                    onChanged: (value) {
                      setState(() {
                        _notUseWhileCharging = value;
                      });
                    },
                  ),
                ),

                // Переключатель "Не удалять приложения"
                ListTile(
                  title: Text(TextConst.txtNotDelApp),
                  trailing: Switch(
                    value: _notDelApp,
                    onChanged: (value) {
                      setState(() {
                        _notDelApp = value;
                      });
                    },
                  ),
                ),

                // Переключатель "Блокировать если есть не выполненые задания>"
                ListTile(
                  title: Text(TextConst.txtCheckPointSensitive),
                  trailing: Switch(
                    value: _checkPointSensitive,
                    onChanged: (value) {
                      setState(() {
                        _checkPointSensitive = value;
                      });
                    },
                  ),
                ),

              ],
            ),
        )
    );
  }

  Future<void> editTimetable() async {
    final timetable = <TimeRange>[];

    if (_timetableChanged || widget.appGroup == null) {
      timetable.addAll(_timetable);
    } else {
      timetable.addAll( widget.appGroup!.getTimetable());
    }

    final timetableChanged = await Timetable.navigatorPush(context, timetable, _tcName.text);

    if (timetableChanged){
      _timetableChanged = timetableChanged;
      _timetable.clear();
      _timetable.addAll(timetable);
      setState(() {});
    }
  }

  Future<void> editDayLengthList() async {
    final dayLengthList = <DayLength>[];

    if (_dayLengthListChanged || widget.appGroup == null) {
      dayLengthList.addAll(_dayLengthList);
    } else {
      dayLengthList.addAll( widget.appGroup!.getDayLengthList());
    }

    final dayLengthListChanged = await DayLengthList.navigatorPush(context, dayLengthList, _tcName.text);

    if (dayLengthListChanged){
      _dayLengthListChanged = dayLengthListChanged;
      _dayLengthList.clear();
      _dayLengthList.addAll(dayLengthList);
      setState(() {});
    }
  }

  Future<void> saveAndExit() async {
    String groupName = '';
    bool individual = false;

    if (widget.appPackageName.isNotEmpty) {
      groupName = widget.appPackageName;
      individual = true;
    } else {
      groupName = _tcName.text;
      if (widget.appGroup != null && oldName != groupName){
        // изменено название группы, надо проверить что нет группы с такимже именем как новое имя
        if (appState.appGroupManager.getFromName(groupName) != null){
          Fluttertoast.showToast(
              msg: '${TextConst.msgAppGroup1} $groupName',
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.CENTER,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.red,
              textColor: Colors.white,
              fontSize: 16.0
          );

          return;
        }
      }
    }

    final intCostNumerator   = int.tryParse(_tcCostNumerator.text)??0;
    final intCostDenominator = int.tryParse(_tcCostDenominator.text)??0;

    final intWorkingDuration = int.tryParse(_tcWorkingDuration.text)??0;
    final intRelaxDuration   = int.tryParse(_tcRelaxDuration.text)??0;

    final appGroup = AppGroup.setAppGroup(
      appGroup        : widget.appGroup,
      user            : appState.serverConnect.user,
      groupName       : groupName,
      costNumerator   : intCostNumerator,
      costDenominator : intCostDenominator,
      workingDuration : intWorkingDuration,
      relaxDuration   : intRelaxDuration,
      notDelApp       : _notDelApp,
      checkPointSensitive : _checkPointSensitive,
      notUseWhileCharging: _notUseWhileCharging,
      individual      : individual,
    );

    if (_timetableChanged){
      appGroup.setTimetable(_timetable);
    }

    if (_dayLengthListChanged) {
      appGroup.setDayLengthList(_dayLengthList);
    }

    await appGroup.save();

    if (mounted) {
      Navigator.pop(context, appGroup);
    }
  }
}

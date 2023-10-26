import 'package:flutter/material.dart';
import 'package:learning_control/app_state.dart';
import 'package:learning_control/parse/parse_app/parse_app_group.dart';
import 'package:learning_control/parse/parse_balance.dart';
import 'package:learning_control/parse/parse_check_point.dart';
import 'package:learning_control/parse/parse_main.dart';
import 'package:learning_control/time.dart';

import 'common.dart';

class CheckPointEditor extends StatefulWidget {
  static Future<CheckPoint?> navigatorPush(BuildContext context, {required Child child, CheckPoint? checkPoint, DateTime? date, required bool viewOnly}) async {
    return Navigator.push(context, MaterialPageRoute(builder: (_) => CheckPointEditor(child: child, checkPoint: checkPoint, date: date, viewOnly: viewOnly) ));
  }

  const CheckPointEditor({required this.child, this.checkPoint, this.date, required this.viewOnly, Key? key}) : super(key: key);

  final Child child;
  final CheckPoint? checkPoint;
  final DateTime? date;
  final bool viewOnly;

  @override
  State<CheckPointEditor> createState() => _CheckPointEditorState();
}

class _CheckPointEditorState extends State<CheckPointEditor> {
  String  _checkTime           = '';
  late    DateTime _date          ;
  int     _periodicity         = 0;
  int     _completionRate      = 0;
  bool    _lockGroups          = true;

  CheckPointStatus     _status      = CheckPointStatus.expectation;
  CheckPointResultType _bonusType   = CheckPointResultType.text;
  CheckPointResultType _penaltyType = CheckPointResultType.text;
  AppGroup?            _appGroup;
  CheckPointStatus?    _newStatus;

  final dayList = <DropdownMenuItem<int>>[];
  final appGroupList = <DropdownMenuItem<AppGroup>>[];
  final statusList = <DropdownMenuItem<CheckPointStatus>>[];

  final _tcTaskText            = TextEditingController();
  final _tcNoticeBeforeMinutes = TextEditingController();
  final _tcCountDaysToCancel   = TextEditingController();
  final _tcBonusValue          = TextEditingController();
  final _tcPenaltyValue        = TextEditingController();
  final _tcCompletionComment   = TextEditingController();

  CheckPoint? _thisCheckPoint;
  
  bool _isStarting = true;

  @override
  void dispose() {
    _tcTaskText.dispose();
    _tcNoticeBeforeMinutes.dispose();
    _tcCountDaysToCancel.dispose();
    _tcBonusValue.dispose();
    _tcPenaltyValue.dispose();
    _tcCompletionComment.dispose();

    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _starting();
    });
  }


  void _starting() async {
    _initDayList();
    await _initAppGroupList();
    _initStatusList();

    _thisCheckPoint = widget.checkPoint;

    setState(() {

      if (_thisCheckPoint != null){
        _tcTaskText.text     = _thisCheckPoint!.taskText;
        _checkTime           = _thisCheckPoint!.checkTime          ;
        _date                = intDateTimeToDateTime(_thisCheckPoint!.date);
        _periodicity         = _thisCheckPoint!.periodicity        ;
        _tcNoticeBeforeMinutes.text = _thisCheckPoint!.noticeBeforeMinutes.toString();
        _tcCountDaysToCancel.text   = _thisCheckPoint!.countDaysToCancel.toString();
        _completionRate      = _thisCheckPoint!.completionRate     ;
        _tcCompletionComment.text = _thisCheckPoint!.completionComment;
        _lockGroups          = _thisCheckPoint!.lockGroups         ;
        _status              = _thisCheckPoint!.status             ;
        _bonusType           = _thisCheckPoint!.bonusType          ;
        _penaltyType         = _thisCheckPoint!.penaltyType        ;
        _appGroup            = _thisCheckPoint!.appGroup           ;

        if (_thisCheckPoint!.bonusType == CheckPointResultType.text) {
          _tcBonusValue.text = _thisCheckPoint!.bonusText;
        } else {
          _tcBonusValue.text = _thisCheckPoint!.bonusValue.toString();
        }

        if (_thisCheckPoint!.penaltyType == CheckPointResultType.text) {
          _tcPenaltyValue.text = _thisCheckPoint!.penaltyText;
        } else {
          _tcPenaltyValue.text = _thisCheckPoint!.penaltyValue.toString();
        }

      } else {
        if (widget.date != null) {
          _date = widget.date!;
        } else {
          _date = DateTime.now();
        }

        _tcNoticeBeforeMinutes.text = '15';
        _tcCountDaysToCancel.text = '0';
        _newStatus = CheckPointStatus.expectation;
      }

      if (_checkTime.isEmpty){
        _checkTime = timeToStr(DateTime.now());
      }

      _isStarting = false;
    });
  }

  _initDayList(){
    final cpDayNameList = <String>[];
    cpDayNameList.addAll([
      TextConst.txtCpOnce,
      TextConst.txtCpEveryDay,
      TextConst.txtCpEveryOtherDay,
      TextConst.txtCpEveryTwoDays,
      TextConst.txtCpEveryThreeDays,
    ]);
    cpDayNameList.addAll(dayNameList);
    cpDayNameList.remove(TextConst.txtTtAny);

    for (int i = 0; i < cpDayNameList.length; i++){
      dayList.add(
        DropdownMenuItem<int>(
          value: i,
          child: Text(cpDayNameList[i]),
        )
      );
    }
  }

  Future<void> _initAppGroupList() async {
    final groupList = (await appState.appGroupManager.getObjectList(appState.serverConnect.user!, appState.usingMode!)).where((group) => !group.deleted && !group.individual );

    for (var appGroup in groupList) {
      appGroupList.add(
          DropdownMenuItem<AppGroup>(
            value: appGroup,
            child: Text(appGroup.name),
          )
      );
    }
  }

  _initStatusList() {
    for (var checkPointStatus in CheckPointStatus.values) {
      statusList.add(
          DropdownMenuItem<CheckPointStatus>(
            value: checkPointStatus,
            child: Text(getCheckPointStatusName(checkPointStatus)),
          )
      );
    }
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


    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.cancel_outlined, color: Colors.deepOrangeAccent), onPressed: (){
          Navigator.pop(context);
        }),
        centerTitle: true,
        title: Text(widget.viewOnly? TextConst.txtCheckPointView: TextConst.txtCheckPointTuning),
        actions: widget.viewOnly? null : [
          if (_thisCheckPoint != null) ...[
            IconButton(icon: const Icon(Icons.copy, color: Colors.yellow), onPressed: (){
              setState(() {
                _thisCheckPoint = null;
              });
            }),
          ],

          IconButton(icon: const Icon(Icons.check, color: Colors.lightGreen), onPressed: ()=> _saveAndExit() )
        ],
      ),

        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(10.0),
            children: _body(),
          ),
        )
    );
  }


  List<Widget> _body(){
    final widgetList = <Widget>[];

    String statusText = '';
    if (_thisCheckPoint == null) {
      statusText = TextConst.txtCheckPointStatusNewTask;
    } else {
      statusText = getCheckPointStatusName(_status);
    }

    widgetList.addAll([

      // Текст задания
      TextField(
        controller: _tcTaskText,
        readOnly: widget.viewOnly,
        keyboardType: TextInputType.multiline,
        maxLines: null,
        decoration: InputDecoration(
          filled: true,
          labelText: TextConst.txtCheckPointTaskText,
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

      Container(height: 6),

      // Статус
      Row(children: [
        Expanded(child: Text(TextConst.txtStatus)),
        Expanded(
          flex: 2,
          child: Text(statusText),
        ),
      ]),

      Container(height: 6),

      // Переодичность
      Row(children: [
        Expanded(child: Text(TextConst.txtPeriodicity)),

        Expanded(
          flex: 2,
          child: DropdownButton<int>(
            isDense: false,
            isExpanded: true,
            value: _periodicity,
            onChanged: widget.viewOnly? null : (int? dayIndex) {
              setState(() {
                _periodicity = dayIndex!;
                _date = _getNextDate(DateTime.now(), _periodicity);
              });
            },
            items: dayList,
          ),
        ),

      ]),

      // Дата
      Row(children: [
        Expanded(child: Text(TextConst.txtDate)),

        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: widget.viewOnly? null : () async {
              final pickedDate = await showDatePicker(
                context     : context,
                initialDate : _date,
                firstDate   : widget.child.createdAt!,
                lastDate    : DateTime.now().add(const Duration(days: 180)),
              );

              if (pickedDate == null) return;
              setState(() {
                _date = _getNextDate(pickedDate, _periodicity);
              });
            },
            child: Text(dateToStr(_date)),
          ),
        )
      ]),

      // Время
      Row(children: [
        Expanded(child: Text(TextConst.txtTime)),

        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: widget.viewOnly? null : () async {
              final time =  Time.fromString(_checkTime);
              final newTimeOfDay = await showTimePicker(context: context, initialTime: time.getTimeOfDay());
              if (newTimeOfDay == null) return;

              final newTime = Time.fromTimeOfDay(newTimeOfDay);
              setState(() {
                _checkTime = newTime.toString();
              });
            },
            child: Text(_checkTime)
          ),
        )
      ]),

      // Предупредить за Х минут
      Row(children: [
        Expanded(child: Text(TextConst.txtNoticeBeforeMinutes)),

        Expanded(
          flex: 2,
          child: Row(
            children: [

              Expanded(
                child: TextField(
                  controller: _tcNoticeBeforeMinutes,
                  readOnly: widget.viewOnly,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: false),
                  decoration: InputDecoration(
                    filled: true,
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
              ),

              Container(width: 10),
              Text(TextConst.txtMinutes),
            ],
          ),
        )
      ]),

      // Контроль выполнения отменяется через Х дней
      Row(children: [
        Expanded(child: Text(TextConst.txtCountDaysToCancel)),

        Expanded(
          flex: 2,
          child: Row(
            children: [

              Expanded(
                child: TextField(
                  controller: _tcCountDaysToCancel,
                  readOnly: widget.viewOnly,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: false),
                  decoration: InputDecoration(
                    filled: true,
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
              ),

              Container(width: 10),
              Text(TextConst.txtDays),
            ],
          ),
        )
      ]),

      Container(height: 6),

      // Бонус: Тип, значение
      Row(children: [
        Expanded(child: Text(TextConst.txtBonus)),

        Expanded(
          flex: 2,
          child: TextField(
            controller: _tcBonusValue,
            readOnly: widget.viewOnly,
            keyboardType: _bonusType == CheckPointResultType.text? null : const TextInputType.numberWithOptions(decimal: true, signed: false),
            decoration: InputDecoration(
              prefixIcon: popupMenu(
                  icon: const Icon(Icons.arrow_drop_down),
                  menuItemList: CheckPointResultType.values.map((checkPointResultType) => SimpleMenuItem(
                    child: Text(getCheckPointResultTypeName(checkPointResultType)),
                    onPress: () {
                      setState(() {
                        _bonusType = checkPointResultType;
                        _tcBonusValue.text = '';
                      });
                    }
                  )).toList()
              ),

              filled: true,
              labelText: getCheckPointResultTypeName(_bonusType),

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
        )

      ]),

      Container(height: 6),

      // Штраф: Тип, значение
      Row(children: [
        Expanded(child: Text(TextConst.txtPenalty)),

        Expanded(
          flex: 2,
          child: TextField(
            controller: _tcPenaltyValue,
            readOnly: widget.viewOnly,
            keyboardType: _penaltyType == CheckPointResultType.text? null : const TextInputType.numberWithOptions(decimal: true, signed: false),
            decoration: InputDecoration(
              prefixIcon: popupMenu(
                  icon: const Icon(Icons.arrow_drop_down),
                  menuItemList: CheckPointResultType.values.map((checkPointResultType) => SimpleMenuItem(
                    child: Text(getCheckPointResultTypeName(checkPointResultType)),
                    onPress: () {
                      setState(() {
                        _penaltyType = checkPointResultType;
                        _tcPenaltyValue.text = '';
                      });
                    }
                  )).toList()
              ),

              filled: true,
              labelText: getCheckPointResultTypeName(_penaltyType),

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
        )

      ]),

      // Группа приложений к которой применяется бонус/штраф
      if (_bonusType   == CheckPointResultType.appGroupUsageTime ||
          _penaltyType == CheckPointResultType.appGroupUsageTime
      ) ...[
        Container(height: 10),
        Row(children: [
          Expanded(child: Text(TextConst.txtBonusGroup)),

          Expanded(
            flex: 2,
            child: DropdownButton<AppGroup>(
              isDense: false,
              isExpanded: true,
              value: _appGroup,
              onChanged: widget.viewOnly? null : (value) {
                setState(() {
                  _appGroup = value!;
                });
              },
              items: appGroupList,
            ),
          ),

        ]),
      ],

      // Блокировать группы чувствительных к CheckPoint
      Container(height: 10),
      Row(children: [
        Expanded(child: Text(TextConst.txtLockGroups)),

        Expanded(
          flex: 2,
          child: Switch(
            value: _lockGroups,
            onChanged: widget.viewOnly? null : (value) {
              setState(() {
                _lockGroups = value;
              });
            },
          ),
        )
      ]),

      if (_thisCheckPoint != null && (!widget.viewOnly || _newStatus != null)) ...[
        // Новый статус
        Container(height: 10),
        Row(children: [
          Expanded(child: Text(TextConst.txtNewStatus)),

          Expanded(
            flex: 2,
            child: DropdownButton<CheckPointStatus>(
              isDense: false,
              isExpanded: true,
              value: _newStatus,
              onChanged: widget.viewOnly? null : (value) {
                setState(() {
                  _newStatus = value!;
                });
              },
              items: statusList,
            ),
          ),

        ]),
      ],

      // Степень выполнения
      if (_thisCheckPoint != null && (
        _newStatus == CheckPointStatus.complete ||
        _newStatus == CheckPointStatus.partiallyComplete
      )) ...[
        Container(height: 8),
        Row(children: [
          Expanded(child: Text(TextConst.txtCompletionRate)),

          Expanded(
            flex: 2,
            child: Slider(
              value: _completionRate.toDouble(),
              min: 0,
              max: 10,
              divisions: 10,
              label: _completionRate.round().toString(),
              onChanged: widget.viewOnly? null : (value) {
                setState(() {
                  _completionRate = value.toInt();
                });
              },
            ),
          ),
        ]),
      ],

      // Комментарий к статусу
      if (_thisCheckPoint != null && _newStatus != null) ...[
        Container(height: 8),
        TextField(
          controller: _tcCompletionComment,
          readOnly: widget.viewOnly,
          keyboardType: TextInputType.multiline,
          maxLines: null,
          decoration: InputDecoration(
            filled: true,
            labelText: TextConst.txtCheckPointCompletionComment,
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
      ],

    ]);

    return widgetList;
  }

  Future<void> _saveAndExit() async {
    final noticeBeforeMinutes = int.tryParse(_tcNoticeBeforeMinutes.text)??0;
    final countDaysToCancel   = int.tryParse(_tcCountDaysToCancel.text)??0;

    String bonusText = '';
    int bonusValue = 0;

    if (_bonusType == CheckPointResultType.text) {
      bonusText = _tcBonusValue.text;
    } else {
      bonusValue = int.tryParse(_tcBonusValue.text)??0;
    }

    String penaltyText = '';
    int penaltyValue = 0;

    if (_penaltyType == CheckPointResultType.text) {
      penaltyText = _tcPenaltyValue.text;
    } else {
      penaltyValue = int.tryParse(_tcPenaltyValue.text)??0;
    }

    int oldBalanceAdd = 0;

    if (_thisCheckPoint != null) {
      oldBalanceAdd = _thisCheckPoint!.balanceAdd;
    }

    final checkPoint = CheckPoint.setCheckPoint(
      checkPoint  : _thisCheckPoint,
      child       : widget.child,
      taskText    : _tcTaskText.text,
      checkTime   : _checkTime,
      date        : dateToInt(_date),
      periodicity : _periodicity,
      noticeBeforeMinutes: noticeBeforeMinutes,
      countDaysToCancel  : countDaysToCancel,
      bonusType   : _bonusType,
      bonusValue  : bonusValue,
      bonusText   : bonusText,
      penaltyType : _penaltyType,
      penaltyValue: penaltyValue,
      penaltyText : penaltyText,
      appGroup    : _appGroup,
      lockGroups  : _lockGroups,
      status      : _newStatus,
      completionRate: _completionRate,
      completionComment: _tcCompletionComment.text,
    );

    await checkPoint.save();

    final newBalanceAdd = checkPoint.balanceAdd;
    await _saveAddBalance(newBalanceAdd - oldBalanceAdd);

    if (mounted) {
      Navigator.pop(context, checkPoint);
    }
  }

  Future<void> _saveAddBalance(int value) async {
    if (value == 0) return;

    final int coinCount = value;
    final int minutes   = value;

    final estimate = Estimate.createNew(widget.child, Coin.sourceCheckPoint, Coin.coinTypeSingle, coinCount, _tcTaskText.text, minutes);

    await estimate.save();
  }

  /// Возвращает дату на которую запланиррованно
  DateTime _getNextDate(DateTime curDate, int periodicity){
    if (periodicity <= 4) return curDate;

    periodicity -= 4; // Понедельник == 1

    if (periodicity <= 7) {
      final weekDay  = curDate.weekday;
      final delta = periodicity - weekDay;

      if (delta == 0) return curDate;
      if (delta <  0) return curDate.add(Duration(days: 7 + delta ));
      if (delta >  0) return curDate.add(Duration(days: delta ));
    }

    periodicity -= 7; // Month 01 == 1

    if (curDate.day <= periodicity) return DateTime(curDate.year, curDate.month, periodicity);
    return DateTime(curDate.year, curDate.month + 1, periodicity);
  }
}

















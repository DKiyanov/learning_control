import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../app_state.dart';
import '../common.dart';
import '../parse/parse_app/parse_app_group.dart';
import '../parse/parse_main.dart';
import '../time.dart';
import 'app_group_timetable.dart';

class TimeRangeAdd extends StatefulWidget {
  static Future<Object?> navigatorPush(BuildContext context, Child child) async {
    return Navigator.push(context, MaterialPageRoute(builder: (_) => TimeRangeAdd(child) ));
  }
  
  final Child child;
  
  const TimeRangeAdd(this.child, {Key? key}) : super(key: key);

  @override
  State<TimeRangeAdd> createState() => _TimeRangeAddState();
}

class _TimeRangeAddState extends State<TimeRangeAdd> {
  bool _isStarting = true;
  late TimeRange _timeRange;
  final _groupList = <AppGroup>[];
  AppGroup? _appGroup;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _starting();
    });
  }

  void _starting() async {
    final now = DateTime.now();
    final intDate = dateToInt(now);
    _timeRange = TimeRange(
      day     : 0,
      from    : Time(hour: now.hour , minute: now.minute),
      to      : Time(hour: 24, minute: 0),
      dateFrom: intDate,
      dateTo  : intDate,
    );
    
    _groupList.addAll((await appState.appGroupManager.getObjectList(appState.serverConnect.user!, appState.usingMode!)).where((group) => !group.deleted && !group.individual ));
    appState.appGroupManager.refreshGroupsAccessInfo();
    _groupList.sort((a,b)=>a.name.compareTo(b.name));

    setState(() {
      _isStarting = false;
    });
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
        title: Column(children: [
          Text(
            widget.child.name,
            style: const TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold),
          ),
          Text(
            TextConst.txtTimeRangeAdding,
            style: const TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold),
          ),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.check, color: Colors.lightGreen), onPressed: ()=> saveAndExit() )
        ],
      ),
      
      body: _body(),
    );
    
  }
  
  Widget _body() {
    String durationStr = '-';

    if (_timeRange.duration != 0) {
      durationStr = _timeRange.duration.toString();
    } else {
      if (_timeRange.to.intTime > _timeRange.from.intTime) {
        durationStr = '${_timeRange.to.getDifference(_timeRange.from)}';
      }
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(children: [
        Row(children: [
          Expanded(child: Card(
            color: Colors.yellow,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Align(child: Text(TextConst.txtTimeRangeAddMsg1)),
            ),
          ))
        ]),

        Container(height: 16),

        Row(children: [
          Expanded(child: Text(TextConst.txtAppGroup)),

          Expanded(
            child: DropdownButton<AppGroup>(
              isDense: true,
              isExpanded: true,
              value: _appGroup,
              onChanged: (value) {
                setState(() {
                  _appGroup = value!;
                });
              },

              items: _groupList.map((appGroup) =>
                  DropdownMenuItem<AppGroup>(
                    value: appGroup,
                    child: Text(appGroup.name),
                  )
              ).toList(),
            ),
          ),
        ]),

        Container(height: 6),

        Row(children: [
          Expanded(child: Text('${TextConst.txtTime} ${TextConst.txtFrom}')),

          Expanded(
            child: ElevatedButton(
              child: Text(_timeRange.from.toString()),
              onPressed: () async {
                final timeOfDay = await showTimePicker(context: context, initialTime: _timeRange.from.getTimeOfDay());
                if (timeOfDay == null) return;

                setState(() {
                  _timeRange.from = Time.fromTimeOfDay(timeOfDay);
                  if (_timeRange.to.intTime < _timeRange.from.intTime) {
                    final from = _timeRange.from;
                    _timeRange.from = _timeRange.to;
                    _timeRange.to = from;
                  }
                });
              }
            )
          ),
        ]),

        Container(height: 6),

        Row(children: [
          Expanded(child: Text('${TextConst.txtTime} ${TextConst.txtTo}')),

          Expanded(
              child: ElevatedButton(
              child: Text(_timeRange.to.toString()),
              onPressed: () async {
                final timeOfDay = await showTimePicker(context: context, initialTime: _timeRange.to.getTimeOfDay());
                if (timeOfDay == null) return;

                setState(() {
                  _timeRange.to = Time.fromTimeOfDay(timeOfDay);
                  if (_timeRange.to.intTime < _timeRange.from.intTime) {
                    final from = _timeRange.from;
                    _timeRange.from = _timeRange.to;
                    _timeRange.to = from;
                  }
                });
              }
            )
          ),
        ]),

        Container(height: 6),

        Row(children: [
            Expanded(child: Text('${TextConst.txtDuration} ${TextConst.txtInMinutes}')),

            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  final newDuration = await durationInputDialog(context, _timeRange.duration);
                  if (_timeRange.duration != newDuration) {
                    setState(() {
                      _timeRange.duration = newDuration;
                    });
                  }
                },
                child: Text(durationStr)
              ),
            ),
          ],
        ),

      ]),
    );
  }
  
  void saveAndExit() async {
    if (_appGroup == null) {
      Fluttertoast.showToast(msg: TextConst.txtTimeRangeAddMsg2);
      return;
    }

    final timetable = _appGroup!.getTimetable();

    timetable.insert(0, _timeRange);

    _appGroup!.setTimetable(timetable);

    _appGroup!.save();

    Navigator.pop(context);
  }
}
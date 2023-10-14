import 'package:flutter/material.dart';
import '../common.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../time.dart';

class Timetable extends StatefulWidget {
  static Future<bool> navigatorPush(BuildContext context, List<TimeRange> timetable, String appGroupName) async {
    return await Navigator.push(context, MaterialPageRoute(builder: (_) => Timetable(timetable, appGroupName)));
  }

  const Timetable(this.timetable, this.appGroupName, {Key? key}) : super(key: key);

  final List<TimeRange> timetable;
  final String appGroupName;

  @override
  State<Timetable> createState() => _TimetableState();
}

class _TimetableState extends State<Timetable> {
  final dayList = <DropdownMenuItem<int>>[];

  @override
  void initState() {
    super.initState();

    for (int i = 0; i < dayNameList.length; i++){
      dayList.add(
          DropdownMenuItem<int>(
            value: i,
            child: Text(dayNameList[i]),
          )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.cancel_outlined, color: Colors.deepOrangeAccent), onPressed: (){
          Navigator.pop(context, false);
        }),
        centerTitle: true,
        title: Column(children: [
          Text(
            TextConst.txtTimetableOfAppGroup,
            style: const TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold),
          ),
          Text(
            widget.appGroupName,
            style: const TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold),
          ),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.check, color: Colors.lightGreen), onPressed: (){
            Navigator.pop(context, true);
          })
        ],
      ),

      body: _body(),

      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: (){
          setState(() {
            _addTimeRange();
          });
        },
      ),
    );
  }

  Widget _body() {
    return Column(children: [
      Row(children: [
        Container(width: 16),

        Expanded(child: ElevatedButton(
          onPressed: () {  },
          child: Column(children: [
            Text(TextConst.txtTime),
            Text(TextConst.txtFrom),
          ]),
        )),

        Container(width: 6),

        Expanded(child: ElevatedButton(
          onPressed: () {  },
          child: Column(children: [
            Text(TextConst.txtTime),
            Text(TextConst.txtTo),
          ]),
        )),

        Container(width: 6),

        Expanded(
          child: ElevatedButton(
            onPressed: () {  },
            child: Column(children: [
              Text(TextConst.txtDurationShort),
              Text(TextConst.txtInMinutes),
            ]),
          ),
        ),

        Container(width: 56),
      ]),

      Expanded(child: _listView())
    ]);

    //return _listView();
  }

  Widget _listView() {
    return ReorderableListView.builder(
      itemCount: widget.timetable.length,
      itemBuilder: (context, index) {
        final timeRange = widget.timetable[index];

        return Slidable(
            key: ValueKey(timeRange),
            startActionPane: ActionPane(
              motion: const ScrollMotion(),
              children: [
                SlidableAction(
                  onPressed: (context){
                    setState(() {
                      widget.timetable.removeAt(index);
                    });
                  },
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  icon: Icons.delete,
                  label: 'Delete',
                )
              ],
            ),

            child: ListTile(
              title: timeRangeView(timeRange),
              trailing: ReorderableDragStartListener(
                index: index,
                child: const Icon(Icons.drag_handle),
              ),
            )
        );
      },

      onReorder: (int oldIndex, int newIndex) {
        setState(() {
          if (oldIndex < newIndex) {
            newIndex -= 1;
          }
          final item = widget.timetable.removeAt(oldIndex);
          widget.timetable.insert(newIndex, item);
        });
      },
    );
  }

  Widget timeRangeView(TimeRange timeRange){
    String durationStr = '-';

    if (timeRange.duration != 0) {
      durationStr = timeRange.duration.toString();
    } else {
      if (timeRange.to.intTime > timeRange.from.intTime) {
        durationStr = '${timeRange.to.getDifference(timeRange.from)}';
      }
    }

    return Column(children: [
      Row(
        children: [
          Text('${TextConst.txtDay}:'),
          Container(width: 4),
          
          Expanded(
            child: DropdownButton<int>(
              isDense: true,
              isExpanded: true,
              value: timeRange.day,
              onChanged: (int? dayIndex) {
                setState(() {
                  timeRange.day = dayIndex!;
                });
              },
              items: dayList,
            ),
          ),
          
        ],
      ),

      Row(children: [
        Expanded(child: ElevatedButton(
            child: Text(timeRange.from.toString()),
            onPressed: () async {
              final timeOfDay = await showTimePicker(context: context, initialTime: timeRange.from.getTimeOfDay());
              if (timeOfDay == null) return;

              setState(() {
                timeRange.from = Time.fromTimeOfDay(timeOfDay);
                if (timeRange.to.intTime < timeRange.from.intTime) {
                  final from = timeRange.from;
                  timeRange.from = timeRange.to;
                  timeRange.to = from;
                }
              });
            }
        )),

        Container(width: 6),

        Expanded(child: ElevatedButton(
            child: Text(timeRange.to.toString()),
            onPressed: () async {
              final timeOfDay = await showTimePicker(context: context, initialTime: timeRange.to.getTimeOfDay());
              if (timeOfDay == null) return;

              setState(() {
                timeRange.to = Time.fromTimeOfDay(timeOfDay);
                if (timeRange.to.intTime < timeRange.from.intTime) {
                  final from = timeRange.from;
                  timeRange.from = timeRange.to;
                  timeRange.to = from;
                }
              });
            }
        )),


        Container(width: 6),

        Expanded(
          child: ElevatedButton(
              onPressed: () async {
                final newDuration = await durationInputDialog(context, timeRange.duration);
                if (timeRange.duration != newDuration) {
                  setState(() {
                    timeRange.duration = newDuration;
                  });
                }
              },
              child: Text(durationStr)
          ),
        ),

      ]),

    ]);

  }

  void _addTimeRange() {
    setState(() {
      widget.timetable.add(TimeRange(
        day     : 0,
        from    : Time(hour: 0 , minute: 0),
        to      : Time(hour: 24, minute: 0),
        duration: 0,
      ));
    });
  }

  Future<int> durationInputDialog(BuildContext context, int value) async {
    final textController = TextEditingController();
    textController.text = value.toString();

    final dialogResult = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(TextConst.txtWorkingDuration),
            content: TextField(
              controller: textController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: false),
              decoration: const InputDecoration( ),
            ),
            actions: <Widget>[
              IconButton(icon: const Icon(Icons.cancel_outlined, color: Colors.deepOrangeAccent), onPressed: (){
                Navigator.pop(context, false);
              }),

              IconButton(icon: const Icon(Icons.check, color: Colors.lightGreen), onPressed: () {
                Navigator.pop(context, true);
              }),

            ],
          );
        });

    if (dialogResult != null && dialogResult){
      if (textController.text.isEmpty) return 0;
      return int.parse(textController.text);
    }

    textController.dispose();

    return value;
  }
}
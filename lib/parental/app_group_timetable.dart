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

      body: ReorderableListView.builder(
          padding: const EdgeInsets.only(top: 8, left: 8, right: 8, bottom: 8),
          itemCount: widget.timetable.length,
          itemBuilder: (context, index) {
            final timeRange = widget.timetable[index];

            return Slidable(
              key: Key(timeRange.day.toString()),
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
      ),

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

  Widget timeRangeViewTxt(TimeRange timeRange){
    return const Text('test');
  }

  Widget timeRangeView(TimeRange timeRange){
    return  Row(children: [
      DropdownButton<int>(
        isDense: false,
        isExpanded: false,
        value: timeRange.day,
        onChanged: (int? dayIndex) {
          setState(() {
            timeRange.day = dayIndex!;
          });
        },
        items: dayList,
      ),

      Container(width: 6),

      Expanded(child: ElevatedButton(
          child: Text(timeRange.from.toString()),
          onPressed: () {
            showTimePicker(context: context, initialTime: timeRange.from.getTimeOfDay()).then((timeOfDay) => {
              setState(() {
                timeRange.from = Time.fromTimeOfDay(timeOfDay!);
                if (timeRange.to.intTime < timeRange.from.intTime) {
                  final from = timeRange.from;
                  timeRange.from = timeRange.to;
                  timeRange.to = from;
                }
              })
            });
          }
      )),

      Container(width: 6),

      Expanded(child: ElevatedButton(
          child: Text(timeRange.to.toString()),
          onPressed: () {
            showTimePicker(context: context, initialTime: timeRange.to.getTimeOfDay()).then((timeOfDay) => {
              setState(() {
                timeRange.to = Time.fromTimeOfDay(timeOfDay!);
                if (timeRange.to.intTime < timeRange.from.intTime) {
                  final from = timeRange.from;
                  timeRange.from = timeRange.to;
                  timeRange.to = from;
                }
              })
            });
          }
      ))

    ]);
  }

  void _addTimeRange() {
    widget.timetable.add(TimeRange(
      day  : 0,
      from : Time(hour: 0 , minute: 0),
      to   : Time(hour: 24, minute: 0),
    ));
  }
}
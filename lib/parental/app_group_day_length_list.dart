import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../common.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../day_length.dart';

class DayLengthList extends StatefulWidget {
  static Future<bool> navigatorPush(BuildContext context, List<DayLength> dayLengthList, String appGroupName) async {
    return await Navigator.push(context, MaterialPageRoute(builder: (_) => DayLengthList(dayLengthList, appGroupName)));
  }

  const DayLengthList(this.dayLengthList, this.appGroupName, {Key? key}) : super(key: key);

  final List<DayLength> dayLengthList;
  final String appGroupName;

  @override
  State<DayLengthList> createState() => _DayLengthListState();
}

class _DayLengthListState extends State<DayLengthList> {
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
            TextConst.txtDayLengthListOfAppGroup,
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
        itemCount: widget.dayLengthList.length,
        itemBuilder: (context, index) {
          final dayLength = widget.dayLengthList[index];

          return Slidable(
              key: Key(dayLength.day.toString()),
              startActionPane: ActionPane(
                motion: const ScrollMotion(),
                children: [
                  SlidableAction(
                    onPressed: (context){
                      setState(() {
                        widget.dayLengthList.removeAt(index);
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
                title: dayLengthView(dayLength),
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
            final item = widget.dayLengthList.removeAt(oldIndex);
            widget.dayLengthList.insert(newIndex, item);
          });
        },
      ),

      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: (){
          setState(() {
            _addDayLength();
          });
        },
      ),
    );
  }

  Widget dayLengthViewTxt(DayLength dayLength){
    return const Text('test');
  }

  Widget dayLengthView(DayLength dayLength){
    return  Row(children: [
      DropdownButton<int>(
        isDense: false,
        isExpanded: false,
        value: dayLength.day,
        onChanged: (int? dayIndex) {
          setState(() {
            dayLength.day = dayIndex!;
          });
        },
        items: dayList,
      ),

      Container(width: 6),

      Expanded(
        child: ElevatedButton(
          onPressed: () async {
            final newDuration = await durationInputDialog(context, dayLength.duration);
            if (dayLength.duration != newDuration) {
              setState(() {
                dayLength.duration = newDuration;
              });
            }
          },
          child: Text('${dayLength.duration.toString()} ${TextConst.txtMinutes}')
        ),
      ),
    ]);
  }

  void _addDayLength() {
    widget.dayLengthList.add(DayLength(
      day  : 0,
      duration : 30,
    ));
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
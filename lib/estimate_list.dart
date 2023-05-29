import 'package:flutter/material.dart';
import 'common.dart';
import 'parse/parse_balance.dart';

import 'parse/parse_main.dart';

class EstimateList extends StatefulWidget {
  static Future<Object?> navigatorPush(BuildContext context, Child child) async {
    return Navigator.push(context, MaterialPageRoute(builder: (_) => EstimateList(child) ));
  }

  const EstimateList(this.child, {Key? key}) : super(key: key);

  final Child child;

  @override
  State<EstimateList> createState() => _EstimateListState();
}

class _EstimateListState extends State<EstimateList> {
  final _estimateList = <Estimate>[];

  bool _isStarting = true;
  DateTime curDate = DateTime.now();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _starting();
    });
  }

  void _starting() async {
    await _refreshEstimateList();

    setState(() {
      _isStarting = false;
    });
  }

  Future<void> _refreshEstimateList() async {
    final from = DateTime(curDate.year, curDate.month, curDate.day);
    final to   = DateTime(curDate.year, curDate.month, curDate.day, 24);
    _estimateList.clear();
    _estimateList.addAll(await Estimate.getList(widget.child, from, to));
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
          centerTitle: true,
          title: Column(children: [
            Text(
              widget.child.name,
              style: const TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold),
            ),
            Text(
              TextConst.txtEstimateList,
              style: const TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold),
            ),
          ]),
        ),

        body: SafeArea(
            child: Column(children: [
              Row(children: [
                ElevatedButton(
                    child: const Icon( Icons.arrow_left, ),
                    onPressed : () async {
                      curDate = curDate.subtract(const Duration(days: 1));
                      await _refreshEstimateList();
                      setState(() { });
                    }
                ),
                Expanded(child: ElevatedButton(
                  child: Text(dateToStr(curDate)),
                  onPressed: () async {
                    final DateTime? pickedDate = await showDatePicker(
                        context     : context,
                        initialDate : curDate,
                        firstDate   : widget.child.createdAt!,
                        lastDate    : DateTime.now(),
                    );
                    if (pickedDate == null) return;
                    curDate = pickedDate;
                    await _refreshEstimateList();
                    setState(() { });
                  },
                )),
                ElevatedButton(
                    child: const Icon( Icons.arrow_right, ),
                    onPressed : () async {
                      curDate = curDate.add(const Duration(days: 1));
                      await _refreshEstimateList();
                      setState(() { });
                    }
                ),
              ],),
              Expanded(child: ListView.builder(
                itemCount: _estimateList.length,
                itemBuilder: _buildEstimateItems,
              ))
            ])

        )
    );
  }

  Widget _buildEstimateItems(BuildContext context, int index) {
    final estimate = _estimateList[index];
    final tsStr = timeToStr(estimate.dateTime);

    return ListTile(
      contentPadding: const EdgeInsets.only(left: 10.0, right: 10.0),
      title: Text('$tsStr ${estimate.sourceName}\n${estimate.coinType}\n${estimate.forWhat}'),
      subtitle: Text('Балы: ${estimate.coinCount}; Минуты: ${estimate.minutes}'),
    );
  }

}
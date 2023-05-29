import 'package:flutter/material.dart';
import 'common.dart';

import 'parse/parse_main.dart';
import 'parse/parse_balance.dart';

class ExpenseList extends StatefulWidget {
  static Future<Object?> navigatorPush(BuildContext context, Child child) async {
    return Navigator.push(context, MaterialPageRoute(builder: (_) => ExpenseList(child) ));
  }

  const ExpenseList(this.child, {Key? key}) : super(key: key);

  final Child child;

  @override
  State<ExpenseList> createState() => _ExpenseListState();
}

class _ExpenseListState extends State<ExpenseList> {
  final _expenseList = <Expense>[];

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
    await _refreshExpenseList();

    setState(() {
      _isStarting = false;
    });
  }

  Future<void> _refreshExpenseList() async {
    final intDate = dateToInt(curDate);
    _expenseList.clear();
    _expenseList.addAll(await Expense.getList(widget.child, intDate, intDate));
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
              TextConst.txtExpenseList,
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
                      await _refreshExpenseList();
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
                    await _refreshExpenseList();
                    setState(() { });
                  },
                )),
                ElevatedButton(
                    child: const Icon( Icons.arrow_right, ),
                    onPressed : () async {
                      curDate = curDate.add(const Duration(days: 1));
                      await _refreshExpenseList();
                      setState(() { });
                    }
                ),
              ],),
              Expanded(child: ListView.builder(
                itemCount: _expenseList.length,
                itemBuilder: _buildExpenseItems,
              ))
            ])

        )
    );
  }

  Widget _buildExpenseItems(BuildContext context, int index) {
    final expense = _expenseList[index];

    return ListTile(
      contentPadding: const EdgeInsets.only(left: 10.0, right: 10.0),
        title: Row(
          children: [
            Expanded( child: Text(expense.description)),
            Text(expense.minutes.toString()),
          ],
        ),
    );
  }

}
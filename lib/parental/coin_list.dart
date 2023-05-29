import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../app_state.dart';
import '../common.dart';
import '../parse/parse_main.dart';
import '../parse/parse_balance.dart';

/// Список видов монет
/// В режиме manual = true выполняется ведение выпадающего ручного списка
class CoinList extends StatefulWidget {
  static Future<Object?> navigatorPush(BuildContext context, Child child, {bool manual = false}) async {
    return Navigator.push(context, MaterialPageRoute(builder: (_) => CoinList(child, manual : manual) ));
  }

  const CoinList(this.child, {this.manual = false, Key? key}) : super(key: key);

  final Child child;
  final bool manual;

  @override
  State<CoinList> createState() => _CoinListState();
}

class _CoinListState extends State<CoinList> {
  final _coinList     = <Coin>[];
  final _coinEditList = <Coin>[];
  final _coinNewList  = <Coin>[];

  bool _isStarting = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _starting();
    });
  }

  void _starting() async {
    await refreshCoinList();

    setState(() {
      _isStarting = false;
    });
  }

  Future<void> refreshCoinList() async {
    _coinList.clear();
    _coinList.addAll(await appState.coinManager.getObjectListForParent(widget.child, onlyManual: widget.manual));
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
            TextConst.txtCoinList,
            style: const TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold),
          ),
        ]),
      ),

      body: SafeArea(
          child: ListView.builder(
            itemCount: _coinList.length,
            itemBuilder: _buildCoinItems,
          )
      ),


      floatingActionButton: !widget.manual? null : FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: (){
          setState(() {
            final coin = Coin.createNew(widget.child, Coin.sourceNameManual, '', 1);
            _coinList.add(coin);
            _coinEditList.add(coin);
            _coinNewList.add(coin);
          });
        },
      ),
    );
  }

  Widget _buildCoinItems(BuildContext context, int index) {
    final coin = _coinList[index];

    final isNew   = _coinNewList.contains(coin);
    final editing = _coinEditList.contains(coin) || isNew;

    // Если sourceName содержит разделительный символ @
    // в качестве заголовка будет выведена часмть полсе символа @
    String sourceName ='';
    final sourceList = coin.sourceName.split('@');
    if (sourceList.length == 2) {
      sourceName = sourceList[1];
    } else {
      sourceName = coin.sourceName;
    }

    Widget title;

    if (widget.manual) {
      if (editing && coin.coinType != Coin.coinTypeSingle) {
        title = TextFormField(
          initialValue: coin.coinType,
          decoration: InputDecoration(
            filled: true,
            labelText: TextConst.txtCoinType,
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(width: 3, color: Colors.blueGrey),
              borderRadius: BorderRadius.circular(15),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(width: 3, color: Colors.blue),
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          onChanged: (value){
            coin.coinType = value;
          },
        );
      } else {
        title = Text(coin.coinType);
      }
    } else {
      title = Text('$sourceName: ${coin.coinType}');
    }

    if (!editing) {
      return ListTile(
        contentPadding: const EdgeInsets.only(left: 10.0, right: 10.0),
        title: title,
        subtitle: Text('${TextConst.txtCoinPrice}:  ${coin.price}'),
        trailing: IconButton(
          icon: const Icon(Icons.edit, color: Colors.blue),
          onPressed: (){
            setState(() {
              _coinEditList.add(coin);
            });
          },
        ),
      );
    }

    final listTile = ListTile(
      contentPadding: const EdgeInsets.only(left: 10.0, right: 10.0),
      title: title,
      subtitle: Padding(padding: const EdgeInsets.only(top: 8), child: TextFormField(
        initialValue: coin.price.toString(),
        decoration: InputDecoration(
          filled: true,
          labelText: TextConst.txtCoinPrice,
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(width: 3, color: Colors.blueGrey),
            borderRadius: BorderRadius.circular(15),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(width: 3, color: Colors.blue),
            borderRadius: BorderRadius.circular(15),
          ),
        ),
          keyboardType:const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.allow(RegExp(r'^(\d+)?\.?\d{0,2}'))
        ],
        onChanged: (value){
          if (value.isEmpty) {
            coin.price = 0;
          } else {
            coin.price = double.parse(value);
          }
        },
      )),
      trailing: IconButton(
        icon: const Icon(Icons.check, color: Colors.lightGreen) ,
        onPressed: (){
          if (!_checkFinishEditingCoin(coin)) return;

          setState(() {
            if (widget.manual) {
              coin.ddlVisible = true;
            }

            coin.save();
            _coinEditList.remove(coin);
            if (isNew) _coinNewList.remove(coin);
          });
        },
      ),
    );

    if (!widget.manual) return listTile;

    return Slidable(
      startActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context)=>{
              setState(() {
                if (coin.objectId != null && coin.objectId!.isNotEmpty){
                  coin.ddlVisible = false;
                  coin.save();
                }

                _coinList.remove(coin);
                if (editing) _coinEditList.remove(coin);
                if (isNew)   _coinNewList.remove(coin);
              })
            },
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            icon: Icons.delete,
          )
        ],
      ),

      child: listTile,
    );

  }

  bool _checkFinishEditingCoin(Coin coin){
    if (coin.coinType.isEmpty){
      Fluttertoast.showToast(
        msg: 'Заполните поле "${TextConst.txtCoinType}"',
      );
      return false;
    }

    if (coin.price == 0){
      Fluttertoast.showToast(
        msg: 'Заполните поле "${TextConst.txtCoinPrice}"',
      );
      return false;
    }

    if (_coinList.any((testCoin) => testCoin != coin && testCoin.coinType == coin.coinType)){
      Fluttertoast.showToast(
        msg: 'Уже есть запись с видом "${coin.coinType}"',
      );
      return false;
    }

    return true;
  }

}
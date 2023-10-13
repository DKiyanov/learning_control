import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:collection/collection.dart';
import '../app_state.dart';
import 'coin_list.dart';
import '../common.dart';
import '../parse/parse_main.dart';
import '../parse/parse_balance.dart';

/// Ручное добавление оценки
class EstimateAdd extends StatefulWidget {
  static Future<Estimate?> navigatorPush(BuildContext context, Child child) async {
    return Navigator.push(context, MaterialPageRoute(builder: (_) => EstimateAdd(child) ));
  }

  const EstimateAdd(this.child, {Key? key}) : super(key: key);

  final Child child;

  @override
  State<EstimateAdd> createState() => _EstimateAddState();
}

class _EstimateAddState extends State<EstimateAdd> {
  bool _isStarting = true;

  final _tcForWhat   = TextEditingController();
  final _tcCoinCount = TextEditingController();
  final _coinList = <DropdownMenuItem<Coin?>>[];
  Coin? _selCoin;

  @override
  void dispose() {
    _tcForWhat.dispose();
    _tcCoinCount.dispose();

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
    await _refreshCoinList();

    setState(() {
      _isStarting = false;
    });
  }

  Future<void> _refreshCoinList() async {
    final coinList = await appState.coinManager.getObjectListForParent(widget.child, onlyManual: true);

    if (_selCoin != null) {
      _selCoin = coinList.firstWhereOrNull((coin) => coin.coinType == _selCoin!.coinType);
    } else {
      _selCoin = coinList.firstWhereOrNull((coin) => coin.coinType == Coin.coinTypeSingle);
    }

    _coinList.clear();
    _coinList.addAll(
        coinList.map((coin) => DropdownMenuItem<Coin>(value: coin, child: Text( coin.coinType))).toList()
    );
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
            TextConst.txtAddEstimate,
            style: const TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold),
          ),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.check, color: Colors.lightGreen), onPressed: ()=> saveAndExit() )
        ],
      ),

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(10.0),
          children: [
            Row(children: [
              DropdownButton<Coin?>(
                value: _selCoin,
                onChanged: (Coin? coin) {
                  setState(() {
                    _selCoin = coin!;
                  });
                },
                items: _coinList,
              ),

              Expanded(child: Container()),

              IconButton(
                icon: const Icon( Icons.list_alt, color: Colors.blue),
                onPressed: () async {
                  await CoinList.navigatorPush(context, widget.child, manual: true);
                  await _refreshCoinList();
                  setState(() {});
                }
              ),
            ]),


            TextField(
              controller: _tcForWhat,
              decoration: InputDecoration(
                filled: true,
                labelText: TextConst.txtForWhat,
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

            Container(height: 7),

            TextField(
              controller: _tcCoinCount,
              decoration: InputDecoration(
                filled: true,
                labelText: TextConst.txtPoints,
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
            ),
          ],
        ),
      )
    );
  }

  void saveAndExit(){
    final int coinCount = int.parse(_tcCoinCount.text);
    final int minutes   =  (coinCount * _selCoin!.price).round();

    final estimate = Estimate.createNew(widget.child, _selCoin!.sourceName, _selCoin!.coinType, coinCount, _tcForWhat.text, minutes);
    estimate.save();

    Navigator.pop(context, estimate);
  }
}

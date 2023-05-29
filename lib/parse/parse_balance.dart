import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:collection/collection.dart';

import '../app_state.dart';
import '../common.dart';
import 'parse_main.dart';
import 'parse_util.dart';

typedef MinutesEvent = Function(int minutes);

/// Заработанная оценка
class Estimate extends ParseObject implements ParseCloneable {
  static const String keyEstimate   = 'Estimate';

  static const String keyChildID    = 'ChildID';

  static const String keySourceName = 'SourceName'; // Имя источника - челловекочитааемое
  static const String keyCoinType   = 'CoinType';   // Тип оценки - челловекочитааемое
  static const String keyCoinCount  = 'CoinCount';  // Оценка
  static const String keyForWhat    = 'ForWhat';    // За что
  static const String keyMinutes    = 'Minutes';    // Соответствующие заработанные минуты

  static const String keyLastChangeTime = ParseList.lastChangeTimeKey;  // Вермя создание

  Estimate() : super(keyEstimate);
  Estimate.clone() : this();

  @override
  Estimate clone(Map<String, dynamic> map) => Estimate.clone()..fromJson(map);

  String get sourceName => get<String>(keySourceName)??'';
  String get coinType   => get<String>(keyCoinType)??'';
  int    get coinCount  => get<int>(keyCoinCount)??0;
  String get forWhat    => get<String>(keyForWhat)??'';
  int    get minutes    => get<int>(keyMinutes)??0;

  DateTime? _dateTime;
  DateTime get dateTime {
    _dateTime ??= DateTime.fromMicrosecondsSinceEpoch(get<int>(keyLastChangeTime)??0);
    return _dateTime!;
  }

  static Estimate createNew(Child child, String sourceName, String coinType, int coinCount, String forWhat, int minutes){
    final newEstimate = Estimate();
    newEstimate.set(keyChildID    , child.objectId );
    newEstimate.set(keySourceName , sourceName     );
    newEstimate.set(keyCoinType   , coinType       );
    newEstimate.set(keyCoinCount  , coinCount      );
    newEstimate.set(keyForWhat    , forWhat        );
    newEstimate.set(keyMinutes    , minutes        );
    newEstimate.set(keyLastChangeTime , DateTime.now().millisecondsSinceEpoch );
    return newEstimate;
  }

  /// возвращает список объектов на сервере
  static Future<List<Estimate>> getList(Child child, DateTime from, DateTime to) async {
    final query = QueryBuilder<Estimate>(Estimate());
    query.whereEqualTo(Estimate.keyChildID , child.objectId);
    query.whereGreaterThanOrEqualsTo(keyLastChangeTime, from.millisecondsSinceEpoch);
    query.whereLessThanOrEqualTo(keyLastChangeTime, to.millisecondsSinceEpoch);

    return await query.find();
  }
}

class EstimateManager {
  static const String _keyListName  = 'EstimateList';
  final _estimateList = <Estimate>[];
  int _localSavedLastChangeTime = 0;
  late Child _child;

  final _listenerList = <MinutesEvent>[];

  void registerListener(MinutesEvent listener){
    _listenerList.add(listener);
  }
  void unRegisterListener(MinutesEvent listener){
    _listenerList.remove(listener);
  }

  Future<void> init(Child child) async {
    _child = child;
    await _getLocal();
  }

  Future<void> addEstimate(String sourceName, String coinType, int coinCount, String forWhat, int minutes) async {
    final newEstimate = Estimate.createNew(_child, sourceName, coinType, coinCount, forWhat, minutes);
    _estimateList.add(newEstimate);
    await _saveLocal();

    for (var listener in _listenerList) {
      listener(minutes);
    }
  }

  Future<void> _getLocal() async {
    final localObjectList = await ParseList.getLocal(_keyListName, () => Estimate() );
    _estimateList.addAll(localObjectList);
    _localSavedLastChangeTime = ParseList.getMaxLastChangeTime(_estimateList);
  }

  Future<void> _saveLocal() async {
    _localSavedLastChangeTime = await ParseList.saveLocal(_estimateList, _keyListName, _localSavedLastChangeTime);
  }

  Future<void> saveToServer() async {
    await ParseList.saveServer(_estimateList, 0);
    await ParseList.deleteLocal(_estimateList, _keyListName);
    _estimateList.clear();
  }
}

/// монета/балл
class Coin extends ParseObject implements ParseCloneable {
  static const String keyCoin = 'Coin';

  static const String keyChildID    = 'ChildID';
  static const String keySourceName = 'SourceName'; // Идентификатор источника - имя источника
  static const String keyCoinType   = 'CoinType';   // Тип монеты

  static const String keyPrice      = 'Price';      // Цена для пересчёта в условные минуты

  static const String keyDdlVisible = 'DdlVisible'; // Видимость в выпадающем списке для ручного ввода оценки

  static String sourceNameManual    = TextConst.txtSourceNameManual;  // Ручной ввод
  static String sourceCheckPoint    = TextConst.txtSourceCheckPoint;  // Результат выполнения задания
  static String coinTypeSingle      = TextConst.txtCoinTypeSingle;    // Одноразовое поощрение

  Coin() : super(keyCoin);
  Coin.clone() : this();

  @override
  Coin clone(Map<String, dynamic> map) => Coin.clone()..fromJson(map);

  String get sourceName => get<String>(keySourceName)??'';

  String get coinType   => get<String>(keyCoinType)??'';
  set coinType(String coinType) => set(keyCoinType ,coinType);

  double get price {
    // косяк в библиотеке целые числа из БД интерпретируются как int
    // в резуультате ошибка приведения типов
    // приходится выкривлять это обстаятельство
    final value = get(keyPrice);
    if (value == null) return 0;
    if (value is int){
      return value.toDouble();
    }
    return value;
  }

  set price(double price) => set(keyPrice, price);

  bool? get ddlVisible             => get<bool>(keyDdlVisible);
  set ddlVisible(bool? ddlVisible) => set(keyDdlVisible, ddlVisible);

  static Coin createNew(Child child, String sourceName, String coinType, double price, [bool? ddlVisible]) {
    final newCoin = Coin();
    newCoin.set(keyChildID    , child.objectId );
    newCoin.set(keySourceName , sourceName     );
    newCoin.set(keyCoinType   , coinType       );
    newCoin.set(keyPrice      , price          );
    newCoin.set(keyDdlVisible , ddlVisible     );
    return newCoin;
  }
}

class CoinManager {
  static const double defaultCoinPrice = 1;

  final _coinList = <Coin>[];
  int savedLastChangeTime = 0;
  Child? _child;

  double getCoinPrice(String sourceName, String coinType) {
    final coin = _coinList.firstWhereOrNull((coin) => coin.sourceName == sourceName && coin.coinType == coinType);
    if (coin == null) {
      addCoin(sourceName, coinType, defaultCoinPrice);
      return defaultCoinPrice;
    }
    return coin.price;
  }

  Future<void> init(Child child) async {
    if (_coinList.isNotEmpty) return;
    _child = child;

    final localObjectList = await ParseList.getLocal<Coin>(Coin.keyCoin, ()=> Coin() );
    _coinList.addAll(localObjectList);
    if (await _addPredefinedCoin()){
      await _saveLocal();
    }
  }

  /// Синхронизирует список
  Future<void> synchronize() async {
    await _saveLocal();

    final serverObjectList = await _getServerObjectList(_child!);

    for (var serverObject in serverObjectList) {
      final coin = _coinList.firstWhereOrNull((coin) => coin.sourceName == serverObject.sourceName && coin.coinType == serverObject.coinType);
      if (coin != null && coin.objectId != serverObject.objectId){
        coin.unpin();
        _coinList.remove(coin);
      }
    }

    final localSaveNeed = await ParseList.synchronizeLists(_coinList, serverObjectList);

    if (localSaveNeed) {
      await _saveLocal();
    }

    savedLastChangeTime = ParseList.getMaxLastChangeTime(_coinList);
  }

  Future<void> _saveLocal() async {
    savedLastChangeTime = await ParseList.saveLocal(_coinList, Coin.keyCoin, savedLastChangeTime);
  }

  /// возвращает список монет
  Future<List<Coin>> _getServerObjectList(Child child, {bool onlyManual = false}) async {
    final query = QueryBuilder<Coin>(Coin());
    query.whereEqualTo(Coin.keyChildID, child.objectId);
    if (onlyManual){
      query.whereEqualTo(Coin.keySourceName  , Coin.sourceNameManual);
    }

    return await query.find();
  }

  /// возвращает список монет для родительского устройства
  Future<List<Coin>> getObjectListForParent(Child child, {bool onlyManual = false}) async {
    _coinList.clear();
    _coinList.addAll(await _getServerObjectList(child, onlyManual : onlyManual));
    await _addPredefinedCoin(saveServer : true);

    savedLastChangeTime = ParseList.getMaxLastChangeTime(_coinList);

    return _coinList;
  }

  /// Проверяет отсутствие и добавляет обязательные предопределённые монеты
  Future<bool> _addPredefinedCoin({bool saveServer = false}) async {
    bool coinAdded = false;
    if (!_coinList.any((coin) => coin.coinType == Coin.coinTypeSingle)) {
      final newCoin = Coin.createNew(_child!, Coin.sourceNameManual, Coin.coinTypeSingle, 1, true);
      if (saveServer) await newCoin.save();
      _coinList.add(newCoin);
      coinAdded = true;
    }

    return coinAdded;
  }

  /// Проверяет отсутствие и доавляет новые монеты
  Future<bool> addCoin(String sourceName, String coinType, double price, {bool ddlVisible = false, bool saveServer = false}) async {
    bool coinAdded = false;
    if (!_coinList.any((coin) => coin.coinType == coinType && coin.sourceName == sourceName)) {
      final newCoin = Coin.createNew(_child!, sourceName, coinType, price, ddlVisible);
      _coinList.add(newCoin);
      _saveLocal();
      if (saveServer) await newCoin.save();
      coinAdded = true;
    }

    return coinAdded;
  }
}

/// Расход времени разрезе дней и программ
/// только чтение
/// создание/запись объекта выполняется при сохраненеии class SendExpense
class Expense extends ParseObject implements ParseCloneable {
  static const String keyExpense = 'Expense';

  static const String keyChildID     = 'ChildID';

  static const String keyDate        = 'Date';        // дата
  static const String keyDescription = 'Description'; // человекочитаемое описание за что снято время (имя программы)
  static const String keyTechInfo    = 'TechInfo';    // техническая информация за что снято время

  static const String keyMinutes     = 'Minutes';     // кол-во израсходованных минут

  Expense() : super(keyExpense);
  Expense.clone() : this();

  @override
  Expense clone(Map<String, dynamic> map) => Expense.clone()..fromJson(map);

  int    get date        => get<int>(keyDate)??0;
  String get description => get<String>(keyDescription)??'';
  String get techInfo    => get<String>(keyTechInfo)??'';
  int    get minutes     => get<int>(keyMinutes)??0;

  /// возвращает список объектов на сервере
  static Future<List<Expense>> getList(Child child, int from, int to) async {
    final query = QueryBuilder<Expense>(Expense());
    query.whereEqualTo(Expense.keyChildID    , child.objectId);
    query.whereGreaterThanOrEqualsTo(keyDate , from);
    query.whereLessThanOrEqualTo(keyDate     , to);

    return await query.find();
  }
}

/// Расход времени
/// Только для записи информации на сервер
/// Для чтения использовать class Expense
class SendExpense extends ParseObject implements ParseCloneable {
  static const String keySendExpense = 'SendExpense';

  static const String keyChildID     = 'ChildID';

  static const String keyDescription = 'Description'; // человекочитаемое описание за что снято время (имя программы)
  static const String keyTechInfo    = 'TechInfo';    // техническая информация за что снято время id устройства + package
  static const String keyMinutes     = 'Minutes';     // кол-во израсходованных минут
  static const String keyDate        = 'Date';        // дата
  static const String keyLastChangeTime = ParseList.lastChangeTimeKey;  // момент последнего изменения записи
  static const String keyCreateTime     = 'CreateTime';      // момент времени начала заполнения буффера (передача данных на сервер выполняется переодически)

  SendExpense() : super(keySendExpense);
  SendExpense.clone() : this();

  @override
  SendExpense clone(Map<String, dynamic> map) => SendExpense.clone()..fromJson(map);

  int    get date        => get<int>(keyDate)??0;
  String get description => get<String>(keyDescription)??'';
  String get techInfo    => get<String>(keyTechInfo)??'';
  int    get minutes     => get<int>(keyMinutes)??0;

  static SendExpense createNew(Child child, String description, String techInfo, int minutes){
    final now       = DateTime.now();
    final date      = dateToInt(now);
    final timeStamp = now.millisecondsSinceEpoch;

    final newExpense = SendExpense();
    newExpense.set(keyChildID     , child.objectId  );
    newExpense.set(keyDescription , description     );
    newExpense.set(keyTechInfo    , techInfo        );
    newExpense.set(keyMinutes     , minutes         );
    newExpense.set(keyDate        , date            );
    newExpense.set(keyLastChangeTime , timeStamp    );
    newExpense.set(keyCreateTime     , timeStamp    );
    return newExpense;
  }
}

class ExpenseManager {
  static const String _keyListName  = 'ExpenseList';
  
  final _expenseList = <SendExpense>[];
  int _localSavedLastChangeTime = 0;
  late Child _child;

  final _listenerList = <MinutesEvent>[];

  void registerListener(MinutesEvent listener){
    _listenerList.add(listener);
  }
  void unRegisterListener(MinutesEvent listener){
    _listenerList.remove(listener);
  }

  Future<void> init(Child child) async {
    _child = child;
    await _getLocal();
  }

  Future<void> addExpense(int minutes, String description, String techInfo) async {
    final now       = DateTime.now();
    final date      = dateToInt(now);
    final timeStamp = now.millisecondsSinceEpoch;

    final expense = _expenseList.firstWhereOrNull((expense) => expense.description == description && expense.techInfo == techInfo && expense.date == date);
    if (expense != null) {
      expense.set(SendExpense.keyMinutes        , expense.minutes + minutes );
      expense.set(SendExpense.keyLastChangeTime , timeStamp );
    } else {
      final newExpense = SendExpense.createNew(_child, description, techInfo, minutes);
      _expenseList.add(newExpense);
    }

    _saveLocal();

    for (var listener in _listenerList) {
      listener(minutes);
    }
  }

  Future<void> _getLocal() async {
    final localObjectList = await ParseList.getLocal(_keyListName, () => SendExpense() );
    _expenseList.addAll(localObjectList);
    _localSavedLastChangeTime = ParseList.getMaxLastChangeTime(_expenseList);
  }

  Future<void> _saveLocal() async {
    _localSavedLastChangeTime = await ParseList.saveLocal(_expenseList, _keyListName, _localSavedLastChangeTime);
  }

  Future<void> saveToServer() async {
    await ParseList.saveServer(_expenseList, 0);
    await ParseList.deleteLocal(_expenseList, _keyListName);
    _expenseList.clear();
  }
}

/// Баланс получено/израсходовано
/// Только чтение, заполняется автоматически на сервере
class Balance extends ParseObject implements ParseCloneable {
  static const String keyBalance   = 'Balance';

  static const String keyChildID  = 'ChildID';

  static const String keyEarned   = 'Earned';
  static const String keySpent    = 'Spent';

  Balance() : super(keyBalance);
  Balance.clone() : this();

  @override
  Balance clone(Map<String, dynamic> map) => Balance.clone()..fromJson(map);

  String get childID => get<String>(keyChildID)??'';
  int get _earned => get<int>(keyEarned)??0;
  int get _spent  => get<int>(keySpent)??0;
  int get minutes => _earned - _spent;

  static Balance createNew(Child child){
    final newBalance = Balance();
    newBalance.set(keyChildID  , child.objectId );
    newBalance.set(keyEarned   , 0              );
    newBalance.set(keySpent    , 0              );
    return newBalance;
  }

  Future<void> readFromServer() async {
    final query = QueryBuilder<Balance>(Balance());
    query.whereEqualTo(Balance.keyChildID, childID);

    final serverBalance = (await query.first())!;
    set<int>(keyEarned, serverBalance._earned);
    set<int>(keySpent, serverBalance._spent);
  }
}

class BalanceManager {
  static const String keyBalance = 'Balance';
  late Child _child;

  Balance? _balance;
  Balance get balance => _balance!;

  List<Balance>? _balanceList;

  final _listenerList = <MinutesEvent>[];

  void registerListener(MinutesEvent listener){
    _listenerList.add(listener);
  }
  void unRegisterListener(MinutesEvent listener){
    _listenerList.remove(listener);
  }

  Future<void> init(Child child) async {
    if (_balance != null) return;

    _child = child;

    appState.balanceDirector.estimateManager.registerListener(_onEarnMinutes);
    appState.balanceDirector.expenseManager.registerListener(_onSpentMinutes);

    final prefs = await SharedPreferences.getInstance();
    final balanceObjectID = prefs.getString(keyBalance)??'';

    if (balanceObjectID.isNotEmpty){
      _balance = await Balance().fromPin(balanceObjectID);
    }

    if (_balance == null) {
      _balance = Balance.createNew(child);
      _balance!.objectId = '${_balance!.parseClassName}/${getNewLocalObjectID()}';
      await _balance!.pin();
      await prefs.setString(keyBalance, _balance!.objectId!);
    }
  }

  Future<void> getServerBalance() async {
    if (_balance != null && !_balance!.objectId!.contains('${_balance!.parseClassName}/')) {
      await _balance!.readFromServer();
      await _balance!.pin();
      balanceChanged();
      return;
    }

    final query = QueryBuilder<Balance>(Balance());
    query.whereEqualTo(Balance.keyChildID , _child.objectId);

    final newBalanceList = await query.find();
    if (newBalanceList.isEmpty) return;
    final newBalance = newBalanceList.first;

    if (_balance == null || _balance!.objectId! != newBalance.objectId!) {
      if (_balance != null){
        _balance!.unpin();
      }

      _balance = newBalance;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(keyBalance, _balance!.objectId!);
      await _balance!.pin();
    }

    _balance = newBalance;
    balanceChanged();
  }

  /// Используется в parent для установки текущего ребёнка
  /// для доступа к его балансу
  Future<void> setChild(Child child) async {
    _balanceList ??= [];

    _child = child;
    _balance = null;

    _balance = _balanceList!.firstWhereOrNull((balance) => balance.childID == child.objectId);
    if (_balance != null) {
      await _balance!.readFromServer();
      return;
    }

    final query = QueryBuilder<Balance>(Balance());
    query.whereEqualTo(Balance.keyChildID, child.objectId);
    final newBalanceList = await query.find();
    if (newBalanceList.isNotEmpty){
      _balance = newBalanceList.first;
      return;
    }

    if (_balance == null){
      final newBalance = Balance.createNew(child);
      await newBalance.save();
      _balanceList!.add(newBalance);
      _balance = newBalance;
    }
  }

  void _onEarnMinutes(int minutes){
    _balance!.set(Balance.keyEarned, _balance!._earned + minutes);
    _balance!.pin();
    balanceChanged();
  }

  void _onSpentMinutes(int minutes){
    _balance!.set(Balance.keySpent, _balance!._spent + minutes);
    _balance!.pin();
    balanceChanged();
  }

  void balanceChanged() {
    for (var listener in _listenerList) {
      listener(_balance!.minutes);
    }
  }
}

class BalanceDirector {
  final estimateManager = EstimateManager();
  final expenseManager = ExpenseManager();
  final balanceManager = BalanceManager();

  Future<void> init(Child child) async {
    await estimateManager.init(child);
    await expenseManager.init(child);
    await balanceManager.init(child);
  }

  Future<void> synchronize() async {
    await estimateManager.saveToServer();
    await expenseManager.saveToServer();
    await balanceManager.getServerBalance();
  }
}
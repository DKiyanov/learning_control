import 'package:learning_control/parse/parse_app/parse_app_group.dart';
import 'package:learning_control/parse/parse_main.dart';
import 'package:learning_control/parse/parse_util.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';

import '../app_state.dart';
import '../common.dart';

enum CheckPointStatus {
  complete,          // Выполнено
  notComplete,       // Не выполнено
  partiallyComplete, // частично выполнено
  expectation,       // Ожидание, CheckPoint ещё не наступил
  canceled,          // Отменено
}

final _checkPointStatusNameMap = {
  CheckPointStatus.complete          : TextConst.txtCheckPointStatusComplete         ,
  CheckPointStatus.notComplete       : TextConst.txtCheckPointStatusNotComplete      ,
  CheckPointStatus.partiallyComplete : TextConst.txtCheckPointStatusPartiallyComplete,
  CheckPointStatus.expectation       : TextConst.txtCheckPointStatusExpectation      ,
  CheckPointStatus.canceled          : TextConst.txtCheckPointStatusCanceled         ,
};

enum CheckPointResultType {
  text,              // Описано в текстте
  appGroupUsageTime, // Доп. время к использованию группы
  balance,           // Минуты к балансу
}

final _checkPointResultTypeNameMap = {
  CheckPointResultType.text              : TextConst.txtCheckPointResultTypeText             ,
  CheckPointResultType.appGroupUsageTime : TextConst.txtCheckPointResultTypeAppGroupUsageTime,
  CheckPointResultType.balance           : TextConst.txtCheckPointResultTypeBalance          ,
};

String getCheckPointStatusName(CheckPointStatus checkPointStatus) => _checkPointStatusNameMap[checkPointStatus]!;
String getCheckPointResultTypeName(CheckPointResultType checkPointResultType) => _checkPointResultTypeNameMap[checkPointResultType]!;

/// Настройки приложения
class CheckPoint extends ParseObject implements ParseCloneable {
  static const String keyCheckPoint = 'CheckPoint';

  static const String keyChildID        = 'ChildID';

  static const String keyTaskText            = 'TaskText';             // String Тескст задачи
  static const String keyCheckTime           = 'CheckTime';            // String Время выполнения проверки
  static const String keyDate                = 'Date';                 // int Дата
  static const String keyDateTime            = 'DateTime';             // DateTime плановое время выполнения проверки (millisecondsSinceEpoch)
  static const String keyPeriodicity         = 'Periodicity';          // int Переодичность, index in dayNameList; 0 - однократное выполнение
  static const String keyNoticeBeforeMinutes = 'NoticeBeforeMinutes';  // int Уведомелние за Х минут
  static const String keyCountDaysToCancel   = 'CountDaysToCancel';    // int - Количество дней для отмены - 0 задание не будет контролироваться на следующий день
  static const String keyCancelDate          = 'CancelDate';           // int - Дата прекращения контроля
  static const String keyStatus              = 'Status';               // CheckPointStatus Статус
  static const String keyCompletionRate      = 'CompletionRate';       // int Степень/процент выполнения
  static const String keyCompletionComment   = 'CompletionComment';    // String - комментарий к выполнению
  static const String keyBonusType           = 'BonusType';            // CheckPointValueType Тип бонуса
  static const String keyBonusValue          = 'BonusValue';           // int Значение бонуса
  static const String keyBonusText           = 'BonusText';            // String Текст бонуса
  static const String keyPenaltyType         = 'PenaltyType';          // CheckPointValueType Тип штрафа
  static const String keyPenaltyValue        = 'PenaltyValue';         // int Значение штрафа
  static const String keyPenaltyText         = 'PenaltyText';          // String Текст штрафа
  static const String keyAppGroup            = 'AppGroup';             // appGroup Группа приложений к которой применяется бонус или штрапф
  static const String keyLockGroups          = 'LockGroups';           // bool - блокировать групы, чувствительные к CheckPoint
  static const String keyRePlaned            = 'RePlaned';             // bool - перепланированно, для перепланирования переодических заданий
  static const String keyBalanceAdd          = 'BalanceAdd';           // int - добавка к балансу в результате бонуса или штрафа

  static const String keyLastChangeTime      = ParseList.lastChangeTimeKey;  // millisecondsSinceEpoch в момент изменения

  CheckPoint() : super(keyCheckPoint);
  CheckPoint.clone() : this();

  @override
  CheckPoint clone(Map<String, dynamic> map) => CheckPoint.clone()..fromJson(map);

  String get taskText               => get<String>(keyTaskText           )??'';
  String get checkTime              => get<String>(keyCheckTime          )??'';
  int    get date                   => get<int>(keyDate                  )??0;
  int    get dateTime               => get<int>(keyDateTime              )??0; // millisecondsSinceEpoch
  int    get periodicity            => get<int>(keyPeriodicity           )??0;
  int    get noticeBeforeMinutes    => get<int>(keyNoticeBeforeMinutes   )??0;
  int    get countDaysToCancel      => get<int>(keyCountDaysToCancel     )??0;
  int    get completionRate         => get<int>(keyCompletionRate        )??0;
  String get completionComment      => get<String>(keyCompletionComment  )??'';
  int    get bonusValue             => get<int>(keyBonusValue            )??0;
  String get bonusText              => get<String>(keyBonusText          )??'';
  int    get penaltyValue           => get<int>(keyPenaltyValue          )??0;
  String get penaltyText            => get<String>(keyPenaltyText        )??'';
  bool   get lockGroups             => get<bool>(keyLockGroups           )??false;
  int    get balanceAdd             => get<int>(keyBalanceAdd            )??0;

  CheckPointStatus     get status      => CheckPointStatus.values.firstWhere((element) => element.name == (get<String>(keyStatus)??CheckPointStatus.notComplete.name));
  CheckPointResultType get bonusType   => CheckPointResultType.values.firstWhere((element) => element.name == (get<String>(keyBonusType)??CheckPointResultType.text)) ;
  CheckPointResultType get penaltyType => CheckPointResultType.values.firstWhere((element) => element.name == (get<String>(keyPenaltyType)??CheckPointResultType.text)) ;
  AppGroup?            get appGroup    => appState.appGroupManager.getFromName((get<String>(keyAppGroup)??'')) ;

  int get checkDateTime => get<int>(keyDateTime )??0;

  int get warningDateTime {
    return DateTime.fromMillisecondsSinceEpoch(checkDateTime).add(Duration(minutes: - noticeBeforeMinutes)).millisecondsSinceEpoch;
  }

  CheckPointCondition get condition {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (checkDateTime   <= now) return CheckPointCondition.lock;
    if (warningDateTime <= now) return CheckPointCondition.warning;
    return CheckPointCondition.free;
  }

  static CheckPoint setCheckPoint({
    CheckPoint? checkPoint,
    Child? child,
    required String taskText,
    required String checkTime,
    required int date,
    int periodicity = 0, // не переодическое - однократное
    int noticeBeforeMinutes = 0,
    int countDaysToCancel = 0,
    CheckPointStatus? status,
    int completionRate = 0,
    String completionComment = '',
    required CheckPointResultType bonusType,
    int bonusValue = 0,
    String bonusText = '',
    required CheckPointResultType penaltyType,
    int penaltyValue = 0,
    String penaltyText = '',
    AppGroup? appGroup,
    bool lockGroups = false,
  }){
    CheckPoint setCheckPoint;
    if (checkPoint != null){
      setCheckPoint = checkPoint;
    } else {
      setCheckPoint = CheckPoint();
      setCheckPoint.set(keyChildID, child!.objectId);
      setCheckPoint.set(keyRePlaned, false);
    }

    final dateTime = intDateTimeToDateTime(date, stringToIntTime(checkTime));

    int cancelDate = date;
    if (countDaysToCancel > 0) {
      cancelDate = dateToInt(dateTime.add(Duration(days: countDaysToCancel)));
    }


    setCheckPoint.set(keyTaskText                 , taskText            );
    setCheckPoint.set(keyCheckTime                , checkTime           );
    setCheckPoint.set(keyDate                     , date                );
    setCheckPoint.set(keyDateTime                 , dateTime.millisecondsSinceEpoch);
    setCheckPoint.set(keyPeriodicity              , periodicity         );
    setCheckPoint.set(keyNoticeBeforeMinutes      , noticeBeforeMinutes );
    setCheckPoint.set(keyCountDaysToCancel        , countDaysToCancel   );
    setCheckPoint.set(keyCancelDate               , cancelDate          );
    setCheckPoint.set(keyCompletionRate           , completionRate      );
    setCheckPoint.set(keyCompletionComment        , completionComment   );
    setCheckPoint.set(keyBonusType                , bonusType.name      );
    setCheckPoint.set(keyBonusValue               , bonusValue          );
    setCheckPoint.set(keyBonusText                , bonusText           );
    setCheckPoint.set(keyPenaltyType              , penaltyType.name    );
    setCheckPoint.set(keyPenaltyValue             , penaltyValue        );
    setCheckPoint.set(keyPenaltyText              , penaltyText         );
    setCheckPoint.set(keyLockGroups               , lockGroups          );

    if (status != null){
      setCheckPoint.set(keyStatus, status.name);
    }

    if (appGroup != null) {
      setCheckPoint.set(keyAppGroup, appGroup.objectId);
    }

    final balanceAdd = setCheckPoint.getResultValue(CheckPointResultType.balance);
    setCheckPoint.set(keyBalanceAdd, balanceAdd);

    setCheckPoint.set(keyLastChangeTime, DateTime.now().millisecondsSinceEpoch );

    return setCheckPoint;
  }

  /// Возвращает результирующее изменение
  int getResultValue(CheckPointResultType resultType){
    if (status == CheckPointStatus.complete ||
        status == CheckPointStatus.partiallyComplete
    ){
      if (bonusType == resultType){
        final value = bonusValue * completionRate ~/ 10;
        return value;
      }
    }

    if (status == CheckPointStatus.notComplete){
      if (penaltyType == resultType){
        return - penaltyValue;
      }
    }

    return 0;
  }

}

enum CheckPointCondition {
  free,
  warning,
  lock,
}

class CheckPointManager {
  /// Содержит список не решонных задач (в статусе CheckPointStatus.expectation)
  /// на текущую и предыдущие даты
  final _checkPointList = <CheckPoint>[];
  Child? _child;
  Child get child => _child!;

  int savedLastChangeTime = 0;

  CheckPointCondition _condition = CheckPointCondition.free;
  CheckPointCondition get condition => _condition;

  /// Обновление (пересчёт) состояния
  void refreshCondition() {
    final now = DateTime.now().millisecondsSinceEpoch;

    _condition = CheckPointCondition.free;

    if (_checkPointList.isEmpty) return;

    for (var checkPoint in _checkPointList) {
      if (checkPoint.status != CheckPointStatus.expectation) continue;

      if (checkPoint.checkDateTime <= now) {
        _condition = CheckPointCondition.lock;
        return;
      }

      if (checkPoint.warningDateTime <= now) {
        _condition = CheckPointCondition.warning;
      }
    }
  }

  /// возвращает список объектов на сервере на заданную дату
  Future<List<CheckPoint>> getCheckPointListForDate(Child child, int date) async {
    final query = QueryBuilder<CheckPoint>(CheckPoint());
    query.whereEqualTo(CheckPoint.keyChildID , child.objectId);
    query.whereEqualTo(CheckPoint.keyDate    , date);
    return await query.find();
  }

  /// Инициализация
  Future<void> init(Child child) async {
    _child = child;

    final localObjectList = await ParseList.getLocal<CheckPoint>(CheckPoint.keyCheckPoint, ()=> CheckPoint() );
    _checkPointList.addAll(localObjectList);

    refreshCondition();
  }

  /// Вызывается устройством родителя для получения condition
  Future<void> setChild(Child child) async {
    _child = child;
    await readFromServer();
  }

  /// Вызывается устройством родителя для обновления condition
  Future<void> readFromServer() async {
    final checkPointList = await _getServerObjectList(_child!);
    _checkPointList.clear();
    _checkPointList.addAll(checkPointList);
    refreshCondition();
  }

  /// возвращает список на текущую дату + не решонных ранее
  Future<List<CheckPoint>> _getServerObjectList(Child child) async {
    final date = dateToInt(DateTime.now());

    // не решонные ранее
    final query = QueryBuilder<CheckPoint>(CheckPoint());
    query.whereEqualTo(CheckPoint.keyChildID, child.objectId);
    query.whereEqualTo(CheckPoint.keyStatus, CheckPointStatus.expectation.name);
    query.whereLessThan(CheckPoint.keyDate, date);
    query.whereGreaterThanOrEqualsTo(CheckPoint.keyCancelDate, date);
    final checkPointList = await query.find();

    // текущая дата
    checkPointList.addAll(
      await getCheckPointListForDate(child, date)
    );

    return checkPointList;
  }

  /// Синхронизирует список
  Future<void> synchronize() async {
    await _saveLocal();

    final serverObjectList = await _getServerObjectList(_child!);

    final localSaveNeed = await ParseList.synchronizeLists(_checkPointList, serverObjectList);

    _checkPointList.sort((a, b) => a.checkDateTime.compareTo(b.checkDateTime));

    if (localSaveNeed) {
      await _saveLocal();
    }

    savedLastChangeTime = ParseList.getMaxLastChangeTime(_checkPointList);

    refreshCondition();
  }

  Future<void> _saveLocal() async {
    final forDelList = <CheckPoint>[];
    for (var checkPoint in _checkPointList) {
      if (checkPoint.status != CheckPointStatus.expectation){
        checkPoint.unpin();
        forDelList.add(checkPoint);
      }
    }
    for (var checkPoint in forDelList) {
      _checkPointList.remove(checkPoint);
    }

    savedLastChangeTime = await ParseList.saveLocal(_checkPointList, CheckPoint.keyCheckPoint, savedLastChangeTime);
  }

  /// Возвращает списки заданий
  List<CheckPoint> getCheckPoints({bool forWarning = false, bool forLock = false}){
    final retCheckPointList = <CheckPoint>[];

    final now = DateTime.now().millisecondsSinceEpoch;

    for (var checkPoint in _checkPointList) {
      if (checkPoint.status != CheckPointStatus.expectation) continue;

      if (
        ( forWarning && checkPoint.warningDateTime <= now) ||
        ( forLock    && checkPoint.checkDateTime   <= now)
      )
      {
        retCheckPointList.add(checkPoint);
      }
    }

    return retCheckPointList;
  }

  int getAppGroupResult(AppGroup appGroup){
    int result = 0;

    for (var checkPoint in _checkPointList) {
      if (checkPoint.appGroup != null && checkPoint.appGroup!.objectId == appGroup.objectId) {
        result += checkPoint.getResultValue(CheckPointResultType.appGroupUsageTime);
      }
    }

    return result;
  }
}


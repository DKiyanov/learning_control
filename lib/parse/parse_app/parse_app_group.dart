import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app_state.dart';
import '../../common.dart';
import '../parse_check_point.dart';
import '../parse_util.dart';
import '../../time.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';

import 'app_access.dart';

/// Группа с настройками ограничений к программе
class AppGroup extends ParseObject implements ParseCloneable {
  static const String keyAppGroup      = 'AppGroup';

  static const String keyUserID          = 'UserID';

  static const String keyName            = 'Name';
  static const String keyCostNumerator   = 'CostNumerator';    // стоимость - расход балов за минуту, числитель
  static const String keyCostDenominator = 'CostDenominator';  // стоимость - расход балов за минуту, знаменатель
  static const String keyTimetable       = 'Timetable';        // расписание доступности
  static const String keyDayLengthList   = 'DayLengthList';    // расписание длительности
  static const String keyIndividual      = 'Individual';       // индивидулаьная настройка к одной программе, не показывается в списке для выбора группы
  static const String keyLastChangeTime  = ParseList.lastChangeTimeKey;  // millisecondsSinceEpoch в момент изменения
  static const String keyLocalObjectID   = 'LocalObjectID';    // локальный идентификатор объекта
  static const String keyDeleted         = 'Deleted';          // Удалено - записи не удаляются, только помечаются
  static const String keyIsDefault       = 'IsDefault';        // Группа используется по умолчанию

  static const String keyWorkingDuration        = 'WorkingDuration'; // длительность использования до отдыха
  static const String keyRelaxDuration          = 'RelaxDuration';   // длительность отдыха
  static const String keyNotUseWhileCharging    = 'NotUseWhileCharging';   // не использовать на зарядке
  static const String keyNotDelApp              = 'keyNotDelApp';   // не удалять приложения
  static const String keyCheckPointSensitive    = 'CheckPointSensitive';   // Чувствительность к CheckPoint

  static const String keySaveLocalEx           = 'SaveLocalEx';   // доп данные сохранённые локально

  AppGroup() : super(keyAppGroup);
  AppGroup.clone() : this();

  @override
  AppGroup clone(Map<String, dynamic> map) => AppGroup.clone()..fromJson(map);

  String get name            => get<String>(keyName)??'';
  int    get costNumerator   => get<int>(keyCostNumerator)??0;
  int    get costDenominator => get<int>(keyCostDenominator)??1;
  bool   get individual      => get<bool>(keyIndividual)??false;
  bool   get deleted         => get<bool>(keyDeleted)??false;
  String get localObjectID   => get<String>(keyLocalObjectID )??'';
  int    get lastChangeTime  => get<int>(keyLastChangeTime)??0;
  bool   get isDefault       => get<bool>(keyIsDefault)??false;

  TimeRange? _timeRange;
  int    get timeRangeMaxDuration => _timeRange?.duration??0;
  String _timeRangeHash = '';

  int    _timeRangeUsageDuration = 0; // время использования в рамках интервала
  int    get timeRangeUsageDuration => _timeRangeUsageDuration;

  int    get workingDuration => get<int>(keyWorkingDuration)??0;
  int    get relaxDuration   => get<int>(keyRelaxDuration)??0;
  double _fatigue = 0;   // величина требуемого отдыха - усталость, в милисекундах
  int    _relaxEndTime = 0; // время завершения отдыха

  bool   get notDelApp => get<bool>(keyNotDelApp)?? false;
  bool   get checkPointSensitive => get<bool>(keyCheckPointSensitive)?? false;
  bool   get notUseWhileCharging => get<bool>(keyNotUseWhileCharging)?? false;

  bool   get isCanEdit       => !appState.appGroupManager.isPredefinedGroup(name);

  bool   get isHidden        => name == TextConst.txtGroupHidden;
  bool   get isUnlimited     => name == TextConst.txtGroupUnlimited   ||
      name == TextConst.txtGroupBottomPanel ||
      name == TextConst.txtGroupTopPanel    ||
      name == TextConst.txtGroupMenu        ||
      name == TextConst.txtGroupMenuPassword;

  bool   _availableOnTimetable = false;
  bool   get availableOnTimetable => _availableOnTimetable;

  AppAccessInfo? _accessInfo;
  AppAccessInfo get accessInfo => _accessInfo!;

  List<TimeRange>? _timetable;

  /// возвращает расписание доступности
  List<TimeRange> getTimetable() {
    if (_timetable != null) return _timetable!;

    final timetableStr = get<String>(keyTimetable)??'';

    if (timetableStr.isEmpty) {
      _timetable = [];
    } else {
      _timetable = jsonStrToTimeRangeList(timetableStr);
    }

    return _timetable!;
  }

  /// устанавливает расписание доступности
  void setTimetable(List<TimeRange> timetable){
    _timetable = timetable;
    final timetableStr = timeRangeListToJsonStr(timetable);
    set(keyTimetable, timetableStr);
  }

  /// Создаёт или изменяет запись группы
  static AppGroup setAppGroup({
    AppGroup?  appGroup,
    ParseUser? user,
    String?    groupName,
    int?       costNumerator,
    int?       costDenominator,
    bool?      individual,
    bool?      isDefault,
    int?       workingDuration,
    int?       relaxDuration,
    bool?      notDelApp,
    bool?      checkPointSensitive,
    bool?      notUseWhileCharging,
    bool?      deleted,
  }){
    AppGroup setAppGroup;

    if (appGroup != null) {
      setAppGroup = appGroup;
    } else {
      setAppGroup = AppGroup();
      setAppGroup.set(keyLocalObjectID , getNewLocalObjectID());
      setAppGroup.set(keyUserID        , user!.objectId );
    }

    if (groupName       != null ) setAppGroup.set(keyName            , groupName       );
    if (costNumerator   != null ) setAppGroup.set(keyCostNumerator   , costNumerator   );
    if (costDenominator != null ) setAppGroup.set(keyCostDenominator , costDenominator );
    if (individual      != null ) setAppGroup.set(keyIndividual      , individual      );
    if (isDefault       != null ) setAppGroup.set(keyIsDefault       , isDefault       );
    if (workingDuration != null ) setAppGroup.set(keyWorkingDuration , workingDuration );
    if (relaxDuration   != null ) setAppGroup.set(keyRelaxDuration   , relaxDuration   );
    if (notDelApp       != null ) setAppGroup.set(keyNotDelApp       , notDelApp       );
    if (deleted         != null ) setAppGroup.set(keyDeleted         , deleted         );
    if (checkPointSensitive    != null ) setAppGroup.set(keyCheckPointSensitive   , checkPointSensitive    );
    if (notUseWhileCharging    != null ) setAppGroup.set(keyNotUseWhileCharging   , notUseWhileCharging    );

    setAppGroup.set(keyLastChangeTime  , DateTime.now().millisecondsSinceEpoch );

    return setAppGroup;
  }

  /// Расчитываем параметры влияющие на доступность группы зависящие от времени
  void calcTimeAvailability(int date, int weekDay, int monthDay, int intTime){
    _calcTimetableAvailability(date, weekDay, monthDay, intTime);
  }

  /// Рассчитывает доступность группы по расписанию
  void _calcTimetableAvailability(int date, int weekDay, int monthDay, int intTime) {
    getTimetable();
    if (_timetable!.isEmpty) {
      _availableOnTimetable = true;
      return;
    }

    final timeRange = _timetable!.firstWhereOrNull((timeRange) =>
        timeRange.from.intTime <= intTime && timeRange.to.intTime >= intTime &&
        (timeRange.day == 0 || timeRange.day == weekDay || timeRange.day == monthDay) &&
        (timeRange.dateFrom == null || (date >= timeRange.dateFrom! && date <= timeRange.dateTo!))
    );

    final timeRangeHash = _timeRange?.getHash()??'';

    if (_timeRangeHash != timeRangeHash) {
      _timeRangeHash = timeRangeHash;
      _timeRange     = timeRange;
      _timeRangeUsageDuration = 0;
    }

    _availableOnTimetable = timeRange != null;
  }

  static TimeRange? getTimeRange(DateTime dateTime, List<TimeRange>? timetable) {
    final date     = dateToInt(dateTime);
    final weekDay  = dateTime.weekday;
    final monthDay = dateTime.day;
    final intTime  = timeToInt(dateTime);

    final timeRange = timetable!.firstWhereOrNull((timeRange) =>
        timeRange.from.intTime <= intTime && timeRange.to.intTime >= intTime &&
        (timeRange.day == 0 || timeRange.day == weekDay || timeRange.day == monthDay) &&
        (timeRange.dateFrom == null || (date >= timeRange.dateFrom! && date <= timeRange.dateTo!))
    );

    return timeRange;
  }

  void fixUsageDuration(int minutes){
    _timeRangeUsageDuration += minutes;

    if (relaxDuration > 0 && workingDuration > 0) {
      _fatigue += minutes * 60000 * relaxDuration / workingDuration;

      if (_fatigue >= relaxDuration * 60000){
        appState.log.add('Relax time started, AppGroup $name');
        _relaxEndTime = DateTime.now().add(Duration(minutes: relaxDuration)).millisecondsSinceEpoch;
        _fatigue = 0;
      }
    }

    _saveLocalEx();
  }

  int getRestRelaxMinutes() {
    if (_relaxEndTime == 0) return 0;

    final now = DateTime.now().millisecondsSinceEpoch;
    if (now >= _relaxEndTime) {
      _relaxEndTime = 0;
      _fatigue = 0;
      appState.log.add('Relax time finished, AppGroup $name');
      appState.launcherRefreshEvent.send();
      return 0;
    }

    final minutes = (_relaxEndTime - now) ~/ 60000;
    return minutes;
  }

  Future<void> _saveLocalEx() async {
    final prefs = await SharedPreferences.getInstance();
    Map<String,dynamic> map = {
      "time"          : DateTime.now().millisecondsSinceEpoch,
      "usageDuration" : _timeRangeUsageDuration,
      "timeRange"     : _timeRangeHash,
      "fatigue"       : _fatigue,
      "relaxEndTime"  : _relaxEndTime
    };
    await prefs.setString('$keySaveLocalEx/$objectId' , jsonEncode(map) );
  }

  Future<void> loadLocalEx() async {
    _timeRangeUsageDuration = 0;
    _fatigue       = 0;

    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('$keySaveLocalEx/$objectId')??'';
    if (json.isEmpty) return;

    final map = jsonDecode(json);
    final int time = map["time"];
    final saveTime = DateTime.fromMillisecondsSinceEpoch(time);
    if ( dateToInt(saveTime) == dateToInt(DateTime.now()) ) {
      _timeRangeUsageDuration = map["usageDuration"]??0;
      _timeRangeHash = map["timeRange"]??'';
      _fatigue       = map["fatigue"]??0;
      _relaxEndTime  = map["relaxEndTime"]??0;
    }
  }

  /// Обновляет расчёт доступности группы, возвращает true если были изменения от последего расчёта
  bool refreshAccessInfo() {
    final newAccessInfo = _calcAccess();
    if (
      _accessInfo == null ||
      _accessInfo!.appAccess != newAccessInfo.appAccess ||
      _accessInfo!.message != newAccessInfo.message
    ){
      _accessInfo = newAccessInfo;
      return true;
    }
    return false;
  }

  AppAccessInfo _calcAccess() {
    if (isHidden) {
      return AppAccessInfo(AppAccess.hidden, TextConst.txtIsHiddenGroup, this);
    }

    if (notUseWhileCharging && appState.charging) {
      return AppAccessInfo(AppAccess.disabled, TextConst.txtNotUseWhileCharging, this);
    }

    if ((timeRangeMaxDuration > 0) && (timeRangeUsageDuration >= timeRangeMaxDuration)) {
      final str = '${TextConst.txtLimitPerRangeReached} ${TextConst.txtFrom} ${_timeRange!.from} ${TextConst.txtTo} ${_timeRange!.to} ${_timeRange!.duration} ${TextConst.txtMinutes}';
      return AppAccessInfo(AppAccess.disabled, str, this);
    }

    final relaxMinutes = getRestRelaxMinutes();
    if ((relaxMinutes > 0)) {
      return AppAccessInfo(AppAccess.disabled, '${TextConst.txtRelaxTime} $relaxMinutes ${TextConst.txtMinutes}', this);
    }

    if (isUnlimited) {
      return AppAccessInfo(AppAccess.allowed, TextConst.txtIsUnlimitedGroup, this);
    }

    if (costNumerator == 0) {
      return AppAccessInfo(AppAccess.disabled, TextConst.txtGroupIsMarkedAsUnavailable, this);
    }

    if (!availableOnTimetable) {
      return AppAccessInfo(AppAccess.disabled, TextConst.txtNotAvailableByTimetable, this);
    }

    if ((costNumerator > 0) && (appState.balanceDirector.balanceManager.balance.minutes <= 0)) {
      return AppAccessInfo(AppAccess.disabled, TextConst.txtNegativeBalance, this);
    }

    if (checkPointSensitive && appState.checkPointManager.condition == CheckPointCondition.lock) {
      return AppAccessInfo(AppAccess.disabled, TextConst.txtCheckPointLock, this);
    }

    return AppAccessInfo(AppAccess.allowed, TextConst.txtIsAvailable, this);
  }

  /// Вызывается после обноление данных полученных с сервера
  /// Приводит в соответствие вычисляемые поля в соотв с новыми данными
  void afterChangeFromServer(){
    _timetable = null;
  }
}

class AppGroupManager {
  final _appGroupList = <AppGroup>[];
  int savedLastChangeTime = 0;
  ParseUser? _user;

  AppGroup? _defaultAppGroup;
  AppGroup get defaultAppGroup {
    if (_defaultAppGroup != null) return _defaultAppGroup!;

    _refreshDefaultGroup();
    return _defaultAppGroup!;
  }

  void _refreshDefaultGroup(){
    _defaultAppGroup = _appGroupList.firstWhereOrNull((appGroup) => appGroup.isDefault );
    if (_defaultAppGroup != null) return;

    _defaultAppGroup = _appGroupList.firstWhere((appGroup) => appGroup.name == TextConst.txtGroupUnlimited );
    setGroupAsDefault(group: _defaultAppGroup!, save: false);
  }

  AppGroup? _hiddenAppGroup;
  AppGroup get hiddenAppGroup {
    if (_hiddenAppGroup != null) return _hiddenAppGroup!;

    _hiddenAppGroup = _appGroupList.firstWhere((appGroup) => appGroup.name == TextConst.txtGroupHidden );
    return _hiddenAppGroup!;
  }

  /// Получает группу по идентификатору
  AppGroup getFromID(String appGroupID) {
    final appGroup = _appGroupList.firstWhereOrNull((appGroup) => appGroup.localObjectID == appGroupID );
    return appGroup!;
  }

  /// Получает группу по имения
  AppGroup? getFromName(String groupName) {
    final appGroup = _appGroupList.firstWhereOrNull((appGroup) => appGroup.name == groupName );
    return appGroup;
  }

  void addAppGroup(AppGroup appGroup){
    _appGroupList.add(appGroup);
  }

  Future<void> setGroupAsDefault({required AppGroup group, required bool save}) async {
    if (group.isDefault) return;

    for (var group in _appGroupList) {
      if (group.isDefault) {
        AppGroup.setAppGroup(appGroup: group, isDefault: false);
        group.save();
      }
    }

    AppGroup.setAppGroup(appGroup: group, isDefault: true);
    if (save) group.save();
  }

  /// Инициализация
  Future<void> init(ParseUser user) async {
    if (_appGroupList.isNotEmpty) return;
    _user = user;

    final localObjectList = await ParseList.getLocal<AppGroup>(AppGroup.keyAppGroup, ()=> AppGroup() );
    _appGroupList.addAll(localObjectList);

    for (var appGroup in _appGroupList) {
      appGroup.loadLocalEx();
    }

    if (await _addPredefinedGroup()){
      await _saveLocal();
    }
  }

  /// Синхронизирует список ограничений
  Future<void> synchronize() async {
    await _saveLocal();

    final serverObjectList = await _getServerObjectList(_user!);

    for (var serverObject in serverObjectList) {
      final appGroup = _appGroupList.firstWhereOrNull((appGroup) => appGroup.name == serverObject.name);
      if (appGroup != null && appGroup.objectId != serverObject.objectId){
        appGroup.unpin();
        _appGroupList.remove(appGroup);
      }
    }

    final changedObjectList = <AppGroup>[];
    final localSaveNeed = await ParseList.synchronizeLists(_appGroupList, serverObjectList, changedObjectList : changedObjectList);

    for (var appGroup in changedObjectList) {
      appGroup.afterChangeFromServer();
    }

    if (localSaveNeed) {
      _refreshDefaultGroup();
      await _saveLocal();
    }

    savedLastChangeTime = ParseList.getMaxLastChangeTime(_appGroupList);

    if (localSaveNeed){
      refreshGroupsAccessInfo();
    }
  }

  Future<void> _saveLocal() async {
    savedLastChangeTime = await ParseList.saveLocal(_appGroupList, AppGroup.keyAppGroup, savedLastChangeTime);
  }

  /// возвращает список всех групп зарегистрированных за пользователем
  Future<List<AppGroup>> _getServerObjectList(ParseUser user) async {
    final query = QueryBuilder<AppGroup>(AppGroup());
    query.whereEqualTo(AppGroup.keyUserID, user.objectId);

    return await query.find();
  }

  /// Возвращает список всех групп
  Future<List<AppGroup>> getObjectList(ParseUser user, UsingMode usingMode) async {
    _user = user;
    if (usingMode == UsingMode.child){
      return _appGroupList;
    }

    _appGroupList.clear();
    _appGroupList.addAll(await _getServerObjectList(user));
    await _addPredefinedGroup(saveServer : true);

    savedLastChangeTime = ParseList.getMaxLastChangeTime(_appGroupList);

    return _appGroupList;
  }

  Future<void> save(UsingMode usingMode) async {
    if (usingMode == UsingMode.child){
      await synchronize();
      return;
    }

    savedLastChangeTime = await ParseList.saveServer(_appGroupList, savedLastChangeTime);
  }

  Future<bool> _checkAndCreate(String groupName, bool saveServer, [String? timetable, String? dayLengthList]) async {
    if (!_appGroupList.any((appGroup) => appGroup.name == groupName)) {
      final appGroup = AppGroup.setAppGroup(
        user      : _user,
        groupName : groupName,
        notDelApp : true,
      );
      _appGroupList.add(appGroup);
      if (timetable != null) {
        appGroup.set(AppGroup.keyTimetable, timetable);
      }
      if (dayLengthList != null) {
        appGroup.set(AppGroup.keyDayLengthList, dayLengthList);
      }
      if (saveServer) await appGroup.save();
      return true;
    }

    return false;
  }

  // Future<void> _deleteAppGroup(String appGroupName) async {
  //   final appGroup = _appGroupList.firstWhereOrNull((appGroup) => appGroup.name == appGroupName);
  //   if (appGroup == null) return;
  //   appGroup.unpin();
  //   _appGroupList.remove(appGroup);
  // }

  /// Проверяет отсутствие и доавляет обязательные предопределённые группы
  /// Проверяет наличие группы по умолчанию
  Future<bool> _addPredefinedGroup({bool saveServer = false} ) async {
    bool groupAdded = false;
    String unlimited = '[{"day":0,"from":"00:00","to":"24:00"}]';

    if (await _checkAndCreate(TextConst.txtGroupUnlimited,    saveServer, unlimited)) groupAdded = true;
    if (await _checkAndCreate(TextConst.txtGroupBottomPanel,  saveServer, unlimited)) groupAdded = true;
    if (await _checkAndCreate(TextConst.txtGroupTopPanel,     saveServer, unlimited)) groupAdded = true;
    if (await _checkAndCreate(TextConst.txtGroupMenu,         saveServer, unlimited)) groupAdded = true;
    if (await _checkAndCreate(TextConst.txtGroupMenuPassword, saveServer, unlimited)) groupAdded = true;

    if (await _checkAndCreate(TextConst.txtNotAvailable,      saveServer)) groupAdded = true;
    if (await _checkAndCreate(TextConst.txtGroupHidden,       saveServer)) groupAdded = true;

    final defaultAppGroup = _appGroupList.firstWhereOrNull((appGroup) => appGroup.isDefault );
    if (defaultAppGroup == null) {
      final appGroup = _appGroupList.firstWhere((appGroup) => appGroup.name == TextConst.txtGroupUnlimited );
      appGroup.set(AppGroup.keyIsDefault, true);
      groupAdded = true;
      if (saveServer) await appGroup.save();
    }

    return groupAdded;
  }

  bool isPredefinedGroup(String groupName) {
    return
      groupName == TextConst.txtGroupUnlimited    ||
          groupName == TextConst.txtGroupBottomPanel  ||
          groupName == TextConst.txtGroupTopPanel     ||
          groupName == TextConst.txtGroupMenu         ||
          groupName == TextConst.txtGroupMenuPassword ||
          groupName == TextConst.txtNotAvailable      ||
          groupName == TextConst.txtGroupHidden;
  }

  /// обновляет расчёт доступности групп по расписанию
  _refreshGroupsTimeAvailability() {
    final now = DateTime.now();

    final date     = dateToInt(now);
    final weekDay  = now.weekday;
    final monthDay = now.day;
    final intTime  = timeToInt(now);

    for (var group in _appGroupList) {
      group.calcTimeAvailability(date, weekDay, monthDay, intTime);
    }
  }

  /// Обновляет рсачёт доступности групп
  /// возвращает true если для какойто из груп в дрступности прооизошли изменения
  bool refreshGroupsAccessInfo() {
    bool result = false;

    _refreshGroupsTimeAvailability();
    appState.checkPointManager.refreshCondition();
    for (var group in _appGroupList) {
      if (group.refreshAccessInfo()) {
        result = true;
      }
    }

    return result;
  }

  void prepareForNewDay() {
    for (var appGroup in _appGroupList) {
      appGroup._timeRangeUsageDuration = 0;
      appGroup._fatigue = 0;
    }
  }
}


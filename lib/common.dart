import 'dart:ui';

import 'app_state.dart';

class TextConst{
  static String versionDateStr    = '30.04.2023';
  static String version           = 'Версия';
  static String defaultURL        = 'http://192.168.0.142:1337/parse';

  static String txtStarting       = 'Запуск';
  static String txtLoading        = 'Загрузка';
  static String txtEntryToOptions = 'Вход в настройку';
  static String txtServerURL      = 'Адрес сервера';
  static String txtWithoutServer  = 'Без сервера';
  static String txtWithServer     = 'С сервером';
  static String txtEmailAddress   = 'Адрес электронной почты родителя';
  static String txtPassword       = 'Пароль';
  static String txtSignIn         = 'Войти';
  static String txtSignUp         = 'Зарегистрироваться';
  static String txtInputAllParams = 'Нужно заполнить все поля';
  static String txtProceed        = 'Продолжить';
  static String txtOptions        = 'Настройки';
  static String txtParentalMenu   = 'Родительское меню';
  static String txtAppFilterShow  = 'Показать фильтр';
  static String txtAppManualFilter = 'Ручной ввод фильтра';
  static String txtAppAvailableFilter = 'Доступные';
  static String txtAppFilterValueHint  = 'Фильтр';
  static String txtStartSetup     = 'Запустить настройку';
  static String txtSwitchControlOn = 'Включить контроль';
  static String txtChildName       = 'Имя ребёнка';
  static String txtDeviceName      = 'Имя устройства';
  static String txtApplyChanges    = 'Применить изменения';
  static String txtAddNewChild     = 'Добавить нового';
  static String txtAddNewDevice    = 'Добавить новоое';
  static String txtAddNewGroup     = 'Добавить новую';
  static String txtAddIndividualGroup = 'Индивидуальная настройка';
  static String txtAppTuner        = 'Настройка программ';
  static String txtGroupUnlimited  = 'Без ограничений';
  static String txtGroupBottomPanel = 'Нижнняя панель'; // Без ограничений
  static String txtGroupTopPanel   = 'Верхняя панель';  // Без ограничений
  static String txtGroupMenu       = 'Меню'; // Без ограничений
  static String txtGroupMenuPassword = 'Меню + пароль'; // Запуск после ввода пароля + ограничение на длительноость использования
  static String txtGroupHidden     = 'Скрытые';
  static String txtDefaultGroup    = 'Группа используется по умолчанию';
  static String txtNotAvailable    = 'Не доступные';
  static String txtAppsSetup       = 'Настройка приложений';
  static String txtNext           = 'Дальше';
  static String txtAppGroupList   = 'Список групп приложений';
  static String txtLogList        = 'Log';
  static String txtSetBackgroundImage = 'Установить фоновую картинку';
  static String txtRestartApp     = 'Перезапустить программу';
  static String txtMonitoringSwitchOff = 'Выключить мониторинг';
  static String txtTurnOffDevice = 'Выключить устройство';
  static String txtMonitoringSwitchingOff = 'Выключение мониторинга';
  static String txtMonitoringSwitchOn  = 'Включить мониторинг';
  static String txtSaveLog        = 'Сохранить лог';
  static String txtExtLoggingOn   = 'Включить расширенное логирование';
  static String txtExtLoggingOff  = 'Выключть расширенное логирование';
  static String txtAppGroupTuning = 'Настройка группы';
  static String txtAppGroupsTuning = 'Настройка групп приложений';
  static String txtMassAssignAppGroup = 'Массовое назначение групп к приложениям';
  static String txtSingleAssignAppGroup = 'Одиночное назначение группы к приложению';
  static String txtAppGroupName   = 'Наименование группы';
  static String txtAppUsageCost   = 'Стоимость использования';
  static String txtCoins          = 'Условные минуты';
  static String txtPoints         = 'Балы';
  static String txtRealMinutes    = 'Реальные минуты';
  static String txtPer            = 'За';
  static String txtMaxTotalDurationPerDay = 'Максимальная длительность использования в день';
  static String txtWorkingDuration = 'Длительность использования';
  static String txtRelaxDuration   = 'Длительность отдыха';
  static String txtHyphen          = '-';
  static String txtDoDelete       = 'Удалить';
  static String txtChildrenDevices = 'Дети и их устройства';

  static String txtUsingModeTitle      = 'Выбор режима использования устройства';
  static String txtUsingModeInvitation = 'Выбирите пожалуйста кем будет использоваться это устойство';
  static String txtUsingModeParent     = 'Это устройство будет использоваться РОДИТЕЛЕМ';
  static String txtUsingModeChild      = 'Это устройство будет использоваться РЕБЁНКОМ';
  static String txtUsingModeWarning    = 'Изменить выор можно будет только переустановкой программы';


  static String errServerUrlEmpty  = 'Не указан адрес сервера';
  static String errServerUnavailable  = 'Сервер недоступен';
  static String errFailedLogin   = 'Не удалось подключиться к серверу';
  static String errFailedSignUp   = 'Не удалось создать учётную запись на сервере';
  static String errInvalidPassword = 'Не правильный пароль';


  static String msgAppGroup1  = 'Есть другая группа с именем';
  static String msgChildList1  = 'Ещё нет ни одного ребёнка, /nСначала выполните настройку на устройстве ребёнка';

  static String txtIgnoringBatteryOptimizationsTitle = 'Игнорирование оптмизации расхода энергии';
  static String txtIgnoringBatteryOptimizationsText  = 'Для того чтобы это приложение не закрывалось системой для оптимизации расхода заряда батареи';

  static String txtUsageAccessTitle = 'Доступ к статистике использования приложений';
  static String txtUsageAccessText  = 'Для того чтобы контроллировать текущее запущенное приложение';

  static String txtDrawOverlaysTitle = 'Вывод поверх других уже запущенных приложений';
  static String txtDrawOverlaysText  = 'Для того чтоб иметь возможность завершить использование текущего приложения';

  static String txtLauncherTitle = 'Замена рабочего стола на это приложение';
  static String txtLauncherText  = 'Для контроля доступных для запуска приложений';

  static String txtTimetableOfAppGroup  = 'Расписание ДОСТУПНОСТИ';
  static String txtDayLengthListOfAppGroup  = 'Расписание ДЛИТЕЛЬНОСТИ';

  static String txtEstimateList     = 'Заработанные оценки';
  static String txtSourceNameManual = 'Ручной ввод';
  static String txtSourceCheckPoint = 'Результат выполнения задания';
  static String txtCoinTypeSingle   = 'Одноразовое поощрение';
  static String txtForWhat          = 'За что';
  static String txtAddEstimate      = 'Добавление оценки';
  static String txtCoinList         = 'Список видов оценки';
  static String txtCoinTuning       = 'Настройка видов оценки';
  static String txtCoinPrice        = 'Кол-во условных минут за балл';
  static String txtCoinType         = 'Наименование';
  static String txtExpenseList      = 'Потраченое время';
  static String txtBalanceValue     = 'Баланс';

  static String txtDebugAddExpense  = 'отладка Добавить расход';
  static String txtDebugAddEstimate = 'отладка Добавить заработок';
  static String txtDebugSynchronize = 'отладка Синхронизация';

  static String txtTimetable        = 'Расписание доступности';
  static String txtDayLengthList    = 'Расписание длительности дня';

  static String txtDelete           = 'Уталить';
  static String txtSetAsDefault     = 'Использовать по умолчанию';

  static String msgAppGroupNoEdit   = 'Эта группа не может быть изменена';
  static String msgAppGroupNoDel    = 'Эта группа не может быть удалена';

  static String txtSelGroupForApp   = 'Выбирите группу для выбранных приложений';

  static String txtIsHiddenGroup      = 'Скрытая группа';
  static String txtNotUseWhileCharging = 'Нельзя использовать во время зарядки';
  static String txtNotDelApp          = 'Нельзя удалять приложения';
  static String txtCheckPointSensitive = 'Блокировать если есть не выполненые задания';
  static String txtLimitPerDayReached = 'Ограничение длительности использования за день достигнуто';
  static String txtRelaxTime          = 'Нужно отдохнуть';
  static String txtMinutes            = 'Минуты';
  static String txtDays               = 'Дней';
  static String txtIsUnlimitedGroup   = 'группа без ограничений';
  static String txtGroupIsMarkedAsUnavailable = 'группа помечена как недоступная';
  static String txtNotAvailableByTimetable = 'Не доступно по расписанию';
  static String txtIsAvailable = 'Доступно';
  static String txtNegativeBalance = 'Отрицательный баланс';
  static String txtDeviceType  = 'Тип устройства';
  static String txtPhone  = 'Телефон';
  static String txtTablet = 'Планшет';
  static String txtTV     = 'Телевизор';

  static String txtCheckPoint                        = 'Задание';
  static String txtCheckPointTuning                  = 'Настройка задания';
  static String txtCheckPointView                    = 'Просмотр задания';
  static String txtCheckPointList                    = 'Список заданий';
  static String txtCheckPointStatusNewTask           = 'Новое задание';
  static String txtCheckPointStatusComplete          = 'Выполнено';
  static String txtCheckPointStatusNotComplete       = 'Не выполнено';
  static String txtCheckPointStatusPartiallyComplete = 'частично выполнено';
  static String txtCheckPointStatusExpectation       = 'Ожидание выполнения';
  static String txtCheckPointStatusCanceled          = 'Отменено';

  static String txtCheckPointResultTypeText              = 'Описано в тексте';
  static String txtCheckPointResultTypeAppGroupUsageTime = 'Доп. время к использованию группы';
  static String txtCheckPointResultTypeBalance           = 'Минуты к балансу';

  static String txtCheckPointTaskText                 = 'Текст задания';
  static String txtCheckPointCompletionComment        = 'Комментарий к статусу';

  static String txtCpOnce                             = 'Однократно';
  static String txtCpEveryDay                         = 'Каждый день';
  static String txtCpEveryOtherDay                    = 'Через день';
  static String txtCpEveryTwoDays                     = 'Через каждые два деня';
  static String txtCpEveryThreeDays                   = 'Через каждые три деня';

  static String txtStatus                             = 'Статус';
  static String txtPeriodicity                        = 'Переодичность';
  static String txtDate                               = 'Дата';
  static String txtTime                               = 'Время';
  static String txtNoticeBeforeMinutes                = 'Предупредить за';
  static String txtCountDaysToCancel                  = 'Контроль выполнения отменяется через';
  static String txtBonus                              = 'Бонус';
  static String txtPenalty                            = 'Штраф';
  static String txtBonusGroup                         = 'Получающая группа';
  static String txtLockGroups                         = 'Блокировать группы';
  static String txtNewStatus                          = 'Новый статус';
  static String txtCompletionRate                     = 'Степень выполнения';
  static String txtCheckPointWarning                  = 'Скоро наступит контроль выполнения заданий';
  static String txtCheckPointLock                     = 'Есть задания с наступившим временем контроля';
  static String txtTVServiceTitle                     = 'Учебный контроль включен';

  static String txtSkipAppListTuning                  = 'Настройка списка исключенных из контроля приложений';
  static String txtShowAllApp                         = 'Показать все приложения';
  static String txtShowOnlyCandidateApp               = 'Показать только приложения кандидаты';

  static String txtTtAny       = 'Любой';
  static String txtTtMonday    = 'Понедельник';
  static String txtTtTuesday   = 'Вторник';
  static String txtTtWednesday = 'Среда';
  static String txtTtThursday  = 'Четверг';
  static String txtTtFriday    = 'Пятница';
  static String txtTtSaturday  = 'Суббота';
  static String txtTtSunday    = 'Воскресенье';
  static String txtTtMonth01   = '01';
  static String txtTtMonth02   = '02';
  static String txtTtMonth03   = '03';
  static String txtTtMonth04   = '04';
  static String txtTtMonth05   = '05';
  static String txtTtMonth06   = '06';
  static String txtTtMonth07   = '07';
  static String txtTtMonth08   = '08';
  static String txtTtMonth09   = '09';
  static String txtTtMonth10   = '10';
  static String txtTtMonth11   = '11';
  static String txtTtMonth12   = '12';
  static String txtTtMonth13   = '13';
  static String txtTtMonth14   = '14';
  static String txtTtMonth15   = '15';
  static String txtTtMonth16   = '16';
  static String txtTtMonth17   = '17';
  static String txtTtMonth18   = '18';
  static String txtTtMonth19   = '19';
  static String txtTtMonth20   = '20';
  static String txtTtMonth21   = '21';
  static String txtTtMonth22   = '22';
  static String txtTtMonth23   = '23';
  static String txtTtMonth24   = '24';
  static String txtTtMonth25   = '25';
  static String txtTtMonth26   = '26';
  static String txtTtMonth27   = '27';
  static String txtTtMonth28   = '28';
  static String txtTtMonth29   = '29';
  static String txtTtMonth30   = '30';
  static String txtTtMonth31   = '31';
}

final _deviceTypeNameMap = {
  DeviceType.phone  : TextConst.txtPhone,
  DeviceType.tablet : TextConst.txtTablet,
  DeviceType.tv     : TextConst.txtTV,
};

String getDeviceTypeName(DeviceType deviceType) => _deviceTypeNameMap[deviceType]!;

int dateToInt(DateTime date){
  return date.year * 10000 + date.month * 100 + date.day;
}

DateTime intDateTimeToDateTime(int intDate, [int intTime = 0]){
  final year  = intDate ~/ 10000;
  final rest  = intDate  % 10000;
  final month = rest ~/ 100;
  final day   = rest  % 100;

  final hour   = intTime ~/  100;
  final minute = intTime  % 100;

  return DateTime(year, month, day, hour, minute);
}

int timeToInt(DateTime time) {
  return time.hour * 100 + time.minute;
}

int dateTimeToInt(DateTime date){
  return date.year * 100000000 + date.month * 1000000 + date.day * 10000 + date.hour * 100 + date.minute;
}

String dateToStr(DateTime date){
  // конечно нужно использовать intl, но пока так сделаем
  return
    '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
}

String timeToStr(DateTime time){
  // конечно нужно использовать intl, но пока так сделаем
  return
    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}

int stringToIntTime(String timeStr){
  final timeSplit = timeStr.split(":");
  final hour   = int.parse(timeSplit[0]);
  final minute = int.parse(timeSplit[1]);
  return hour * 100 + minute;
}

const ColorFilter greyscaleColorFilter = ColorFilter.matrix(<double>[
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,  0, 0, 0, 1, 0,
]);

final dayNameList = <String>[
  TextConst.txtTtAny      ,
  TextConst.txtTtMonday   ,
  TextConst.txtTtTuesday  ,
  TextConst.txtTtWednesday,
  TextConst.txtTtThursday ,
  TextConst.txtTtFriday   ,
  TextConst.txtTtSaturday ,
  TextConst.txtTtSunday   ,
  TextConst.txtTtMonth01  ,
  TextConst.txtTtMonth02  ,
  TextConst.txtTtMonth03  ,
  TextConst.txtTtMonth04  ,
  TextConst.txtTtMonth05  ,
  TextConst.txtTtMonth06  ,
  TextConst.txtTtMonth07  ,
  TextConst.txtTtMonth08  ,
  TextConst.txtTtMonth09  ,
  TextConst.txtTtMonth10  ,
  TextConst.txtTtMonth11  ,
  TextConst.txtTtMonth12  ,
  TextConst.txtTtMonth13  ,
  TextConst.txtTtMonth14  ,
  TextConst.txtTtMonth15  ,
  TextConst.txtTtMonth16  ,
  TextConst.txtTtMonth17  ,
  TextConst.txtTtMonth18  ,
  TextConst.txtTtMonth19  ,
  TextConst.txtTtMonth20  ,
  TextConst.txtTtMonth21  ,
  TextConst.txtTtMonth22  ,
  TextConst.txtTtMonth23  ,
  TextConst.txtTtMonth24  ,
  TextConst.txtTtMonth25  ,
  TextConst.txtTtMonth26  ,
  TextConst.txtTtMonth27  ,
  TextConst.txtTtMonth28  ,
  TextConst.txtTtMonth29  ,
  TextConst.txtTtMonth30  ,
  TextConst.txtTtMonth31  ,
];
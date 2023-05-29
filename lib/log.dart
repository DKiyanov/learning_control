class Log{
  final _logList = <String>[];
  Iterable<String> get logList => _logList;

  bool extLogging = false;

  void add(String logStr, [bool extLog = false]){
    if (extLog && !extLogging) return;

    print(logStr);
    _logList.add('${DateTime.now()} $logStr');
  }
}


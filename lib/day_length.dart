import 'dart:convert';

class DayLength{
  int  day;
  int  duration;

  DayLength({required this.day, required this.duration });

  factory DayLength.fromJson(Map<String, dynamic> json){
    return DayLength(
      day      : json['day'],
      duration : json['duration'],
    );
  }

  Map<String, dynamic> toJson(){
    return {
      'day'      : day,
      'duration' : duration,
    };
  }
}

List<DayLength> jsonStrToDayLengthList(String jsonStr) {
  final jsonList = json.decode(jsonStr);
  final List<DayLength> dayLengthList = (jsonList as List).map((jsonRow) => DayLength.fromJson(jsonRow)).toList();
  return dayLengthList;
}

String dayLengthListToJsonStr(List<DayLength> dayLengthList){
  final jsonMap = dayLengthList.map((item) => item.toJson()).toList();
  return json.encode(jsonMap);
}


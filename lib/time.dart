import 'dart:convert';

import 'package:flutter/material.dart';

class Time{
  final int hour;
  final int minute;
  int get intTime => hour * 100 + minute;

  Time({required this.hour, required this.minute});

  factory Time.fromString(String timeStr){
    final timeSplit = timeStr.split(":");
    return Time(
        hour   : int.parse(timeSplit[0]),
        minute : int.parse(timeSplit[1])
    );
  }

  factory Time.fromTimeOfDay(TimeOfDay timeOfDay){
    return Time( hour : timeOfDay.hour, minute: timeOfDay.minute);
  }

  @override
  String toString(){
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  TimeOfDay getTimeOfDay(){
    return TimeOfDay(hour: hour, minute : minute);
  }

  int compareTo(Time other){
    return intTime.compareTo(other.intTime);
  }
}

class TimeRange{
  int  day;
  Time from;
  Time to;

  TimeRange({required this.day, required this.from, required this.to});

  factory TimeRange.fromJson(Map<String, dynamic> json){
    return TimeRange(
        day      : json['day'],
        from     : Time.fromString(json['from']),
        to       : Time.fromString(json['to']),
    );
  }

  Map<String, dynamic> toJson(){
    return {
      'day'      : day,
      'from'     : from.toString(),
      'to'       : to.toString(),
    };
  }
}

List<TimeRange> jsonStrToTimeRangeList(String jsonStr) {
  final jsonList = json.decode(jsonStr);
  final List<TimeRange> timeRangeList = (jsonList as List).map((jsonRow) => TimeRange.fromJson(jsonRow)).toList();
  return timeRangeList;
}

String timeRangeListToJsonStr(List<TimeRange> timeRangeList){
  final jsonMap = timeRangeList.map((item) => item.toJson()).toList();
  return json.encode(jsonMap);
}


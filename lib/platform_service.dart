import 'dart:async';
import 'package:flutter/services.dart';

class PlatformService{
  static const platform = MethodChannel('com.dkiyanov.learning_control');

  static Future<bool> setSkipAppList(List<String> skipAppList) async {
    try {
      final arguments = <String, dynamic>{
        'skipAppList' : skipAppList,
      };

      final bool result = await platform.invokeMethod('setSkipAppList', arguments);
      return result;
    } on PlatformException {
      return false;
    }
  }

  static Future<String> getTopActivityName() async {
    try {
      final String result = await platform.invokeMethod('getTopActivityName');
      // print('TopActivityName: $result');
      return result;
    } on PlatformException {
      return '';
    }
  }

  static Future<bool> isUsageAccessExists() async {
    try {
      final bool result = await platform.invokeMethod('isUsageAccessExists');
      return result;
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> showUsageAccessSettings() async {
    try {
      final bool result = await platform.invokeMethod('showUsageAccessSettings');
      return result;
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> isCanDrawOverlays() async {
    try {
      final bool result = await platform.invokeMethod('isCanDrawOverlays');
      return result;
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> showDrawOverlaysSettings() async {
    try {
      final bool result = await platform.invokeMethod('showDrawOverlaysSettings');
      return result;
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> isIgnoringBatteryOptimizations() async {
    try {
      final bool result = await platform.invokeMethod('isIgnoringBatteryOptimizations');
      return result;
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> showBatteryOptimizationsSettings() async {
    try {
      final bool result = await platform.invokeMethod('showBatteryOptimizationsSettings');
      return result;
    } on PlatformException {
      return false;
    }
  }

  static Future<String> getPackageName() async {
    try {
      final String result = await platform.invokeMethod('getPackageName');
      return result;
    } on PlatformException {
      return "";
    }
  }

  static Future<String> getLaunchers() async {
    try {
      final String result = await platform.invokeMethod('getLaunchers');
      return result;
    } on PlatformException {
      return "";
    }
  }

  static Future<bool> isMyLauncherDefault() async {
    try {
      final bool result = await platform.invokeMethod('isMyLauncherDefault');
      return result;
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> showLauncherSettings() async {
    try {
      final bool result = await platform.invokeMethod('showLauncherSettings');
      return result;
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> backToHome() async {
    try {
      final bool result = await platform.invokeMethod('backToHome');
      return result;
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> foregroundService(String title, String text) async {
    try {
      final arguments = <String, dynamic>{
        'title' : title,
        'text' : text
      };

      final bool result = await platform.invokeMethod('foregroundServiceStart', arguments);
      return result;
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> foregroundServiceStop() async {
    try {
      final bool result = await platform.invokeMethod('foregroundServiceStop');
      return result;
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> restartApp() async {
    try {
      final bool result = await platform.invokeMethod('restartApp');
      return result;
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> appIsVisible() async {
    try {
      final bool result = await platform.invokeMethod('appIsVisible');
      return result;
    } on PlatformException {
      return false;
    }
  }

  static Future<String> getDeviceID() async {
    try {
      final String result = await platform.invokeMethod('getDeviceID');
      return result;
    } on PlatformException {
      return '';
    }
  }
}
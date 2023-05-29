import 'package:learning_control/parse/parse_app/parse_app_group.dart';
import '../../app_state.dart';

enum AppAccess {
  allowed,
  disabled,
  hidden,
}

class AppAccessInfo{
  final AppAccess appAccess;
  final String message;
  final AppGroup appGroup;
  AppAccessInfo(this.appAccess, this.message, this.appGroup);
}

/// Возвращает возможность работы с приложением
AppAccessInfo getAppAccess(String packageName) {
  final appGroup = appState.appSettingsManager.getAppGroup(packageName);
  return appGroup.accessInfo;
}
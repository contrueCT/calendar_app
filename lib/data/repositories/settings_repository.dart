import '../datasources/local/shared_prefs_helper.dart';

/// 设置仓库
class SettingsRepository {
  final SharedPrefsHelper _prefsHelper;

  SettingsRepository({SharedPrefsHelper? prefsHelper})
    : _prefsHelper = prefsHelper ?? SharedPrefsHelper();

  /// 是否显示农历
  bool get showLunarDate => _prefsHelper.showLunarDate;
  Future<void> setShowLunarDate(bool value) async {
    _prefsHelper.showLunarDate = value;
  }

  /// 一周的第一天 (1=周一, 7=周日)
  int get firstDayOfWeek => _prefsHelper.firstDayOfWeek;
  Future<void> setFirstDayOfWeek(int value) async {
    _prefsHelper.firstDayOfWeek = value;
  }

  /// 默认视图 ('month', 'week', 'day')
  String get defaultView => _prefsHelper.defaultView;
  Future<void> setDefaultView(String value) async {
    _prefsHelper.defaultView = value;
  }

  /// 默认提醒时间（分钟）
  int get defaultReminderMinutes => _prefsHelper.defaultReminderMinutes;
  Future<void> setDefaultReminderMinutes(int value) async {
    _prefsHelper.defaultReminderMinutes = value;
  }

  /// 是否启用通知
  bool get notificationEnabled => _prefsHelper.notificationEnabled;
  Future<void> setNotificationEnabled(bool value) async {
    _prefsHelper.notificationEnabled = value;
  }

  /// 主题模式 ('system', 'light', 'dark')
  String get themeMode => _prefsHelper.themeMode;
  Future<void> setThemeMode(String value) async {
    _prefsHelper.themeMode = value;
  }
}

import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences 助手类
class SharedPrefsHelper {
  static SharedPrefsHelper? _instance;
  static SharedPreferences? _prefs;

  SharedPrefsHelper._internal();

  factory SharedPrefsHelper() {
    _instance ??= SharedPrefsHelper._internal();
    return _instance!;
  }

  /// 初始化
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// 获取SharedPreferences实例
  SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('SharedPrefsHelper not initialized. Call init() first.');
    }
    return _prefs!;
  }

  // ==================== 键名常量 ====================

  static const String keyLastSyncTime = 'last_sync_time';
  static const String keyDefaultCalendarId = 'default_calendar_id';
  static const String keyShowLunarDate = 'show_lunar_date';
  static const String keyFirstDayOfWeek = 'first_day_of_week';
  static const String keyDefaultView = 'default_view';
  static const String keyDefaultReminderMinutes = 'default_reminder_minutes';
  static const String keyNotificationEnabled = 'notification_enabled';
  static const String keyThemeMode = 'theme_mode';

  // ==================== 通用方法 ====================

  /// 获取字符串
  String? getString(String key) => prefs.getString(key);

  /// 设置字符串
  Future<bool> setString(String key, String value) =>
      prefs.setString(key, value);

  /// 获取整数
  int? getInt(String key) => prefs.getInt(key);

  /// 设置整数
  Future<bool> setInt(String key, int value) => prefs.setInt(key, value);

  /// 获取布尔值
  bool? getBool(String key) => prefs.getBool(key);

  /// 设置布尔值
  Future<bool> setBool(String key, bool value) => prefs.setBool(key, value);

  /// 获取双精度浮点数
  double? getDouble(String key) => prefs.getDouble(key);

  /// 设置双精度浮点数
  Future<bool> setDouble(String key, double value) =>
      prefs.setDouble(key, value);

  /// 获取字符串列表
  List<String>? getStringList(String key) => prefs.getStringList(key);

  /// 设置字符串列表
  Future<bool> setStringList(String key, List<String> value) =>
      prefs.setStringList(key, value);

  /// 移除键
  Future<bool> remove(String key) => prefs.remove(key);

  /// 清除所有数据
  Future<bool> clear() => prefs.clear();

  // ==================== 业务方法 ====================

  /// 是否显示农历
  bool get showLunarDate => getBool(keyShowLunarDate) ?? true;
  set showLunarDate(bool value) => setBool(keyShowLunarDate, value);

  /// 一周的第一天 (1=周一, 7=周日)
  int get firstDayOfWeek => getInt(keyFirstDayOfWeek) ?? 1;
  set firstDayOfWeek(int value) => setInt(keyFirstDayOfWeek, value);

  /// 默认视图 ('month', 'week', 'day')
  String get defaultView => getString(keyDefaultView) ?? 'month';
  set defaultView(String value) => setString(keyDefaultView, value);

  /// 默认提醒时间（分钟）
  int get defaultReminderMinutes => getInt(keyDefaultReminderMinutes) ?? 15;
  set defaultReminderMinutes(int value) =>
      setInt(keyDefaultReminderMinutes, value);

  /// 是否启用通知
  bool get notificationEnabled => getBool(keyNotificationEnabled) ?? true;
  set notificationEnabled(bool value) => setBool(keyNotificationEnabled, value);

  /// 主题模式 ('system', 'light', 'dark')
  String get themeMode => getString(keyThemeMode) ?? 'system';
  set themeMode(String value) => setString(keyThemeMode, value);
}

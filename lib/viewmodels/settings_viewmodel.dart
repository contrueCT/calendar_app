import 'package:flutter/material.dart';
import '../data/repositories/settings_repository.dart';
import '../data/datasources/local/shared_prefs_helper.dart';

/// 设置视图模型
class SettingsViewModel extends ChangeNotifier {
  final SettingsRepository _settingsRepository;
  bool _isInitialized = false;

  // 缓存设置值
  bool _showLunarDate = true;
  int _firstDayOfWeek = 1;
  String _defaultView = 'month';
  int _defaultReminderMinutes = 15;
  bool _notificationEnabled = true;
  String _themeMode = 'system';

  SettingsViewModel({SettingsRepository? settingsRepository})
    : _settingsRepository = settingsRepository ?? SettingsRepository();

  // Getters
  bool get isInitialized => _isInitialized;
  bool get showLunarDate => _showLunarDate;
  int get firstDayOfWeek => _firstDayOfWeek;
  String get defaultView => _defaultView;
  int get defaultReminderMinutes => _defaultReminderMinutes;
  bool get notificationEnabled => _notificationEnabled;
  String get themeMode => _themeMode;

  /// 初始化
  Future<void> initialize() async {
    if (_isInitialized) return;

    // 确保SharedPreferences已初始化
    await SharedPrefsHelper().init();

    // 加载设置
    _showLunarDate = _settingsRepository.showLunarDate;
    _firstDayOfWeek = _settingsRepository.firstDayOfWeek;
    _defaultView = _settingsRepository.defaultView;
    _defaultReminderMinutes = _settingsRepository.defaultReminderMinutes;
    _notificationEnabled = _settingsRepository.notificationEnabled;
    _themeMode = _settingsRepository.themeMode;

    _isInitialized = true;
    notifyListeners();
  }

  /// 设置是否显示农历
  Future<void> setShowLunarDate(bool value) async {
    if (_showLunarDate != value) {
      _showLunarDate = value;
      await _settingsRepository.setShowLunarDate(value);
      notifyListeners();
    }
  }

  /// 设置一周的第一天
  Future<void> setFirstDayOfWeek(int value) async {
    if (_firstDayOfWeek != value) {
      _firstDayOfWeek = value;
      await _settingsRepository.setFirstDayOfWeek(value);
      notifyListeners();
    }
  }

  /// 设置默认视图
  Future<void> setDefaultView(String value) async {
    if (_defaultView != value) {
      _defaultView = value;
      await _settingsRepository.setDefaultView(value);
      notifyListeners();
    }
  }

  /// 设置默认提醒时间
  Future<void> setDefaultReminderMinutes(int value) async {
    if (_defaultReminderMinutes != value) {
      _defaultReminderMinutes = value;
      await _settingsRepository.setDefaultReminderMinutes(value);
      notifyListeners();
    }
  }

  /// 设置是否启用通知
  Future<void> setNotificationEnabled(bool value) async {
    if (_notificationEnabled != value) {
      _notificationEnabled = value;
      await _settingsRepository.setNotificationEnabled(value);
      notifyListeners();
    }
  }

  /// 设置主题模式
  Future<void> setThemeMode(String value) async {
    if (_themeMode != value) {
      _themeMode = value;
      await _settingsRepository.setThemeMode(value);
      notifyListeners();
    }
  }

  /// 获取一周第一天的显示名称
  String get firstDayOfWeekName {
    switch (_firstDayOfWeek) {
      case 1:
        return '周一';
      case 6:
        return '周六';
      case 7:
        return '周日';
      default:
        return '周一';
    }
  }

  /// 获取默认视图的显示名称
  String get defaultViewName {
    switch (_defaultView) {
      case 'month':
        return '月视图';
      case 'week':
        return '周视图';
      case 'day':
        return '日视图';
      default:
        return '月视图';
    }
  }

  /// 获取默认提醒时间的显示名称
  String get defaultReminderName {
    if (_defaultReminderMinutes == 0) return '事件发生时';
    if (_defaultReminderMinutes < 60) return '提前$_defaultReminderMinutes分钟';
    if (_defaultReminderMinutes < 1440) {
      final hours = _defaultReminderMinutes ~/ 60;
      return '提前$hours小时';
    }
    final days = _defaultReminderMinutes ~/ 1440;
    return '提前$days天';
  }

  /// 获取主题模式的显示名称
  String get themeModeName {
    switch (_themeMode) {
      case 'light':
        return '浅色';
      case 'dark':
        return '深色';
      default:
        return '跟随系统';
    }
  }
}

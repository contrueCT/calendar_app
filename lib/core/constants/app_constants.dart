/// 应用常量定义
class AppConstants {
  AppConstants._();

  /// 应用名称
  static const String appName = 'Flutter日历';

  /// 数据库名称
  static const String dbName = 'calendar.db';

  /// 数据库版本
  static const int dbVersion = 1;

  /// 重复事件缓存天数
  static const int cacheDays = 90;

  /// 默认提醒选项（分钟）
  static const List<int> defaultReminderOptions = [
    0, // 事件发生时
    5, // 提前5分钟
    15, // 提前15分钟
    30, // 提前30分钟
    60, // 提前1小时
    1440, // 提前1天
  ];

  /// 通知渠道ID
  static const String notificationChannelId = 'calendar_reminders';

  /// 通知渠道名称
  static const String notificationChannelName = '日程提醒';

  /// 通知渠道描述
  static const String notificationChannelDescription = '日历事件提醒通知';
}

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../../data/models/event_model.dart';
import '../../data/models/reminder_model.dart';
import '../constants/app_constants.dart';

/// 通知服务
class NotificationService {
  static NotificationService? _instance;
  final FlutterLocalNotificationsPlugin _notificationsPlugin;
  bool _isInitialized = false;

  NotificationService._internal()
    : _notificationsPlugin = FlutterLocalNotificationsPlugin();

  factory NotificationService() {
    _instance ??= NotificationService._internal();
    return _instance!;
  }

  FlutterLocalNotificationsPlugin get plugin => _notificationsPlugin;

  /// 初始化通知服务
  Future<void> initialize() async {
    if (_isInitialized) return;

    // 初始化时区
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));

    // Android初始化设置
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // 初始化设置
    const initSettings = InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
  }

  /// 通知点击回调
  void _onNotificationTapped(NotificationResponse response) {
    // 处理通知点击事件
    // 可以通过payload获取事件ID，跳转到事件详情
    final payload = response.payload;
    if (payload != null) {
      // TODO: 实现跳转到事件详情
    }
  }

  /// 请求通知权限
  Future<bool> requestPermission() async {
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      return granted ?? false;
    }
    return false;
  }

  /// 检查通知权限
  Future<bool> checkPermission() async {
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      final granted = await androidPlugin.areNotificationsEnabled();
      return granted ?? false;
    }
    return false;
  }

  /// 调度事件提醒
  Future<void> scheduleReminder(
    EventModel event,
    ReminderModel reminder,
  ) async {
    final scheduledTime = event.dtStart.subtract(
      Duration(minutes: reminder.triggerMinutes),
    );

    // 如果提醒时间已过，不调度
    if (scheduledTime.isBefore(DateTime.now())) {
      return;
    }

    final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

    await _notificationsPlugin.zonedSchedule(
      reminder.notificationId,
      event.summary,
      _buildNotificationBody(event, reminder),
      tzScheduledTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.notificationChannelId,
          AppConstants.notificationChannelName,
          channelDescription: AppConstants.notificationChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
          ticker: event.summary,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: event.uid,
    );
  }

  /// 构建通知正文
  String _buildNotificationBody(EventModel event, ReminderModel reminder) {
    final buffer = StringBuffer();

    if (reminder.triggerMinutes == 0) {
      buffer.write('现在开始');
    } else {
      buffer.write(reminder.triggerDescription);
    }

    if (event.location != null && event.location!.isNotEmpty) {
      buffer.write(' · ${event.location}');
    }

    return buffer.toString();
  }

  /// 取消提醒
  Future<void> cancelReminder(int notificationId) async {
    await _notificationsPlugin.cancel(notificationId);
  }

  /// 取消事件的所有提醒
  Future<void> cancelEventReminders(List<ReminderModel> reminders) async {
    for (final reminder in reminders) {
      await cancelReminder(reminder.notificationId);
    }
  }

  /// 取消所有提醒
  Future<void> cancelAllReminders() async {
    await _notificationsPlugin.cancelAll();
  }

  /// 重新调度事件的所有提醒
  Future<void> rescheduleEventReminders(EventModel event) async {
    // 先取消旧提醒
    await cancelEventReminders(event.reminders);

    // 重新调度
    for (final reminder in event.reminders) {
      await scheduleReminder(event, reminder);
    }
  }

  /// 显示即时通知（用于测试）
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _notificationsPlugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.notificationChannelId,
          AppConstants.notificationChannelName,
          channelDescription: AppConstants.notificationChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: payload,
    );
  }
}

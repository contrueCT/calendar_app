import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../../data/models/event_model.dart';
import '../../data/models/reminder_model.dart';
import '../constants/app_constants.dart';

/// 通知点击回调类型
typedef NotificationTapCallback = void Function(String? eventUid);

/// 通知服务
class NotificationService {
  static NotificationService? _instance;
  final FlutterLocalNotificationsPlugin _notificationsPlugin;
  bool _isInitialized = false;
  bool _permissionGranted = false;

  /// 通知点击回调
  NotificationTapCallback? onNotificationTap;

  /// 全局导航键，用于通知点击时导航
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  NotificationService._internal()
    : _notificationsPlugin = FlutterLocalNotificationsPlugin();

  factory NotificationService() {
    _instance ??= NotificationService._internal();
    return _instance!;
  }

  FlutterLocalNotificationsPlugin get plugin => _notificationsPlugin;
  bool get isInitialized => _isInitialized;
  bool get permissionGranted => _permissionGranted;

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
      onDidReceiveBackgroundNotificationResponse:
          _onBackgroundNotificationTapped,
    );

    // 检查权限状态
    _permissionGranted = await checkPermission();

    // 检查应用是否通过通知启动
    await _checkAppLaunchDetails();

    _isInitialized = true;
  }

  /// 检查应用是否通过通知启动
  Future<void> _checkAppLaunchDetails() async {
    final launchDetails = await _notificationsPlugin
        .getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      final payload = launchDetails!.notificationResponse?.payload;
      if (payload != null) {
        // 延迟处理，等待应用完全初始化
        Future.delayed(const Duration(milliseconds: 500), () {
          onNotificationTap?.call(payload);
        });
      }
    }
  }

  /// 通知点击回调（前台）
  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    onNotificationTap?.call(payload);
  }

  /// 后台通知点击回调（静态方法）
  @pragma('vm:entry-point')
  static void _onBackgroundNotificationTapped(NotificationResponse response) {
    // 后台点击时，payload会在应用启动后通过getNotificationAppLaunchDetails获取
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

  /// 为重复事件调度提醒
  /// 为未来90天内的所有实例创建提醒
  Future<void> scheduleRecurringEventReminders(EventModel event) async {
    if (!event.isRecurring || event.recurrenceRule == null) {
      // 非重复事件，使用普通调度
      await rescheduleEventReminders(event);
      return;
    }

    // 先取消旧提醒
    await cancelEventReminders(event.reminders);

    // 获取未来90天内的所有实例
    final now = DateTime.now();
    final rangeEnd = now.add(const Duration(days: AppConstants.cacheDays));

    final occurrences = event.recurrenceRule!.getOccurrences(
      event.dtStart,
      now,
      rangeEnd,
      excludeDates: event.exDates,
    );

    // 为每个实例的每个提醒创建通知
    int notificationIndex = 0;
    for (final occurrence in occurrences) {
      for (final reminder in event.reminders) {
        final scheduledTime = occurrence.subtract(
          Duration(minutes: reminder.triggerMinutes),
        );

        // 如果提醒时间已过，跳过
        if (scheduledTime.isBefore(now)) continue;

        // 为每个实例生成唯一的通知ID
        final instanceNotificationId =
            (reminder.notificationId + notificationIndex) % 0x7FFFFFFF;

        await _scheduleNotification(
          notificationId: instanceNotificationId,
          title: event.summary,
          body: _buildRecurringNotificationBody(event, reminder, occurrence),
          scheduledTime: scheduledTime,
          payload: '${event.uid}|${occurrence.millisecondsSinceEpoch}',
        );

        notificationIndex++;
      }
    }
  }

  /// 构建重复事件通知正文
  String _buildRecurringNotificationBody(
    EventModel event,
    ReminderModel reminder,
    DateTime occurrence,
  ) {
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

  /// 内部调度通知方法
  Future<void> _scheduleNotification({
    required int notificationId,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

    await _notificationsPlugin.zonedSchedule(
      notificationId,
      title,
      body,
      tzScheduledTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.notificationChannelId,
          AppConstants.notificationChannelName,
          channelDescription: AppConstants.notificationChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
          ticker: title,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  /// 获取所有待处理的通知
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notificationsPlugin.pendingNotificationRequests();
  }

  /// 获取待处理通知数量
  Future<int> getPendingNotificationCount() async {
    final pending = await getPendingNotifications();
    return pending.length;
  }

  /// 请求精确闹钟权限（Android 12+）
  Future<bool> requestExactAlarmPermission() async {
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      return await androidPlugin.requestExactAlarmsPermission() ?? false;
    }
    return false;
  }

  /// 检查精确闹钟权限
  Future<bool> checkExactAlarmPermission() async {
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      return await androidPlugin.canScheduleExactNotifications() ?? false;
    }
    return false;
  }
}

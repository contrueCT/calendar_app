import 'dart:math';
import '../../data/models/event_model.dart';
import '../../data/models/reminder_model.dart';
import '../../data/repositories/event_repository.dart';
import 'notification_service.dart';

/// 提醒管理器
/// 负责协调事件和通知之间的关系
class ReminderManager {
  static ReminderManager? _instance;
  final NotificationService _notificationService;
  final EventRepository _eventRepository;

  ReminderManager._internal({
    NotificationService? notificationService,
    EventRepository? eventRepository,
  }) : _notificationService = notificationService ?? NotificationService(),
       _eventRepository = eventRepository ?? EventRepository();

  factory ReminderManager({
    NotificationService? notificationService,
    EventRepository? eventRepository,
  }) {
    _instance ??= ReminderManager._internal(
      notificationService: notificationService,
      eventRepository: eventRepository,
    );
    return _instance!;
  }

  /// 为事件调度提醒
  Future<void> scheduleRemindersForEvent(EventModel event) async {
    // 检查通知权限
    final hasPermission = await _notificationService.checkPermission();
    if (!hasPermission) {
      // 尝试请求权限
      final granted = await _notificationService.requestPermission();
      if (!granted) {
        return; // 无权限，不调度
      }
    }

    if (event.reminders.isEmpty) {
      return;
    }

    if (event.isRecurring) {
      // 重复事件
      await _notificationService.scheduleRecurringEventReminders(event);
    } else {
      // 普通事件
      await _notificationService.rescheduleEventReminders(event);
    }
  }

  /// 取消事件的所有提醒
  Future<void> cancelRemindersForEvent(EventModel event) async {
    await _notificationService.cancelEventReminders(event.reminders);
  }

  /// 更新事件提醒（先取消再重新调度）
  Future<void> updateRemindersForEvent(EventModel event) async {
    await cancelRemindersForEvent(event);
    await scheduleRemindersForEvent(event);
  }

  /// 重新调度所有事件的提醒
  /// 通常在应用启动或设备重启后调用
  Future<void> rescheduleAllReminders() async {
    // 检查权限
    final hasPermission = await _notificationService.checkPermission();
    if (!hasPermission) {
      return;
    }

    // 取消所有现有提醒
    await _notificationService.cancelAllReminders();

    // 获取所有有提醒的事件
    final allEvents = await _eventRepository.getAllEvents();
    final eventsWithReminders = allEvents
        .where((e) => e.reminders.isNotEmpty)
        .toList();

    // 重新调度
    for (final event in eventsWithReminders) {
      await scheduleRemindersForEvent(event);
    }
  }

  /// 获取待处理提醒数量
  Future<int> getPendingReminderCount() async {
    return await _notificationService.getPendingNotificationCount();
  }

  /// 创建新提醒
  /// 返回带有唯一通知ID的ReminderModel
  static ReminderModel createReminder({
    required String eventUid,
    required int triggerMinutes,
    ReminderType type = ReminderType.notification,
  }) {
    // 生成唯一的通知ID（基于时间戳和随机数，避免高并发冲突）
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomPart = random.nextInt(0xFFFF);
    final notificationId = ((timestamp << 16) | randomPart) % 0x7FFFFFFF;

    return ReminderModel(
      eventUid: eventUid,
      type: type,
      triggerMinutes: triggerMinutes,
      notificationId: notificationId.abs(),
    );
  }

  /// 获取默认提醒选项列表
  static List<ReminderOption> get defaultReminderOptions => const [
    ReminderOption(minutes: 0, label: '事件发生时'),
    ReminderOption(minutes: 5, label: '提前5分钟'),
    ReminderOption(minutes: 10, label: '提前10分钟'),
    ReminderOption(minutes: 15, label: '提前15分钟'),
    ReminderOption(minutes: 30, label: '提前30分钟'),
    ReminderOption(minutes: 60, label: '提前1小时'),
    ReminderOption(minutes: 120, label: '提前2小时'),
    ReminderOption(minutes: 1440, label: '提前1天'),
    ReminderOption(minutes: 2880, label: '提前2天'),
    ReminderOption(minutes: 10080, label: '提前1周'),
  ];
}

/// 提醒选项
class ReminderOption {
  final int minutes;
  final String label;

  const ReminderOption({required this.minutes, required this.label});
}

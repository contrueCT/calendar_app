import 'package:flutter_test/flutter_test.dart';
import 'package:calendar_app/data/repositories/calendar_repository.dart';
import 'package:calendar_app/data/repositories/event_repository.dart';
import 'package:calendar_app/data/models/calendar_model.dart';
import 'package:calendar_app/data/models/event_model.dart';
import 'package:calendar_app/data/models/reminder_model.dart';

void main() {
  group('CalendarRepository 集成测试', () {
    test('CalendarModel 应正确创建和转换', () {
      final now = DateTime.now();
      final calendar = CalendarModel(
        id: 'test-calendar-1',
        name: '测试日历',
        color: 0xFF2196F3,
        isVisible: true,
        isDefault: false,
        isSubscription: false,
        syncInterval: SyncInterval.manual,
        createdAt: now,
      );

      expect(calendar.id, 'test-calendar-1');
      expect(calendar.name, '测试日历');
      expect(calendar.color, 0xFF2196F3);
      expect(calendar.isVisible, true);
      expect(calendar.isDefault, false);
      expect(calendar.isSubscription, false);

      // 测试 toMap 和 fromMap
      final map = calendar.toMap();
      final recreated = CalendarModel.fromMap(map);

      expect(recreated.id, calendar.id);
      expect(recreated.name, calendar.name);
      expect(recreated.color, calendar.color);
    });

    test('CalendarModel copyWith 应正确工作', () {
      final now = DateTime.now();
      final calendar = CalendarModel(
        id: 'test-calendar-1',
        name: '原始名称',
        color: 0xFF2196F3,
        createdAt: now,
      );

      final updated = calendar.copyWith(name: '新名称', color: 0xFF4CAF50);

      expect(updated.name, '新名称');
      expect(updated.color, 0xFF4CAF50);
      expect(updated.id, calendar.id); // 未修改的字段应保持不变
    });

    test('订阅日历应包含订阅URL', () {
      final calendar = CalendarModel(
        id: 'subscription-1',
        name: '订阅日历',
        isSubscription: true,
        subscriptionUrl: 'https://example.com/calendar.ics',
        syncInterval: SyncInterval.daily,
        createdAt: DateTime.now(),
      );

      expect(calendar.isSubscription, true);
      expect(calendar.subscriptionUrl, isNotNull);
      expect(calendar.syncInterval, SyncInterval.daily);
    });
  });

  group('EventRepository 集成测试', () {
    test('EventModel 应正确创建和转换', () {
      final now = DateTime.now();
      final event = EventModel(
        uid: 'test-event-1',
        calendarId: 'calendar-1',
        summary: '测试事件',
        description: '这是一个测试事件',
        location: '会议室A',
        dtStart: now,
        dtEnd: now.add(const Duration(hours: 1)),
        isAllDay: false,
        status: EventStatus.confirmed,
        priority: 5,
        reminders: [],
        createdAt: now,
        updatedAt: now,
      );

      expect(event.uid, 'test-event-1');
      expect(event.summary, '测试事件');
      expect(event.isAllDay, false);
      expect(event.status, EventStatus.confirmed);

      // 测试 toMap 和 fromMap
      final map = event.toMap();
      final recreated = EventModel.fromMap(map);

      expect(recreated.uid, event.uid);
      expect(recreated.summary, event.summary);
      expect(recreated.calendarId, event.calendarId);
    });

    test('全天事件应正确处理', () {
      final now = DateTime.now();
      final date = DateTime(now.year, now.month, now.day);

      final event = EventModel(
        uid: 'all-day-event',
        calendarId: 'calendar-1',
        summary: '全天事件',
        dtStart: date,
        isAllDay: true,
        reminders: [],
        createdAt: now,
        updatedAt: now,
      );

      expect(event.isAllDay, true);
      expect(event.duration, const Duration(days: 1));
    });

    test('重复事件应有有效的rrule', () {
      final now = DateTime.now();
      final event = EventModel(
        uid: 'recurring-event',
        calendarId: 'calendar-1',
        summary: '每周会议',
        dtStart: now,
        dtEnd: now.add(const Duration(hours: 1)),
        rrule: 'FREQ=WEEKLY;BYDAY=MO,WE,FR',
        reminders: [],
        createdAt: now,
        updatedAt: now,
      );

      expect(event.isRecurring, true);
      expect(event.recurrenceRule, isNotNull);
    });

    test('EventModel copyWith 应正确工作', () {
      final now = DateTime.now();
      final event = EventModel(
        uid: 'test-event',
        calendarId: 'calendar-1',
        summary: '原始标题',
        dtStart: now,
        reminders: [],
        createdAt: now,
        updatedAt: now,
      );

      final updated = event.copyWith(summary: '新标题', location: '新地点');

      expect(updated.summary, '新标题');
      expect(updated.location, '新地点');
      expect(updated.uid, event.uid);
      expect(updated.calendarId, event.calendarId);
    });
  });

  group('ReminderModel 集成测试', () {
    test('ReminderModel 应正确创建', () {
      final reminder = ReminderModel(
        eventUid: 'event-1',
        type: ReminderType.notification,
        triggerMinutes: 15,
        notificationId: 12345,
      );

      expect(reminder.eventUid, 'event-1');
      expect(reminder.type, ReminderType.notification);
      expect(reminder.triggerMinutes, 15);
    });

    test('提醒描述应正确生成', () {
      final reminder0 = ReminderModel(
        eventUid: 'event-1',
        triggerMinutes: 0,
        notificationId: 1,
      );
      expect(reminder0.triggerDescription, '事件发生时');

      final reminder15 = ReminderModel(
        eventUid: 'event-1',
        triggerMinutes: 15,
        notificationId: 2,
      );
      expect(reminder15.triggerDescription, '提前15分钟');

      final reminder60 = ReminderModel(
        eventUid: 'event-1',
        triggerMinutes: 60,
        notificationId: 3,
      );
      expect(reminder60.triggerDescription, '提前1小时');

      final reminder1440 = ReminderModel(
        eventUid: 'event-1',
        triggerMinutes: 1440,
        notificationId: 4,
      );
      expect(reminder1440.triggerDescription, '提前1天');
    });

    test('ReminderModel toMap 和 fromMap 应正确工作', () {
      final reminder = ReminderModel(
        id: 1,
        eventUid: 'event-1',
        type: ReminderType.alarm,
        triggerMinutes: 30,
        notificationId: 12345,
      );

      final map = reminder.toMap();
      final recreated = ReminderModel.fromMap(map);

      expect(recreated.eventUid, reminder.eventUid);
      expect(recreated.type, reminder.type);
      expect(recreated.triggerMinutes, reminder.triggerMinutes);
      expect(recreated.notificationId, reminder.notificationId);
    });
  });

  group('事件时间处理测试', () {
    test('事件时长应正确计算', () {
      final now = DateTime.now();

      // 1小时事件
      final event1h = EventModel(
        uid: 'event-1h',
        calendarId: 'cal-1',
        summary: '1小时事件',
        dtStart: now,
        dtEnd: now.add(const Duration(hours: 1)),
        reminders: [],
        createdAt: now,
        updatedAt: now,
      );
      expect(event1h.duration, const Duration(hours: 1));

      // 全天事件（无结束时间）
      final allDayEvent = EventModel(
        uid: 'all-day',
        calendarId: 'cal-1',
        summary: '全天事件',
        dtStart: now,
        isAllDay: true,
        reminders: [],
        createdAt: now,
        updatedAt: now,
      );
      expect(allDayEvent.duration, const Duration(days: 1));
    });

    test('EventInstance 应正确创建', () {
      final now = DateTime.now();
      final event = EventModel(
        uid: 'event-1',
        calendarId: 'cal-1',
        summary: '测试事件',
        dtStart: now,
        dtEnd: now.add(const Duration(hours: 2)),
        reminders: [],
        createdAt: now,
        updatedAt: now,
      );

      final instance = EventInstance.fromEvent(event);

      expect(instance.event.uid, event.uid);
      expect(instance.instanceStart, event.dtStart);
      expect(instance.instanceEnd, event.dtEnd);
      expect(instance.isException, false);
    });

    test('重复事件实例应正确创建', () {
      final baseDate = DateTime(2025, 1, 1, 10, 0);
      final event = EventModel(
        uid: 'recurring-1',
        calendarId: 'cal-1',
        summary: '重复事件',
        dtStart: baseDate,
        dtEnd: baseDate.add(const Duration(hours: 1)),
        rrule: 'FREQ=DAILY',
        reminders: [],
        createdAt: baseDate,
        updatedAt: baseDate,
      );

      // 创建第5天的实例
      final instanceDate = DateTime(2025, 1, 5, 10, 0);
      final instance = EventInstance.fromRecurringEvent(event, instanceDate);

      // 验证实例属性
      expect(instance.event.rrule, isNotNull);
      expect(instance.instanceStart, instanceDate);
      expect(instance.instanceEnd, instanceDate.add(const Duration(hours: 1)));
    });
  });

  group('SyncInterval 枚举测试', () {
    test('SyncInterval 应正确从字符串解析', () {
      expect(SyncInterval.fromString('manual'), SyncInterval.manual);
      expect(SyncInterval.fromString('hourly'), SyncInterval.hourly);
      expect(SyncInterval.fromString('daily'), SyncInterval.daily);
      expect(SyncInterval.fromString('weekly'), SyncInterval.weekly);
      expect(SyncInterval.fromString('unknown'), SyncInterval.manual); // 默认值
    });

    test('SyncInterval 应有正确的标签', () {
      expect(SyncInterval.manual.label, '手动');
      expect(SyncInterval.hourly.label, '每小时');
      expect(SyncInterval.daily.label, '每天');
      expect(SyncInterval.weekly.label, '每周');
    });
  });

  group('EventStatus 枚举测试', () {
    test('EventStatus 应正确从字符串解析', () {
      expect(EventStatus.fromString('tentative'), EventStatus.tentative);
      expect(EventStatus.fromString('confirmed'), EventStatus.confirmed);
      expect(EventStatus.fromString('cancelled'), EventStatus.cancelled);
      expect(EventStatus.fromString('unknown'), EventStatus.confirmed); // 默认值
    });
  });
}

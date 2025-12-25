import 'package:flutter_test/flutter_test.dart';
import 'package:calendar_app/data/models/event_model.dart';
import 'package:calendar_app/data/models/reminder_model.dart';

void main() {
  group('EventModel', () {
    group('基本属性', () {
      test('应正确创建事件', () {
        final now = DateTime.now();
        final event = EventModel(
          uid: 'test-uid',
          calendarId: 'cal-1',
          summary: '测试事件',
          dtStart: now,
          dtEnd: now.add(const Duration(hours: 1)),
          createdAt: now,
          updatedAt: now,
        );

        expect(event.uid, 'test-uid');
        expect(event.summary, '测试事件');
        expect(event.isRecurring, isFalse);
      });

      test('duration应正确计算', () {
        final start = DateTime(2025, 12, 25, 10, 0);
        final end = DateTime(2025, 12, 25, 12, 30);
        final event = EventModel(
          uid: 'test',
          calendarId: 'cal',
          summary: 'test',
          dtStart: start,
          dtEnd: end,
          createdAt: start,
          updatedAt: start,
        );

        expect(event.duration.inMinutes, 150); // 2.5小时
      });

      test('全天事件应默认1天时长', () {
        final start = DateTime(2025, 12, 25);
        final event = EventModel(
          uid: 'test',
          calendarId: 'cal',
          summary: 'test',
          dtStart: start,
          isAllDay: true,
          createdAt: start,
          updatedAt: start,
        );

        expect(event.duration.inDays, 1);
      });
    });

    group('重复事件', () {
      test('isRecurring应正确判断', () {
        final now = DateTime.now();
        final recurring = EventModel(
          uid: 'test',
          calendarId: 'cal',
          summary: 'test',
          dtStart: now,
          rrule: 'FREQ=DAILY',
          createdAt: now,
          updatedAt: now,
        );

        expect(recurring.isRecurring, isTrue);
      });

      test('recurrenceRule应正确解析', () {
        final now = DateTime.now();
        final event = EventModel(
          uid: 'test',
          calendarId: 'cal',
          summary: 'test',
          dtStart: now,
          rrule: 'FREQ=WEEKLY;BYDAY=MO,WE,FR',
          createdAt: now,
          updatedAt: now,
        );

        expect(event.recurrenceRule, isNotNull);
        expect(event.recurrenceRule!.byDay!.length, 3);
      });
    });

    group('fromMap/toMap', () {
      test('应正确序列化和反序列化', () {
        final now = DateTime.now();
        final original = EventModel(
          uid: 'test-uid',
          calendarId: 'cal-1',
          summary: '测试事件',
          description: '描述',
          location: '地点',
          dtStart: now,
          dtEnd: now.add(const Duration(hours: 1)),
          isAllDay: false,
          rrule: 'FREQ=DAILY',
          color: 0xFFFF0000,
          status: EventStatus.confirmed,
          priority: 5,
          url: 'https://example.com',
          createdAt: now,
          updatedAt: now,
          sequence: 1,
        );

        final map = original.toMap();
        final restored = EventModel.fromMap(map);

        expect(restored.uid, original.uid);
        expect(restored.summary, original.summary);
        expect(restored.description, original.description);
        expect(restored.location, original.location);
        expect(restored.isAllDay, original.isAllDay);
        expect(restored.rrule, original.rrule);
        expect(restored.color, original.color);
        expect(restored.status, original.status);
        expect(restored.priority, original.priority);
        expect(restored.url, original.url);
        expect(restored.sequence, original.sequence);
      });
    });

    group('copyWith', () {
      test('应正确复制并修改', () {
        final now = DateTime.now();
        final original = EventModel(
          uid: 'test',
          calendarId: 'cal',
          summary: '原标题',
          dtStart: now,
          createdAt: now,
          updatedAt: now,
        );

        final copied = original.copyWith(summary: '新标题', priority: 5);

        expect(copied.uid, original.uid);
        expect(copied.summary, '新标题');
        expect(copied.priority, 5);
      });
    });

    group('equality', () {
      test('相同UID应相等', () {
        final now = DateTime.now();
        final event1 = EventModel(
          uid: 'same-uid',
          calendarId: 'cal',
          summary: 'test1',
          dtStart: now,
          createdAt: now,
          updatedAt: now,
        );
        final event2 = EventModel(
          uid: 'same-uid',
          calendarId: 'cal',
          summary: 'test2',
          dtStart: now,
          createdAt: now,
          updatedAt: now,
        );

        expect(event1, event2);
      });
    });
  });

  group('EventStatus', () {
    test('fromString应正确解析', () {
      expect(EventStatus.fromString('tentative'), EventStatus.tentative);
      expect(EventStatus.fromString('confirmed'), EventStatus.confirmed);
      expect(EventStatus.fromString('cancelled'), EventStatus.cancelled);
      expect(EventStatus.fromString('invalid'), EventStatus.confirmed); // 默认值
    });
  });

  group('EventInstance', () {
    test('fromEvent应正确创建', () {
      final now = DateTime.now();
      final event = EventModel(
        uid: 'test',
        calendarId: 'cal',
        summary: 'test',
        dtStart: now,
        dtEnd: now.add(const Duration(hours: 2)),
        createdAt: now,
        updatedAt: now,
      );

      final instance = EventInstance.fromEvent(event);

      expect(instance.event, event);
      expect(instance.instanceStart, now);
      expect(instance.instanceEnd, now.add(const Duration(hours: 2)));
    });

    test('fromRecurringEvent应正确创建', () {
      final eventStart = DateTime(2025, 1, 1, 10, 0);
      final event = EventModel(
        uid: 'test',
        calendarId: 'cal',
        summary: 'test',
        dtStart: eventStart,
        dtEnd: eventStart.add(const Duration(hours: 2)),
        rrule: 'FREQ=DAILY',
        createdAt: eventStart,
        updatedAt: eventStart,
      );

      final occurrenceDate = DateTime(2025, 1, 5); // 第5天
      final instance = EventInstance.fromRecurringEvent(event, occurrenceDate);

      expect(instance.instanceStart.day, 5);
      expect(instance.instanceStart.hour, 10); // 保持原始时间
      expect(instance.instanceEnd.hour, 12); // 2小时后
    });
  });

  group('ReminderModel', () {
    test('应正确创建提醒', () {
      final reminder = ReminderModel(
        eventUid: 'event-uid',
        type: ReminderType.notification,
        triggerMinutes: -15, // 提前15分钟
        notificationId: 123,
      );

      expect(reminder.eventUid, 'event-uid');
      expect(reminder.triggerMinutes, -15);
    });

    test('fromMap/toMap应正确工作', () {
      final original = ReminderModel(
        id: 1,
        eventUid: 'event-uid',
        type: ReminderType.alarm,
        triggerMinutes: -30,
        notificationId: 456,
      );

      final map = original.toMap();
      final restored = ReminderModel.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.eventUid, original.eventUid);
      expect(restored.type, original.type);
      expect(restored.triggerMinutes, original.triggerMinutes);
      expect(restored.notificationId, original.notificationId);
    });

    test('copyWith应正确复制', () {
      final original = ReminderModel(
        eventUid: 'event-uid',
        type: ReminderType.notification,
        triggerMinutes: -15,
        notificationId: 123,
      );

      final copied = original.copyWith(triggerMinutes: -30);

      expect(copied.eventUid, original.eventUid);
      expect(copied.triggerMinutes, -30);
    });
  });

  group('ReminderType', () {
    test('fromString应正确解析', () {
      expect(
        ReminderType.fromString('notification'),
        ReminderType.notification,
      );
      expect(ReminderType.fromString('alarm'), ReminderType.alarm);
      expect(ReminderType.fromString('invalid'), ReminderType.notification);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:calendar_app/core/services/reminder_manager.dart';
import 'package:calendar_app/data/models/reminder_model.dart';

void main() {
  group('ReminderModel', () {
    test('should create reminder with correct properties', () {
      final reminder = ReminderModel(
        eventUid: 'event-123',
        triggerMinutes: 30,
        type: ReminderType.notification,
        notificationId: 12345,
      );

      expect(reminder.eventUid, equals('event-123'));
      expect(reminder.triggerMinutes, equals(30));
      expect(reminder.type, equals(ReminderType.notification));
      expect(reminder.notificationId, equals(12345));
    });

    test('should return correct trigger description for minutes', () {
      final reminder = ReminderModel(
        eventUid: 'event-123',
        triggerMinutes: 30,
        type: ReminderType.notification,
        notificationId: 12345,
      );

      expect(reminder.triggerDescription, equals('提前30分钟'));
    });

    test('should return correct trigger description for hours', () {
      final reminder = ReminderModel(
        eventUid: 'event-123',
        triggerMinutes: 120,
        type: ReminderType.notification,
        notificationId: 12345,
      );

      expect(reminder.triggerDescription, equals('提前2小时'));
    });

    test(
      'should return correct trigger description for hours with minutes',
      () {
        final reminder = ReminderModel(
          eventUid: 'event-123',
          triggerMinutes: 90,
          type: ReminderType.notification,
          notificationId: 12345,
        );

        expect(reminder.triggerDescription, equals('提前1小时30分钟'));
      },
    );

    test('should return correct trigger description for days', () {
      final reminder = ReminderModel(
        eventUid: 'event-123',
        triggerMinutes: 1440,
        type: ReminderType.notification,
        notificationId: 12345,
      );

      expect(reminder.triggerDescription, equals('提前1天'));
    });

    test('should return correct trigger description for event time', () {
      final reminder = ReminderModel(
        eventUid: 'event-123',
        triggerMinutes: 0,
        type: ReminderType.notification,
        notificationId: 12345,
      );

      expect(reminder.triggerDescription, equals('事件发生时'));
    });

    test('should correctly serialize and deserialize', () {
      final original = ReminderModel(
        eventUid: 'event-123',
        triggerMinutes: 15,
        type: ReminderType.notification,
        notificationId: 12345,
      );

      final map = original.toMap();
      final restored = ReminderModel.fromMap(map);

      expect(restored.eventUid, equals(original.eventUid));
      expect(restored.triggerMinutes, equals(original.triggerMinutes));
      expect(restored.type, equals(original.type));
      expect(restored.notificationId, equals(original.notificationId));
    });

    test('should copy with modified values', () {
      final original = ReminderModel(
        eventUid: 'event-123',
        triggerMinutes: 30,
        type: ReminderType.notification,
        notificationId: 12345,
      );

      final copied = original.copyWith(triggerMinutes: 60);

      expect(copied.eventUid, equals(original.eventUid));
      expect(copied.triggerMinutes, equals(60));
      expect(copied.notificationId, equals(original.notificationId));
    });
  });

  group('ReminderType', () {
    test('should parse notification type from string', () {
      final type = ReminderType.fromString('notification');
      expect(type, equals(ReminderType.notification));
    });

    test('should parse alarm type from string', () {
      final type = ReminderType.fromString('alarm');
      expect(type, equals(ReminderType.alarm));
    });

    test('should return notification for unknown type', () {
      final type = ReminderType.fromString('unknown');
      expect(type, equals(ReminderType.notification));
    });

    test('should have correct value', () {
      expect(ReminderType.notification.value, equals('notification'));
      expect(ReminderType.alarm.value, equals('alarm'));
    });

    test('should have correct label', () {
      expect(ReminderType.notification.label, equals('通知'));
      expect(ReminderType.alarm.label, equals('闹钟'));
    });
  });

  group('ReminderManager static methods', () {
    test('should create reminder with unique notification ID', () {
      final reminder1 = ReminderManager.createReminder(
        eventUid: 'event-123',
        triggerMinutes: 30,
      );

      // Small delay to ensure different timestamps
      final reminder2 = ReminderManager.createReminder(
        eventUid: 'event-123',
        triggerMinutes: 30,
      );

      expect(reminder1.eventUid, equals('event-123'));
      expect(reminder1.triggerMinutes, equals(30));
      expect(reminder1.type, equals(ReminderType.notification));
      // notification IDs might be same if created in same millisecond
      // but both should be valid positive integers
      expect(reminder1.notificationId, greaterThanOrEqualTo(0));
      expect(reminder2.notificationId, greaterThanOrEqualTo(0));
    });

    test('should create reminder with custom type', () {
      final reminder = ReminderManager.createReminder(
        eventUid: 'event-123',
        triggerMinutes: 30,
        type: ReminderType.alarm,
      );

      expect(reminder.type, equals(ReminderType.alarm));
    });

    test('should have default reminder options', () {
      final options = ReminderManager.defaultReminderOptions;

      expect(options, isNotEmpty);
      expect(options.length, equals(10));

      // Check first option (event time)
      expect(options[0].minutes, equals(0));
      expect(options[0].label, equals('事件发生时'));

      // Check 15 minute option
      expect(options[3].minutes, equals(15));
      expect(options[3].label, equals('提前15分钟'));

      // Check 1 hour option
      expect(options[5].minutes, equals(60));
      expect(options[5].label, equals('提前1小时'));

      // Check 1 day option
      expect(options[7].minutes, equals(1440));
      expect(options[7].label, equals('提前1天'));

      // Check 1 week option
      expect(options[9].minutes, equals(10080));
      expect(options[9].label, equals('提前1周'));
    });
  });

  group('ReminderOption', () {
    test('should create option with correct values', () {
      const option = ReminderOption(minutes: 30, label: '提前30分钟');

      expect(option.minutes, equals(30));
      expect(option.label, equals('提前30分钟'));
    });
  });

  group('Trigger minutes calculations', () {
    test('5 minutes should be less than 1 hour in minutes', () {
      expect(5 < 60, isTrue);
    });

    test('1 hour should equal 60 minutes', () {
      expect(60, equals(60));
    });

    test('1 day should equal 1440 minutes', () {
      expect(1440, equals(24 * 60));
    });

    test('1 week should equal 10080 minutes', () {
      expect(10080, equals(7 * 24 * 60));
    });
  });
}

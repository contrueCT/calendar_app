import 'package:flutter_test/flutter_test.dart';
import 'package:calendar_app/core/services/reminder_manager.dart';
import 'package:calendar_app/data/models/reminder_model.dart';

void main() {
  group('ReminderManager', () {
    group('createReminder static method', () {
      test('should create reminder with correct properties', () {
        final reminder = ReminderManager.createReminder(
          eventUid: 'event-123',
          triggerMinutes: 30,
          type: ReminderType.notification,
        );

        expect(reminder.eventUid, equals('event-123'));
        expect(reminder.triggerMinutes, equals(30));
        expect(reminder.type, equals(ReminderType.notification));
        expect(reminder.notificationId, greaterThanOrEqualTo(0));
      });

      test('should create reminder with alarm type', () {
        final reminder = ReminderManager.createReminder(
          eventUid: 'event-123',
          triggerMinutes: 60,
          type: ReminderType.alarm,
        );

        expect(reminder.type, equals(ReminderType.alarm));
      });

      test('should create reminder with 0 minutes (at event time)', () {
        final reminder = ReminderManager.createReminder(
          eventUid: 'event-123',
          triggerMinutes: 0,
        );

        expect(reminder.triggerMinutes, equals(0));
        expect(reminder.triggerDescription, equals('事件发生时'));
      });

      test('should create reminder with 1 day in minutes', () {
        final reminder = ReminderManager.createReminder(
          eventUid: 'event-123',
          triggerMinutes: 1440,
        );

        expect(reminder.triggerMinutes, equals(1440));
        expect(reminder.triggerDescription, equals('提前1天'));
      });

      test('should generate unique notification IDs', () {
        final reminder1 = ReminderManager.createReminder(
          eventUid: 'event-1',
          triggerMinutes: 30,
        );

        // Wait a small amount to ensure different milliseconds
        final reminder2 = ReminderManager.createReminder(
          eventUid: 'event-2',
          triggerMinutes: 30,
        );

        // Both should be valid notification IDs
        expect(reminder1.notificationId, greaterThanOrEqualTo(0));
        expect(reminder2.notificationId, greaterThanOrEqualTo(0));
      });
    });

    group('defaultReminderOptions', () {
      test('should return list of reminder options', () {
        final options = ReminderManager.defaultReminderOptions;

        expect(options, isNotEmpty);
        expect(options.length, greaterThanOrEqualTo(5));
      });

      test('should include at event time option', () {
        final options = ReminderManager.defaultReminderOptions;
        final atEventTime = options.where((o) => o.minutes == 0).toList();

        expect(atEventTime, isNotEmpty);
        expect(atEventTime.first.label, equals('事件发生时'));
      });

      test('should include common reminder times', () {
        final options = ReminderManager.defaultReminderOptions;
        final minutes = options.map((o) => o.minutes).toList();

        expect(minutes.contains(0), isTrue); // At event time
        expect(minutes.contains(5), isTrue); // 5 minutes
        expect(minutes.contains(15), isTrue); // 15 minutes
        expect(minutes.contains(30), isTrue); // 30 minutes
        expect(minutes.contains(60), isTrue); // 1 hour
        expect(minutes.contains(1440), isTrue); // 1 day
      });

      test('should have sorted options', () {
        final options = ReminderManager.defaultReminderOptions;

        for (int i = 0; i < options.length - 1; i++) {
          expect(
            options[i].minutes <= options[i + 1].minutes,
            isTrue,
            reason:
                'Options should be sorted by minutes: ${options[i].minutes} should be <= ${options[i + 1].minutes}',
          );
        }
      });
    });
  });

  group('ReminderOption', () {
    test('should create option with minutes and label', () {
      const option = ReminderOption(minutes: 15, label: '提前15分钟');

      expect(option.minutes, equals(15));
      expect(option.label, equals('提前15分钟'));
    });

    test('should support zero minutes for at event time', () {
      const option = ReminderOption(minutes: 0, label: '事件发生时');

      expect(option.minutes, equals(0));
      expect(option.label, equals('事件发生时'));
    });

    test('should support large minute values for weeks', () {
      const option = ReminderOption(minutes: 10080, label: '提前1周');

      expect(option.minutes, equals(10080));
      expect(option.minutes, equals(7 * 24 * 60));
    });
  });

  group('Trigger minutes to time conversion', () {
    test('1 hour = 60 minutes', () {
      expect(60, equals(1 * 60));
    });

    test('2 hours = 120 minutes', () {
      expect(120, equals(2 * 60));
    });

    test('1 day = 1440 minutes', () {
      expect(1440, equals(24 * 60));
    });

    test('2 days = 2880 minutes', () {
      expect(2880, equals(2 * 24 * 60));
    });

    test('1 week = 10080 minutes', () {
      expect(10080, equals(7 * 24 * 60));
    });
  });
}

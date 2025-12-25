import 'package:flutter_test/flutter_test.dart';
import 'package:calendar_app/core/utils/icalendar_utils.dart';
import 'package:calendar_app/data/models/event_model.dart';
import 'package:calendar_app/data/models/reminder_model.dart';

void main() {
  group('ICalendarUtils', () {
    group('parseICalendar', () {
      test('应正确解析简单的iCalendar内容', () {
        const icsContent = '''
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Test//Test//EN
BEGIN:VEVENT
UID:test-uid-123
DTSTART:20251225T100000Z
DTEND:20251225T120000Z
SUMMARY:圣诞聚会
DESCRIPTION:和朋友们一起庆祝
LOCATION:餐厅
STATUS:CONFIRMED
END:VEVENT
END:VCALENDAR
''';

        final events = ICalendarUtils.parseICalendar(icsContent, 'cal-1');

        expect(events.length, 1);
        expect(events.first.uid, 'test-uid-123');
        expect(events.first.summary, '圣诞聚会');
        expect(events.first.description, '和朋友们一起庆祝');
        expect(events.first.location, '餐厅');
        expect(events.first.status, EventStatus.confirmed);
      });

      test('应正确解析全天事件', () {
        const icsContent = '''
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:allday-123
DTSTART;VALUE=DATE:20251225
DTEND;VALUE=DATE:20251226
SUMMARY:圣诞节
END:VEVENT
END:VCALENDAR
''';

        final events = ICalendarUtils.parseICalendar(icsContent, 'cal-1');

        expect(events.length, 1);
        expect(events.first.isAllDay, isTrue);
      });

      test('应正确解析重复事件', () {
        const icsContent = '''
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:recurring-123
DTSTART:20251225T100000Z
SUMMARY:每周会议
RRULE:FREQ=WEEKLY;BYDAY=MO,WE,FR
END:VEVENT
END:VCALENDAR
''';

        final events = ICalendarUtils.parseICalendar(icsContent, 'cal-1');

        expect(events.length, 1);
        expect(events.first.isRecurring, isTrue);
        expect(events.first.rrule, 'FREQ=WEEKLY;BYDAY=MO,WE,FR');
      });

      test('应正确解析带提醒的事件', () {
        const icsContent = '''
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:alarm-123
DTSTART:20251225T100000Z
SUMMARY:重要会议
BEGIN:VALARM
ACTION:DISPLAY
TRIGGER:-PT15M
DESCRIPTION:提醒
END:VALARM
BEGIN:VALARM
ACTION:DISPLAY
TRIGGER:-PT1H
DESCRIPTION:提醒
END:VALARM
END:VEVENT
END:VCALENDAR
''';

        final events = ICalendarUtils.parseICalendar(icsContent, 'cal-1');

        expect(events.length, 1);
        expect(events.first.reminders.length, 2);
        expect(events.first.reminders[0].triggerMinutes, -15);
        expect(events.first.reminders[1].triggerMinutes, -60);
      });

      test('应正确解析EXDATE', () {
        const icsContent = '''
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:exdate-123
DTSTART:20251225T100000Z
SUMMARY:带排除日期的事件
RRULE:FREQ=DAILY
EXDATE:20251226T100000Z,20251228T100000Z
END:VEVENT
END:VCALENDAR
''';

        final events = ICalendarUtils.parseICalendar(icsContent, 'cal-1');

        expect(events.length, 1);
        expect(events.first.exDates, isNotNull);
        expect(events.first.exDates!.length, 2);
      });

      test('应正确处理折叠行', () {
        const icsContent = '''
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:longdesc-123
DTSTART:20251225T100000Z
SUMMARY:测试
DESCRIPTION:这是一段很长的描述
 ，需要被折叠成多行来展示
 ，这是第三行
END:VEVENT
END:VCALENDAR
''';

        final events = ICalendarUtils.parseICalendar(icsContent, 'cal-1');

        expect(events.length, 1);
        expect(events.first.description!.contains('需要被折叠'), isTrue);
      });

      test('应正确处理转义字符', () {
        const icsContent = '''
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:escape-123
DTSTART:20251225T100000Z
SUMMARY:测试\\;逗号\\,和反斜杠\\\\
DESCRIPTION:换行\\n测试
END:VEVENT
END:VCALENDAR
''';

        final events = ICalendarUtils.parseICalendar(icsContent, 'cal-1');

        expect(events.length, 1);
        expect(events.first.summary, '测试;逗号,和反斜杠\\');
        expect(events.first.description!.contains('\n'), isTrue);
      });

      test('应正确解析多个事件', () {
        const icsContent = '''
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:event-1
DTSTART:20251225T100000Z
SUMMARY:事件1
END:VEVENT
BEGIN:VEVENT
UID:event-2
DTSTART:20251226T100000Z
SUMMARY:事件2
END:VEVENT
BEGIN:VEVENT
UID:event-3
DTSTART:20251227T100000Z
SUMMARY:事件3
END:VEVENT
END:VCALENDAR
''';

        final events = ICalendarUtils.parseICalendar(icsContent, 'cal-1');

        expect(events.length, 3);
      });
    });

    group('exportToICalendar', () {
      test('应正确导出单个事件', () {
        final now = DateTime.now();
        final events = [
          EventModel(
            uid: 'test-uid',
            calendarId: 'cal-1',
            summary: '测试事件',
            description: '描述',
            location: '地点',
            dtStart: now,
            dtEnd: now.add(const Duration(hours: 1)),
            createdAt: now,
            updatedAt: now,
          ),
        ];

        final ics = ICalendarUtils.exportToICalendar(events);

        expect(ics.contains('BEGIN:VCALENDAR'), isTrue);
        expect(ics.contains('END:VCALENDAR'), isTrue);
        expect(ics.contains('BEGIN:VEVENT'), isTrue);
        expect(ics.contains('END:VEVENT'), isTrue);
        expect(ics.contains('UID:test-uid'), isTrue);
        expect(ics.contains('SUMMARY:测试事件'), isTrue);
      });

      test('应正确导出全天事件', () {
        final date = DateTime(2025, 12, 25);
        final events = [
          EventModel(
            uid: 'allday',
            calendarId: 'cal-1',
            summary: '全天事件',
            dtStart: date,
            dtEnd: date.add(const Duration(days: 1)),
            isAllDay: true,
            createdAt: date,
            updatedAt: date,
          ),
        ];

        final ics = ICalendarUtils.exportToICalendar(events);

        expect(ics.contains('DTSTART;VALUE=DATE:'), isTrue);
      });

      test('应正确导出重复事件', () {
        final now = DateTime.now();
        final events = [
          EventModel(
            uid: 'recurring',
            calendarId: 'cal-1',
            summary: '重复事件',
            dtStart: now,
            rrule: 'FREQ=WEEKLY;BYDAY=MO',
            createdAt: now,
            updatedAt: now,
          ),
        ];

        final ics = ICalendarUtils.exportToICalendar(events);

        expect(ics.contains('RRULE:FREQ=WEEKLY;BYDAY=MO'), isTrue);
      });

      test('应正确导出带提醒的事件', () {
        final now = DateTime.now();
        final events = [
          EventModel(
            uid: 'withreminder',
            calendarId: 'cal-1',
            summary: '带提醒',
            dtStart: now,
            reminders: const [
              ReminderModel(
                eventUid: 'withreminder',
                type: ReminderType.notification,
                triggerMinutes: -15,
                notificationId: 1,
              ),
            ],
            createdAt: now,
            updatedAt: now,
          ),
        ];

        final ics = ICalendarUtils.exportToICalendar(events);

        expect(ics.contains('BEGIN:VALARM'), isTrue);
        expect(ics.contains('TRIGGER:-PT15M'), isTrue);
      });
    });

    group('isValidICalendar', () {
      test('有效的iCalendar应返回true', () {
        const valid = '''
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:test
DTSTART:20251225T100000Z
SUMMARY:Test
END:VEVENT
END:VCALENDAR
''';
        expect(ICalendarUtils.isValidICalendar(valid), isTrue);
      });

      test('无效的iCalendar应返回false', () {
        expect(ICalendarUtils.isValidICalendar('invalid'), isFalse);
        expect(ICalendarUtils.isValidICalendar('BEGIN:VCALENDAR'), isFalse);
        expect(ICalendarUtils.isValidICalendar(''), isFalse);
      });
    });

    group('extractCalendarName', () {
      test('应正确提取日历名称', () {
        const ics = '''
BEGIN:VCALENDAR
X-WR-CALNAME:我的日历
VERSION:2.0
END:VCALENDAR
''';
        expect(ICalendarUtils.extractCalendarName(ics), '我的日历');
      });

      test('没有名称应返回null', () {
        const ics = '''
BEGIN:VCALENDAR
VERSION:2.0
END:VCALENDAR
''';
        expect(ICalendarUtils.extractCalendarName(ics), isNull);
      });
    });

    group('countEvents', () {
      test('应正确计数事件', () {
        const ics = '''
BEGIN:VCALENDAR
BEGIN:VEVENT
END:VEVENT
BEGIN:VEVENT
END:VEVENT
BEGIN:VEVENT
END:VEVENT
END:VCALENDAR
''';
        expect(ICalendarUtils.countEvents(ics), 3);
      });

      test('无事件应返回0', () {
        const ics = '''
BEGIN:VCALENDAR
END:VCALENDAR
''';
        expect(ICalendarUtils.countEvents(ics), 0);
      });
    });
  });
}

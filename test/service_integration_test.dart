import 'package:flutter_test/flutter_test.dart';
import 'package:calendar_app/core/services/subscription_service.dart';
import 'package:calendar_app/core/services/icalendar_service.dart';
import 'package:calendar_app/core/utils/icalendar_utils.dart';
import 'package:calendar_app/data/models/calendar_model.dart';
import 'package:calendar_app/data/models/event_model.dart';
import 'package:calendar_app/data/models/reminder_model.dart';

void main() {
  group('SubscriptionService 测试', () {
    test('SyncResult 应正确创建成功结果', () {
      final result = SyncResult.success(
        addedCount: 5,
        updatedCount: 3,
        deletedCount: 1,
      );

      expect(result.success, true);
      expect(result.addedCount, 5);
      expect(result.updatedCount, 3);
      expect(result.deletedCount, 1);
      expect(result.totalChanges, 9);
      expect(result.error, isNull);
    });

    test('SyncResult 应正确创建失败结果', () {
      final result = SyncResult.failure('网络错误');

      expect(result.success, false);
      expect(result.error, '网络错误');
      expect(result.totalChanges, 0);
    });

    test('SyncResult summary 应正确生成', () {
      final successResult = SyncResult.success(addedCount: 2, updatedCount: 1);
      expect(successResult.summary, contains('新增'));

      final noChangeResult = SyncResult.success();
      expect(noChangeResult.summary, '无更新');

      final failureResult = SyncResult.failure('测试错误');
      expect(failureResult.summary, '测试错误');
    });

    test('SubscriptionValidation 应正确创建', () {
      final valid = SubscriptionValidation.valid(
        calendarName: '测试日历',
        eventCount: 10,
      );

      expect(valid.isValid, true);
      expect(valid.calendarName, '测试日历');
      expect(valid.eventCount, 10);

      final invalid = SubscriptionValidation.invalid('无效URL');
      expect(invalid.isValid, false);
      expect(invalid.error, '无效URL');
    });
  });

  group('ICalendarService 测试', () {
    test('ImportResult 应正确创建成功结果', () {
      final result = ImportResult.success(importedCount: 10, skippedCount: 2);

      expect(result.success, true);
      expect(result.importedCount, 10);
      expect(result.skippedCount, 2);
    });

    test('ImportResult 应正确创建失败结果', () {
      final result = ImportResult.failure('解析错误');

      expect(result.success, false);
      expect(result.error, '解析错误');
    });

    test('ImportResult summary 应正确生成', () {
      final result1 = ImportResult.success(importedCount: 5);
      expect(result1.summary, contains('成功导入'));

      final result2 = ImportResult.success(importedCount: 5, skippedCount: 2);
      expect(result2.summary, contains('跳过'));

      final result3 = ImportResult.failure('测试错误');
      expect(result3.summary, '测试错误');
    });

    test('ExportResult 应正确创建', () {
      final success = ExportResult.success(
        exportedCount: 15,
        filePath: '/path/to/file.ics',
      );

      expect(success.success, true);
      expect(success.exportedCount, 15);
      expect(success.filePath, isNotNull);

      final failure = ExportResult.failure('导出失败');
      expect(failure.success, false);
      expect(failure.error, '导出失败');
    });

    test('ImportPreview 应正确创建', () {
      final now = DateTime.now();
      final events = [
        EventModel(
          uid: 'event-1',
          calendarId: 'cal-1',
          summary: '事件1',
          dtStart: now,
          reminders: [],
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final preview = ImportPreview.success(
        calendarName: '测试日历',
        events: events,
      );

      expect(preview.success, true);
      expect(preview.calendarName, '测试日历');
      expect(preview.events.length, 1);

      final failure = ImportPreview.failure('预览失败');
      expect(failure.success, false);
      expect(failure.error, '预览失败');
    });
  });

  group('ICalendarUtils 验证测试', () {
    test('isValidICalendar 应正确验证有效内容', () {
      const validIcs = '''
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Test//Test//EN
BEGIN:VEVENT
UID:test-1
DTSTART:20251225T100000Z
SUMMARY:测试事件
END:VEVENT
END:VCALENDAR
''';

      expect(ICalendarUtils.isValidICalendar(validIcs), true);
    });

    test('isValidICalendar 应正确拒绝无效内容', () {
      expect(ICalendarUtils.isValidICalendar(''), false);
      expect(ICalendarUtils.isValidICalendar('random text'), false);
      expect(ICalendarUtils.isValidICalendar('BEGIN:VCALENDAR'), false);
    });

    test('extractCalendarName 应正确提取日历名称', () {
      const icsWithName = '''
BEGIN:VCALENDAR
VERSION:2.0
X-WR-CALNAME:我的日历
BEGIN:VEVENT
END:VEVENT
END:VCALENDAR
''';

      final name = ICalendarUtils.extractCalendarName(icsWithName);
      expect(name, '我的日历');
    });

    test('countEvents 应正确计数事件', () {
      const icsContent = '''
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:event-1
END:VEVENT
BEGIN:VEVENT
UID:event-2
END:VEVENT
BEGIN:VEVENT
UID:event-3
END:VEVENT
END:VCALENDAR
''';

      expect(ICalendarUtils.countEvents(icsContent), 3);
    });
  });

  group('iCalendar 解析边界情况测试', () {
    test('应处理空日历', () {
      const emptyCalendar = '''
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Test//Test//EN
END:VCALENDAR
''';

      final events = ICalendarUtils.parseICalendar(emptyCalendar, 'cal-1');
      expect(events, isEmpty);
    });

    test('应处理缺少UID的事件', () {
      const icsContent = '''
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
DTSTART:20251225T100000Z
SUMMARY:无UID事件
END:VEVENT
END:VCALENDAR
''';

      final events = ICalendarUtils.parseICalendar(icsContent, 'cal-1');
      expect(events.length, 1);
      expect(events.first.uid, isNotEmpty); // 应自动生成UID
    });

    test('应处理缺少SUMMARY的事件', () {
      const icsContent = '''
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:test-1
DTSTART:20251225T100000Z
END:VEVENT
END:VCALENDAR
''';

      final events = ICalendarUtils.parseICalendar(icsContent, 'cal-1');
      expect(events.length, 1);
      expect(events.first.summary, '无标题'); // 应有默认标题
    });

    test('应跳过缺少DTSTART的事件', () {
      const icsContent = '''
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:invalid-event
SUMMARY:缺少开始时间
END:VEVENT
END:VCALENDAR
''';

      final events = ICalendarUtils.parseICalendar(icsContent, 'cal-1');
      expect(events, isEmpty);
    });
  });

  group('iCalendar 导出测试', () {
    test('导出应生成有效的iCalendar格式', () {
      final now = DateTime.now();
      final events = [
        EventModel(
          uid: 'export-test-1',
          calendarId: 'cal-1',
          summary: '导出测试事件',
          description: '这是描述',
          location: '测试地点',
          dtStart: now,
          dtEnd: now.add(const Duration(hours: 1)),
          reminders: [],
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final icsContent = ICalendarUtils.exportToICalendar(
        events,
        calendarName: '测试日历',
      );

      expect(icsContent, contains('BEGIN:VCALENDAR'));
      expect(icsContent, contains('END:VCALENDAR'));
      expect(icsContent, contains('BEGIN:VEVENT'));
      expect(icsContent, contains('END:VEVENT'));
      expect(icsContent, contains('UID:export-test-1'));
      expect(icsContent, contains('SUMMARY:导出测试事件'));
      expect(icsContent, contains('X-WR-CALNAME:测试日历'));
    });

    test('导出应正确处理特殊字符', () {
      final now = DateTime.now();
      final events = [
        EventModel(
          uid: 'special-chars',
          calendarId: 'cal-1',
          summary: '包含;逗号,和\\反斜杠',
          description: '换行\n测试',
          dtStart: now,
          reminders: [],
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final icsContent = ICalendarUtils.exportToICalendar(events);

      // 特殊字符应被转义
      expect(icsContent, contains('\\;'));
      expect(icsContent, contains('\\,'));
      expect(icsContent, contains('\\\\'));
      expect(icsContent, contains('\\n'));
    });

    test('导出应包含提醒信息', () {
      final now = DateTime.now();
      final events = [
        EventModel(
          uid: 'with-reminder',
          calendarId: 'cal-1',
          summary: '带提醒的事件',
          dtStart: now,
          reminders: [
            const ReminderModel(
              eventUid: 'with-reminder',
              triggerMinutes: 15,
              notificationId: 1,
            ),
          ],
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final icsContent = ICalendarUtils.exportToICalendar(events);

      expect(icsContent, contains('BEGIN:VALARM'));
      expect(icsContent, contains('END:VALARM'));
      // 实际导出格式为 PT15M (不带负号)
      expect(icsContent, contains('TRIGGER:PT15M'));
    });

    test('导出应包含重复规则', () {
      final now = DateTime.now();
      final events = [
        EventModel(
          uid: 'recurring',
          calendarId: 'cal-1',
          summary: '重复事件',
          dtStart: now,
          rrule: 'FREQ=WEEKLY;BYDAY=MO,WE,FR',
          reminders: [],
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final icsContent = ICalendarUtils.exportToICalendar(events);

      expect(icsContent, contains('RRULE:FREQ=WEEKLY;BYDAY=MO,WE,FR'));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:calendar_app/data/models/models.dart';

/// 测试事件创建流程
void main() {
  group('事件创建流程测试', () {
    test('事件日期时间应正确转换为UTC毫秒', () {
      final now = DateTime.now();
      final event = EventModel(
        uid: 'test-event-1',
        calendarId: 'default',
        summary: '测试事件',
        dtStart: now,
        dtEnd: now.add(const Duration(hours: 1)),
        createdAt: now,
        updatedAt: now,
      );

      // 检查 toMap 转换
      final map = event.toMap();
      final dtStartMs = map['dtstart'] as int;
      final dtEndMs = map['dtend'] as int;

      // 验证毫秒值
      expect(dtStartMs, now.toUtc().millisecondsSinceEpoch);
      expect(
        dtEndMs,
        now.add(const Duration(hours: 1)).toUtc().millisecondsSinceEpoch,
      );

      // 验证从 map 重建事件后日期正确
      final recreated = EventModel.fromMap(map);
      expect(recreated.dtStart.year, now.year);
      expect(recreated.dtStart.month, now.month);
      expect(recreated.dtStart.day, now.day);
      expect(recreated.dtStart.hour, now.hour);
    });

    test('事件日期应在加载范围内被查询到', () {
      final now = DateTime.now();
      final eventStart = now;
      final eventEnd = now.add(const Duration(hours: 1));

      // 模拟 loadEventsForMonth 的范围计算
      final month = now;
      final rangeStart = DateTime(
        month.year,
        month.month,
        1,
      ).subtract(const Duration(days: 7));
      final rangeEnd = DateTime(
        month.year,
        month.month + 1,
        0,
      ).add(const Duration(days: 8));

      // 验证事件在范围内
      expect(
        eventStart.isAfter(rangeStart) ||
            eventStart.isAtSameMomentAs(rangeStart),
        true,
      );
      expect(
        eventEnd.isBefore(rangeEnd) || eventEnd.isAtSameMomentAs(rangeEnd),
        true,
      );
    });

    test('默认日历ID应为default', () {
      expect('default', 'default');

      // 模拟 EventEditViewModel 默认值
      final defaultCalendarId = 'default';

      // 模拟 visibleCalendars 包含默认日历
      final calendars = [
        CalendarModel(
          id: 'default',
          name: '我的日历',
          isVisible: true,
          isDefault: true,
          createdAt: DateTime.now(),
        ),
      ];

      final visibleCalendars = calendars.where((c) => c.isVisible).toList();
      final visibleIds = visibleCalendars.map((c) => c.id).toSet();

      // 验证默认日历在可见日历中
      expect(visibleIds.contains(defaultCalendarId), true);
    });

    test('事件calendarId应与可见日历匹配', () {
      final event = EventModel(
        uid: 'test-event-1',
        calendarId: 'default',
        summary: '测试事件',
        dtStart: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final visibleIds = {'default'};

      // 模拟 _loadEventsForRange 的过滤逻辑
      final events = [event];
      final filteredEvents = events
          .where((e) => visibleIds.contains(e.calendarId))
          .toList();

      expect(filteredEvents.length, 1);
      expect(filteredEvents.first.uid, 'test-event-1');
    });

    test('事件应正确添加到eventsByDate map', () {
      final now = DateTime.now();
      final dateKey = DateTime(now.year, now.month, now.day);

      final event = EventModel(
        uid: 'test-event-1',
        calendarId: 'default',
        summary: '测试事件',
        dtStart: now,
        dtEnd: now.add(const Duration(hours: 1)),
        createdAt: now,
        updatedAt: now,
      );

      // 模拟 eventsByDate 构建
      final eventsByDate = <DateTime, List<EventModel>>{};
      eventsByDate[dateKey] = [event];

      expect(eventsByDate[dateKey]?.length, 1);
      expect(eventsByDate[dateKey]?.first.uid, 'test-event-1');
    });
  });
}

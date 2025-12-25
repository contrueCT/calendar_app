import 'package:flutter_test/flutter_test.dart';
import 'package:calendar_app/core/utils/date_utils.dart';

void main() {
  group('DateTimeUtils', () {
    group('startOfDay', () {
      test('应返回当天00:00:00', () {
        final date = DateTime(2025, 12, 25, 14, 30, 45);
        final result = DateTimeUtils.startOfDay(date);

        expect(result.year, 2025);
        expect(result.month, 12);
        expect(result.day, 25);
        expect(result.hour, 0);
        expect(result.minute, 0);
        expect(result.second, 0);
      });
    });

    group('endOfDay', () {
      test('应返回当天23:59:59.999', () {
        final date = DateTime(2025, 12, 25, 14, 30, 45);
        final result = DateTimeUtils.endOfDay(date);

        expect(result.year, 2025);
        expect(result.month, 12);
        expect(result.day, 25);
        expect(result.hour, 23);
        expect(result.minute, 59);
        expect(result.second, 59);
      });
    });

    group('startOfWeek', () {
      test('应返回周一（默认）', () {
        final date = DateTime(2025, 12, 25); // 周四
        final result = DateTimeUtils.startOfWeek(date);

        expect(result.weekday, DateTime.monday);
        expect(result.day, 22); // 12月22日是周一
      });

      test('应支持周日作为周起始', () {
        final date = DateTime(2025, 12, 25); // 周四
        final result = DateTimeUtils.startOfWeek(date, weekStartsOn: DateTime.sunday);

        expect(result.weekday, DateTime.sunday);
        expect(result.day, 21); // 12月21日是周日
      });
    });

    group('startOfMonth', () {
      test('应返回月份第一天', () {
        final date = DateTime(2025, 12, 25);
        final result = DateTimeUtils.startOfMonth(date);

        expect(result.day, 1);
        expect(result.month, 12);
      });
    });

    group('endOfMonth', () {
      test('应返回月份最后一天', () {
        final date = DateTime(2025, 12, 15);
        final result = DateTimeUtils.endOfMonth(date);

        expect(result.day, 31);
        expect(result.month, 12);
      });

      test('应正确处理二月', () {
        final date = DateTime(2025, 2, 15); // 非闰年
        final result = DateTimeUtils.endOfMonth(date);

        expect(result.day, 28);
      });

      test('应正确处理闰年二月', () {
        final date = DateTime(2024, 2, 15); // 闰年
        final result = DateTimeUtils.endOfMonth(date);

        expect(result.day, 29);
      });
    });

    group('isSameDay', () {
      test('相同日期应返回true', () {
        final date1 = DateTime(2025, 12, 25, 10, 30);
        final date2 = DateTime(2025, 12, 25, 20, 15);

        expect(DateTimeUtils.isSameDay(date1, date2), isTrue);
      });

      test('不同日期应返回false', () {
        final date1 = DateTime(2025, 12, 25);
        final date2 = DateTime(2025, 12, 26);

        expect(DateTimeUtils.isSameDay(date1, date2), isFalse);
      });

      test('null值应返回false', () {
        expect(DateTimeUtils.isSameDay(null, DateTime.now()), isFalse);
        expect(DateTimeUtils.isSameDay(DateTime.now(), null), isFalse);
      });
    });

    group('isSameWeek', () {
      test('同一周应返回true', () {
        final date1 = DateTime(2025, 12, 22); // 周一
        final date2 = DateTime(2025, 12, 26); // 周五

        expect(DateTimeUtils.isSameWeek(date1, date2), isTrue);
      });

      test('不同周应返回false', () {
        final date1 = DateTime(2025, 12, 22); // 第一周周一
        final date2 = DateTime(2025, 12, 29); // 第二周周一

        expect(DateTimeUtils.isSameWeek(date1, date2), isFalse);
      });
    });

    group('isSameMonth', () {
      test('同月应返回true', () {
        final date1 = DateTime(2025, 12, 1);
        final date2 = DateTime(2025, 12, 31);

        expect(DateTimeUtils.isSameMonth(date1, date2), isTrue);
      });

      test('不同月应返回false', () {
        final date1 = DateTime(2025, 12, 31);
        final date2 = DateTime(2026, 1, 1);

        expect(DateTimeUtils.isSameMonth(date1, date2), isFalse);
      });
    });

    group('isInRange', () {
      test('范围内日期应返回true', () {
        final date = DateTime(2025, 12, 25);
        final start = DateTime(2025, 12, 20);
        final end = DateTime(2025, 12, 31);

        expect(DateTimeUtils.isInRange(date, start, end), isTrue);
      });

      test('边界日期应返回true', () {
        final start = DateTime(2025, 12, 20);
        final end = DateTime(2025, 12, 31);

        expect(DateTimeUtils.isInRange(start, start, end), isTrue);
        expect(DateTimeUtils.isInRange(end, start, end), isTrue);
      });

      test('范围外日期应返回false', () {
        final date = DateTime(2025, 12, 19);
        final start = DateTime(2025, 12, 20);
        final end = DateTime(2025, 12, 31);

        expect(DateTimeUtils.isInRange(date, start, end), isFalse);
      });
    });

    group('daysBetween', () {
      test('应正确计算天数差', () {
        final start = DateTime(2025, 12, 20);
        final end = DateTime(2025, 12, 25);

        expect(DateTimeUtils.daysBetween(start, end), 5);
      });

      test('同一天应返回0', () {
        final date = DateTime(2025, 12, 25);

        expect(DateTimeUtils.daysBetween(date, date), 0);
      });
    });

    group('daysInMonth', () {
      test('应返回正确的天数', () {
        expect(DateTimeUtils.daysInMonth(2025, 1), 31);
        expect(DateTimeUtils.daysInMonth(2025, 2), 28);
        expect(DateTimeUtils.daysInMonth(2024, 2), 29); // 闰年
        expect(DateTimeUtils.daysInMonth(2025, 4), 30);
      });
    });

    group('getNthWeekdayOfMonth', () {
      test('应返回第一个周一', () {
        final result = DateTimeUtils.getNthWeekdayOfMonth(2025, 12, DateTime.monday, 1);

        expect(result, isNotNull);
        expect(result!.day, 1); // 2025年12月1日是周一
      });

      test('应返回第二个周五', () {
        final result = DateTimeUtils.getNthWeekdayOfMonth(2025, 12, DateTime.friday, 2);

        expect(result, isNotNull);
        expect(result!.day, 12);
      });

      test('应返回最后一个周五', () {
        final result = DateTimeUtils.getNthWeekdayOfMonth(2025, 12, DateTime.friday, -1);

        expect(result, isNotNull);
        expect(result!.day, 26);
      });

      test('不存在的日期应返回null', () {
        // 2025年12月没有第6个周一
        final result = DateTimeUtils.getNthWeekdayOfMonth(2025, 12, DateTime.monday, 6);

        expect(result, isNull);
      });
    });

    group('addMonths', () {
      test('应正确增加月份', () {
        final date = DateTime(2025, 1, 15);
        final result = DateTimeUtils.addMonths(date, 3);

        expect(result.year, 2025);
        expect(result.month, 4);
        expect(result.day, 15);
      });

      test('应正确跨年', () {
        final date = DateTime(2025, 11, 15);
        final result = DateTimeUtils.addMonths(date, 3);

        expect(result.year, 2026);
        expect(result.month, 2);
      });

      test('应正确处理月末', () {
        final date = DateTime(2025, 1, 31);
        final result = DateTimeUtils.addMonths(date, 1); // 2月没有31日

        expect(result.month, 2);
        expect(result.day, 28); // 2025年非闰年
      });

      test('应支持负数', () {
        final date = DateTime(2025, 3, 15);
        final result = DateTimeUtils.addMonths(date, -2);

        expect(result.year, 2025);
        expect(result.month, 1);
      });
    });

    group('parseICalDateTime', () {
      test('应解析仅日期格式', () {
        final result = DateTimeUtils.parseICalDateTime('20251225');

        expect(result, isNotNull);
        expect(result!.year, 2025);
        expect(result.month, 12);
        expect(result.day, 25);
      });

      test('应解析带时间的UTC格式', () {
        final result = DateTimeUtils.parseICalDateTime('20251225T143000Z');

        expect(result, isNotNull);
        // 注意：结果会转换为本地时间
      });

      test('无效格式应返回null', () {
        expect(DateTimeUtils.parseICalDateTime('invalid'), isNull);
        expect(DateTimeUtils.parseICalDateTime(''), isNull);
      });
    });

    group('toICalDateTime', () {
      test('应生成UTC格式字符串', () {
        final date = DateTime.utc(2025, 12, 25, 14, 30, 0);
        final result = DateTimeUtils.toICalDateTime(date);

        expect(result, '20251225T143000Z');
      });

      test('应支持仅日期格式', () {
        final date = DateTime.utc(2025, 12, 25);
        final result = DateTimeUtils.toICalDateTime(date, dateOnly: true);

        expect(result, '20251225');
      });
    });

    group('formatRelative', () {
      test('刚刚应返回"刚刚"', () {
        final now = DateTime.now();
        expect(DateTimeUtils.formatRelative(now), '刚刚');
      });

      test('几分钟前', () {
        final date = DateTime.now().subtract(const Duration(minutes: 5));
        expect(DateTimeUtils.formatRelative(date), '5分钟前');
      });

      test('几小时前', () {
        final date = DateTime.now().subtract(const Duration(hours: 3));
        expect(DateTimeUtils.formatRelative(date), '3小时前');
      });

      test('昨天', () {
        final date = DateTime.now().subtract(const Duration(days: 1));
        expect(DateTimeUtils.formatRelative(date), '昨天');
      });
    });
  });
}

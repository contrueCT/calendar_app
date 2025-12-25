import 'package:flutter_test/flutter_test.dart';
import 'package:calendar_app/data/models/recurrence_rule.dart';

void main() {
  group('RecurrenceRule', () {
    group('fromRRuleString', () {
      test('应正确解析简单的每日重复规则', () {
        final rule = RecurrenceRule.fromRRuleString('FREQ=DAILY');

        expect(rule, isNotNull);
        expect(rule!.frequency, Frequency.daily);
        expect(rule.interval, 1);
        expect(rule.count, isNull);
        expect(rule.until, isNull);
      });

      test('应正确解析带RRULE:前缀的规则', () {
        final rule = RecurrenceRule.fromRRuleString('RRULE:FREQ=WEEKLY');

        expect(rule, isNotNull);
        expect(rule!.frequency, Frequency.weekly);
      });

      test('应正确解析带间隔的规则', () {
        final rule = RecurrenceRule.fromRRuleString('FREQ=DAILY;INTERVAL=3');

        expect(rule, isNotNull);
        expect(rule!.interval, 3);
      });

      test('应正确解析带COUNT的规则', () {
        final rule = RecurrenceRule.fromRRuleString('FREQ=WEEKLY;COUNT=10');

        expect(rule, isNotNull);
        expect(rule!.count, 10);
      });

      test('应正确解析带UNTIL的规则', () {
        final rule = RecurrenceRule.fromRRuleString(
          'FREQ=MONTHLY;UNTIL=20251231',
        );

        expect(rule, isNotNull);
        expect(rule!.until, isNotNull);
        expect(rule.until!.year, 2025);
        expect(rule.until!.month, 12);
        expect(rule.until!.day, 31);
      });

      test('应正确解析带BYDAY的周重复规则', () {
        final rule = RecurrenceRule.fromRRuleString(
          'FREQ=WEEKLY;BYDAY=MO,WE,FR',
        );

        expect(rule, isNotNull);
        expect(rule!.byDay, isNotNull);
        expect(rule.byDay!.length, 3);
        expect(rule.byDay!.contains(WeekDay.monday), isTrue);
        expect(rule.byDay!.contains(WeekDay.wednesday), isTrue);
        expect(rule.byDay!.contains(WeekDay.friday), isTrue);
      });

      test('应正确解析带位置的BYDAY', () {
        final rule = RecurrenceRule.fromRRuleString('FREQ=MONTHLY;BYDAY=1MO');

        expect(rule, isNotNull);
        expect(rule!.byDay, isNotNull);
        expect(rule.byDay!.contains(WeekDay.monday), isTrue);
        expect(rule.byDayRules, isNotNull);
        expect(rule.byDayRules!.first.position, 1);
      });

      test('应正确解析带负位置的BYDAY（最后一个）', () {
        final rule = RecurrenceRule.fromRRuleString('FREQ=MONTHLY;BYDAY=-1FR');

        expect(rule, isNotNull);
        expect(rule!.byDayRules, isNotNull);
        expect(rule.byDayRules!.first.weekDay, WeekDay.friday);
        expect(rule.byDayRules!.first.position, -1);
      });

      test('应正确解析BYMONTHDAY', () {
        final rule = RecurrenceRule.fromRRuleString(
          'FREQ=MONTHLY;BYMONTHDAY=15',
        );

        expect(rule, isNotNull);
        expect(rule!.byMonthDay, isNotNull);
        expect(rule.byMonthDay!.contains(15), isTrue);
      });

      test('应正确解析BYMONTH', () {
        final rule = RecurrenceRule.fromRRuleString(
          'FREQ=YEARLY;BYMONTH=1,6,12',
        );

        expect(rule, isNotNull);
        expect(rule!.byMonth, isNotNull);
        expect(rule.byMonth!.length, 3);
        expect(rule.byMonth!.contains(1), isTrue);
        expect(rule.byMonth!.contains(6), isTrue);
        expect(rule.byMonth!.contains(12), isTrue);
      });

      test('应正确解析BYSETPOS', () {
        final rule = RecurrenceRule.fromRRuleString(
          'FREQ=MONTHLY;BYDAY=MO;BYSETPOS=-1',
        );

        expect(rule, isNotNull);
        expect(rule!.bySetPos, isNotNull);
        expect(rule.bySetPos!.first, -1);
      });

      test('应正确解析WKST', () {
        final rule = RecurrenceRule.fromRRuleString('FREQ=WEEKLY;WKST=SU');

        expect(rule, isNotNull);
        expect(rule!.weekStart, WeekDay.sunday);
      });

      test('无效的规则应返回null', () {
        expect(RecurrenceRule.fromRRuleString(''), isNull);
        expect(RecurrenceRule.fromRRuleString('INVALID'), isNull);
        expect(RecurrenceRule.fromRRuleString('FREQ=INVALID'), isNull);
      });
    });

    group('toRRuleString', () {
      test('应正确生成简单规则字符串', () {
        const rule = RecurrenceRule(frequency: Frequency.daily);
        expect(rule.toRRuleString(), 'FREQ=DAILY');
      });

      test('应正确生成带间隔的规则字符串', () {
        const rule = RecurrenceRule(frequency: Frequency.weekly, interval: 2);
        expect(rule.toRRuleString(), 'FREQ=WEEKLY;INTERVAL=2');
      });

      test('应正确生成带COUNT的规则字符串', () {
        const rule = RecurrenceRule(frequency: Frequency.monthly, count: 5);
        expect(rule.toRRuleString(), 'FREQ=MONTHLY;COUNT=5');
      });

      test('应正确生成带BYDAY的规则字符串', () {
        const rule = RecurrenceRule(
          frequency: Frequency.weekly,
          byDay: [WeekDay.monday, WeekDay.friday],
        );
        expect(rule.toRRuleString(), 'FREQ=WEEKLY;BYDAY=MO,FR');
      });

      test('应正确生成带BYSETPOS的规则字符串', () {
        const rule = RecurrenceRule(
          frequency: Frequency.monthly,
          byDay: [WeekDay.monday],
          bySetPos: [-1],
        );
        expect(rule.toRRuleString().contains('BYSETPOS=-1'), isTrue);
      });
    });

    group('getOccurrences', () {
      test('每日重复应正确生成实例', () {
        const rule = RecurrenceRule(frequency: Frequency.daily);
        final start = DateTime(2025, 1, 1);
        final rangeEnd = DateTime(2025, 1, 5);

        final occurrences = rule.getOccurrences(start, start, rangeEnd);

        expect(occurrences.length, 4); // 1, 2, 3, 4
        expect(occurrences[0], DateTime(2025, 1, 1));
        expect(occurrences[1], DateTime(2025, 1, 2));
        expect(occurrences[2], DateTime(2025, 1, 3));
        expect(occurrences[3], DateTime(2025, 1, 4));
      });

      test('每周重复应正确生成实例', () {
        const rule = RecurrenceRule(frequency: Frequency.weekly);
        final start = DateTime(2025, 1, 1); // 周三
        final rangeEnd = DateTime(2025, 1, 22);

        final occurrences = rule.getOccurrences(start, start, rangeEnd);

        expect(occurrences.length, 3); // 1/1, 1/8, 1/15
        expect(occurrences[0].day, 1);
        expect(occurrences[1].day, 8);
        expect(occurrences[2].day, 15);
      });

      test('带BYDAY的周重复应正确生成实例', () {
        const rule = RecurrenceRule(
          frequency: Frequency.weekly,
          byDay: [WeekDay.monday, WeekDay.wednesday, WeekDay.friday],
        );
        final start = DateTime(2025, 1, 1); // 周三
        final rangeEnd = DateTime(2025, 1, 8);

        final occurrences = rule.getOccurrences(start, start, rangeEnd);

        // 1/1(周三), 1/3(周五), 1/6(周一)
        expect(occurrences.isNotEmpty, isTrue);
      });

      test('应正确处理COUNT限制', () {
        const rule = RecurrenceRule(frequency: Frequency.daily, count: 3);
        final start = DateTime(2025, 1, 1);
        final rangeEnd = DateTime(2025, 1, 10);

        final occurrences = rule.getOccurrences(start, start, rangeEnd);

        expect(occurrences.length, 3);
      });

      test('应正确处理UNTIL限制', () {
        final rule = RecurrenceRule(
          frequency: Frequency.daily,
          until: DateTime(2025, 1, 3),
        );
        final start = DateTime(2025, 1, 1);
        final rangeEnd = DateTime(2025, 1, 10);

        final occurrences = rule.getOccurrences(start, start, rangeEnd);

        expect(occurrences.length, 3); // 1, 2, 3
      });

      test('应正确排除EXDATES', () {
        const rule = RecurrenceRule(frequency: Frequency.daily);
        final start = DateTime(2025, 1, 1);
        final rangeEnd = DateTime(2025, 1, 5);
        final excludeDates = [DateTime(2025, 1, 2), DateTime(2025, 1, 4)];

        final occurrences = rule.getOccurrences(
          start,
          start,
          rangeEnd,
          excludeDates: excludeDates,
        );

        expect(occurrences.length, 2); // 1, 3
        expect(occurrences[0].day, 1);
        expect(occurrences[1].day, 3);
      });

      test('每月重复应正确处理月末', () {
        const rule = RecurrenceRule(frequency: Frequency.monthly);
        final start = DateTime(2025, 1, 31); // 1月31日
        final rangeEnd = DateTime(2025, 5, 1); // 改为5月1日以确保包含4月的实例

        final occurrences = rule.getOccurrences(start, start, rangeEnd);

        // 1月31日、2月28日、3月31日、4月30日
        expect(occurrences.length, 4);
        expect(occurrences[0].day, 31); // 1月31日
        expect(occurrences[1].day, 28); // 2月28日（2025年非闰年）
        expect(occurrences[2].day, 31); // 3月31日
        expect(occurrences[3].day, 30); // 4月30日
      });

      test('每年重复应正确生成实例', () {
        const rule = RecurrenceRule(frequency: Frequency.yearly);
        final start = DateTime(2025, 6, 15);
        final rangeEnd = DateTime(2028, 1, 1);

        final occurrences = rule.getOccurrences(start, start, rangeEnd);

        expect(occurrences.length, 3); // 2025, 2026, 2027
      });
    });

    group('description', () {
      test('应正确生成每日描述', () {
        const rule = RecurrenceRule(frequency: Frequency.daily);
        expect(rule.description, '每天');
      });

      test('应正确生成每2天描述', () {
        const rule = RecurrenceRule(frequency: Frequency.daily, interval: 2);
        expect(rule.description, '每2天');
      });

      test('应正确生成带COUNT的描述', () {
        const rule = RecurrenceRule(frequency: Frequency.weekly, count: 5);
        expect(rule.description.contains('共5次'), isTrue);
      });

      test('应正确生成带星期的描述', () {
        const rule = RecurrenceRule(
          frequency: Frequency.weekly,
          byDay: [WeekDay.monday, WeekDay.friday],
        );
        expect(rule.description.contains('周一'), isTrue);
        expect(rule.description.contains('周五'), isTrue);
      });
    });

    group('copyWith', () {
      test('应正确复制并修改', () {
        const original = RecurrenceRule(
          frequency: Frequency.daily,
          interval: 1,
        );
        final copied = original.copyWith(interval: 2, count: 5);

        expect(copied.frequency, Frequency.daily);
        expect(copied.interval, 2);
        expect(copied.count, 5);
      });
    });

    group('equality', () {
      test('相同的规则应相等', () {
        const rule1 = RecurrenceRule(frequency: Frequency.daily, interval: 2);
        const rule2 = RecurrenceRule(frequency: Frequency.daily, interval: 2);

        expect(rule1, rule2);
      });

      test('不同的规则应不相等', () {
        const rule1 = RecurrenceRule(frequency: Frequency.daily);
        const rule2 = RecurrenceRule(frequency: Frequency.weekly);

        expect(rule1, isNot(rule2));
      });
    });
  });

  group('WeekDay', () {
    test('fromDayNumber应正确返回星期', () {
      expect(WeekDay.fromDayNumber(1), WeekDay.monday);
      expect(WeekDay.fromDayNumber(7), WeekDay.sunday);
      expect(WeekDay.fromDayNumber(0), isNull);
      expect(WeekDay.fromDayNumber(8), isNull);
    });

    test('fromRruleValue应正确返回星期', () {
      expect(WeekDay.fromRruleValue('MO'), WeekDay.monday);
      expect(WeekDay.fromRruleValue('SU'), WeekDay.sunday);
      expect(WeekDay.fromRruleValue('XX'), isNull);
    });
  });

  group('ByDayRule', () {
    test('fromString应正确解析简单星期', () {
      final rule = ByDayRule.fromString('MO');
      expect(rule, isNotNull);
      expect(rule!.weekDay, WeekDay.monday);
      expect(rule.position, isNull);
    });

    test('fromString应正确解析带位置的星期', () {
      final rule = ByDayRule.fromString('2TU');
      expect(rule, isNotNull);
      expect(rule!.weekDay, WeekDay.tuesday);
      expect(rule.position, 2);
    });

    test('fromString应正确解析负位置', () {
      final rule = ByDayRule.fromString('-1FR');
      expect(rule, isNotNull);
      expect(rule!.weekDay, WeekDay.friday);
      expect(rule.position, -1);
    });

    test('toString应正确生成字符串', () {
      const rule1 = ByDayRule(WeekDay.monday);
      expect(rule1.toString(), 'MO');

      const rule2 = ByDayRule(WeekDay.friday, 1);
      expect(rule2.toString(), '1FR');

      const rule3 = ByDayRule(WeekDay.wednesday, -1);
      expect(rule3.toString(), '-1WE');
    });
  });
}

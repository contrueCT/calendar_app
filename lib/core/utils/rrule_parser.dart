import '../../data/models/recurrence_rule.dart';

/// RRULE解析和计算的高级工具类
/// 支持RFC 5545完整的重复规则
class RRuleParser {
  RRuleParser._();

  /// 预设的常用重复规则
  static const Map<String, String> presets = {
    'daily': 'FREQ=DAILY',
    'weekly': 'FREQ=WEEKLY',
    'weekdays': 'FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR',
    'monthly': 'FREQ=MONTHLY',
    'yearly': 'FREQ=YEARLY',
  };

  /// 创建每天重复规则
  static RecurrenceRule daily({int interval = 1, int? count, DateTime? until}) {
    return RecurrenceRule(
      frequency: Frequency.daily,
      interval: interval,
      count: count,
      until: until,
    );
  }

  /// 创建每周重复规则
  static RecurrenceRule weekly({
    int interval = 1,
    List<WeekDay>? byDay,
    int? count,
    DateTime? until,
    WeekDay weekStart = WeekDay.monday,
  }) {
    return RecurrenceRule(
      frequency: Frequency.weekly,
      interval: interval,
      byDay: byDay,
      count: count,
      until: until,
      weekStart: weekStart,
    );
  }

  /// 创建每月重复规则（按日期）
  static RecurrenceRule monthlyByDate({
    int interval = 1,
    List<int>? byMonthDay,
    int? count,
    DateTime? until,
  }) {
    return RecurrenceRule(
      frequency: Frequency.monthly,
      interval: interval,
      byMonthDay: byMonthDay,
      count: count,
      until: until,
    );
  }

  /// 创建每月重复规则（按星期）
  /// 例如：每月第一个周一、每月最后一个周五
  static RecurrenceRule monthlyByWeekday({
    int interval = 1,
    required WeekDay weekday,
    required int position, // 1-5 表示第几个，-1 表示最后一个
    int? count,
    DateTime? until,
  }) {
    return RecurrenceRule(
      frequency: Frequency.monthly,
      interval: interval,
      byDay: [weekday],
      bySetPos: [position],
      count: count,
      until: until,
    );
  }

  /// 创建每年重复规则
  static RecurrenceRule yearly({
    int interval = 1,
    List<int>? byMonth,
    List<int>? byMonthDay,
    int? count,
    DateTime? until,
  }) {
    return RecurrenceRule(
      frequency: Frequency.yearly,
      interval: interval,
      byMonth: byMonth,
      byMonthDay: byMonthDay,
      count: count,
      until: until,
    );
  }

  /// 创建工作日重复规则
  static RecurrenceRule weekdays({int? count, DateTime? until}) {
    return RecurrenceRule(
      frequency: Frequency.weekly,
      byDay: [
        WeekDay.monday,
        WeekDay.tuesday,
        WeekDay.wednesday,
        WeekDay.thursday,
        WeekDay.friday,
      ],
      count: count,
      until: until,
    );
  }

  /// 验证RRULE字符串格式
  static bool isValidRRule(String rrule) {
    if (rrule.isEmpty) return false;

    String ruleString = rrule;
    if (ruleString.toUpperCase().startsWith('RRULE:')) {
      ruleString = ruleString.substring(6);
    }

    // 必须包含FREQ
    if (!ruleString.toUpperCase().contains('FREQ=')) {
      return false;
    }

    // 尝试解析
    final rule = RecurrenceRule.fromRRuleString(rrule);
    return rule != null;
  }

  /// 获取规则的人类可读描述
  static String getDescription(String rrule, {String locale = 'zh'}) {
    final rule = RecurrenceRule.fromRRuleString(rrule);
    if (rule == null) return '无效的重复规则';
    return rule.description;
  }

  /// 计算从开始日期起的第N个实例日期
  static DateTime? getNthOccurrence(
    String rrule,
    DateTime eventStart,
    int n, {
    List<DateTime>? excludeDates,
  }) {
    if (n <= 0) return null;

    final rule = RecurrenceRule.fromRRuleString(rrule);
    if (rule == null) return null;

    DateTime current = eventStart;
    int count = 0;
    final maxIterations = 10000; // 安全限制
    int iterations = 0;

    while (iterations < maxIterations) {
      // 检查是否超过UNTIL
      if (rule.until != null && current.isAfter(rule.until!)) {
        return null;
      }

      // 检查是否超过COUNT
      if (rule.count != null && count >= rule.count!) {
        return null;
      }

      // 检查是否被排除
      final isExcluded =
          excludeDates?.any(
            (date) =>
                date.year == current.year &&
                date.month == current.month &&
                date.day == current.day,
          ) ??
          false;

      if (!isExcluded) {
        count++;
        if (count == n) {
          return current;
        }
      }

      // 计算下一个实例
      current = _getNextOccurrenceInternal(rule, current, eventStart);
      iterations++;
    }

    return null;
  }

  /// 判断指定日期是否是该规则的一个实例
  static bool isOccurrenceDate(
    String rrule,
    DateTime eventStart,
    DateTime targetDate, {
    List<DateTime>? excludeDates,
  }) {
    final rule = RecurrenceRule.fromRRuleString(rrule);
    if (rule == null) return false;

    // 检查是否被排除
    final isExcluded =
        excludeDates?.any(
          (date) =>
              date.year == targetDate.year &&
              date.month == targetDate.month &&
              date.day == targetDate.day,
        ) ??
        false;
    if (isExcluded) return false;

    // 如果目标日期早于开始日期，返回false
    if (targetDate.isBefore(eventStart)) return false;

    // 检查UNTIL
    if (rule.until != null && targetDate.isAfter(rule.until!)) {
      return false;
    }

    // 获取该日期范围内的所有实例
    final startOfDay = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
    );
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final occurrences = rule.getOccurrences(
      eventStart,
      startOfDay,
      endOfDay,
      excludeDates: excludeDates,
    );

    return occurrences.any(
      (date) =>
          date.year == targetDate.year &&
          date.month == targetDate.month &&
          date.day == targetDate.day,
    );
  }

  /// 计算两个日期之间的实例数量
  static int countOccurrencesInRange(
    String rrule,
    DateTime eventStart,
    DateTime rangeStart,
    DateTime rangeEnd, {
    List<DateTime>? excludeDates,
  }) {
    final rule = RecurrenceRule.fromRRuleString(rrule);
    if (rule == null) return 0;

    final occurrences = rule.getOccurrences(
      eventStart,
      rangeStart,
      rangeEnd,
      excludeDates: excludeDates,
    );

    return occurrences.length;
  }

  /// 内部方法：获取下一个实例日期
  static DateTime _getNextOccurrenceInternal(
    RecurrenceRule rule,
    DateTime current,
    DateTime eventStart,
  ) {
    switch (rule.frequency) {
      case Frequency.daily:
        return current.add(Duration(days: rule.interval));

      case Frequency.weekly:
        if (rule.byDay != null && rule.byDay!.isNotEmpty) {
          // 查找下一个符合的星期
          DateTime next = current.add(const Duration(days: 1));
          int daysChecked = 0;
          while (daysChecked < 7 * rule.interval) {
            final weekDay = WeekDay.fromDayNumber(next.weekday);
            if (weekDay != null && rule.byDay!.contains(weekDay)) {
              return next;
            }
            next = next.add(const Duration(days: 1));
            daysChecked++;
          }
          return next;
        }
        return current.add(Duration(days: 7 * rule.interval));

      case Frequency.monthly:
        if (rule.bySetPos != null &&
            rule.bySetPos!.isNotEmpty &&
            rule.byDay != null &&
            rule.byDay!.isNotEmpty) {
          // 处理"每月第N个星期X"的情况
          return _getNextMonthlyBySetPos(rule, current, eventStart);
        }

        DateTime next = DateTime(
          current.year,
          current.month + rule.interval,
          current.day,
          eventStart.hour,
          eventStart.minute,
        );
        // 处理月末日期
        final lastDay = DateTime(next.year, next.month + 1, 0).day;
        if (next.day > lastDay) {
          next = DateTime(
            next.year,
            next.month,
            lastDay,
            eventStart.hour,
            eventStart.minute,
          );
        }
        return next;

      case Frequency.yearly:
        return DateTime(
          current.year + rule.interval,
          eventStart.month,
          eventStart.day,
          eventStart.hour,
          eventStart.minute,
        );
    }
  }

  /// 处理每月按BYSETPOS的计算
  static DateTime _getNextMonthlyBySetPos(
    RecurrenceRule rule,
    DateTime current,
    DateTime eventStart,
  ) {
    final weekday = rule.byDay!.first;
    final position = rule.bySetPos!.first;

    // 从下个月开始查找
    int year = current.year;
    int month = current.month + rule.interval;
    if (month > 12) {
      year++;
      month -= 12;
    }

    final targetDate = _getNthWeekdayOfMonth(
      year,
      month,
      weekday.dayNumber,
      position,
    );
    if (targetDate != null) {
      return DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day,
        eventStart.hour,
        eventStart.minute,
      );
    }

    // 如果该月没有符合条件的日期，尝试下个月
    month++;
    if (month > 12) {
      year++;
      month = 1;
    }
    final fallbackDate = _getNthWeekdayOfMonth(
      year,
      month,
      weekday.dayNumber,
      position,
    );
    return fallbackDate != null
        ? DateTime(
            fallbackDate.year,
            fallbackDate.month,
            fallbackDate.day,
            eventStart.hour,
            eventStart.minute,
          )
        : current.add(Duration(days: 30 * rule.interval));
  }

  /// 获取某年某月的第N个星期几
  static DateTime? _getNthWeekdayOfMonth(
    int year,
    int month,
    int weekday,
    int n,
  ) {
    if (n == 0) return null;

    if (n > 0) {
      // 正数：从月初开始找
      final firstDay = DateTime(year, month, 1);
      int daysToAdd = (weekday - firstDay.weekday + 7) % 7;
      DateTime result = firstDay.add(Duration(days: daysToAdd));
      result = result.add(Duration(days: (n - 1) * 7));

      // 检查是否仍在同一月
      if (result.month != month) return null;
      return result;
    } else {
      // 负数：从月末开始找
      final lastDay = DateTime(year, month + 1, 0);
      int daysToSubtract = (lastDay.weekday - weekday + 7) % 7;
      DateTime result = lastDay.subtract(Duration(days: daysToSubtract));
      result = result.subtract(Duration(days: (-n - 1) * 7));

      // 检查是否仍在同一月
      if (result.month != month) return null;
      return result;
    }
  }
}

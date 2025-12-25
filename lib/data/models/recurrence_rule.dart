/// 重复频率枚举
enum Frequency {
  daily('DAILY', '每天'),
  weekly('WEEKLY', '每周'),
  monthly('MONTHLY', '每月'),
  yearly('YEARLY', '每年');

  final String value;
  final String label;

  const Frequency(this.value, this.label);

  static Frequency? fromString(String value) {
    for (final freq in Frequency.values) {
      if (freq.value == value) return freq;
    }
    return null;
  }
}

/// 星期枚举
enum WeekDay {
  monday(1, 'MO', '周一'),
  tuesday(2, 'TU', '周二'),
  wednesday(3, 'WE', '周三'),
  thursday(4, 'TH', '周四'),
  friday(5, 'FR', '周五'),
  saturday(6, 'SA', '周六'),
  sunday(7, 'SU', '周日');

  final int dayNumber;
  final String rruleValue;
  final String label;

  const WeekDay(this.dayNumber, this.rruleValue, this.label);

  static WeekDay? fromDayNumber(int dayNumber) {
    for (final day in WeekDay.values) {
      if (day.dayNumber == dayNumber) return day;
    }
    return null;
  }

  static WeekDay? fromRruleValue(String value) {
    for (final day in WeekDay.values) {
      if (day.rruleValue == value) return day;
    }
    return null;
  }
}

/// 带有位置前缀的星期规则（如 "1MO" 表示第一个周一）
class ByDayRule {
  final WeekDay weekDay;
  final int? position; // null表示每周，1-5表示第几个，-1表示倒数第一个

  const ByDayRule(this.weekDay, [this.position]);

  /// 从RRULE字符串解析（如 "1MO", "-1FR", "MO"）
  static ByDayRule? fromString(String value) {
    final match = RegExp(
      r'^(-?\d+)?([A-Z]{2})$',
    ).firstMatch(value.toUpperCase());
    if (match == null) return null;

    final posStr = match.group(1);
    final dayStr = match.group(2)!;

    final weekDay = WeekDay.fromRruleValue(dayStr);
    if (weekDay == null) return null;

    final position = posStr != null ? int.tryParse(posStr) : null;
    return ByDayRule(weekDay, position);
  }

  @override
  String toString() {
    if (position != null) {
      return '$position${weekDay.rruleValue}';
    }
    return weekDay.rruleValue;
  }
}

/// 重复规则模型
class RecurrenceRule {
  final Frequency frequency;
  final int interval;
  final int? count;
  final DateTime? until;
  final List<WeekDay>? byDay;
  final List<ByDayRule>? byDayRules; // 带位置的星期规则
  final List<int>? byMonthDay;
  final List<int>? byMonth;
  final List<int>? bySetPos; // 在集合中的位置（如每月最后一个周五用 BYDAY=FR;BYSETPOS=-1）
  final List<int>? byYearDay;
  final List<int>? byWeekNo;
  final WeekDay weekStart;

  const RecurrenceRule({
    required this.frequency,
    this.interval = 1,
    this.count,
    this.until,
    this.byDay,
    this.byDayRules,
    this.byMonthDay,
    this.byMonth,
    this.bySetPos,
    this.byYearDay,
    this.byWeekNo,
    this.weekStart = WeekDay.monday,
  });

  /// 从RRULE字符串解析
  static RecurrenceRule? fromRRuleString(String rrule) {
    if (rrule.isEmpty) return null;

    // 移除 "RRULE:" 前缀（如果有）
    String ruleString = rrule;
    if (ruleString.toUpperCase().startsWith('RRULE:')) {
      ruleString = ruleString.substring(6);
    }

    final parts = ruleString.split(';');
    final Map<String, String> params = {};

    for (final part in parts) {
      final keyValue = part.split('=');
      if (keyValue.length == 2) {
        params[keyValue[0].toUpperCase()] = keyValue[1];
      }
    }

    // 解析频率（必需）
    final freqStr = params['FREQ'];
    if (freqStr == null) return null;

    final frequency = Frequency.fromString(freqStr);
    if (frequency == null) return null;

    // 解析间隔
    final interval = int.tryParse(params['INTERVAL'] ?? '1') ?? 1;

    // 解析次数
    final count = params['COUNT'] != null
        ? int.tryParse(params['COUNT']!)
        : null;

    // 解析结束日期
    DateTime? until;
    if (params['UNTIL'] != null) {
      until = _parseDateTime(params['UNTIL']!);
    }

    // 解析星期
    List<WeekDay>? byDay;
    List<ByDayRule>? byDayRules;
    if (params['BYDAY'] != null) {
      final parsed = _parseByDayWithPosition(params['BYDAY']!);
      byDay = parsed.$1;
      byDayRules = parsed.$2;
    }

    // 解析月中日期
    List<int>? byMonthDay;
    if (params['BYMONTHDAY'] != null) {
      byMonthDay = params['BYMONTHDAY']!
          .split(',')
          .map((e) => int.parse(e.trim()))
          .toList();
    }

    // 解析月份
    List<int>? byMonth;
    if (params['BYMONTH'] != null) {
      byMonth = params['BYMONTH']!
          .split(',')
          .map((e) => int.parse(e.trim()))
          .toList();
    }

    // 解析BYSETPOS
    List<int>? bySetPos;
    if (params['BYSETPOS'] != null) {
      bySetPos = params['BYSETPOS']!
          .split(',')
          .map((e) => int.parse(e.trim()))
          .toList();
    }

    // 解析BYYEARDAY
    List<int>? byYearDay;
    if (params['BYYEARDAY'] != null) {
      byYearDay = params['BYYEARDAY']!
          .split(',')
          .map((e) => int.parse(e.trim()))
          .toList();
    }

    // 解析BYWEEKNO
    List<int>? byWeekNo;
    if (params['BYWEEKNO'] != null) {
      byWeekNo = params['BYWEEKNO']!
          .split(',')
          .map((e) => int.parse(e.trim()))
          .toList();
    }

    // 解析周起始日
    WeekDay weekStart = WeekDay.monday;
    if (params['WKST'] != null) {
      weekStart = WeekDay.fromRruleValue(params['WKST']!) ?? WeekDay.monday;
    }

    return RecurrenceRule(
      frequency: frequency,
      interval: interval,
      count: count,
      until: until,
      byDay: byDay,
      byDayRules: byDayRules,
      byMonthDay: byMonthDay,
      byMonth: byMonth,
      bySetPos: bySetPos,
      byYearDay: byYearDay,
      byWeekNo: byWeekNo,
      weekStart: weekStart,
    );
  }

  /// 转换为RRULE字符串
  String toRRuleString() {
    final parts = <String>[];

    parts.add('FREQ=${frequency.value}');

    if (interval != 1) {
      parts.add('INTERVAL=$interval');
    }

    if (count != null) {
      parts.add('COUNT=$count');
    }

    if (until != null) {
      parts.add('UNTIL=${_formatDateTime(until!)}');
    }

    // 优先使用带位置的规则
    if (byDayRules != null && byDayRules!.isNotEmpty) {
      parts.add('BYDAY=${byDayRules!.map((r) => r.toString()).join(',')}');
    } else if (byDay != null && byDay!.isNotEmpty) {
      parts.add('BYDAY=${byDay!.map((d) => d.rruleValue).join(',')}');
    }

    if (byMonthDay != null && byMonthDay!.isNotEmpty) {
      parts.add('BYMONTHDAY=${byMonthDay!.join(',')}');
    }

    if (byMonth != null && byMonth!.isNotEmpty) {
      parts.add('BYMONTH=${byMonth!.join(',')}');
    }

    if (bySetPos != null && bySetPos!.isNotEmpty) {
      parts.add('BYSETPOS=${bySetPos!.join(',')}');
    }

    if (byYearDay != null && byYearDay!.isNotEmpty) {
      parts.add('BYYEARDAY=${byYearDay!.join(',')}');
    }

    if (byWeekNo != null && byWeekNo!.isNotEmpty) {
      parts.add('BYWEEKNO=${byWeekNo!.join(',')}');
    }

    if (weekStart != WeekDay.monday) {
      parts.add('WKST=${weekStart.rruleValue}');
    }

    return parts.join(';');
  }

  /// 获取规则描述文本
  String get description {
    String desc = '';

    switch (frequency) {
      case Frequency.daily:
        desc = interval == 1 ? '每天' : '每$interval天';
        break;
      case Frequency.weekly:
        desc = interval == 1 ? '每周' : '每$interval周';
        if (byDay != null && byDay!.isNotEmpty) {
          desc += '（${byDay!.map((d) => d.label).join('、')}）';
        }
        break;
      case Frequency.monthly:
        desc = interval == 1 ? '每月' : '每$interval个月';
        if (byMonthDay != null && byMonthDay!.isNotEmpty) {
          desc += '（${byMonthDay!.map((d) => '$d日').join('、')}）';
        }
        break;
      case Frequency.yearly:
        desc = interval == 1 ? '每年' : '每$interval年';
        break;
    }

    if (count != null) {
      desc += '，共$count次';
    } else if (until != null) {
      desc += '，直到${until!.year}年${until!.month}月${until!.day}日';
    }

    return desc;
  }

  /// 获取指定范围内的所有重复实例日期
  List<DateTime> getOccurrences(
    DateTime eventStart,
    DateTime rangeStart,
    DateTime rangeEnd, {
    List<DateTime>? excludeDates,
  }) {
    final occurrences = <DateTime>[];
    DateTime current = eventStart;
    int occurrenceCount = 0;
    final maxOccurrences = count ?? 1000; // 防止无限循环

    while (current.isBefore(rangeEnd) && occurrenceCount < maxOccurrences) {
      // 检查是否超过结束日期
      if (until != null && current.isAfter(until!)) {
        break;
      }

      // 检查是否在范围内
      if (!current.isBefore(rangeStart)) {
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
          occurrences.add(current);
        }
      }

      // 计算下一个实例
      current = _getNextOccurrence(current, eventStart);
      occurrenceCount++;
    }

    return occurrences;
  }

  DateTime _getNextOccurrence(DateTime current, DateTime eventStart) {
    switch (frequency) {
      case Frequency.daily:
        return current.add(Duration(days: interval));

      case Frequency.weekly:
        if (byDay != null && byDay!.isNotEmpty) {
          // 查找下一个符合的星期
          DateTime next = current.add(const Duration(days: 1));
          int daysChecked = 0;
          while (daysChecked < 7 * interval) {
            final weekDay = WeekDay.fromDayNumber(next.weekday);
            if (weekDay != null && byDay!.contains(weekDay)) {
              return next;
            }
            next = next.add(const Duration(days: 1));
            daysChecked++;
          }
          return next;
        }
        return current.add(Duration(days: 7 * interval));

      case Frequency.monthly:
        // 使用原始事件的日期，而不是当前实例的日期
        final targetDay = eventStart.day;
        int newMonth = current.month + interval;
        int newYear = current.year;

        // 处理年份进位
        while (newMonth > 12) {
          newMonth -= 12;
          newYear++;
        }

        // 处理月末日期：如果目标日期超过该月天数，使用该月最后一天
        final lastDay = DateTime(newYear, newMonth + 1, 0).day;
        final actualDay = targetDay > lastDay ? lastDay : targetDay;

        return DateTime(
          newYear,
          newMonth,
          actualDay,
          eventStart.hour,
          eventStart.minute,
        );

      case Frequency.yearly:
        return DateTime(
          current.year + interval,
          eventStart.month,
          eventStart.day,
          eventStart.hour,
          eventStart.minute,
        );
    }
  }

  /// 复制并修改
  RecurrenceRule copyWith({
    Frequency? frequency,
    int? interval,
    int? count,
    DateTime? until,
    List<WeekDay>? byDay,
    List<ByDayRule>? byDayRules,
    List<int>? byMonthDay,
    List<int>? byMonth,
    List<int>? bySetPos,
    List<int>? byYearDay,
    List<int>? byWeekNo,
    WeekDay? weekStart,
  }) {
    return RecurrenceRule(
      frequency: frequency ?? this.frequency,
      interval: interval ?? this.interval,
      count: count ?? this.count,
      until: until ?? this.until,
      byDay: byDay ?? this.byDay,
      byDayRules: byDayRules ?? this.byDayRules,
      byMonthDay: byMonthDay ?? this.byMonthDay,
      byMonth: byMonth ?? this.byMonth,
      bySetPos: bySetPos ?? this.bySetPos,
      byYearDay: byYearDay ?? this.byYearDay,
      byWeekNo: byWeekNo ?? this.byWeekNo,
      weekStart: weekStart ?? this.weekStart,
    );
  }

  static DateTime? _parseDateTime(String dateStr) {
    try {
      // 格式: YYYYMMDD 或 YYYYMMDDTHHmmssZ
      if (dateStr.length == 8) {
        return DateTime(
          int.parse(dateStr.substring(0, 4)),
          int.parse(dateStr.substring(4, 6)),
          int.parse(dateStr.substring(6, 8)),
        );
      } else if (dateStr.length >= 15) {
        final isUtc = dateStr.endsWith('Z');
        final dt = DateTime(
          int.parse(dateStr.substring(0, 4)),
          int.parse(dateStr.substring(4, 6)),
          int.parse(dateStr.substring(6, 8)),
          int.parse(dateStr.substring(9, 11)),
          int.parse(dateStr.substring(11, 13)),
          int.parse(dateStr.substring(13, 15)),
        );
        return isUtc ? dt.toLocal() : dt;
      }
    } catch (e) {
      // 解析失败返回null
    }
    return null;
  }

  static String _formatDateTime(DateTime dt) {
    final utc = dt.toUtc();
    return '${utc.year.toString().padLeft(4, '0')}'
        '${utc.month.toString().padLeft(2, '0')}'
        '${utc.day.toString().padLeft(2, '0')}T'
        '${utc.hour.toString().padLeft(2, '0')}'
        '${utc.minute.toString().padLeft(2, '0')}'
        '${utc.second.toString().padLeft(2, '0')}Z';
  }

  /// 解析BYDAY，同时返回简单星期列表和带位置的规则列表
  static (List<WeekDay>, List<ByDayRule>?) _parseByDayWithPosition(
    String byDayStr,
  ) {
    final days = <WeekDay>[];
    final rules = <ByDayRule>[];
    bool hasPosition = false;

    final parts = byDayStr.split(',');
    for (final part in parts) {
      final trimmed = part.trim();
      final rule = ByDayRule.fromString(trimmed);
      if (rule != null) {
        days.add(rule.weekDay);
        rules.add(rule);
        if (rule.position != null) {
          hasPosition = true;
        }
      }
    }

    return (days, hasPosition ? rules : null);
  }

  @override
  String toString() => 'RecurrenceRule(${toRRuleString()})';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RecurrenceRule && toRRuleString() == other.toRRuleString();
  }

  @override
  int get hashCode => toRRuleString().hashCode;
}

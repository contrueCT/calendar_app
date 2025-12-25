import 'package:intl/intl.dart';

/// 日期工具类
class DateTimeUtils {
  DateTimeUtils._();

  /// 获取一天的开始时间（00:00:00）
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// 获取一天的结束时间（23:59:59.999）
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  /// 获取一周的开始（周一）
  static DateTime startOfWeek(
    DateTime date, {
    int weekStartsOn = DateTime.monday,
  }) {
    final daysToSubtract = (date.weekday - weekStartsOn + 7) % 7;
    return startOfDay(date.subtract(Duration(days: daysToSubtract)));
  }

  /// 获取一周的结束（周日）
  static DateTime endOfWeek(
    DateTime date, {
    int weekStartsOn = DateTime.monday,
  }) {
    final start = startOfWeek(date, weekStartsOn: weekStartsOn);
    return endOfDay(start.add(const Duration(days: 6)));
  }

  /// 获取月份的第一天
  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// 获取月份的最后一天
  static DateTime endOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0, 23, 59, 59, 999);
  }

  /// 获取年份的第一天
  static DateTime startOfYear(DateTime date) {
    return DateTime(date.year, 1, 1);
  }

  /// 获取年份的最后一天
  static DateTime endOfYear(DateTime date) {
    return DateTime(date.year, 12, 31, 23, 59, 59, 999);
  }

  /// 判断两个日期是否是同一天
  static bool isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// 判断两个日期是否是同一周
  static bool isSameWeek(
    DateTime a,
    DateTime b, {
    int weekStartsOn = DateTime.monday,
  }) {
    final startA = startOfWeek(a, weekStartsOn: weekStartsOn);
    final startB = startOfWeek(b, weekStartsOn: weekStartsOn);
    return isSameDay(startA, startB);
  }

  /// 判断两个日期是否是同一月
  static bool isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  /// 判断日期是否在范围内（包含边界）
  static bool isInRange(DateTime date, DateTime start, DateTime end) {
    return !date.isBefore(start) && !date.isAfter(end);
  }

  /// 获取两个日期之间的天数
  static int daysBetween(DateTime start, DateTime end) {
    final startDate = startOfDay(start);
    final endDate = startOfDay(end);
    return endDate.difference(startDate).inDays;
  }

  /// 获取月份的天数
  static int daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  /// 获取某年某月的第n个星期几
  /// weekday: 1-7 (周一到周日)
  /// n: 正数表示第n个，负数表示倒数第n个
  static DateTime? getNthWeekdayOfMonth(
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

  /// 增加月份（正确处理月末）
  static DateTime addMonths(DateTime date, int months) {
    int newYear = date.year;
    int newMonth = date.month + months;

    while (newMonth > 12) {
      newYear++;
      newMonth -= 12;
    }
    while (newMonth < 1) {
      newYear--;
      newMonth += 12;
    }

    final maxDay = daysInMonth(newYear, newMonth);
    final day = date.day > maxDay ? maxDay : date.day;

    return DateTime(
      newYear,
      newMonth,
      day,
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
    );
  }

  /// 增加年份
  static DateTime addYears(DateTime date, int years) {
    return addMonths(date, years * 12);
  }

  /// 格式化日期 - 仅日期
  static String formatDate(DateTime date, {String? locale}) {
    return DateFormat.yMMMd(locale).format(date);
  }

  /// 格式化日期 - 含时间
  static String formatDateTime(DateTime date, {String? locale}) {
    return DateFormat.yMMMd(locale).add_Hm().format(date);
  }

  /// 格式化时间
  static String formatTime(DateTime date, {String? locale}) {
    return DateFormat.Hm(locale).format(date);
  }

  /// 格式化为相对时间
  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        if (diff.inMinutes == 0) {
          return '刚刚';
        }
        return '${diff.inMinutes}分钟前';
      }
      return '${diff.inHours}小时前';
    } else if (diff.inDays == 1) {
      return '昨天';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}天前';
    } else if (diff.inDays < 30) {
      return '${diff.inDays ~/ 7}周前';
    } else if (diff.inDays < 365) {
      return '${diff.inDays ~/ 30}个月前';
    } else {
      return '${diff.inDays ~/ 365}年前';
    }
  }

  /// 解析iCalendar日期时间字符串
  static DateTime? parseICalDateTime(String dateStr) {
    try {
      // 格式: YYYYMMDD 或 YYYYMMDDTHHmmss 或 YYYYMMDDTHHmmssZ
      final cleanStr = dateStr.replaceAll('-', '').replaceAll(':', '');

      if (cleanStr.length == 8) {
        // 仅日期格式 YYYYMMDD
        return DateTime(
          int.parse(cleanStr.substring(0, 4)),
          int.parse(cleanStr.substring(4, 6)),
          int.parse(cleanStr.substring(6, 8)),
        );
      } else if (cleanStr.length >= 15) {
        // 带时间格式
        final isUtc = cleanStr.endsWith('Z');
        final timeStr = isUtc
            ? cleanStr.substring(0, cleanStr.length - 1)
            : cleanStr;

        final year = int.parse(timeStr.substring(0, 4));
        final month = int.parse(timeStr.substring(4, 6));
        final day = int.parse(timeStr.substring(6, 8));
        final hour = int.parse(timeStr.substring(9, 11));
        final minute = int.parse(timeStr.substring(11, 13));
        final second = int.parse(timeStr.substring(13, 15));

        final dt = DateTime(year, month, day, hour, minute, second);
        return isUtc ? dt.toLocal() : dt;
      }
    } catch (e) {
      // 解析失败
    }
    return null;
  }

  /// 格式化为iCalendar日期时间字符串（UTC）
  static String toICalDateTime(DateTime date, {bool dateOnly = false}) {
    final utc = date.toUtc();

    if (dateOnly) {
      return '${utc.year.toString().padLeft(4, '0')}'
          '${utc.month.toString().padLeft(2, '0')}'
          '${utc.day.toString().padLeft(2, '0')}';
    }

    return '${utc.year.toString().padLeft(4, '0')}'
        '${utc.month.toString().padLeft(2, '0')}'
        '${utc.day.toString().padLeft(2, '0')}T'
        '${utc.hour.toString().padLeft(2, '0')}'
        '${utc.minute.toString().padLeft(2, '0')}'
        '${utc.second.toString().padLeft(2, '0')}Z';
  }

  /// 获取今天零点
  static DateTime get today => startOfDay(DateTime.now());

  /// 获取明天零点
  static DateTime get tomorrow => today.add(const Duration(days: 1));

  /// 获取昨天零点
  static DateTime get yesterday => today.subtract(const Duration(days: 1));

  /// 获取本周一
  static DateTime get thisWeekMonday => startOfWeek(DateTime.now());

  /// 获取本月第一天
  static DateTime get thisMonthStart => startOfMonth(DateTime.now());
}

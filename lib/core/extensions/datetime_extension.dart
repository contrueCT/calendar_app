import 'package:intl/intl.dart';

/// DateTime 扩展方法
extension DateTimeExtension on DateTime {
  /// 获取当天的开始时间 (00:00:00)
  DateTime get startOfDay => DateTime(year, month, day);

  /// 获取当天的结束时间 (23:59:59.999)
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);

  /// 获取当周的开始时间（周一）
  DateTime get startOfWeek {
    final diff = weekday - DateTime.monday;
    return subtract(Duration(days: diff)).startOfDay;
  }

  /// 获取当周的结束时间（周日）
  DateTime get endOfWeek {
    final diff = DateTime.sunday - weekday;
    return add(Duration(days: diff)).endOfDay;
  }

  /// 获取当月的开始时间
  DateTime get startOfMonth => DateTime(year, month, 1);

  /// 获取当月的结束时间
  DateTime get endOfMonth => DateTime(year, month + 1, 0, 23, 59, 59, 999);

  /// 判断是否是同一天
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  /// 判断是否是同一周
  bool isSameWeek(DateTime other) {
    return startOfWeek.isSameDay(other.startOfWeek);
  }

  /// 判断是否是同一月
  bool isSameMonth(DateTime other) {
    return year == other.year && month == other.month;
  }

  /// 判断是否是今天
  bool get isToday => isSameDay(DateTime.now());

  /// 判断是否是明天
  bool get isTomorrow => isSameDay(DateTime.now().add(const Duration(days: 1)));

  /// 判断是否是昨天
  bool get isYesterday =>
      isSameDay(DateTime.now().subtract(const Duration(days: 1)));

  /// 判断是否是周末
  bool get isWeekend =>
      weekday == DateTime.saturday || weekday == DateTime.sunday;

  /// 格式化为日期字符串 (yyyy-MM-dd)
  String toDateString() => DateFormat('yyyy-MM-dd').format(this);

  /// 格式化为时间字符串 (HH:mm)
  String toTimeString() => DateFormat('HH:mm').format(this);

  /// 格式化为完整日期时间字符串 (yyyy-MM-dd HH:mm)
  String toDateTimeString() => DateFormat('yyyy-MM-dd HH:mm').format(this);

  /// 格式化为友好的日期字符串
  String toFriendlyDateString() {
    if (isToday) return '今天';
    if (isTomorrow) return '明天';
    if (isYesterday) return '昨天';

    final now = DateTime.now();
    if (year == now.year) {
      return DateFormat('M月d日').format(this);
    }
    return DateFormat('yyyy年M月d日').format(this);
  }

  /// 格式化为友好的日期时间字符串
  String toFriendlyDateTimeString() {
    return '${toFriendlyDateString()} ${toTimeString()}';
  }

  /// 获取星期几的中文名称
  String get weekdayName {
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return weekdays[weekday - 1];
  }

  /// 复制并修改部分字段
  DateTime copyWith({
    int? year,
    int? month,
    int? day,
    int? hour,
    int? minute,
    int? second,
    int? millisecond,
    int? microsecond,
  }) {
    return DateTime(
      year ?? this.year,
      month ?? this.month,
      day ?? this.day,
      hour ?? this.hour,
      minute ?? this.minute,
      second ?? this.second,
      millisecond ?? this.millisecond,
      microsecond ?? this.microsecond,
    );
  }

  /// 添加指定天数
  DateTime addDays(int days) => add(Duration(days: days));

  /// 添加指定月数
  DateTime addMonths(int months) {
    var newYear = year;
    var newMonth = month + months;

    while (newMonth > 12) {
      newYear++;
      newMonth -= 12;
    }
    while (newMonth < 1) {
      newYear--;
      newMonth += 12;
    }

    final lastDayOfMonth = DateTime(newYear, newMonth + 1, 0).day;
    final newDay = day > lastDayOfMonth ? lastDayOfMonth : day;

    return DateTime(
      newYear,
      newMonth,
      newDay,
      hour,
      minute,
      second,
      millisecond,
      microsecond,
    );
  }

  /// 添加指定年数
  DateTime addYears(int years) => copyWith(year: year + years);

  /// 转换为UTC时间戳（毫秒）
  int toUtcMilliseconds() => toUtc().millisecondsSinceEpoch;

  /// 从UTC时间戳创建DateTime
  static DateTime fromUtcMilliseconds(int milliseconds) {
    return DateTime.fromMillisecondsSinceEpoch(
      milliseconds,
      isUtc: true,
    ).toLocal();
  }
}

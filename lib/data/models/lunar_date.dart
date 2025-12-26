import 'package:lunar/lunar.dart';

/// 农历日期模型
class LunarDate {
  final int year; // 农历年
  final int month; // 农历月
  final int day; // 农历日
  final bool isLeapMonth; // 是否闰月
  final String yearGanZhi; // 年干支
  final String monthGanZhi; // 月干支
  final String dayGanZhi; // 日干支
  final String zodiac; // 生肖
  final String? solarTerm; // 节气
  final List<String> lunarFestivals; // 农历节日
  final List<String> solarFestivals; // 公历节日

  const LunarDate({
    required this.year,
    required this.month,
    required this.day,
    this.isLeapMonth = false,
    required this.yearGanZhi,
    required this.monthGanZhi,
    required this.dayGanZhi,
    required this.zodiac,
    this.solarTerm,
    this.lunarFestivals = const [],
    this.solarFestivals = const [],
  });

  /// 从公历日期创建农历日期
  factory LunarDate.fromDateTime(DateTime date) {
    final lunar = Lunar.fromDate(date);
    final solar = Solar.fromDate(date);

    return LunarDate(
      year: lunar.getYear(),
      month: lunar.getMonth().abs(),
      day: lunar.getDay(),
      isLeapMonth: lunar.getMonth() < 0,
      yearGanZhi: lunar.getYearInGanZhi(),
      monthGanZhi: lunar.getMonthInGanZhi(),
      dayGanZhi: lunar.getDayInGanZhi(),
      zodiac: lunar.getYearShengXiao(),
      solarTerm: lunar.getJieQi().isNotEmpty ? lunar.getJieQi() : null,
      lunarFestivals: lunar.getFestivals(),
      solarFestivals: solar.getFestivals(),
    );
  }

  /// 获取农历月份中文名
  String get monthInChinese {
    const months = ['正', '二', '三', '四', '五', '六', '七', '八', '九', '十', '冬', '腊'];
    final prefix = isLeapMonth ? '闰' : '';
    // 边界检查
    if (month < 1 || month > 12) return '?月';
    return '$prefix${months[month - 1]}月';
  }

  /// 获取农历日期中文名
  String get dayInChinese {
    const days = [
      '初一',
      '初二',
      '初三',
      '初四',
      '初五',
      '初六',
      '初七',
      '初八',
      '初九',
      '初十',
      '十一',
      '十二',
      '十三',
      '十四',
      '十五',
      '十六',
      '十七',
      '十八',
      '十九',
      '二十',
      '廿一',
      '廿二',
      '廿三',
      '廿四',
      '廿五',
      '廿六',
      '廿七',
      '廿八',
      '廿九',
      '三十',
    ];
    // 边界检查
    if (day < 1 || day > 30) return '?';
    return days[day - 1];
  }

  /// 获取显示文本（优先级：节气 > 农历节日 > 公历节日 > 农历日期）
  String get displayText {
    // 节气优先
    if (solarTerm != null && solarTerm!.isNotEmpty) {
      return solarTerm!;
    }

    // 农历节日
    if (lunarFestivals.isNotEmpty) {
      return lunarFestivals.first;
    }

    // 公历节日
    if (solarFestivals.isNotEmpty) {
      return solarFestivals.first;
    }

    // 初一显示月份，其他显示日期
    if (day == 1) {
      return monthInChinese;
    }

    return dayInChinese;
  }

  /// 判断是否是节假日
  bool get isHoliday {
    return lunarFestivals.isNotEmpty || solarFestivals.isNotEmpty;
  }

  /// 判断是否是节气
  bool get isSolarTerm {
    return solarTerm != null && solarTerm!.isNotEmpty;
  }

  /// 获取完整的农历日期字符串
  String get fullDateString {
    return '$yearGanZhi年$monthInChinese$dayInChinese';
  }

  /// 获取年份信息字符串（如：乙巳年 蛇）
  String get yearInfo {
    return '$yearGanZhi年 $zodiac年';
  }

  @override
  String toString() {
    return 'LunarDate($year年$month月$day日, $yearGanZhi, $zodiac)';
  }
}

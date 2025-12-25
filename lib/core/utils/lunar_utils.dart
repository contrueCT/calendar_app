import 'package:lunar/lunar.dart';
import '../../data/models/lunar_date.dart';

/// 农历工具类
class LunarUtils {
  LunarUtils._();

  /// 公历日期转农历日期
  static LunarDate solarToLunar(DateTime date) {
    return getLunarDate(date);
  }

  /// 获取农历日期的简短显示文本（用于日历单元格）
  static String getLunarDayText(LunarDate lunarDate) {
    // 优先显示节气
    if (lunarDate.solarTerm != null && lunarDate.solarTerm!.isNotEmpty) {
      return lunarDate.solarTerm!;
    }

    // 其次显示农历节日
    if (lunarDate.lunarFestivals.isNotEmpty) {
      return lunarDate.lunarFestivals.first;
    }

    // 初一显示月份名
    if (lunarDate.day == 1) {
      return lunarDate.monthInChinese;
    }

    // 其他日期显示农历日
    return lunarDate.dayInChinese;
  }

  /// 获取指定日期的农历信息
  static LunarDate getLunarDate(DateTime date) {
    final lunar = Lunar.fromDate(date);
    final solar = Solar.fromDate(date);

    return LunarDate(
      year: lunar.getYear(),
      month: lunar.getMonth(),
      day: lunar.getDay(),
      isLeapMonth: lunar.getMonth() < 0, // 负数表示闰月
      yearGanZhi: lunar.getYearInGanZhi(),
      monthGanZhi: lunar.getMonthInGanZhi(),
      dayGanZhi: lunar.getDayInGanZhi(),
      zodiac: lunar.getYearShengXiao(),
      solarTerm: lunar.getJieQi(),
      lunarFestivals: lunar.getFestivals(),
      solarFestivals: solar.getFestivals(),
    );
  }

  /// 获取农历日期的显示文本
  /// 优先级：节气 > 农历节日 > 农历日期
  static String getDisplayText(DateTime date) {
    final lunar = Lunar.fromDate(date);

    // 优先显示节气
    final jieQi = lunar.getJieQi();
    if (jieQi.isNotEmpty) {
      return jieQi;
    }

    // 其次显示农历节日
    final festivals = lunar.getFestivals();
    if (festivals.isNotEmpty) {
      return festivals.first;
    }

    // 最后显示农历日期
    // 初一显示月份，其他显示日期
    if (lunar.getDay() == 1) {
      return '${lunar.getMonthInChinese()}月';
    }
    return lunar.getDayInChinese();
  }

  /// 获取农历月份名称
  static String getLunarMonthName(int month, {bool isLeapMonth = false}) {
    const months = ['正', '二', '三', '四', '五', '六', '七', '八', '九', '十', '冬', '腊'];
    final absMonth = month.abs();
    if (absMonth < 1 || absMonth > 12) return '';

    final prefix = isLeapMonth ? '闰' : '';
    return '$prefix${months[absMonth - 1]}月';
  }

  /// 获取农历日期名称
  static String getLunarDayName(int day) {
    if (day < 1 || day > 30) return '';

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
    return days[day - 1];
  }

  /// 获取生肖
  static String getZodiac(DateTime date) {
    final lunar = Lunar.fromDate(date);
    return lunar.getYearShengXiao();
  }

  /// 获取天干地支年份
  static String getGanZhiYear(DateTime date) {
    final lunar = Lunar.fromDate(date);
    return '${lunar.getYearInGanZhi()}年';
  }

  /// 获取完整的农历日期字符串
  static String getFullLunarDateString(DateTime date) {
    final lunar = Lunar.fromDate(date);
    final yearGanZhi = lunar.getYearInGanZhi();
    final zodiac = lunar.getYearShengXiao();
    final month = lunar.getMonthInChinese();
    final day = lunar.getDayInChinese();

    return '$yearGanZhi年（$zodiac年）$month月$day';
  }

  /// 获取节日列表（公历+农历）
  static List<String> getFestivals(DateTime date) {
    final lunar = Lunar.fromDate(date);
    final solar = Solar.fromDate(date);

    final festivals = <String>[];
    festivals.addAll(solar.getFestivals());
    festivals.addAll(lunar.getFestivals());

    return festivals;
  }

  /// 判断是否是节假日
  static bool isFestival(DateTime date) {
    return getFestivals(date).isNotEmpty;
  }

  /// 获取节气
  static String? getSolarTerm(DateTime date) {
    final lunar = Lunar.fromDate(date);
    final jieQi = lunar.getJieQi();
    return jieQi.isEmpty ? null : jieQi;
  }

  /// 判断是否是节气日
  static bool isSolarTermDay(DateTime date) {
    return getSolarTerm(date) != null;
  }

  /// 获取宜忌
  static Map<String, List<String>> getYiJi(DateTime date) {
    final lunar = Lunar.fromDate(date);
    final dayYi = lunar.getDayYi();
    final dayJi = lunar.getDayJi();

    return {'yi': List<String>.from(dayYi), 'ji': List<String>.from(dayJi)};
  }

  /// 农历日期转公历日期
  static DateTime? lunarToSolar(
    int year,
    int month,
    int day, {
    bool isLeapMonth = false,
  }) {
    try {
      final lunar = Lunar.fromYmd(year, isLeapMonth ? -month : month, day);
      final solar = lunar.getSolar();
      return DateTime(solar.getYear(), solar.getMonth(), solar.getDay());
    } catch (e) {
      return null;
    }
  }

  /// 查找下一个农历节日
  static DateTime? findNextLunarFestival(DateTime from, String festivalName) {
    DateTime current = from;
    // 最多查找一年
    for (int i = 0; i < 365; i++) {
      final lunar = Lunar.fromDate(current);
      final festivals = lunar.getFestivals();
      if (festivals.contains(festivalName)) {
        return current;
      }
      current = current.add(const Duration(days: 1));
    }
    return null;
  }

  /// 主要农历节日列表
  static const List<Map<String, dynamic>> majorLunarFestivals = [
    {'name': '春节', 'month': 1, 'day': 1},
    {'name': '元宵节', 'month': 1, 'day': 15},
    {'name': '龙抬头', 'month': 2, 'day': 2},
    {'name': '端午节', 'month': 5, 'day': 5},
    {'name': '七夕节', 'month': 7, 'day': 7},
    {'name': '中元节', 'month': 7, 'day': 15},
    {'name': '中秋节', 'month': 8, 'day': 15},
    {'name': '重阳节', 'month': 9, 'day': 9},
    {'name': '寒衣节', 'month': 10, 'day': 1},
    {'name': '下元节', 'month': 10, 'day': 15},
    {'name': '腊八节', 'month': 12, 'day': 8},
    {'name': '小年', 'month': 12, 'day': 23},
    {'name': '除夕', 'month': 12, 'day': 30}, // 注意：有些年份没有30日
  ];

  /// 主要公历节日列表
  static const List<Map<String, dynamic>> majorSolarFestivals = [
    {'name': '元旦', 'month': 1, 'day': 1},
    {'name': '情人节', 'month': 2, 'day': 14},
    {'name': '妇女节', 'month': 3, 'day': 8},
    {'name': '植树节', 'month': 3, 'day': 12},
    {'name': '愚人节', 'month': 4, 'day': 1},
    {'name': '劳动节', 'month': 5, 'day': 1},
    {'name': '青年节', 'month': 5, 'day': 4},
    {'name': '儿童节', 'month': 6, 'day': 1},
    {'name': '建党节', 'month': 7, 'day': 1},
    {'name': '建军节', 'month': 8, 'day': 1},
    {'name': '教师节', 'month': 9, 'day': 10},
    {'name': '国庆节', 'month': 10, 'day': 1},
    {'name': '平安夜', 'month': 12, 'day': 24},
    {'name': '圣诞节', 'month': 12, 'day': 25},
  ];
}

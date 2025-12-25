import 'package:flutter/material.dart';

/// 应用颜色常量定义
class AppColors {
  AppColors._();

  /// 主色调
  static const Color primary = Color(0xFF2196F3);
  static const Color primaryLight = Color(0xFF64B5F6);
  static const Color primaryDark = Color(0xFF1976D2);

  /// 强调色
  static const Color accent = Color(0xFF03A9F4);

  /// 背景色
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;

  /// 文字颜色
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);

  /// 分割线颜色
  static const Color divider = Color(0xFFE0E0E0);

  /// 错误颜色
  static const Color error = Color(0xFFE53935);

  /// 成功颜色
  static const Color success = Color(0xFF43A047);

  /// 警告颜色
  static const Color warning = Color(0xFFFFA000);

  /// 预定义日历颜色
  static const List<Color> calendarColors = [
    Color(0xFF2196F3), // 蓝色
    Color(0xFF4CAF50), // 绿色
    Color(0xFFF44336), // 红色
    Color(0xFFFF9800), // 橙色
    Color(0xFF9C27B0), // 紫色
    Color(0xFF00BCD4), // 青色
    Color(0xFFE91E63), // 粉色
    Color(0xFF795548), // 棕色
    Color(0xFF607D8B), // 蓝灰色
    Color(0xFF009688), // 蓝绿色
  ];

  /// 今日高亮颜色
  static const Color todayHighlight = Color(0xFFE3F2FD);

  /// 选中日期颜色
  static const Color selectedDate = Color(0xFF2196F3);

  /// 周末颜色
  static const Color weekend = Color(0xFFE57373);

  /// 农历文字颜色
  static const Color lunarText = Color(0xFF9E9E9E);

  /// 节假日颜色
  static const Color holiday = Color(0xFFE53935);

  /// 节气颜色
  static const Color solarTerm = Color(0xFF43A047);
}

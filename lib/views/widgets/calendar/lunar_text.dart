import 'package:flutter/material.dart';
import '../../../core/utils/lunar_utils.dart';
import '../../../data/models/lunar_date.dart';

/// 农历文本组件
class LunarText extends StatelessWidget {
  final DateTime date;
  final TextStyle? style;
  final bool showFestivalOnly;

  const LunarText({
    super.key,
    required this.date,
    this.style,
    this.showFestivalOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final text = LunarUtils.getDisplayText(date);
    final lunarDate = LunarUtils.getLunarDate(date);

    // 判断是否为特殊日期（节气、节日）
    final isSpecial =
        (lunarDate.solarTerm?.isNotEmpty ?? false) ||
        lunarDate.lunarFestivals.isNotEmpty ||
        lunarDate.solarFestivals.isNotEmpty;

    if (showFestivalOnly && !isSpecial) {
      return const SizedBox.shrink();
    }

    final defaultStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      fontSize: 10,
      color: isSpecial
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.onSurfaceVariant,
    );

    return Text(
      text,
      style: style ?? defaultStyle,
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }
}

/// 农历详情组件（显示更多农历信息）
class LunarDetailText extends StatelessWidget {
  final DateTime? date;
  final LunarDate? lunarDateInput;
  final bool showGanZhi;
  final bool showZodiac;
  final TextStyle? style;

  const LunarDetailText({
    super.key,
    this.date,
    this.lunarDateInput,
    this.showGanZhi = true,
    this.showZodiac = true,
    this.style,
  }) : assert(
         date != null || lunarDateInput != null,
         'Either date or lunarDateInput must be provided',
       );

  /// 便捷构造函数：直接传入 LunarDate
  const LunarDetailText.fromLunarDate({
    super.key,
    required LunarDate lunarDate,
    this.showGanZhi = true,
    this.showZodiac = true,
    this.style,
  }) : date = null,
       lunarDateInput = lunarDate;

  @override
  Widget build(BuildContext context) {
    final lunarDate = lunarDateInput ?? LunarUtils.getLunarDate(date!);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    // 如果提供了自定义样式，使用简化的单行显示
    if (style != null) {
      return Text(_buildSimpleText(lunarDate), style: style);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 农历日期
        Text(
          lunarDate.fullDateString,
          style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
        ),
        const SizedBox(height: 4),

        // 干支纪年
        if (showGanZhi)
          Text(
            '${lunarDate.yearGanZhi}年 ${lunarDate.monthGanZhi}月 ${lunarDate.dayGanZhi}日',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),

        // 生肖
        if (showZodiac)
          Text(
            '生肖：${lunarDate.zodiac}',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),

        // 节气
        if (lunarDate.solarTerm?.isNotEmpty ?? false)
          Text(
            '节气：${lunarDate.solarTerm}',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),

        // 节日
        if (lunarDate.lunarFestivals.isNotEmpty ||
            lunarDate.solarFestivals.isNotEmpty)
          Text(
            '节日：${[...lunarDate.lunarFestivals, ...lunarDate.solarFestivals].join('、')}',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.error,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }

  String _buildSimpleText(LunarDate lunarDate) {
    final parts = <String>[];
    parts.add(lunarDate.fullDateString);

    if (lunarDate.solarTerm?.isNotEmpty ?? false) {
      parts.add(lunarDate.solarTerm!);
    }

    if (lunarDate.lunarFestivals.isNotEmpty) {
      parts.add(lunarDate.lunarFestivals.first);
    }

    return parts.join(' · ');
  }
}

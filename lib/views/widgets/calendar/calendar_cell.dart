import 'package:flutter/material.dart';
import 'lunar_text.dart';
import 'event_marker.dart';

/// 日历单元格组件
class CalendarCell extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final bool isToday;
  final bool isOutsideMonth;
  final bool isWeekend;
  final List<Color> eventColors;
  final bool showLunar;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const CalendarCell({
    super.key,
    required this.date,
    this.isSelected = false,
    this.isToday = false,
    this.isOutsideMonth = false,
    this.isWeekend = false,
    this.eventColors = const [],
    this.showLunar = true,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // 确定文字颜色
    Color textColor;
    if (isSelected) {
      textColor = colorScheme.onPrimary;
    } else if (isOutsideMonth) {
      textColor = colorScheme.outline.withOpacity(0.5);
    } else if (isWeekend) {
      textColor = colorScheme.error.withOpacity(0.8);
    } else {
      textColor = colorScheme.onSurface;
    }

    // 确定背景色
    Color? backgroundColor;
    if (isSelected) {
      backgroundColor = colorScheme.primary;
    } else if (isToday) {
      backgroundColor = colorScheme.primaryContainer;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: isToday && !isSelected
                ? Border.all(color: colorScheme.primary, width: 1)
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 公历日期
              Text(
                date.day.toString(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                  color: textColor,
                ),
              ),
              
              // 农历日期
              if (showLunar)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: LunarText(
                    date: date,
                    style: TextStyle(
                      fontSize: 9,
                      color: isSelected 
                          ? colorScheme.onPrimary.withOpacity(0.8)
                          : isOutsideMonth
                              ? colorScheme.outline.withOpacity(0.4)
                              : null,
                    ),
                  ),
                ),
              
              // 事件标记
              if (eventColors.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: MultiEventMarkers(
                    colors: eventColors,
                    size: 5,
                    maxMarkers: 3,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 周视图的日期头部单元格
class WeekDayHeader extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final bool isToday;
  final VoidCallback? onTap;

  const WeekDayHeader({
    super.key,
    required this.date,
    this.isSelected = false,
    this.isToday = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isWeekend = date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
    
    final weekDayNames = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final weekDayName = weekDayNames[date.weekday - 1];

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primaryContainer : null,
          border: Border(
            bottom: BorderSide(
              color: colorScheme.outlineVariant,
              width: 1,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              weekDayName,
              style: TextStyle(
                fontSize: 12,
                color: isWeekend 
                    ? colorScheme.error.withOpacity(0.8)
                    : colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isToday ? colorScheme.primary : null,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  date.day.toString(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    color: isToday 
                        ? colorScheme.onPrimary
                        : isWeekend 
                            ? colorScheme.error.withOpacity(0.8)
                            : colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/calendar_viewmodel.dart';
import '../../data/models/event_model.dart';
import '../../core/utils/lunar_utils.dart';
import '../widgets/event/event.dart';
import '../widgets/calendar/calendar.dart';
import '../widgets/common/common.dart';

/// 月视图页面
class MonthViewScreen extends StatefulWidget {
  final DateTime? initialDate;
  final void Function(DateTime)? onDaySelected;
  final void Function(EventInstance)? onEventTap;

  const MonthViewScreen({
    super.key,
    this.initialDate,
    this.onDaySelected,
    this.onEventTap,
  });

  @override
  State<MonthViewScreen> createState() => _MonthViewScreenState();
}

class _MonthViewScreenState extends State<MonthViewScreen> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.initialDate ?? DateTime.now();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CalendarViewModel>(
      builder: (context, viewModel, child) {
        return Column(
          children: [
            // 日历组件
            _buildCalendar(context, viewModel),
            
            const Divider(height: 1),
            
            // 选中日期的事件列表
            Expanded(
              child: _buildEventList(context, viewModel),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCalendar(BuildContext context, CalendarViewModel viewModel) {
    final colorScheme = Theme.of(context).colorScheme;

    return TableCalendar<EventInstance>(
      // 基本配置
      firstDay: DateTime.utc(2000, 1, 1),
      lastDay: DateTime.utc(2100, 12, 31),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      calendarFormat: _calendarFormat,
      availableCalendarFormats: const {
        CalendarFormat.month: '月',
        CalendarFormat.twoWeeks: '两周',
        CalendarFormat.week: '周',
      },
      locale: 'zh_CN',
      startingDayOfWeek: StartingDayOfWeek.sunday,

      // 样式配置
      headerStyle: HeaderStyle(
        formatButtonVisible: true,
        titleCentered: true,
        formatButtonShowsNext: false,
        formatButtonDecoration: BoxDecoration(
          border: Border.all(color: colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        leftChevronIcon: Icon(
          Icons.chevron_left,
          color: colorScheme.onSurface,
        ),
        rightChevronIcon: Icon(
          Icons.chevron_right,
          color: colorScheme.onSurface,
        ),
      ),

      calendarStyle: CalendarStyle(
        outsideDaysVisible: true,
        weekendTextStyle: TextStyle(color: colorScheme.error),
        outsideTextStyle: TextStyle(color: colorScheme.outline),
        todayDecoration: BoxDecoration(
          color: colorScheme.primary.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        todayTextStyle: TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
        selectedDecoration: BoxDecoration(
          color: colorScheme.primary,
          shape: BoxShape.circle,
        ),
        selectedTextStyle: TextStyle(
          color: colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
        ),
        markerDecoration: BoxDecoration(
          color: colorScheme.secondary,
          shape: BoxShape.circle,
        ),
        markersMaxCount: 3,
        markersAlignment: Alignment.bottomCenter,
        markerSize: 6,
        markerMargin: const EdgeInsets.only(top: 1),
      ),

      daysOfWeekStyle: DaysOfWeekStyle(
        weekendStyle: TextStyle(color: colorScheme.error),
        weekdayStyle: TextStyle(color: colorScheme.onSurface),
      ),

      // 事件加载器
      eventLoader: (day) {
        return viewModel.getEventsForDay(day);
      },

      // 构建日历单元格
      calendarBuilders: CalendarBuilders<EventInstance>(
        // 自定义默认日期构建器
        defaultBuilder: (context, day, focusedDay) {
          return _buildCalendarCell(context, day, false, false, viewModel);
        },
        // 今天
        todayBuilder: (context, day, focusedDay) {
          return _buildCalendarCell(context, day, true, false, viewModel);
        },
        // 选中的日期
        selectedBuilder: (context, day, focusedDay) {
          return _buildCalendarCell(context, day, false, true, viewModel);
        },
        // 当月外的日期
        outsideBuilder: (context, day, focusedDay) {
          return _buildOutsideCell(context, day);
        },
        // 事件标记
        markerBuilder: (context, day, events) {
          if (events.isEmpty) return null;
          return Positioned(
            bottom: 4,
            child: MultiEventMarkers(
              events: events,
              maxMarkers: 3,
              size: 6,
            ),
          );
        },
      ),

      // 回调
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
        widget.onDaySelected?.call(selectedDay);
      },

      onFormatChanged: (format) {
        setState(() {
          _calendarFormat = format;
        });
      },

      onPageChanged: (focusedDay) {
        setState(() {
          _focusedDay = focusedDay;
        });
        // 加载新月份的事件
        viewModel.loadEventsForMonth(focusedDay);
      },
    );
  }

  Widget _buildCalendarCell(
    BuildContext context,
    DateTime day,
    bool isToday,
    bool isSelected,
    CalendarViewModel viewModel,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final lunarDate = LunarUtils.solarToLunar(day);
    final isWeekend = day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;

    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isSelected 
            ? colorScheme.primary 
            : isToday 
                ? colorScheme.primary.withOpacity(0.1) 
                : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 公历日期
          Text(
            '${day.day}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected 
                  ? colorScheme.onPrimary 
                  : isWeekend 
                      ? colorScheme.error 
                      : colorScheme.onSurface,
            ),
          ),
          // 农历日期
          Text(
            LunarUtils.getLunarDayText(lunarDate),
            style: TextStyle(
              fontSize: 10,
              color: isSelected 
                  ? colorScheme.onPrimary.withOpacity(0.8) 
                  : colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutsideCell(BuildContext context, DateTime day) {
    final colorScheme = Theme.of(context).colorScheme;
    final lunarDate = LunarUtils.solarToLunar(day);

    return Container(
      margin: const EdgeInsets.all(2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${day.day}',
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.outline.withOpacity(0.5),
            ),
          ),
          Text(
            LunarUtils.getLunarDayText(lunarDate),
            style: TextStyle(
              fontSize: 10,
              color: colorScheme.outline.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventList(BuildContext context, CalendarViewModel viewModel) {
    final colorScheme = Theme.of(context).colorScheme;
    
    if (_selectedDay == null) {
      return EmptyState.noEvents();
    }

    final events = viewModel.getEventsForDay(_selectedDay!);
    final dateFormat = DateFormat('M月d日 EEEE', 'zh_CN');
    final lunarDate = LunarUtils.solarToLunar(_selectedDay!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 日期标题
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateFormat.format(_selectedDay!),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  LunarDetailText(
                    lunarDateInput: lunarDate,
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                '${events.length} 个日程',
                style: TextStyle(
                  color: colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
        
        const Divider(height: 1),
        
        // 事件列表
        Expanded(
          child: events.isEmpty
              ? EmptyState.noEvents()
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: events.length,
                  separatorBuilder: (context, index) => const Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                  ),
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return EventListTile(
                      event: event,
                      onTap: () => widget.onEventTap?.call(event),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

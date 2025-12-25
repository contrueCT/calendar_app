import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/calendar_viewmodel.dart';
import '../../data/models/event_model.dart';
import '../../core/utils/lunar_utils.dart';
import '../widgets/event/event.dart';
import '../widgets/common/common.dart';

/// 周视图页面
class WeekViewScreen extends StatefulWidget {
  final DateTime? initialDate;
  final void Function(DateTime)? onDaySelected;
  final void Function(EventInstance)? onEventTap;
  final void Function(DateTime, int)? onTimeSlotTap;

  const WeekViewScreen({
    super.key,
    this.initialDate,
    this.onDaySelected,
    this.onEventTap,
    this.onTimeSlotTap,
  });

  @override
  State<WeekViewScreen> createState() => _WeekViewScreenState();
}

class _WeekViewScreenState extends State<WeekViewScreen> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  late ScrollController _scrollController;
  final double _hourHeight = 60.0;
  final double _dayColumnWidth = 48.0;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.initialDate ?? DateTime.now();
    _selectedDay = _focusedDay;
    _scrollController = ScrollController();
    
    // 初始滚动到当前时间
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentTime();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrentTime() {
    final now = DateTime.now();
    final targetOffset = (now.hour - 1) * _hourHeight;
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        targetOffset.clamp(0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CalendarViewModel>(
      builder: (context, viewModel, child) {
        return Column(
          children: [
            // 周日历头部
            _buildWeekCalendar(context, viewModel),
            
            const Divider(height: 1),
            
            // 全天事件
            _buildAllDayEvents(context, viewModel),
            
            // 时间轴视图
            Expanded(
              child: _buildTimeAxisView(context, viewModel),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWeekCalendar(BuildContext context, CalendarViewModel viewModel) {
    final colorScheme = Theme.of(context).colorScheme;

    return TableCalendar<EventInstance>(
      firstDay: DateTime.utc(2000, 1, 1),
      lastDay: DateTime.utc(2100, 12, 31),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      calendarFormat: CalendarFormat.week,
      availableCalendarFormats: const {CalendarFormat.week: '周'},
      locale: 'zh_CN',
      startingDayOfWeek: StartingDayOfWeek.sunday,
      
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextFormatter: (date, locale) {
          final weekStart = _getWeekStart(date);
          final weekEnd = weekStart.add(const Duration(days: 6));
          final format = DateFormat('M月d日');
          return '${format.format(weekStart)} - ${format.format(weekEnd)}';
        },
        titleTextStyle: const TextStyle(
          fontSize: 16,
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
        outsideDaysVisible: false,
        weekendTextStyle: TextStyle(color: colorScheme.error),
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
      ),

      daysOfWeekHeight: 20,
      rowHeight: 50,

      calendarBuilders: CalendarBuilders<EventInstance>(
        defaultBuilder: (context, day, focusedDay) {
          return _buildDayCell(context, day, false, false);
        },
        todayBuilder: (context, day, focusedDay) {
          return _buildDayCell(context, day, true, false);
        },
        selectedBuilder: (context, day, focusedDay) {
          return _buildDayCell(context, day, false, true);
        },
      ),

      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
        widget.onDaySelected?.call(selectedDay);
      },

      onPageChanged: (focusedDay) {
        setState(() {
          _focusedDay = focusedDay;
        });
        viewModel.loadEventsForWeek(focusedDay);
      },
    );
  }

  Widget _buildDayCell(BuildContext context, DateTime day, bool isToday, bool isSelected) {
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
          Text(
            LunarUtils.getLunarDayText(lunarDate),
            style: TextStyle(
              fontSize: 9,
              color: isSelected 
                  ? colorScheme.onPrimary.withOpacity(0.8) 
                  : colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllDayEvents(BuildContext context, CalendarViewModel viewModel) {
    if (_selectedDay == null) return const SizedBox.shrink();
    
    final events = viewModel.getEventsForDay(_selectedDay!);
    final allDayEvents = events.where((e) => e.event.isAllDay).toList();
    
    return AllDayEventBar(
      allDayEvents: allDayEvents,
      onEventTap: widget.onEventTap,
    );
  }

  Widget _buildTimeAxisView(BuildContext context, CalendarViewModel viewModel) {
    final colorScheme = Theme.of(context).colorScheme;
    
    if (_selectedDay == null) {
      return EmptyState.noEvents();
    }

    final events = viewModel.getEventsForDay(_selectedDay!);
    final timedEvents = events.where((e) => !e.event.isAllDay).toList();
    final eventsByHour = TimeAxis.groupEventsByHour(timedEvents);
    final isToday = isSameDay(_selectedDay!, DateTime.now());

    return Stack(
      children: [
        // 时间轴
        ListView.builder(
          controller: _scrollController,
          itemCount: 24,
          itemBuilder: (context, hour) {
            return TimeSlot(
              hour: hour,
              events: eventsByHour[hour] ?? [],
              slotHeight: _hourHeight,
              onEventTap: widget.onEventTap,
              onSlotTap: (h) {
                widget.onTimeSlotTap?.call(_selectedDay!, h);
              },
            );
          },
        ),
        
        // 当前时间指示器（仅当查看今天时显示）
        if (isToday)
          CurrentTimeIndicator(
            slotHeight: _hourHeight,
          ),
      ],
    );
  }

  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday % 7));
  }
}

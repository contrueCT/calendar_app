import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/calendar_viewmodel.dart';
import '../../data/models/event_model.dart';
import '../../core/utils/lunar_utils.dart';
import '../widgets/event/event.dart';
import '../widgets/calendar/calendar.dart';

/// 日视图页面
class DayViewScreen extends StatefulWidget {
  final DateTime? initialDate;
  final void Function(DateTime)? onDateChanged;
  final void Function(EventInstance)? onEventTap;
  final void Function(DateTime, int)? onTimeSlotTap;

  const DayViewScreen({
    super.key,
    this.initialDate,
    this.onDateChanged,
    this.onEventTap,
    this.onTimeSlotTap,
  });

  @override
  State<DayViewScreen> createState() => _DayViewScreenState();
}

class _DayViewScreenState extends State<DayViewScreen> {
  late DateTime _selectedDate;
  late ScrollController _scrollController;
  late PageController _pageController;
  final double _hourHeight = 60.0;

  // 用于PageView计算的基准日期
  final DateTime _baseDate = DateTime(2000, 1, 1);

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _scrollController = ScrollController();

    // 计算初始页面索引
    final initialPage = _selectedDate.difference(_baseDate).inDays;
    _pageController = PageController(initialPage: initialPage);

    // 初始滚动到当前时间
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentTime();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pageController.dispose();
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
            // 日期导航头部
            _buildDateHeader(context, viewModel),

            const Divider(height: 1),

            // 日视图内容（支持左右滑动）
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  final newDate = _baseDate.add(Duration(days: index));
                  setState(() {
                    _selectedDate = newDate;
                  });
                  widget.onDateChanged?.call(newDate);
                  viewModel.loadEventsForDay(newDate);
                },
                itemBuilder: (context, index) {
                  final date = _baseDate.add(Duration(days: index));
                  return _buildDayContent(context, date, viewModel);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateHeader(BuildContext context, CalendarViewModel viewModel) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('yyyy年M月d日 EEEE', 'zh_CN');
    final lunarDate = LunarUtils.solarToLunar(_selectedDate);
    final isToday = _isToday(_selectedDate);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: [
          // 前一天按钮
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            },
          ),

          // 日期信息
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      dateFormat.format(_selectedDate),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isToday ? colorScheme.primary : null,
                      ),
                    ),
                    if (isToday)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '今天',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                LunarDetailText(
                  lunarDateInput: lunarDate,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // 后一天按钮
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              _pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDayContent(
    BuildContext context,
    DateTime date,
    CalendarViewModel viewModel,
  ) {
    final events = viewModel.getEventsForDay(date);
    final allDayEvents = events.where((e) => e.event.isAllDay).toList();
    final timedEvents = events.where((e) => !e.event.isAllDay).toList();
    final eventsByHour = TimeAxis.groupEventsByHour(timedEvents);
    final isToday = _isToday(date);

    return Column(
      children: [
        // 全天事件
        if (allDayEvents.isNotEmpty)
          AllDayEventBar(
            allDayEvents: allDayEvents,
            onEventTap: widget.onEventTap,
            maxVisibleEvents: 3,
          ),

        // 时间轴
        Expanded(
          child: Stack(
            children: [
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
                      widget.onTimeSlotTap?.call(date, h);
                    },
                  );
                },
              ),

              // 当前时间指示器
              if (isToday) CurrentTimeIndicator(slotHeight: _hourHeight),
            ],
          ),
        ),
      ],
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

/// 简化的日期选择器组件
class DaySelector extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime>? onDateChanged;

  const DaySelector({
    super.key,
    required this.selectedDate,
    this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final weekDays = _getWeekDays(selectedDate);

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: weekDays.map((day) {
          final isSelected = _isSameDay(day, selectedDate);
          final isToday = _isSameDay(day, DateTime.now());

          return GestureDetector(
            onTap: () => onDateChanged?.call(day),
            child: Container(
              width: 44,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primary
                    : isToday
                    ? colorScheme.primary.withValues(alpha: 0.1)
                    : null,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getWeekDayLabel(day.weekday),
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected
                          ? colorScheme.onPrimary
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? colorScheme.onPrimary
                          : isToday
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  List<DateTime> _getWeekDays(DateTime date) {
    final weekday = date.weekday;
    final startOfWeek = date.subtract(Duration(days: weekday % 7));
    return List.generate(7, (i) => startOfWeek.add(Duration(days: i)));
  }

  String _getWeekDayLabel(int weekday) {
    const labels = ['', '周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return labels[weekday];
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

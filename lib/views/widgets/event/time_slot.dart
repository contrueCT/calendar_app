import 'package:flutter/material.dart';
import '../../../data/models/event_model.dart';
import 'package:intl/intl.dart';

/// 时间槽组件 - 用于周视图和日视图
class TimeSlot extends StatelessWidget {
  final int hour;
  final List<EventInstance> events;
  final double slotHeight;
  final void Function(EventInstance)? onEventTap;
  final void Function(int hour)? onSlotTap;
  final bool showHalfHour;

  const TimeSlot({
    super.key,
    required this.hour,
    this.events = const [],
    this.slotHeight = 60.0,
    this.onEventTap,
    this.onSlotTap,
    this.showHalfHour = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onSlotTap != null ? () => onSlotTap!(hour) : null,
      child: Container(
        height: showHalfHour ? slotHeight * 2 : slotHeight,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: colorScheme.outlineVariant.withOpacity(0.3),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 时间标签
            SizedBox(
              width: 50,
              child: Padding(
                padding: const EdgeInsets.only(top: 4, right: 8),
                child: Text(
                  '${hour.toString().padLeft(2, '0')}:00',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.outline,
                  ),
                ),
              ),
            ),
            
            // 事件区域
            Expanded(
              child: _buildEventsArea(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsArea(BuildContext context) {
    if (events.isEmpty) {
      return const SizedBox.shrink();
    }

    // 简化实现：将事件竖直排列
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: events.map((event) {
        return _buildEventChip(context, event);
      }).toList(),
    );
  }

  Widget _buildEventChip(BuildContext context, EventInstance event) {
    final colorScheme = Theme.of(context).colorScheme;
    final eventColor = event.event.colorValue ?? colorScheme.primary;
    final timeFormat = DateFormat('HH:mm');

    return GestureDetector(
      onTap: onEventTap != null ? () => onEventTap!(event) : null,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 1, horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: eventColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(4),
          border: Border(
            left: BorderSide(color: eventColor, width: 3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              event.event.summary,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${timeFormat.format(event.instanceStart)}${event.instanceEnd != null ? ' - ${timeFormat.format(event.instanceEnd!)}' : ''}',
              style: TextStyle(
                fontSize: 10,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 时间轴组件 - 显示24小时时间轴
class TimeAxis extends StatelessWidget {
  final DateTime date;
  final Map<int, List<EventInstance>> eventsByHour;
  final double slotHeight;
  final void Function(EventInstance)? onEventTap;
  final void Function(int hour)? onSlotTap;
  final ScrollController? scrollController;
  final int startHour;
  final int endHour;

  const TimeAxis({
    super.key,
    required this.date,
    this.eventsByHour = const {},
    this.slotHeight = 60.0,
    this.onEventTap,
    this.onSlotTap,
    this.scrollController,
    this.startHour = 0,
    this.endHour = 24,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      itemCount: endHour - startHour,
      itemBuilder: (context, index) {
        final hour = startHour + index;
        return TimeSlot(
          hour: hour,
          events: eventsByHour[hour] ?? [],
          slotHeight: slotHeight,
          onEventTap: onEventTap,
          onSlotTap: onSlotTap,
        );
      },
    );
  }

  /// 将事件按小时分组
  static Map<int, List<EventInstance>> groupEventsByHour(List<EventInstance> events) {
    final result = <int, List<EventInstance>>{};
    
    for (final event in events) {
      // 全天事件不在时间轴上显示
      if (event.event.isAllDay) continue;
      
      final startHour = event.instanceStart.hour;
      result.putIfAbsent(startHour, () => []);
      result[startHour]!.add(event);
    }
    
    return result;
  }
}

/// 当前时间指示线
class CurrentTimeIndicator extends StatelessWidget {
  final double slotHeight;
  final int startHour;

  const CurrentTimeIndicator({
    super.key,
    this.slotHeight = 60.0,
    this.startHour = 0,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final colorScheme = Theme.of(context).colorScheme;
    
    // 计算当前时间的位置
    final minutesSinceStart = (now.hour - startHour) * 60 + now.minute;
    final position = (minutesSinceStart / 60) * slotHeight;
    
    if (position < 0) return const SizedBox.shrink();
    
    return Positioned(
      top: position,
      left: 0,
      right: 0,
      child: Row(
        children: [
          const SizedBox(width: 46), // 对齐时间标签
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: colorScheme.error,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Container(
              height: 1.5,
              color: colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }
}

/// 全天事件栏
class AllDayEventBar extends StatelessWidget {
  final List<EventInstance> allDayEvents;
  final void Function(EventInstance)? onEventTap;
  final int maxVisibleEvents;

  const AllDayEventBar({
    super.key,
    required this.allDayEvents,
    this.onEventTap,
    this.maxVisibleEvents = 2,
  });

  @override
  Widget build(BuildContext context) {
    if (allDayEvents.isEmpty) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final visibleEvents = allDayEvents.take(maxVisibleEvents).toList();
    final moreCount = allDayEvents.length - maxVisibleEvents;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标签
          Row(
            children: [
              const SizedBox(width: 50),
              Text(
                '全天',
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // 全天事件列表
          Row(
            children: [
              const SizedBox(width: 50),
              Expanded(
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    ...visibleEvents.map((event) => _buildEventChip(context, event)),
                    if (moreCount > 0)
                      Text(
                        '+$moreCount',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.primary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEventChip(BuildContext context, EventInstance event) {
    final colorScheme = Theme.of(context).colorScheme;
    final eventColor = event.event.colorValue ?? colorScheme.primary;

    return GestureDetector(
      onTap: onEventTap != null ? () => onEventTap!(event) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: eventColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: eventColor.withOpacity(0.4)),
        ),
        child: Text(
          event.event.summary,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

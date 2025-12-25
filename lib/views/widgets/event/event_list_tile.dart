import 'package:flutter/material.dart';
import '../../../data/models/event_model.dart';
import 'package:intl/intl.dart';

/// 事件列表项组件
class EventListTile extends StatelessWidget {
  final EventInstance event;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showDate;
  final bool dense;

  const EventListTile({
    super.key,
    required this.event,
    this.onTap,
    this.onLongPress,
    this.showDate = false,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final eventColor = event.event.colorValue ?? colorScheme.primary;

    return ListTile(
      onTap: onTap,
      onLongPress: onLongPress,
      dense: dense,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 4,
        height: dense ? 36 : 48,
        decoration: BoxDecoration(
          color: eventColor,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      title: Text(
        event.event.summary,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: dense ? 14 : 16,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        _getSubtitle(),
        style: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: dense ? 12 : 14,
        ),
      ),
      trailing: _buildTrailing(context),
    );
  }

  String _getSubtitle() {
    final timeFormat = DateFormat('HH:mm');
    final dateFormat = DateFormat('M月d日');

    if (event.event.isAllDay) {
      if (showDate) {
        return '${dateFormat.format(event.instanceStart)} 全天';
      }
      return '全天';
    }

    final start = timeFormat.format(event.instanceStart);
    final end = ' - ${timeFormat.format(event.instanceEnd)}';

    if (showDate) {
      return '${dateFormat.format(event.instanceStart)} $start$end';
    }

    return '$start$end';
  }

  Widget? _buildTrailing(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final indicators = <Widget>[];

    if (event.event.isRecurring) {
      indicators.add(
        Icon(Icons.repeat, size: 16, color: colorScheme.onSurfaceVariant),
      );
    }

    if (event.event.reminders.isNotEmpty) {
      indicators.add(
        Icon(
          Icons.notifications_outlined,
          size: 16,
          color: colorScheme.onSurfaceVariant,
        ),
      );
    }

    if (indicators.isEmpty) return null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: indicators
          .map(
            (icon) =>
                Padding(padding: const EdgeInsets.only(left: 4), child: icon),
          )
          .toList(),
    );
  }
}

/// 分组的事件列表
class GroupedEventList extends StatelessWidget {
  final Map<DateTime, List<EventInstance>> eventsByDate;
  final void Function(EventInstance)? onEventTap;
  final Widget Function(DateTime date)? headerBuilder;
  final bool showEmptyDates;

  const GroupedEventList({
    super.key,
    required this.eventsByDate,
    this.onEventTap,
    this.headerBuilder,
    this.showEmptyDates = false,
  });

  @override
  Widget build(BuildContext context) {
    final sortedDates = eventsByDate.keys.toList()
      ..sort((a, b) => a.compareTo(b));

    if (sortedDates.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final events = eventsByDate[date] ?? [];

        if (events.isEmpty && !showEmptyDates) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 日期头部
            headerBuilder?.call(date) ?? _buildDefaultHeader(context, date),

            // 事件列表
            if (events.isNotEmpty)
              ...events.map(
                (event) => EventListTile(
                  event: event,
                  onTap: onEventTap != null ? () => onEventTap!(event) : null,
                  dense: true,
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  '暂无日程',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.outline,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildDefaultHeader(BuildContext context, DateTime date) {
    final colorScheme = Theme.of(context).colorScheme;
    final isToday = _isToday(date);
    final dateFormat = DateFormat('M月d日 EEEE', 'zh_CN');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Row(
        children: [
          if (isToday)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '今天',
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Text(
            dateFormat.format(date),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isToday ? colorScheme.primary : colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

import 'package:flutter/material.dart';
import '../../../data/models/event_model.dart';
import 'package:intl/intl.dart';

/// 事件卡片组件 - 用于列表显示
class EventCard extends StatelessWidget {
  final EventInstance event;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showDate;

  const EventCard({
    super.key,
    required this.event,
    this.onTap,
    this.onLongPress,
    this.showDate = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final eventColor = event.event.colorValue ?? colorScheme.primary;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border(left: BorderSide(color: eventColor, width: 4)),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题行
              Row(
                children: [
                  Expanded(
                    child: Text(
                      event.event.summary,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (event.event.isAllDay)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: eventColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '全天',
                        style: TextStyle(fontSize: 12, color: eventColor),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 4),

              // 时间信息
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatTimeRange(event),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),

              // 地点
              if (event.event.location != null &&
                  event.event.location!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        event.event.location!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],

              // 重复标记
              if (event.event.isRecurring) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.repeat,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      event.event.recurrenceRule?.description ?? '重复事件',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimeRange(EventInstance event) {
    final timeFormat = DateFormat('HH:mm');

    if (event.event.isAllDay) {
      final dateFormat = DateFormat('M月d日');
      if (showDate) {
        return dateFormat.format(event.instanceStart);
      }
      return '全天';
    }

    final start = timeFormat.format(event.instanceStart);
    final end = timeFormat.format(event.instanceEnd);

    if (showDate) {
      final dateFormat = DateFormat('M月d日');
      return '${dateFormat.format(event.instanceStart)} $start - $end';
    }

    return '$start - $end';
  }
}

/// 简洁的事件卡片 - 用于日期下方的小卡片
class CompactEventCard extends StatelessWidget {
  final EventInstance event;
  final VoidCallback? onTap;

  const CompactEventCard({super.key, required this.event, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final eventColor = event.event.colorValue ?? colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: eventColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border(left: BorderSide(color: eventColor, width: 3)),
        ),
        child: Row(
          children: [
            if (!event.event.isAllDay) ...[
              Text(
                DateFormat('HH:mm').format(event.instanceStart),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: eventColor,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                event.event.summary,
                style: TextStyle(fontSize: 13, color: colorScheme.onSurface),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

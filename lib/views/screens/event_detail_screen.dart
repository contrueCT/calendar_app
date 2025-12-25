import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../data/models/event_model.dart';
import '../../data/models/calendar_model.dart';
import '../../viewmodels/calendar_viewmodel.dart';
import '../../config/routes.dart';

/// 事件详情页面
class EventDetailScreen extends StatelessWidget {
  final EventInstance instance;

  const EventDetailScreen({super.key, required this.instance});

  @override
  Widget build(BuildContext context) {
    final event = instance.event;

    return Scaffold(
      appBar: AppBar(
        title: const Text('事件详情'),
        actions: [
          // 编辑按钮
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: '编辑',
            onPressed: () => _editEvent(context),
          ),
          // 删除按钮
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: '删除',
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题和颜色指示器
            _buildHeader(context, event),
            const SizedBox(height: 24),

            // 时间信息
            _buildTimeSection(context, event),
            const SizedBox(height: 16),

            // 重复规则
            if (event.isRecurring) ...[
              _buildRecurrenceSection(context, event),
              const SizedBox(height: 16),
            ],

            // 日历信息
            _buildCalendarSection(context, event),
            const SizedBox(height: 16),

            // 地点
            if (event.location != null && event.location!.isNotEmpty) ...[
              _buildLocationSection(context, event),
              const SizedBox(height: 16),
            ],

            // 备注
            if (event.description != null && event.description!.isNotEmpty) ...[
              _buildDescriptionSection(context, event),
              const SizedBox(height: 16),
            ],

            // 提醒
            if (event.reminders.isNotEmpty) ...[
              _buildRemindersSection(context, event),
              const SizedBox(height: 16),
            ],

            // URL
            if (event.url != null && event.url!.isNotEmpty) ...[
              _buildUrlSection(context, event),
              const SizedBox(height: 16),
            ],

            // 状态和优先级
            _buildMetadataSection(context, event),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, EventModel event) {
    final colorScheme = Theme.of(context).colorScheme;
    final eventColor = event.colorValue ?? colorScheme.primary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 4,
          height: 32,
          decoration: BoxDecoration(
            color: eventColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.summary,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (event.status == EventStatus.cancelled)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '已取消',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onErrorContainer,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSection(BuildContext context, EventModel event) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('yyyy年M月d日 EEEE', 'zh_CN');
    final timeFormat = DateFormat('HH:mm');

    String timeText;
    if (event.isAllDay) {
      if (event.dtEnd == null ||
          _isSameDay(instance.instanceStart, instance.instanceEnd)) {
        timeText = dateFormat.format(instance.instanceStart);
      } else {
        timeText =
            '${dateFormat.format(instance.instanceStart)} - ${dateFormat.format(instance.instanceEnd)}';
      }
    } else {
      final startDate = dateFormat.format(instance.instanceStart);
      final startTime = timeFormat.format(instance.instanceStart);
      final endTime = timeFormat.format(instance.instanceEnd);

      if (_isSameDay(instance.instanceStart, instance.instanceEnd)) {
        timeText = '$startDate\n$startTime - $endTime';
      } else {
        final endDate = dateFormat.format(instance.instanceEnd);
        timeText = '$startDate $startTime\n至 $endDate $endTime';
      }
    }

    return _DetailSection(
      icon: Icons.access_time,
      iconColor: colorScheme.primary,
      title: '时间',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            timeText,
            style: TextStyle(fontSize: 15, color: colorScheme.onSurface),
          ),
          if (event.isAllDay)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '全天',
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecurrenceSection(BuildContext context, EventModel event) {
    final colorScheme = Theme.of(context).colorScheme;
    final rule = event.recurrenceRule;

    return _DetailSection(
      icon: Icons.repeat,
      iconColor: colorScheme.tertiary,
      title: '重复',
      child: Text(
        rule?.description ?? '未知重复规则',
        style: TextStyle(fontSize: 15, color: colorScheme.onSurface),
      ),
    );
  }

  Widget _buildCalendarSection(BuildContext context, EventModel event) {
    final colorScheme = Theme.of(context).colorScheme;
    final viewModel = context.read<CalendarViewModel>();

    // 查找对应的日历
    CalendarModel? calendar;
    try {
      calendar = viewModel.calendars.firstWhere(
        (c) => c.id == event.calendarId,
      );
    } catch (_) {
      calendar = null;
    }

    return _DetailSection(
      icon: Icons.calendar_today,
      iconColor: calendar?.colorValue ?? colorScheme.secondary,
      title: '日历',
      child: Text(
        calendar?.displayName ?? '未知日历',
        style: TextStyle(fontSize: 15, color: colorScheme.onSurface),
      ),
    );
  }

  Widget _buildLocationSection(BuildContext context, EventModel event) {
    final colorScheme = Theme.of(context).colorScheme;

    return _DetailSection(
      icon: Icons.location_on_outlined,
      iconColor: colorScheme.error,
      title: '地点',
      child: Text(
        event.location!,
        style: TextStyle(fontSize: 15, color: colorScheme.onSurface),
      ),
    );
  }

  Widget _buildDescriptionSection(BuildContext context, EventModel event) {
    final colorScheme = Theme.of(context).colorScheme;

    return _DetailSection(
      icon: Icons.notes,
      iconColor: colorScheme.onSurfaceVariant,
      title: '备注',
      child: Text(
        event.description!,
        style: TextStyle(fontSize: 15, color: colorScheme.onSurface),
      ),
    );
  }

  Widget _buildRemindersSection(BuildContext context, EventModel event) {
    final colorScheme = Theme.of(context).colorScheme;

    return _DetailSection(
      icon: Icons.notifications_outlined,
      iconColor: colorScheme.secondary,
      title: '提醒',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: event.reminders.map((reminder) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              _formatReminder(reminder.triggerMinutes),
              style: TextStyle(fontSize: 15, color: colorScheme.onSurface),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUrlSection(BuildContext context, EventModel event) {
    final colorScheme = Theme.of(context).colorScheme;

    return _DetailSection(
      icon: Icons.link,
      iconColor: colorScheme.primary,
      title: '链接',
      child: Text(
        event.url!,
        style: TextStyle(
          fontSize: 15,
          color: colorScheme.primary,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  Widget _buildMetadataSection(BuildContext context, EventModel event) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    return _DetailSection(
      icon: Icons.info_outline,
      iconColor: colorScheme.onSurfaceVariant,
      title: '其他信息',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MetadataRow(label: '状态', value: event.status.label),
          if (event.priority > 0)
            _MetadataRow(label: '优先级', value: '${event.priority}'),
          _MetadataRow(
            label: '创建时间',
            value: dateFormat.format(event.createdAt),
          ),
          _MetadataRow(
            label: '更新时间',
            value: dateFormat.format(event.updatedAt),
          ),
        ],
      ),
    );
  }

  String _formatReminder(int minutes) {
    if (minutes == 0) return '事件开始时';
    if (minutes < 60) return '提前 $minutes 分钟';
    if (minutes < 1440) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      if (mins == 0) return '提前 $hours 小时';
      return '提前 $hours 小时 $mins 分钟';
    }
    final days = minutes ~/ 1440;
    return '提前 $days 天';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _editEvent(BuildContext context) {
    Navigator.pushNamed(context, Routes.eventEdit, arguments: instance.event);
  }

  void _confirmDelete(BuildContext context) {
    final event = instance.event;
    final isRecurring = event.isRecurring;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除事件'),
        content: Text(
          isRecurring
              ? '这是一个重复事件。您想删除所有重复的事件，还是只删除这一个实例？'
              : '确定要删除"${event.summary}"吗？此操作无法撤销。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          if (isRecurring) ...[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteInstance(context);
              },
              child: const Text('仅删除此实例'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteAll(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('删除所有'),
            ),
          ] else
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteAll(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('删除'),
            ),
        ],
      ),
    );
  }

  void _deleteInstance(BuildContext context) async {
    final viewModel = context.read<CalendarViewModel>();
    final success = await viewModel.deleteEventInstance(
      instance.event,
      instance.instanceStart,
    );

    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('已删除此实例')));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('删除失败')));
      }
    }
  }

  void _deleteAll(BuildContext context) async {
    final viewModel = context.read<CalendarViewModel>();
    final success = await viewModel.deleteEvent(instance.event.uid);

    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('已删除事件')));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('删除失败')));
      }
    }
  }
}

/// 详情区块组件
class _DetailSection extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;

  const _DetailSection({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              child,
            ],
          ),
        ),
      ],
    );
  }
}

/// 元数据行组件
class _MetadataRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetadataRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

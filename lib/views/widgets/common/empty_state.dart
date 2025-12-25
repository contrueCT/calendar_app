import 'package:flutter/material.dart';

/// 空状态组件
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: colorScheme.outline),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[const SizedBox(height: 24), action!],
          ],
        ),
      ),
    );
  }

  /// 无事件状态
  factory EmptyState.noEvents({VoidCallback? onAddEvent}) {
    return EmptyState(
      icon: Icons.event_busy,
      title: '暂无日程',
      subtitle: '点击下方按钮添加新的日程',
      action: onAddEvent != null
          ? ElevatedButton.icon(
              onPressed: onAddEvent,
              icon: const Icon(Icons.add),
              label: const Text('添加日程'),
            )
          : null,
    );
  }

  /// 无日历状态
  factory EmptyState.noCalendars({VoidCallback? onAddCalendar}) {
    return EmptyState(
      icon: Icons.calendar_today,
      title: '暂无日历',
      subtitle: '创建一个日历来开始添加日程',
      action: onAddCalendar != null
          ? ElevatedButton.icon(
              onPressed: onAddCalendar,
              icon: const Icon(Icons.add),
              label: const Text('创建日历'),
            )
          : null,
    );
  }

  /// 加载失败状态
  factory EmptyState.error({String? message, VoidCallback? onRetry}) {
    return EmptyState(
      icon: Icons.error_outline,
      title: '加载失败',
      subtitle: message ?? '请检查网络连接后重试',
      action: onRetry != null
          ? ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            )
          : null,
    );
  }
}

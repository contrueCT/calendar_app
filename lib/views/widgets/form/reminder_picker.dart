import 'package:flutter/material.dart';
import '../../../data/models/reminder_model.dart';

/// 预设提醒选项
class ReminderOption {
  final int minutes;
  final String label;

  const ReminderOption(this.minutes, this.label);

  static const List<ReminderOption> presets = [
    ReminderOption(0, '事件发生时'),
    ReminderOption(5, '提前5分钟'),
    ReminderOption(15, '提前15分钟'),
    ReminderOption(30, '提前30分钟'),
    ReminderOption(60, '提前1小时'),
    ReminderOption(120, '提前2小时'),
    ReminderOption(1440, '提前1天'),
    ReminderOption(2880, '提前2天'),
    ReminderOption(10080, '提前1周'),
  ];
}

/// 提醒选择器组件
class ReminderPicker extends StatelessWidget {
  final List<ReminderModel> reminders;
  final ValueChanged<int> onAdd;
  final void Function(int index) onRemove;

  const ReminderPicker({
    super.key,
    required this.reminders,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题和添加按钮
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notifications_outlined,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                const Text('提醒', style: TextStyle(fontSize: 16)),
              ],
            ),
            TextButton.icon(
              onPressed: () => _showAddReminderDialog(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('添加'),
            ),
          ],
        ),

        // 已添加的提醒列表
        if (reminders.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...reminders.asMap().entries.map((entry) {
            final index = entry.key;
            final reminder = entry.value;
            return _ReminderChip(
              reminder: reminder,
              onDelete: () => onRemove(index),
            );
          }),
        ] else
          Padding(
            padding: const EdgeInsets.only(left: 32, top: 4),
            child: Text(
              '无提醒',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }

  void _showAddReminderDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _ReminderOptionsSheet(
        existingMinutes: reminders.map((r) => r.triggerMinutes).toSet(),
        onSelect: (minutes) {
          Navigator.pop(context);
          onAdd(minutes);
        },
      ),
    );
  }
}

class _ReminderChip extends StatelessWidget {
  final ReminderModel reminder;
  final VoidCallback onDelete;

  const _ReminderChip({required this.reminder, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(left: 32, bottom: 4),
      child: Chip(
        label: Text(reminder.triggerDescription),
        deleteIcon: const Icon(Icons.close, size: 16),
        onDeleted: onDelete,
        backgroundColor: colorScheme.secondaryContainer,
        labelStyle: TextStyle(
          fontSize: 13,
          color: colorScheme.onSecondaryContainer,
        ),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }
}

class _ReminderOptionsSheet extends StatelessWidget {
  final Set<int> existingMinutes;
  final ValueChanged<int> onSelect;

  const _ReminderOptionsSheet({
    required this.existingMinutes,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('添加提醒', style: Theme.of(context).textTheme.titleMedium),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: ReminderOption.presets.length,
              itemBuilder: (context, index) {
                final option = ReminderOption.presets[index];
                final isSelected = existingMinutes.contains(option.minutes);

                return ListTile(
                  leading: Icon(
                    isSelected ? Icons.check_circle : Icons.alarm,
                    color: isSelected ? colorScheme.primary : null,
                  ),
                  title: Text(option.label),
                  enabled: !isSelected,
                  onTap: isSelected ? null : () => onSelect(option.minutes),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// 简单的提醒显示组件（用于事件详情）
class ReminderDisplay extends StatelessWidget {
  final List<ReminderModel> reminders;

  const ReminderDisplay({super.key, required this.reminders});

  @override
  Widget build(BuildContext context) {
    if (reminders.isEmpty) {
      return const Text('无提醒');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: reminders.map((r) => Text(r.triggerDescription)).toList(),
    );
  }
}

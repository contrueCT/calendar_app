import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 日期时间选择器组件
class DateTimePicker extends StatelessWidget {
  final DateTime date;
  final TimeOfDay time;
  final bool isAllDay;
  final String label;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<TimeOfDay> onTimeChanged;

  const DateTimePicker({
    super.key,
    required this.date,
    required this.time,
    required this.isAllDay,
    required this.label,
    required this.onDateChanged,
    required this.onTimeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('yyyy年M月d日 EEEE', 'zh_CN');
    final timeFormat = DateFormat('HH:mm');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // 日期选择
            Expanded(
              flex: 3,
              child: _DateButton(
                date: date,
                dateFormat: dateFormat,
                onTap: () => _selectDate(context),
              ),
            ),
            // 时间选择（非全天事件时显示）
            if (!isAllDay) ...[
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _TimeButton(
                  time: time,
                  timeFormat: timeFormat,
                  onTap: () => _selectTime(context),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('zh', 'CN'),
    );
    if (picked != null) {
      onDateChanged(picked);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: time,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked != null) {
      onTimeChanged(picked);
    }
  }
}

class _DateButton extends StatelessWidget {
  final DateTime date;
  final DateFormat dateFormat;
  final VoidCallback onTap;

  const _DateButton({
    required this.date,
    required this.dateFormat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  dateFormat.format(date),
                  style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  final TimeOfDay time;
  final DateFormat timeFormat;
  final VoidCallback onTap;

  const _TimeButton({
    required this.time,
    required this.timeFormat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final dateTime = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              Icon(
                Icons.access_time,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                timeFormat.format(dateTime),
                style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 全天事件开关
class AllDaySwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const AllDaySwitch({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              Icons.wb_sunny_outlined,
              size: 20,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            const Text('全天', style: TextStyle(fontSize: 16)),
          ],
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}

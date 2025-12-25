// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import '../../../data/models/recurrence_rule.dart';

/// 重复规则选择器组件
class RecurrencePicker extends StatelessWidget {
  final RecurrenceRule? rule;
  final ValueChanged<RecurrenceRule?> onChanged;

  const RecurrencePicker({super.key, this.rule, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => _showRecurrenceDialog(context),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(Icons.repeat, size: 20, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('重复', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(
                    rule?.description ?? '不重复',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  void _showRecurrenceDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => RecurrenceConfigSheet(
        initialRule: rule,
        onConfirm: (newRule) {
          Navigator.pop(context);
          onChanged(newRule);
        },
      ),
    );
  }
}

/// 重复规则配置表单
class RecurrenceConfigSheet extends StatefulWidget {
  final RecurrenceRule? initialRule;
  final ValueChanged<RecurrenceRule?> onConfirm;

  const RecurrenceConfigSheet({
    super.key,
    this.initialRule,
    required this.onConfirm,
  });

  @override
  State<RecurrenceConfigSheet> createState() => _RecurrenceConfigSheetState();
}

class _RecurrenceConfigSheetState extends State<RecurrenceConfigSheet> {
  late Frequency? _frequency;
  late int _interval;
  late int? _count;
  late DateTime? _until;
  late List<WeekDay> _selectedDays;
  late List<int> _selectedMonthDays;
  late _EndType _endType;

  @override
  void initState() {
    super.initState();
    final rule = widget.initialRule;
    _frequency = rule?.frequency;
    _interval = rule?.interval ?? 1;
    _count = rule?.count;
    _until = rule?.until;
    _selectedDays = rule?.byDay?.toList() ?? [];
    _selectedMonthDays = rule?.byMonthDay?.toList() ?? [];

    if (_count != null) {
      _endType = _EndType.count;
    } else if (_until != null) {
      _endType = _EndType.until;
    } else {
      _endType = _EndType.never;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题栏
            AppBar(
              title: const Text('重复设置'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                TextButton(onPressed: _onConfirm, child: const Text('确定')),
              ],
            ),

            // 内容
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 频率选择
                    _buildFrequencySelector(colorScheme),

                    if (_frequency != null) ...[
                      const SizedBox(height: 24),
                      // 间隔设置
                      _buildIntervalSelector(colorScheme),

                      // 周重复：选择星期几
                      if (_frequency == Frequency.weekly) ...[
                        const SizedBox(height: 24),
                        _buildWeekDaySelector(colorScheme),
                      ],

                      // 月重复：选择日期
                      if (_frequency == Frequency.monthly) ...[
                        const SizedBox(height: 24),
                        _buildMonthDaySelector(colorScheme),
                      ],

                      const SizedBox(height: 24),
                      // 结束条件
                      _buildEndCondition(colorScheme),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequencySelector(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '重复频率',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _FrequencyChip(
              label: '不重复',
              isSelected: _frequency == null,
              onTap: () => setState(() => _frequency = null),
            ),
            ...Frequency.values.map(
              (f) => _FrequencyChip(
                label: f.label,
                isSelected: _frequency == f,
                onTap: () => setState(() => _frequency = f),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIntervalSelector(ColorScheme colorScheme) {
    final unitLabel = switch (_frequency) {
      Frequency.daily => '天',
      Frequency.weekly => '周',
      Frequency.monthly => '月',
      Frequency.yearly => '年',
      null => '',
    };

    return Row(
      children: [
        Text('每', style: TextStyle(fontSize: 16, color: colorScheme.onSurface)),
        const SizedBox(width: 12),
        SizedBox(
          width: 60,
          child: DropdownButtonFormField<int>(
            initialValue: _interval,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
            items: List.generate(30, (i) => i + 1)
                .map((n) => DropdownMenuItem(value: n, child: Text('$n')))
                .toList(),
            onChanged: (v) => setState(() => _interval = v ?? 1),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          unitLabel,
          style: TextStyle(fontSize: 16, color: colorScheme.onSurface),
        ),
      ],
    );
  }

  Widget _buildWeekDaySelector(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '重复于',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: WeekDay.values.map((day) {
            final isSelected = _selectedDays.contains(day);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedDays.remove(day);
                  } else {
                    _selectedDays.add(day);
                  }
                });
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  day.label.substring(1),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMonthDaySelector(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '每月的第几天',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: List.generate(31, (i) => i + 1).map((day) {
            final isSelected = _selectedMonthDays.contains(day);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedMonthDays.remove(day);
                  } else {
                    _selectedMonthDays.add(day);
                  }
                });
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildEndCondition(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '结束条件',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),

        // 永不结束
        RadioListTile<_EndType>(
          title: const Text('永不结束'),
          value: _EndType.never,
          groupValue: _endType,
          onChanged: (v) => setState(() {
            _endType = v!;
            _count = null;
            _until = null;
          }),
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),

        // 次数结束
        RadioListTile<_EndType>(
          title: Row(
            children: [
              const Text('共'),
              const SizedBox(width: 8),
              SizedBox(
                width: 60,
                child: TextFormField(
                  initialValue: '${_count ?? 10}',
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    isDense: true,
                  ),
                  enabled: _endType == _EndType.count,
                  onChanged: (v) => _count = int.tryParse(v),
                ),
              ),
              const SizedBox(width: 8),
              const Text('次'),
            ],
          ),
          value: _EndType.count,
          groupValue: _endType,
          onChanged: (v) => setState(() {
            _endType = v!;
            _count = _count ?? 10;
            _until = null;
          }),
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),

        // 日期结束
        RadioListTile<_EndType>(
          title: Row(
            children: [
              const Text('直到'),
              const SizedBox(width: 8),
              TextButton(
                onPressed: _endType == _EndType.until ? _pickEndDate : null,
                child: Text(
                  _until != null
                      ? '${_until!.year}年${_until!.month}月${_until!.day}日'
                      : '选择日期',
                ),
              ),
            ],
          ),
          value: _EndType.until,
          groupValue: _endType,
          onChanged: (v) => setState(() {
            _endType = v!;
            _count = null;
            _until = _until ?? DateTime.now().add(const Duration(days: 365));
          }),
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
      ],
    );
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _until ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _until = picked);
    }
  }

  void _onConfirm() {
    if (_frequency == null) {
      widget.onConfirm(null);
      return;
    }

    final rule = RecurrenceRule(
      frequency: _frequency!,
      interval: _interval,
      count: _endType == _EndType.count ? _count : null,
      until: _endType == _EndType.until ? _until : null,
      byDay: _frequency == Frequency.weekly && _selectedDays.isNotEmpty
          ? _selectedDays
          : null,
      byMonthDay:
          _frequency == Frequency.monthly && _selectedMonthDays.isNotEmpty
          ? _selectedMonthDays
          : null,
    );

    widget.onConfirm(rule);
  }
}

enum _EndType { never, count, until }

class _FrequencyChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FrequencyChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: colorScheme.primaryContainer,
      checkmarkColor: colorScheme.onPrimaryContainer,
    );
  }
}

/// 简单的重复规则显示组件（用于事件详情）
class RecurrenceDisplay extends StatelessWidget {
  final RecurrenceRule? rule;

  const RecurrenceDisplay({super.key, this.rule});

  @override
  Widget build(BuildContext context) {
    return Text(rule?.description ?? '不重复');
  }
}

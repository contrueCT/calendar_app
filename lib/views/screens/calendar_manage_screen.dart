import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/calendar_model.dart';
import '../../data/repositories/calendar_repository.dart';
import '../../data/repositories/event_repository.dart';
import 'subscription_screen.dart';

/// 日历管理页面
class CalendarManageScreen extends StatefulWidget {
  const CalendarManageScreen({super.key});

  @override
  State<CalendarManageScreen> createState() => _CalendarManageScreenState();
}

class _CalendarManageScreenState extends State<CalendarManageScreen> {
  final _calendarRepository = CalendarRepository();
  final _eventRepository = EventRepository();

  List<CalendarModel> _localCalendars = [];
  List<CalendarModel> _subscriptionCalendars = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCalendars();
  }

  Future<void> _loadCalendars() async {
    setState(() => _isLoading = true);
    try {
      final allCalendars = await _calendarRepository.getAllCalendars();
      setState(() {
        _localCalendars = allCalendars.where((c) => !c.isSubscription).toList();
        _subscriptionCalendars = allCalendars
            .where((c) => c.isSubscription)
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('加载失败: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('日历管理')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCalendars,
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  // 本地日历
                  _buildSectionHeader(
                    colorScheme,
                    '本地日历',
                    action: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _showAddCalendarDialog,
                      tooltip: '添加日历',
                    ),
                  ),
                  if (_localCalendars.isEmpty)
                    _buildEmptyHint(colorScheme, '暂无本地日历')
                  else
                    ..._localCalendars.map(
                      (calendar) => _buildCalendarTile(
                        calendar,
                        colorScheme,
                        isLocal: true,
                      ),
                    ),

                  const SizedBox(height: 16),

                  // 订阅日历
                  _buildSectionHeader(
                    colorScheme,
                    '订阅日历',
                    action: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _navigateToSubscriptionScreen,
                      tooltip: '管理订阅',
                    ),
                  ),
                  if (_subscriptionCalendars.isEmpty)
                    _buildEmptyHint(colorScheme, '暂无订阅日历')
                  else
                    ..._subscriptionCalendars.map(
                      (calendar) => _buildCalendarTile(
                        calendar,
                        colorScheme,
                        isLocal: false,
                      ),
                    ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCalendarDialog,
        icon: const Icon(Icons.add),
        label: const Text('新建日历'),
      ),
    );
  }

  Widget _buildSectionHeader(
    ColorScheme colorScheme,
    String title, {
    Widget? action,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            ),
          ),
          const Spacer(),
          if (action != null) action,
        ],
      ),
    );
  }

  Widget _buildEmptyHint(ColorScheme colorScheme, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5)),
      ),
    );
  }

  Widget _buildCalendarTile(
    CalendarModel calendar,
    ColorScheme colorScheme, {
    required bool isLocal,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: calendar.colorValue,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isLocal ? Icons.calendar_today : Icons.cloud,
            color: _getContrastColor(calendar.colorValue),
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(calendar.name, overflow: TextOverflow.ellipsis),
            ),
            if (calendar.isDefault) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '默认',
                  style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: isLocal
            ? null
            : Text(
                calendar.subscriptionUrl ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 可见性开关
            IconButton(
              icon: Icon(
                calendar.isVisible ? Icons.visibility : Icons.visibility_off,
                color: calendar.isVisible
                    ? colorScheme.primary
                    : colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              onPressed: () => _toggleVisibility(calendar),
              tooltip: calendar.isVisible ? '隐藏日历' : '显示日历',
            ),
            // 更多操作
            PopupMenuButton<String>(
              onSelected: (value) =>
                  _handleMenuAction(value, calendar, isLocal),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit),
                    title: Text('编辑'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                if (isLocal && !calendar.isDefault)
                  const PopupMenuItem(
                    value: 'setDefault',
                    child: ListTile(
                      leading: Icon(Icons.star),
                      title: Text('设为默认'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                if (!calendar.isDefault)
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete, color: Colors.red),
                      title: Text('删除', style: TextStyle(color: Colors.red)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getContrastColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  Future<void> _toggleVisibility(CalendarModel calendar) async {
    try {
      await _calendarRepository.updateCalendarVisibility(
        calendar.id,
        !calendar.isVisible,
      );
      _loadCalendars();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('更新失败: $e')));
      }
    }
  }

  void _handleMenuAction(String action, CalendarModel calendar, bool isLocal) {
    switch (action) {
      case 'edit':
        if (isLocal) {
          _showEditCalendarDialog(calendar);
        } else {
          _navigateToSubscriptionScreen();
        }
        break;
      case 'setDefault':
        _setDefaultCalendar(calendar);
        break;
      case 'delete':
        _confirmDeleteCalendar(calendar);
        break;
    }
  }

  void _showAddCalendarDialog() {
    showDialog(
      context: context,
      builder: (context) => _CalendarEditDialog(onSave: _addCalendar),
    );
  }

  void _showEditCalendarDialog(CalendarModel calendar) {
    showDialog(
      context: context,
      builder: (context) => _CalendarEditDialog(
        calendar: calendar,
        onSave: (name, color) => _updateCalendar(calendar, name, color),
      ),
    );
  }

  Future<void> _addCalendar(String name, int color) async {
    try {
      final calendar = CalendarModel(
        id: const Uuid().v4(),
        name: name,
        color: color,
        isDefault: _localCalendars.isEmpty, // 第一个日历设为默认
        createdAt: DateTime.now(),
      );

      await _calendarRepository.insertCalendar(calendar);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('已创建日历"$name"')));
      }
      _loadCalendars();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('创建失败: $e')));
      }
    }
  }

  Future<void> _updateCalendar(
    CalendarModel calendar,
    String name,
    int color,
  ) async {
    try {
      final updated = calendar.copyWith(name: name, color: color);
      await _calendarRepository.updateCalendar(updated);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('已更新日历"$name"')));
      }
      _loadCalendars();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('更新失败: $e')));
      }
    }
  }

  Future<void> _setDefaultCalendar(CalendarModel calendar) async {
    try {
      await _calendarRepository.setDefaultCalendar(calendar.id);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('已将"${calendar.name}"设为默认日历')));
      }
      _loadCalendars();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('设置失败: $e')));
      }
    }
  }

  void _confirmDeleteCalendar(CalendarModel calendar) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除日历'),
        content: Text(
          '确定要删除日历"${calendar.name}"吗？\n'
          '这将同时删除该日历中的所有事件。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteCalendar(calendar);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCalendar(CalendarModel calendar) async {
    try {
      // 先删除该日历的所有事件
      await _eventRepository.deleteEventsByCalendar(calendar.id);
      // 再删除日历
      await _calendarRepository.deleteCalendar(calendar.id);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('已删除日历"${calendar.name}"')));
      }
      _loadCalendars();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('删除失败: $e')));
      }
    }
  }

  void _navigateToSubscriptionScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
    ).then((_) => _loadCalendars());
  }
}

/// 日历编辑对话框
class _CalendarEditDialog extends StatefulWidget {
  final CalendarModel? calendar;
  final Future<void> Function(String name, int color) onSave;

  const _CalendarEditDialog({this.calendar, required this.onSave});

  @override
  State<_CalendarEditDialog> createState() => _CalendarEditDialogState();
}

class _CalendarEditDialogState extends State<_CalendarEditDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  Color _selectedColor = Colors.blue;

  bool get _isEditing => widget.calendar != null;

  @override
  void initState() {
    super.initState();
    if (widget.calendar != null) {
      _nameController.text = widget.calendar!.name;
      _selectedColor = widget.calendar!.colorValue;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(_isEditing ? '编辑日历' : '新建日历'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '日历名称',
                prefixIcon: Icon(Icons.calendar_today),
              ),
              autofocus: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入日历名称';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(Icons.palette, color: Colors.grey),
                const SizedBox(width: 12),
                const Text('日历颜色'),
                const Spacer(),
                GestureDetector(
                  onTap: _showColorPicker,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _selectedColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: colorScheme.outline, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(onPressed: _save, child: Text(_isEditing ? '保存' : '创建')),
      ],
    );
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择颜色'),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: _selectedColor,
            onColorChanged: (color) {
              setState(() => _selectedColor = color);
              Navigator.pop(context);
            },
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    Navigator.pop(context);
    await widget.onSave(_nameController.text.trim(), _selectedColor.toARGB32());
  }
}

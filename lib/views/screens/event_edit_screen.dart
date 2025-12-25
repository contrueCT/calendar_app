import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/models.dart';
import '../../viewmodels/event_edit_viewmodel.dart';
import '../../viewmodels/calendar_viewmodel.dart';
import '../widgets/form/form_widgets.dart';

/// 事件编辑/添加页面
class EventEditScreen extends StatefulWidget {
  /// 要编辑的事件（新建时为null）
  final EventModel? event;

  /// 初始日期（新建时可选）
  final DateTime? initialDate;

  /// 初始时间（新建时可选）
  final TimeOfDay? initialTime;

  const EventEditScreen({
    super.key,
    this.event,
    this.initialDate,
    this.initialTime,
  });

  @override
  State<EventEditScreen> createState() => _EventEditScreenState();
}

class _EventEditScreenState extends State<EventEditScreen> {
  late final EventEditViewModel _viewModel;
  late final TextEditingController _summaryController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;
  late final TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    _viewModel = EventEditViewModel();
    _summaryController = TextEditingController();
    _descriptionController = TextEditingController();
    _locationController = TextEditingController();
    _urlController = TextEditingController();

    // 初始化ViewModel
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.event != null) {
        _viewModel.initializeForEdit(widget.event!).then((_) {
          _syncControllersFromViewModel();
        });
      } else {
        _viewModel.initializeForCreate(
          initialDate: widget.initialDate,
          initialTime: widget.initialTime,
        );
      }
    });
  }

  void _syncControllersFromViewModel() {
    _summaryController.text = _viewModel.summary;
    _descriptionController.text = _viewModel.description ?? '';
    _locationController.text = _viewModel.location ?? '';
    _urlController.text = _viewModel.url ?? '';
  }

  @override
  void dispose() {
    _summaryController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _urlController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<EventEditViewModel>(
        builder: (context, viewModel, child) {
          return PopScope(
            canPop: !viewModel.hasChanges,
            onPopInvokedWithResult: (didPop, result) {
              if (!didPop && viewModel.hasChanges) {
                _showDiscardDialog();
              }
            },
            child: Scaffold(
              appBar: _buildAppBar(context, viewModel),
              body: viewModel.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildForm(context, viewModel),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    EventEditViewModel viewModel,
  ) {
    return AppBar(
      title: Text(viewModel.isEditMode ? '编辑事件' : '新建事件'),
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () {
          if (viewModel.hasChanges) {
            _showDiscardDialog();
          } else {
            Navigator.pop(context);
          }
        },
      ),
      actions: [
        // 保存按钮
        TextButton(
          onPressed: viewModel.isSaving || !viewModel.isValid
              ? null
              : () => _save(context, viewModel),
          child: viewModel.isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('保存'),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context, EventEditViewModel viewModel) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 错误提示
          if (viewModel.error != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      viewModel.error!,
                      style: TextStyle(color: colorScheme.onErrorContainer),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: colorScheme.onErrorContainer,
                    ),
                    onPressed: viewModel.clearError,
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

          // 标题
          _buildSectionCard(
            context,
            children: [
              TextFormField(
                controller: _summaryController,
                decoration: const InputDecoration(
                  hintText: '添加标题',
                  border: InputBorder.none,
                ),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
                onChanged: viewModel.setSummary,
                textCapitalization: TextCapitalization.sentences,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 时间设置
          _buildSectionCard(
            context,
            children: [
              // 全天开关
              AllDaySwitch(
                value: viewModel.isAllDay,
                onChanged: viewModel.setIsAllDay,
              ),
              const Divider(height: 1),

              // 开始时间
              DateTimePicker(
                label: '开始',
                date: viewModel.startDate,
                time: viewModel.startTime,
                isAllDay: viewModel.isAllDay,
                onDateChanged: viewModel.setStartDate,
                onTimeChanged: viewModel.setStartTime,
              ),
              const Divider(height: 1),

              // 结束时间
              DateTimePicker(
                label: '结束',
                date: viewModel.endDate,
                time: viewModel.endTime,
                isAllDay: viewModel.isAllDay,
                onDateChanged: viewModel.setEndDate,
                onTimeChanged: viewModel.setEndTime,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 重复和提醒
          _buildSectionCard(
            context,
            children: [
              // 重复规则
              RecurrencePicker(
                rule: viewModel.recurrenceRule,
                onChanged: viewModel.setRecurrenceRule,
              ),
              const Divider(height: 1),

              // 提醒
              ReminderPicker(
                reminders: viewModel.reminders,
                onAdd: viewModel.addReminder,
                onRemove: viewModel.removeReminder,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 日历和颜色
          _buildSectionCard(
            context,
            children: [
              // 日历选择
              _buildCalendarPicker(context, viewModel),
              const Divider(height: 1),

              // 颜色选择
              ColorPickerField(
                color: viewModel.color != null
                    ? Color(viewModel.color!)
                    : colorScheme.primary,
                onChanged: (color) => viewModel.setColor(color.toARGB32()),
                label: '事件颜色',
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 地点
          _buildSectionCard(
            context,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    color: colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        hintText: '添加地点',
                        border: InputBorder.none,
                      ),
                      onChanged: viewModel.setLocation,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 备注
          _buildSectionCard(
            context,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Icon(
                      Icons.notes,
                      color: colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        hintText: '添加备注',
                        border: InputBorder.none,
                      ),
                      maxLines: null,
                      minLines: 3,
                      onChanged: viewModel.setDescription,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // URL
          _buildSectionCard(
            context,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.link,
                    color: colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _urlController,
                      decoration: const InputDecoration(
                        hintText: '添加链接',
                        border: InputBorder.none,
                      ),
                      keyboardType: TextInputType.url,
                      onChanged: viewModel.setUrl,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required List<Widget> children,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _buildCalendarPicker(
    BuildContext context,
    EventEditViewModel viewModel,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    // 查找当前选中的日历
    CalendarModel? selectedCalendar;
    try {
      selectedCalendar = viewModel.calendars.firstWhere(
        (c) => c.id == viewModel.calendarId,
      );
    } catch (_) {
      selectedCalendar = null;
    }

    return InkWell(
      onTap: () => _showCalendarPicker(context, viewModel),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: selectedCalendar?.colorValue ?? colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('日历', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(
                    selectedCalendar?.displayName ?? '选择日历',
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

  void _showCalendarPicker(BuildContext context, EventEditViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '选择日历',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const Divider(height: 1),
            ...viewModel.calendars.map((calendar) {
              final isSelected = calendar.id == viewModel.calendarId;
              return ListTile(
                leading: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: calendar.colorValue,
                    shape: BoxShape.circle,
                  ),
                ),
                title: Text(calendar.displayName),
                trailing: isSelected
                    ? Icon(
                        Icons.check,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                onTap: () {
                  viewModel.setCalendarId(calendar.id);
                  Navigator.pop(context);
                },
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showDiscardDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('放弃更改？'),
        content: const Text('您有未保存的更改。确定要放弃吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('继续编辑'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // 关闭对话框
              Navigator.pop(this.context); // 关闭编辑页面
            },
            child: Text(
              '放弃',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save(BuildContext context, EventEditViewModel viewModel) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final calendarViewModel = context.read<CalendarViewModel>();
    final isEditMode = viewModel.isEditMode;

    final success = await viewModel.save();
    if (success && mounted) {
      // 刷新日历视图
      await calendarViewModel.refreshEvents();

      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(isEditMode ? '事件已更新' : '事件已创建')),
        );
        navigator.pop(true);
      }
    }
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/services/icalendar_service.dart';
import '../../data/models/calendar_model.dart';
import '../../data/models/event_model.dart';
import '../../data/repositories/calendar_repository.dart';

/// 导入导出页面
class ImportExportScreen extends StatefulWidget {
  const ImportExportScreen({super.key});

  @override
  State<ImportExportScreen> createState() => _ImportExportScreenState();
}

class _ImportExportScreenState extends State<ImportExportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _calendarRepository = CalendarRepository();
  final _icalendarService = ICalendarService();

  List<CalendarModel> _calendars = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCalendars();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCalendars() async {
    setState(() => _isLoading = true);
    try {
      final calendars = await _calendarRepository.getAllCalendars();
      setState(() {
        _calendars = calendars.where((c) => !c.isSubscription).toList();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('导入导出'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.file_download), text: '导入'),
            Tab(icon: Icon(Icons.file_upload), text: '导出'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _ImportTab(
                  calendars: _calendars,
                  icalendarService: _icalendarService,
                ),
                _ExportTab(
                  calendars: _calendars,
                  icalendarService: _icalendarService,
                ),
              ],
            ),
    );
  }
}

/// 导入标签页
class _ImportTab extends StatefulWidget {
  final List<CalendarModel> calendars;
  final ICalendarService icalendarService;

  const _ImportTab({required this.calendars, required this.icalendarService});

  @override
  State<_ImportTab> createState() => _ImportTabState();
}

class _ImportTabState extends State<_ImportTab> {
  ImportPreview? _preview;
  bool _isLoading = false;
  String? _selectedCalendarId;
  bool _skipDuplicates = true;

  @override
  void initState() {
    super.initState();
    if (widget.calendars.isNotEmpty) {
      _selectedCalendarId = widget.calendars
          .firstWhere((c) => c.isDefault, orElse: () => widget.calendars.first)
          .id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 选择文件按钮
          Card(
            child: InkWell(
              onTap: _isLoading ? null : _pickFile,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.upload_file,
                      size: 48,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '选择 iCalendar 文件',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '支持 .ics, .ical 格式',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (_isLoading) ...[
            const SizedBox(height: 24),
            const Center(child: CircularProgressIndicator()),
          ],

          // 预览内容
          if (_preview != null && _preview!.success) ...[
            const SizedBox(height: 24),
            _buildPreviewSection(colorScheme),
          ],

          // 错误信息
          if (_preview != null && !_preview!.success) ...[
            const SizedBox(height: 24),
            Card(
              color: colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.error, color: colorScheme.error),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _preview!.error ?? '解析失败',
                        style: TextStyle(color: colorScheme.error),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreviewSection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 文件信息
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      '文件解析成功',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_preview!.calendarName != null)
                  _buildInfoRow('日历名称', _preview!.calendarName!),
                _buildInfoRow('事件数量', '${_preview!.events.length} 个'),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // 目标日历选择
        Text(
          '导入到日历',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedCalendarId,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: widget.calendars.map((calendar) {
            return DropdownMenuItem(
              value: calendar.id,
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: calendar.colorValue,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(calendar.name),
                  if (calendar.isDefault) ...[
                    const SizedBox(width: 8),
                    Text(
                      '(默认)',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedCalendarId = value);
          },
        ),

        const SizedBox(height: 16),

        // 选项
        CheckboxListTile(
          title: const Text('跳过重复事件'),
          subtitle: const Text('已存在相同 UID 的事件将被跳过'),
          value: _skipDuplicates,
          onChanged: (value) {
            setState(() => _skipDuplicates = value ?? true);
          },
          contentPadding: EdgeInsets.zero,
        ),

        const SizedBox(height: 16),

        // 事件预览列表
        Text(
          '事件预览',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _preview!.events.length.clamp(0, 10),
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final event = _preview!.events[index];
                return ListTile(
                  dense: true,
                  title: Text(
                    event.summary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    _formatEventTime(event),
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  trailing: event.isRecurring
                      ? Icon(Icons.repeat, size: 16, color: colorScheme.primary)
                      : null,
                );
              },
            ),
          ),
        ),

        if (_preview!.events.length > 10) ...[
          const SizedBox(height: 8),
          Text(
            '还有 ${_preview!.events.length - 10} 个事件...',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],

        const SizedBox(height: 24),

        // 导入按钮
        FilledButton.icon(
          onPressed: _selectedCalendarId != null ? _import : null,
          icon: const Icon(Icons.download),
          label: const Text('开始导入'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatEventTime(EventModel event) {
    final dateFormat = DateFormat('yyyy/MM/dd');
    final timeFormat = DateFormat('HH:mm');

    if (event.isAllDay) {
      return dateFormat.format(event.dtStart);
    }

    final date = dateFormat.format(event.dtStart);
    final startTime = timeFormat.format(event.dtStart);
    if (event.dtEnd != null) {
      final endTime = timeFormat.format(event.dtEnd!);
      return '$date $startTime - $endTime';
    }
    return '$date $startTime';
  }

  Future<void> _pickFile() async {
    setState(() {
      _isLoading = true;
      _preview = null;
    });

    try {
      final preview = await widget.icalendarService.pickAndPreviewFile();
      setState(() {
        _preview = preview;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _preview = ImportPreview.failure('选择文件失败: $e');
        _isLoading = false;
      });
    }
  }

  Future<void> _import() async {
    if (_preview == null || !_preview!.success || _selectedCalendarId == null) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await widget.icalendarService.importEvents(
        events: _preview!.events,
        targetCalendarId: _selectedCalendarId!,
        skipDuplicates: _skipDuplicates,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.summary),
            backgroundColor: result.success ? null : Colors.red,
          ),
        );

        if (result.success) {
          setState(() => _preview = null);
        }
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

/// 导出标签页
class _ExportTab extends StatefulWidget {
  final List<CalendarModel> calendars;
  final ICalendarService icalendarService;

  const _ExportTab({required this.calendars, required this.icalendarService});

  @override
  State<_ExportTab> createState() => _ExportTabState();
}

class _ExportTabState extends State<_ExportTab> {
  final Set<String> _selectedCalendarIds = {};
  bool _useDateRange = false;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now().add(const Duration(days: 365));
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    // 默认选中所有日历
    _selectedCalendarIds.addAll(widget.calendars.map((c) => c.id));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 日历选择
          Text(
            '选择要导出的日历',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                // 全选/取消全选
                CheckboxListTile(
                  title: const Text('全选'),
                  value: _selectedCalendarIds.length == widget.calendars.length,
                  tristate: true,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedCalendarIds.addAll(
                          widget.calendars.map((c) => c.id),
                        );
                      } else {
                        _selectedCalendarIds.clear();
                      }
                    });
                  },
                ),
                const Divider(height: 1),
                ...widget.calendars.map((calendar) {
                  return CheckboxListTile(
                    title: Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: calendar.colorValue,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(calendar.name),
                      ],
                    ),
                    value: _selectedCalendarIds.contains(calendar.id),
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedCalendarIds.add(calendar.id);
                        } else {
                          _selectedCalendarIds.remove(calendar.id);
                        }
                      });
                    },
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 日期范围
          SwitchListTile(
            title: const Text('指定日期范围'),
            subtitle: const Text('仅导出指定时间段内的事件'),
            value: _useDateRange,
            onChanged: (value) {
              setState(() => _useDateRange = value);
            },
            contentPadding: EdgeInsets.zero,
          ),

          if (_useDateRange) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _DatePickerField(
                    label: '开始日期',
                    date: _startDate,
                    onChanged: (date) {
                      setState(() => _startDate = date);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _DatePickerField(
                    label: '结束日期',
                    date: _endDate,
                    onChanged: (date) {
                      setState(() => _endDate = date);
                    },
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 32),

          // 导出按钮
          FilledButton.icon(
            onPressed: _selectedCalendarIds.isEmpty || _isExporting
                ? null
                : _export,
            icon: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.upload),
            label: Text(_isExporting ? '导出中...' : '导出日历'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),

          const SizedBox(height: 16),

          // 提示信息
          Card(
            color: colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '导出的文件格式为 iCalendar (.ics)，可被大多数日历应用导入。',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _export() async {
    if (_selectedCalendarIds.isEmpty) return;

    setState(() => _isExporting = true);

    try {
      final selectedCalendars = widget.calendars
          .where((c) => _selectedCalendarIds.contains(c.id))
          .toList();

      ExportResult result;

      if (selectedCalendars.length == 1) {
        result = await widget.icalendarService.exportCalendar(
          calendar: selectedCalendars.first,
          startDate: _useDateRange ? _startDate : null,
          endDate: _useDateRange ? _endDate : null,
        );
      } else {
        result = await widget.icalendarService.exportCalendars(
          calendars: selectedCalendars,
          startDate: _useDateRange ? _startDate : null,
          endDate: _useDateRange ? _endDate : null,
        );
      }

      if (mounted) {
        if (result.success && result.filePath != null) {
          _showExportSuccessDialog(result);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.error ?? '导出失败'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  void _showExportSuccessDialog(ExportResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导出成功'),
        content: Text('已导出 ${result.exportedCount} 个事件'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              widget.icalendarService.shareExportedFile(result.filePath!);
            },
            icon: const Icon(Icons.share),
            label: const Text('分享'),
          ),
        ],
      ),
    );
  }
}

/// 日期选择字段
class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  const _DatePickerField({
    required this.label,
    required this.date,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd');

    return InkWell(
      onTap: () => _showPicker(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(dateFormat.format(date)),
            const Icon(Icons.calendar_today, size: 18),
          ],
        ),
      ),
    );
  }

  Future<void> _showPicker(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      onChanged(picked);
    }
  }
}

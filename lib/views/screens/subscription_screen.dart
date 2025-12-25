import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:uuid/uuid.dart';
import '../../core/services/subscription_service.dart';
import '../../data/models/calendar_model.dart';
import '../../data/repositories/calendar_repository.dart';
import '../../data/repositories/event_repository.dart';

/// 订阅管理页面
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final _calendarRepository = CalendarRepository();
  final _eventRepository = EventRepository();
  final _subscriptionService = SubscriptionService();

  List<CalendarModel> _subscriptions = [];
  bool _isLoading = true;
  final Map<String, bool> _syncingCalendars = {};

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
  }

  Future<void> _loadSubscriptions() async {
    setState(() => _isLoading = true);
    try {
      final subscriptions = await _calendarRepository
          .getSubscriptionCalendars();
      setState(() {
        _subscriptions = subscriptions;
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
      appBar: AppBar(
        title: const Text('订阅管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _syncAllSubscriptions,
            tooltip: '同步所有',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _subscriptions.isEmpty
          ? _buildEmptyState(colorScheme)
          : _buildSubscriptionList(colorScheme),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSubscriptionDialog(),
        icon: const Icon(Icons.add),
        label: const Text('添加订阅'),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_download_outlined,
            size: 80,
            color: colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无订阅日历',
            style: TextStyle(
              fontSize: 18,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击下方按钮添加网络日历订阅',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionList(ColorScheme colorScheme) {
    return RefreshIndicator(
      onRefresh: _loadSubscriptions,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: _subscriptions.length,
        itemBuilder: (context, index) {
          final subscription = _subscriptions[index];
          final isSyncing = _syncingCalendars[subscription.id] ?? false;

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: subscription.colorValue,
                child: Icon(
                  Icons.cloud,
                  color: _getContrastColor(subscription.colorValue),
                ),
              ),
              title: Text(subscription.name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subscription.subscriptionUrl ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.sync,
                        size: 14,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        subscription.syncInterval.label,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      if (subscription.lastSyncTime != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '上次: ${_formatLastSync(subscription.lastSyncTime!)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              trailing: isSyncing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : PopupMenuButton<String>(
                      onSelected: (value) =>
                          _handleMenuAction(value, subscription),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'sync',
                          child: ListTile(
                            leading: Icon(Icons.sync),
                            title: Text('立即同步'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit),
                            title: Text('编辑'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(Icons.delete, color: Colors.red),
                            title: Text(
                              '删除',
                              style: TextStyle(color: Colors.red),
                            ),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }

  String _formatLastSync(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${time.month}/${time.day}';
  }

  Color _getContrastColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  void _handleMenuAction(String action, CalendarModel subscription) {
    switch (action) {
      case 'sync':
        _syncSubscription(subscription);
        break;
      case 'edit':
        _showEditSubscriptionDialog(subscription);
        break;
      case 'delete':
        _confirmDeleteSubscription(subscription);
        break;
    }
  }

  Future<void> _syncSubscription(CalendarModel subscription) async {
    setState(() => _syncingCalendars[subscription.id] = true);

    try {
      final result = await _subscriptionService.syncSubscription(subscription);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.success
                  ? '${subscription.name}: ${result.summary}'
                  : '同步失败: ${result.error}',
            ),
            backgroundColor: result.success ? null : Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _syncingCalendars[subscription.id] = false);
        _loadSubscriptions();
      }
    }
  }

  Future<void> _syncAllSubscriptions() async {
    if (_subscriptions.isEmpty) return;

    for (final subscription in _subscriptions) {
      setState(() => _syncingCalendars[subscription.id] = true);
    }

    try {
      final results = await _subscriptionService.syncAllSubscriptions();
      if (mounted) {
        final successCount = results.values.where((r) => r.success).length;
        final failCount = results.values.where((r) => !r.success).length;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '同步完成: $successCount 成功'
              '${failCount > 0 ? ', $failCount 失败' : ''}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        _syncingCalendars.clear();
        setState(() {});
        _loadSubscriptions();
      }
    }
  }

  void _showAddSubscriptionDialog() {
    showDialog(
      context: context,
      builder: (context) => _SubscriptionDialog(onSave: _addSubscription),
    );
  }

  void _showEditSubscriptionDialog(CalendarModel subscription) {
    showDialog(
      context: context,
      builder: (context) => _SubscriptionDialog(
        subscription: subscription,
        onSave: _updateSubscription,
      ),
    );
  }

  Future<void> _addSubscription(
    String url,
    String name,
    int color,
    SyncInterval syncInterval, {
    CalendarModel? existing,
  }) async {
    final calendar = CalendarModel(
      id: const Uuid().v4(),
      name: name,
      color: color,
      isSubscription: true,
      subscriptionUrl: url,
      syncInterval: syncInterval,
      createdAt: DateTime.now(),
    );

    await _calendarRepository.insertCalendar(calendar);

    // 立即同步
    _syncSubscription(calendar);
    _loadSubscriptions();
  }

  Future<void> _updateSubscription(
    String url,
    String name,
    int color,
    SyncInterval syncInterval, {
    CalendarModel? existing,
  }) async {
    if (existing == null) return;

    final updated = existing.copyWith(
      name: name,
      color: color,
      subscriptionUrl: url,
      syncInterval: syncInterval,
    );

    await _calendarRepository.updateCalendar(updated);
    _loadSubscriptions();
  }

  void _confirmDeleteSubscription(CalendarModel subscription) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除订阅'),
        content: Text(
          '确定要删除订阅"${subscription.name}"吗？\n'
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
              _deleteSubscription(subscription);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSubscription(CalendarModel subscription) async {
    try {
      // 先删除该日历的所有事件
      await _eventRepository.deleteEventsByCalendar(subscription.id);
      // 再删除日历
      await _calendarRepository.deleteCalendar(subscription.id);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('已删除订阅"${subscription.name}"')));
      }
      _loadSubscriptions();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('删除失败: $e')));
      }
    }
  }
}

/// 添加/编辑订阅对话框
class _SubscriptionDialog extends StatefulWidget {
  final CalendarModel? subscription;
  final Future<void> Function(
    String url,
    String name,
    int color,
    SyncInterval syncInterval, {
    CalendarModel? existing,
  })
  onSave;

  const _SubscriptionDialog({this.subscription, required this.onSave});

  @override
  State<_SubscriptionDialog> createState() => _SubscriptionDialogState();
}

class _SubscriptionDialogState extends State<_SubscriptionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _nameController = TextEditingController();
  final _subscriptionService = SubscriptionService();

  Color _selectedColor = Colors.blue;
  SyncInterval _syncInterval = SyncInterval.daily;
  bool _isValidating = false;
  bool _isUrlValidated = false;
  String? _validationError;
  int? _eventCount;

  bool get _isEditing => widget.subscription != null;

  @override
  void initState() {
    super.initState();
    if (widget.subscription != null) {
      _urlController.text = widget.subscription!.subscriptionUrl ?? '';
      _nameController.text = widget.subscription!.name;
      _selectedColor = widget.subscription!.colorValue;
      _syncInterval = widget.subscription!.syncInterval;
      _isUrlValidated = true;
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(_isEditing ? '编辑订阅' : '添加订阅'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // URL 输入
              TextFormField(
                controller: _urlController,
                decoration: InputDecoration(
                  labelText: '订阅地址',
                  hintText: 'https://example.com/calendar.ics',
                  prefixIcon: const Icon(Icons.link),
                  suffixIcon: _isValidating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : _isUrlValidated
                      ? const Icon(Icons.check, color: Colors.green)
                      : IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: _validateUrl,
                          tooltip: '验证地址',
                        ),
                  errorText: _validationError,
                ),
                enabled: !_isEditing,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入订阅地址';
                  }
                  final uri = Uri.tryParse(value);
                  if (uri == null ||
                      (!uri.isScheme('http') && !uri.isScheme('https'))) {
                    return '请输入有效的 HTTP/HTTPS 地址';
                  }
                  return null;
                },
                onChanged: (_) {
                  setState(() {
                    _isUrlValidated = false;
                    _validationError = null;
                    _eventCount = null;
                  });
                },
              ),

              if (_eventCount != null) ...[
                const SizedBox(height: 8),
                Text(
                  '包含 $_eventCount 个事件',
                  style: TextStyle(fontSize: 12, color: colorScheme.primary),
                ),
              ],

              const SizedBox(height: 16),

              // 名称输入
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '日历名称',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入日历名称';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // 颜色选择
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
                        border: Border.all(
                          color: colorScheme.outline,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 同步间隔
              Row(
                children: [
                  const Icon(Icons.sync, color: Colors.grey),
                  const SizedBox(width: 12),
                  const Text('同步频率'),
                  const Spacer(),
                  DropdownButton<SyncInterval>(
                    value: _syncInterval,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _syncInterval = value);
                      }
                    },
                    items: SyncInterval.values.map((interval) {
                      return DropdownMenuItem(
                        value: interval,
                        child: Text(interval.label),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _isValidating ? null : _save,
          child: Text(_isEditing ? '保存' : '添加'),
        ),
      ],
    );
  }

  Future<void> _validateUrl() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isValidating = true;
      _validationError = null;
    });

    try {
      final result = await _subscriptionService.validateSubscriptionUrl(
        _urlController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _isValidating = false;
          if (result.isValid) {
            _isUrlValidated = true;
            _eventCount = result.eventCount;
            if (result.calendarName != null && _nameController.text.isEmpty) {
              _nameController.text = result.calendarName!;
            }
          } else {
            _validationError = result.error;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isValidating = false;
          _validationError = '验证失败: $e';
        });
      }
    }
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

    // 非编辑模式下需要先验证 URL
    if (!_isEditing && !_isUrlValidated) {
      await _validateUrl();
      if (!_isUrlValidated) return;
    }

    if (!mounted) return;
    Navigator.pop(context);

    await widget.onSave(
      _urlController.text.trim(),
      _nameController.text.trim(),
      _selectedColor.toARGB32(),
      _syncInterval,
      existing: widget.subscription,
    );
  }
}

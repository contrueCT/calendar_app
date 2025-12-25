import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_settings/app_settings.dart';
import '../../viewmodels/settings_viewmodel.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/reminder_manager.dart';
import 'calendar_manage_screen.dart';
import 'subscription_screen.dart';
import 'import_export_screen.dart';

/// 设置页面
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final NotificationService _notificationService = NotificationService();
  bool _notificationPermissionGranted = false;
  bool _exactAlarmPermissionGranted = false;
  int _pendingNotificationCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationStatus();
  }

  Future<void> _loadNotificationStatus() async {
    final notificationGranted = await _notificationService.checkPermission();
    final exactAlarmGranted = await _notificationService
        .checkExactAlarmPermission();
    final pendingCount = await _notificationService
        .getPendingNotificationCount();

    if (mounted) {
      setState(() {
        _notificationPermissionGranted = notificationGranted;
        _exactAlarmPermissionGranted = exactAlarmGranted;
        _pendingNotificationCount = pendingCount;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<SettingsViewModel>(
              builder: (context, viewModel, child) {
                return ListView(
                  children: [
                    // 通知设置
                    _buildSectionHeader('通知'),
                    _buildNotificationSection(viewModel),

                    const Divider(),

                    // 显示设置
                    _buildSectionHeader('显示'),
                    _buildDisplaySection(viewModel),

                    const Divider(),

                    // 日历设置
                    _buildSectionHeader('日历'),
                    _buildCalendarSection(viewModel),

                    const Divider(),

                    // 关于
                    _buildSectionHeader('关于'),
                    _buildAboutSection(),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildNotificationSection(SettingsViewModel viewModel) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // 通知权限状态
        ListTile(
          leading: Icon(
            _notificationPermissionGranted
                ? Icons.notifications_active
                : Icons.notifications_off,
            color: _notificationPermissionGranted
                ? colorScheme.primary
                : colorScheme.error,
          ),
          title: const Text('通知权限'),
          subtitle: Text(
            _notificationPermissionGranted ? '已授权' : '未授权',
            style: TextStyle(
              color: _notificationPermissionGranted
                  ? colorScheme.primary
                  : colorScheme.error,
            ),
          ),
          trailing: _notificationPermissionGranted
              ? Icon(Icons.check_circle, color: colorScheme.primary)
              : TextButton(
                  onPressed: _requestNotificationPermission,
                  child: const Text('授权'),
                ),
        ),

        // 精确闹钟权限（Android 12+）
        ListTile(
          leading: Icon(
            _exactAlarmPermissionGranted ? Icons.alarm_on : Icons.alarm_off,
            color: _exactAlarmPermissionGranted
                ? colorScheme.primary
                : colorScheme.outline,
          ),
          title: const Text('精确闹钟权限'),
          subtitle: Text(
            _exactAlarmPermissionGranted ? '已授权' : '未授权（可能影响提醒准确性）',
          ),
          trailing: _exactAlarmPermissionGranted
              ? Icon(Icons.check_circle, color: colorScheme.primary)
              : TextButton(
                  onPressed: _requestExactAlarmPermission,
                  child: const Text('授权'),
                ),
        ),

        // 启用通知开关
        SwitchListTile(
          secondary: const Icon(Icons.notifications_outlined),
          title: const Text('启用事件提醒'),
          subtitle: const Text('在事件发生前发送通知提醒'),
          value: viewModel.notificationEnabled,
          onChanged: (value) async {
            if (value && !_notificationPermissionGranted) {
              // 如果要启用但没有权限，先请求权限
              final granted = await _requestNotificationPermission();
              if (!granted) return;
            }
            viewModel.setNotificationEnabled(value);
          },
        ),

        // 待处理通知数量
        if (_notificationPermissionGranted)
          ListTile(
            leading: const Icon(Icons.schedule),
            title: const Text('待处理提醒'),
            subtitle: Text('共 $_pendingNotificationCount 个提醒已调度'),
            trailing: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadNotificationStatus,
              tooltip: '刷新',
            ),
          ),

        // 默认提醒时间
        ListTile(
          leading: const Icon(Icons.timer_outlined),
          title: const Text('默认提醒时间'),
          subtitle: Text(viewModel.defaultReminderName),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showDefaultReminderPicker(context, viewModel),
        ),

        // 重新调度所有提醒
        if (_notificationPermissionGranted && viewModel.notificationEnabled)
          ListTile(
            leading: const Icon(Icons.sync),
            title: const Text('重新调度所有提醒'),
            subtitle: const Text('修复提醒不工作时使用'),
            onTap: () => _rescheduleAllReminders(context),
          ),
      ],
    );
  }

  Widget _buildDisplaySection(SettingsViewModel viewModel) {
    return Column(
      children: [
        // 主题模式
        ListTile(
          leading: const Icon(Icons.palette_outlined),
          title: const Text('主题模式'),
          subtitle: Text(viewModel.themeModeName),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showThemeModePicker(context, viewModel),
        ),

        // 显示农历
        SwitchListTile(
          secondary: const Icon(Icons.calendar_today_outlined),
          title: const Text('显示农历'),
          subtitle: const Text('在日历中显示农历日期'),
          value: viewModel.showLunarDate,
          onChanged: viewModel.setShowLunarDate,
        ),
      ],
    );
  }

  Widget _buildCalendarSection(SettingsViewModel viewModel) {
    return Column(
      children: [
        // 日历管理
        ListTile(
          leading: const Icon(Icons.calendar_month_outlined),
          title: const Text('日历管理'),
          subtitle: const Text('管理本地日历'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CalendarManageScreen()),
          ),
        ),

        // 订阅管理
        ListTile(
          leading: const Icon(Icons.cloud_download_outlined),
          title: const Text('订阅管理'),
          subtitle: const Text('管理网络日历订阅'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
          ),
        ),

        // 导入导出
        ListTile(
          leading: const Icon(Icons.import_export_outlined),
          title: const Text('导入导出'),
          subtitle: const Text('导入或导出 iCalendar 文件'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ImportExportScreen()),
          ),
        ),

        const Divider(indent: 16, endIndent: 16),

        // 默认视图
        ListTile(
          leading: const Icon(Icons.view_module_outlined),
          title: const Text('默认视图'),
          subtitle: Text(viewModel.defaultViewName),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showDefaultViewPicker(context, viewModel),
        ),

        // 一周第一天
        ListTile(
          leading: const Icon(Icons.view_week_outlined),
          title: const Text('一周的第一天'),
          subtitle: Text(viewModel.firstDayOfWeekName),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showFirstDayOfWeekPicker(context, viewModel),
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('版本'),
          subtitle: const Text('1.0.0'),
        ),
        ListTile(
          leading: const Icon(Icons.description_outlined),
          title: const Text('开源许可'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            showLicensePage(
              context: context,
              applicationName: 'Flutter日历',
              applicationVersion: '1.0.0',
            );
          },
        ),
      ],
    );
  }

  Future<bool> _requestNotificationPermission() async {
    final granted = await _notificationService.requestPermission();
    if (mounted) {
      setState(() {
        _notificationPermissionGranted = granted;
      });
      if (!granted) {
        _showPermissionDeniedDialog('通知权限', '请在系统设置中开启通知权限以接收事件提醒。');
      }
    }
    return granted;
  }

  Future<bool> _requestExactAlarmPermission() async {
    final granted = await _notificationService.requestExactAlarmPermission();
    if (mounted) {
      setState(() {
        _exactAlarmPermissionGranted = granted;
      });
      if (!granted) {
        _showPermissionDeniedDialog('精确闹钟权限', '请在系统设置中开启精确闹钟权限以确保提醒准时发送。');
      }
    }
    return granted;
  }

  void _showPermissionDeniedDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              // 打开应用设置
              AppSettings.openAppSettings();
            },
            child: const Text('去设置'),
          ),
        ],
      ),
    );
  }

  Future<void> _rescheduleAllReminders(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('重新调度提醒'),
        content: const Text('这将取消所有现有提醒并重新创建。确定继续吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // 显示加载指示器 - 使用预先保存的 navigator context
      unawaited(
        showDialog(
          context: navigator.context,
          barrierDismissible: false,
          builder: (dialogContext) =>
              const Center(child: CircularProgressIndicator()),
        ),
      );

      try {
        final reminderManager = ReminderManager();
        await reminderManager.rescheduleAllReminders();

        if (mounted) {
          navigator.pop(); // 关闭加载指示器
          await _loadNotificationStatus();
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('提醒已重新调度')),
          );
        }
      } catch (e) {
        if (mounted) {
          navigator.pop();
          scaffoldMessenger.showSnackBar(SnackBar(content: Text('重新调度失败: $e')));
        }
      }
    }
  }

  void _showDefaultReminderPicker(
    BuildContext context,
    SettingsViewModel viewModel,
  ) {
    final options = ReminderManager.defaultReminderOptions;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '默认提醒时间',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            const Divider(height: 1),
            ...options.map((option) {
              final isSelected =
                  option.minutes == viewModel.defaultReminderMinutes;
              return ListTile(
                title: Text(option.label),
                trailing: isSelected
                    ? Icon(
                        Icons.check,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                onTap: () {
                  viewModel.setDefaultReminderMinutes(option.minutes);
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

  void _showThemeModePicker(BuildContext context, SettingsViewModel viewModel) {
    final options = [('system', '跟随系统'), ('light', '浅色'), ('dark', '深色')];

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '主题模式',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            const Divider(height: 1),
            ...options.map((option) {
              final isSelected = option.$1 == viewModel.themeMode;
              return ListTile(
                title: Text(option.$2),
                trailing: isSelected
                    ? Icon(
                        Icons.check,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                onTap: () {
                  viewModel.setThemeMode(option.$1);
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

  void _showDefaultViewPicker(
    BuildContext context,
    SettingsViewModel viewModel,
  ) {
    final options = [('month', '月视图'), ('week', '周视图'), ('day', '日视图')];

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '默认视图',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            const Divider(height: 1),
            ...options.map((option) {
              final isSelected = option.$1 == viewModel.defaultView;
              return ListTile(
                title: Text(option.$2),
                trailing: isSelected
                    ? Icon(
                        Icons.check,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                onTap: () {
                  viewModel.setDefaultView(option.$1);
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

  void _showFirstDayOfWeekPicker(
    BuildContext context,
    SettingsViewModel viewModel,
  ) {
    final options = [(1, '周一'), (6, '周六'), (7, '周日')];

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '一周的第一天',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            const Divider(height: 1),
            ...options.map((option) {
              final isSelected = option.$1 == viewModel.firstDayOfWeek;
              return ListTile(
                title: Text(option.$2),
                trailing: isSelected
                    ? Icon(
                        Icons.check,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                onTap: () {
                  viewModel.setFirstDayOfWeek(option.$1);
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
}

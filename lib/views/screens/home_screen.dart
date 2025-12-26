import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/calendar_viewmodel.dart';
import '../../data/models/event_model.dart';
import '../../config/routes.dart';
import 'month_view_screen.dart';
import 'week_view_screen.dart';
import 'day_view_screen.dart';
import '../widgets/common/common.dart';

/// 首页 - 日历主界面
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // 初始化ViewModel
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CalendarViewModel>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Consumer<CalendarViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading && viewModel.events.isEmpty) {
            return const LoadingOverlay(
              isLoading: true,
              message: '加载中...',
              child: SizedBox.expand(),
            );
          }

          if (viewModel.error != null) {
            return EmptyState.error(
              message: viewModel.error!,
              onRetry: () {
                viewModel.clearError();
                viewModel.refresh();
              },
            );
          }

          // 根据 viewMode 显示不同的视图
          return _buildCalendarView(context, viewModel);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _handleAddEvent(context),
        tooltip: '添加事件',
        child: const Icon(Icons.add),
      ),
      drawer: _buildDrawer(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Consumer<CalendarViewModel>(
        builder: (context, viewModel, child) {
          return Text(_getAppBarTitle(viewModel));
        },
      ),
      actions: [
        // 今天按钮
        IconButton(
          icon: const Icon(Icons.today),
          onPressed: () {
            context.read<CalendarViewModel>().goToToday();
          },
          tooltip: '今天',
        ),

        // 视图切换按钮
        Consumer<CalendarViewModel>(
          builder: (context, viewModel, child) {
            return PopupMenuButton<CalendarViewMode>(
              icon: Icon(_getViewModeIcon(viewModel.viewMode)),
              tooltip: '视图切换',
              onSelected: (mode) {
                viewModel.setViewMode(mode);
              },
              itemBuilder: (context) => [
                _buildViewModeMenuItem(
                  CalendarViewMode.month,
                  '月视图',
                  Icons.calendar_view_month,
                  viewModel.viewMode,
                ),
                _buildViewModeMenuItem(
                  CalendarViewMode.week,
                  '周视图',
                  Icons.view_week,
                  viewModel.viewMode,
                ),
                _buildViewModeMenuItem(
                  CalendarViewMode.day,
                  '日视图',
                  Icons.view_day,
                  viewModel.viewMode,
                ),
              ],
            );
          },
        ),

        // 设置按钮
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            Navigator.of(context).pushNamed(Routes.settings);
          },
          tooltip: '设置',
        ),
      ],
    );
  }

  PopupMenuItem<CalendarViewMode> _buildViewModeMenuItem(
    CalendarViewMode mode,
    String label,
    IconData icon,
    CalendarViewMode currentMode,
  ) {
    final isSelected = mode == currentMode;
    return PopupMenuItem(
      value: mode,
      child: Row(
        children: [
          Icon(
            icon,
            color: isSelected ? Theme.of(context).colorScheme.primary : null,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Theme.of(context).colorScheme.primary : null,
              fontWeight: isSelected ? FontWeight.bold : null,
            ),
          ),
          if (isSelected) ...[
            const Spacer(),
            Icon(
              Icons.check,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCalendarView(BuildContext context, CalendarViewModel viewModel) {
    switch (viewModel.viewMode) {
      case CalendarViewMode.month:
        return MonthViewScreen(
          initialDate: viewModel.selectedDate,
          onDaySelected: (day) {
            viewModel.selectDate(day);
          },
          onEventTap: (event) => _handleEventTap(context, event),
          onMonthChanged: (date) {
            // 当月份变化时，同步更新 ViewModel 的焦点日期
            // 使用 selectDate 而不是 setFocusedDate 来避免重复加载
            viewModel.setSelectedDate(date);
          },
        );

      case CalendarViewMode.week:
        return WeekViewScreen(
          initialDate: viewModel.selectedDate,
          onDaySelected: (day) {
            viewModel.selectDate(day);
          },
          onEventTap: (event) => _handleEventTap(context, event),
          onTimeSlotTap: (date, hour) =>
              _handleTimeSlotTap(context, date, hour),
          onWeekChanged: (date) {
            // 当周变化时，同步更新 ViewModel 的选择日期
            viewModel.setSelectedDate(date);
          },
        );

      case CalendarViewMode.day:
        return DayViewScreen(
          initialDate: viewModel.selectedDate,
          onDateChanged: (day) {
            viewModel.selectDate(day);
          },
          onEventTap: (event) => _handleEventTap(context, event),
          onTimeSlotTap: (date, hour) =>
              _handleTimeSlotTap(context, date, hour),
        );
    }
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.calendar_month,
                  size: 48,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                const SizedBox(height: 8),
                Text(
                  'Flutter日历',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 4),
                Consumer<CalendarViewModel>(
                  builder: (context, viewModel, child) {
                    return Text(
                      '${viewModel.calendars.length} 个日历 · ${viewModel.events.length} 个事件',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onPrimary.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // 日历管理
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('日历管理'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamed(Routes.calendarManage);
            },
          ),

          // 订阅管理
          ListTile(
            leading: const Icon(Icons.cloud_download),
            title: const Text('订阅管理'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamed(Routes.subscription);
            },
          ),

          // 导入/导出
          ListTile(
            leading: const Icon(Icons.import_export),
            title: const Text('导入/导出'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamed(Routes.importExport);
            },
          ),

          const Divider(),

          // 设置
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('设置'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamed(Routes.settings);
            },
          ),

          // 关于
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('关于'),
            onTap: () {
              Navigator.pop(context);
              _showAboutDialog(context);
            },
          ),
        ],
      ),
    );
  }

  String _getAppBarTitle(CalendarViewModel viewModel) {
    final date = viewModel.selectedDate;
    switch (viewModel.viewMode) {
      case CalendarViewMode.month:
        return '${date.year}年${date.month}月';
      case CalendarViewMode.week:
        return '${date.year}年${date.month}月 第${_getWeekOfMonth(date)}周';
      case CalendarViewMode.day:
        return '${date.year}年${date.month}月${date.day}日';
    }
  }

  int _getWeekOfMonth(DateTime date) {
    final firstDayOfMonth = DateTime(date.year, date.month, 1);
    final firstWeekday = firstDayOfMonth.weekday % 7;
    return ((date.day + firstWeekday - 1) / 7).ceil();
  }

  IconData _getViewModeIcon(CalendarViewMode mode) {
    switch (mode) {
      case CalendarViewMode.month:
        return Icons.calendar_view_month;
      case CalendarViewMode.week:
        return Icons.view_week;
      case CalendarViewMode.day:
        return Icons.view_day;
    }
  }

  void _handleAddEvent(BuildContext context) {
    Navigator.of(context).pushNamed(
      Routes.eventCreate,
      arguments: EventEditArguments(
        initialDate: context.read<CalendarViewModel>().selectedDate,
      ),
    );
  }

  void _handleEventTap(BuildContext context, EventInstance event) {
    Navigator.of(context).pushNamed(
      Routes.eventDetail,
      arguments: EventDetailArguments(instance: event),
    );
  }

  void _handleTimeSlotTap(BuildContext context, DateTime date, int hour) {
    Navigator.of(context).pushNamed(
      Routes.eventCreate,
      arguments: EventEditArguments(
        initialDate: date,
        initialTime: TimeOfDay(hour: hour, minute: 0),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Flutter日历',
      applicationVersion: '1.0.0',
      applicationIcon: Icon(
        Icons.calendar_month,
        size: 48,
        color: Theme.of(context).colorScheme.primary,
      ),
      applicationLegalese: '© 2024 Flutter日历应用',
      children: [
        const SizedBox(height: 16),
        const Text('一款支持农历显示的跨平台日历应用。'),
        const SizedBox(height: 8),
        const Text('功能特点:'),
        const Text('• 月/周/日视图切换'),
        const Text('• 农历日期显示'),
        const Text('• 事件管理'),
        const Text('• 重复事件'),
        const Text('• 提醒功能'),
      ],
    );
  }
}

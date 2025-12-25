import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/calendar_viewmodel.dart';

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
      appBar: AppBar(
        title: const Text('Flutter日历'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              context.read<CalendarViewModel>().goToToday();
            },
            tooltip: '今天',
          ),
          PopupMenuButton<CalendarViewMode>(
            icon: const Icon(Icons.view_agenda),
            tooltip: '视图切换',
            onSelected: (mode) {
              context.read<CalendarViewModel>().setViewMode(mode);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: CalendarViewMode.month,
                child: Text('月视图'),
              ),
              const PopupMenuItem(
                value: CalendarViewMode.week,
                child: Text('周视图'),
              ),
              const PopupMenuItem(
                value: CalendarViewMode.day,
                child: Text('日视图'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: 导航到设置页面
            },
            tooltip: '设置',
          ),
        ],
      ),
      body: Consumer<CalendarViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    viewModel.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      viewModel.clearError();
                      viewModel.refresh();
                    },
                    child: const Text('重试'),
                  ),
                ],
              ),
            );
          }

          // TODO: 根据viewMode显示不同的视图
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_month,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Flutter日历应用',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '阶段一：基础架构已完成',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                Text(
                  '当前视图: ${_getViewModeName(viewModel.viewMode)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  '选中日期: ${_formatDate(viewModel.selectedDate)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  '日历数量: ${viewModel.calendars.length}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  '事件数量: ${viewModel.events.length}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: 导航到添加事件页面
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('添加事件功能将在后续阶段实现')));
        },
        tooltip: '添加事件',
        child: const Icon(Icons.add),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.calendar_month, size: 48, color: Colors.white),
                  SizedBox(height: 8),
                  Text(
                    'Flutter日历',
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('日历管理'),
              onTap: () {
                Navigator.pop(context);
                // TODO: 导航到日历管理页面
              },
            ),
            ListTile(
              leading: const Icon(Icons.cloud_download),
              title: const Text('订阅管理'),
              onTap: () {
                Navigator.pop(context);
                // TODO: 导航到订阅管理页面
              },
            ),
            ListTile(
              leading: const Icon(Icons.import_export),
              title: const Text('导入/导出'),
              onTap: () {
                Navigator.pop(context);
                // TODO: 导航到导入导出页面
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('设置'),
              onTap: () {
                Navigator.pop(context);
                // TODO: 导航到设置页面
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getViewModeName(CalendarViewMode mode) {
    switch (mode) {
      case CalendarViewMode.month:
        return '月视图';
      case CalendarViewMode.week:
        return '周视图';
      case CalendarViewMode.day:
        return '日视图';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }
}

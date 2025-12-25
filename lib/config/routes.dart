import 'package:flutter/material.dart';
import '../views/screens/home_screen.dart';

/// 路由名称常量
class Routes {
  Routes._();

  static const String home = '/';
  static const String monthView = '/month';
  static const String weekView = '/week';
  static const String dayView = '/day';
  static const String eventDetail = '/event/detail';
  static const String eventEdit = '/event/edit';
  static const String calendarManage = '/calendar/manage';
  static const String subscription = '/subscription';
  static const String importExport = '/import-export';
  static const String settings = '/settings';
}

/// 路由配置
class AppRouter {
  AppRouter._();

  /// 生成路由
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.home:
        return _buildRoute(const HomeScreen(), settings);

      case Routes.eventDetail:
        // TODO: 返回事件详情页
        return _buildRoute(
          const Placeholder(child: Center(child: Text('事件详情'))),
          settings,
        );

      case Routes.eventEdit:
        // TODO: 返回事件编辑页
        return _buildRoute(
          const Placeholder(child: Center(child: Text('事件编辑'))),
          settings,
        );

      case Routes.calendarManage:
        // TODO: 返回日历管理页
        return _buildRoute(
          const Placeholder(child: Center(child: Text('日历管理'))),
          settings,
        );

      case Routes.subscription:
        // TODO: 返回订阅管理页
        return _buildRoute(
          const Placeholder(child: Center(child: Text('订阅管理'))),
          settings,
        );

      case Routes.importExport:
        // TODO: 返回导入导出页
        return _buildRoute(
          const Placeholder(child: Center(child: Text('导入导出'))),
          settings,
        );

      case Routes.settings:
        // TODO: 返回设置页
        return _buildRoute(
          const Placeholder(child: Center(child: Text('设置'))),
          settings,
        );

      default:
        return _buildRoute(
          Scaffold(body: Center(child: Text('未找到页面: ${settings.name}'))),
          settings,
        );
    }
  }

  /// 构建路由
  static MaterialPageRoute _buildRoute(Widget page, RouteSettings settings) {
    return MaterialPageRoute(builder: (_) => page, settings: settings);
  }
}

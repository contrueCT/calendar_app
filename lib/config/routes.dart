import 'package:flutter/material.dart';
import '../views/screens/home_screen.dart';
import '../views/screens/event_detail_screen.dart';
import '../views/screens/event_edit_screen.dart';
import '../views/screens/settings_screen.dart';
import '../views/screens/calendar_manage_screen.dart';
import '../views/screens/subscription_screen.dart';
import '../views/screens/import_export_screen.dart';
import '../data/models/event_model.dart';

/// 路由名称常量
class Routes {
  Routes._();

  static const String home = '/';
  static const String monthView = '/month';
  static const String weekView = '/week';
  static const String dayView = '/day';
  static const String eventDetail = '/event/detail';
  static const String eventEdit = '/event/edit';
  static const String eventCreate = '/event/create';
  static const String calendarManage = '/calendar/manage';
  static const String subscription = '/subscription';
  static const String importExport = '/import-export';
  static const String settings = '/settings';
}

/// 事件详情页参数
class EventDetailArguments {
  final EventInstance instance;

  const EventDetailArguments({required this.instance});
}

/// 事件编辑页参数
class EventEditArguments {
  final EventModel? event;
  final DateTime? initialDate;
  final TimeOfDay? initialTime;

  const EventEditArguments({this.event, this.initialDate, this.initialTime});
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
        final args = settings.arguments as EventDetailArguments;
        return _buildRoute(
          EventDetailScreen(instance: args.instance),
          settings,
        );

      case Routes.eventEdit:
        final args = settings.arguments as EventEditArguments?;
        return _buildRoute(
          EventEditScreen(
            event: args?.event,
            initialDate: args?.initialDate,
            initialTime: args?.initialTime,
          ),
          settings,
        );

      case Routes.eventCreate:
        final args = settings.arguments as EventEditArguments?;
        return _buildRoute(
          EventEditScreen(
            initialDate: args?.initialDate,
            initialTime: args?.initialTime,
          ),
          settings,
        );

      case Routes.calendarManage:
        return _buildRoute(const CalendarManageScreen(), settings);

      case Routes.subscription:
        return _buildRoute(const SubscriptionScreen(), settings);

      case Routes.importExport:
        return _buildRoute(const ImportExportScreen(), settings);

      case Routes.settings:
        return _buildRoute(const SettingsScreen(), settings);

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

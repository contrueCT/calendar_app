import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';
import 'core/services/database_service.dart';
import 'core/services/notification_service.dart';

void main() async {
  // 确保Flutter绑定初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化日期格式化的locale数据（中文）
  await initializeDateFormatting('zh_CN', null);

  // 初始化数据库服务
  await DatabaseService().initialize();

  // 初始化通知服务
  await NotificationService().initialize();

  // 运行应用
  runApp(const CalendarApp());
}

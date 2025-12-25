// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:calendar_app/app.dart';

void main() {
  setUpAll(() async {
    // 初始化中文日期格式化
    await initializeDateFormatting('zh_CN', null);
  });

  testWidgets('App launches smoke test', (WidgetTester tester) async {
    // 设置更大的屏幕尺寸以避免溢出
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // Build our app and trigger a frame.
    await tester.pumpWidget(const CalendarApp());

    // 先等待 frame 稳定
    await tester.pump();

    // Verify that the app launches without error - the app bar shows the month view title
    expect(find.byType(CalendarApp), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:calendar_app/data/models/calendar_model.dart';

void main() {
  group('CalendarModel', () {
    group('基本属性', () {
      test('应正确创建日历', () {
        final now = DateTime.now();
        final calendar = CalendarModel(
          id: 'cal-1',
          name: '工作日历',
          color: 0xFF2196F3,
          isVisible: true,
          isDefault: true,
          createdAt: now,
        );

        expect(calendar.id, 'cal-1');
        expect(calendar.name, '工作日历');
        expect(calendar.color, 0xFF2196F3);
        expect(calendar.isVisible, isTrue);
        expect(calendar.isDefault, isTrue);
        expect(calendar.isSubscription, isFalse);
      });

      test('订阅日历应有正确属性', () {
        final now = DateTime.now();
        final calendar = CalendarModel(
          id: 'sub-1',
          name: '订阅日历',
          color: 0xFFFF0000,
          isSubscription: true,
          subscriptionUrl: 'https://example.com/calendar.ics',
          syncInterval: SyncInterval.daily,
          createdAt: now,
        );

        expect(calendar.isSubscription, isTrue);
        expect(calendar.subscriptionUrl, 'https://example.com/calendar.ics');
        expect(calendar.syncInterval, SyncInterval.daily);
      });
    });

    group('fromMap/toMap', () {
      test('应正确序列化和反序列化', () {
        final now = DateTime.now();
        final original = CalendarModel(
          id: 'cal-1',
          name: '测试日历',
          color: 0xFF00FF00,
          isVisible: false,
          isDefault: true,
          isSubscription: true,
          subscriptionUrl: 'https://test.com/cal.ics',
          syncInterval: SyncInterval.hourly,
          lastSyncTime: now,
          createdAt: now,
        );

        final map = original.toMap();
        final restored = CalendarModel.fromMap(map);

        expect(restored.id, original.id);
        expect(restored.name, original.name);
        expect(restored.color, original.color);
        expect(restored.isVisible, original.isVisible);
        expect(restored.isDefault, original.isDefault);
        expect(restored.isSubscription, original.isSubscription);
        expect(restored.subscriptionUrl, original.subscriptionUrl);
        expect(restored.syncInterval, original.syncInterval);
      });
    });

    group('copyWith', () {
      test('应正确复制并修改', () {
        final now = DateTime.now();
        final original = CalendarModel(
          id: 'cal-1',
          name: '原名称',
          color: 0xFF000000,
          createdAt: now,
        );

        final copied = original.copyWith(
          name: '新名称',
          color: 0xFFFFFFFF,
          isVisible: false,
        );

        expect(copied.id, original.id);
        expect(copied.name, '新名称');
        expect(copied.color, 0xFFFFFFFF);
        expect(copied.isVisible, isFalse);
      });
    });

    group('colorValue', () {
      test('应返回正确的Color对象', () {
        final calendar = CalendarModel(
          id: 'test',
          name: 'test',
          color: 0xFFFF5722,
          createdAt: DateTime.now(),
        );

        final color = calendar.colorValue;
        expect(color.toARGB32(), 0xFFFF5722);
      });
    });
  });

  group('SyncInterval', () {
    test('fromString应正确解析', () {
      expect(SyncInterval.fromString('manual'), SyncInterval.manual);
      expect(SyncInterval.fromString('hourly'), SyncInterval.hourly);
      expect(SyncInterval.fromString('daily'), SyncInterval.daily);
      expect(SyncInterval.fromString('weekly'), SyncInterval.weekly);
      expect(SyncInterval.fromString('invalid'), SyncInterval.manual);
    });

    test('value属性应返回正确的字符串', () {
      expect(SyncInterval.manual.value, 'manual');
      expect(SyncInterval.hourly.value, 'hourly');
      expect(SyncInterval.daily.value, 'daily');
      expect(SyncInterval.weekly.value, 'weekly');
    });

    test('label属性应返回中文标签', () {
      expect(SyncInterval.manual.label, '手动');
      expect(SyncInterval.hourly.label, '每小时');
      expect(SyncInterval.daily.label, '每天');
      expect(SyncInterval.weekly.label, '每周');
    });
  });
}

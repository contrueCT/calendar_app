import 'package:flutter/material.dart';
import '../../core/constants/db_constants.dart';

/// 同步间隔枚举
enum SyncInterval {
  manual('manual', '手动'),
  hourly('hourly', '每小时'),
  daily('daily', '每天'),
  weekly('weekly', '每周');

  final String value;
  final String label;

  const SyncInterval(this.value, this.label);

  static SyncInterval fromString(String value) {
    return SyncInterval.values.firstWhere(
      (e) => e.value == value,
      orElse: () => SyncInterval.manual,
    );
  }
}

/// 日历模型
class CalendarModel {
  final String id;
  final String name;
  final int color;
  final bool isVisible;
  final bool isDefault;
  final bool isSubscription;
  final String? subscriptionUrl;
  final SyncInterval syncInterval;
  final DateTime? lastSyncTime;
  final DateTime createdAt;

  const CalendarModel({
    required this.id,
    required this.name,
    this.color = 0xFF2196F3,
    this.isVisible = true,
    this.isDefault = false,
    this.isSubscription = false,
    this.subscriptionUrl,
    this.syncInterval = SyncInterval.manual,
    this.lastSyncTime,
    required this.createdAt,
  });

  /// 获取颜色对象
  Color get colorValue => Color(color);

  /// 获取显示名称（兼容属性）
  String get displayName => name;

  /// 从数据库Map创建
  factory CalendarModel.fromMap(Map<String, dynamic> map) {
    return CalendarModel(
      id: map[DbConstants.calendarId] as String,
      name: map[DbConstants.calendarName] as String,
      color: map[DbConstants.calendarColor] as int,
      isVisible: (map[DbConstants.calendarIsVisible] as int) == 1,
      isDefault: (map[DbConstants.calendarIsDefault] as int) == 1,
      isSubscription: (map[DbConstants.calendarIsSubscription] as int) == 1,
      subscriptionUrl: map[DbConstants.calendarSubscriptionUrl] as String?,
      syncInterval: SyncInterval.fromString(
        map[DbConstants.calendarSyncInterval] as String? ?? 'manual',
      ),
      lastSyncTime: map[DbConstants.calendarLastSyncTime] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              map[DbConstants.calendarLastSyncTime] as int,
              isUtc: true,
            ).toLocal()
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map[DbConstants.calendarCreatedAt] as int,
        isUtc: true,
      ).toLocal(),
    );
  }

  /// 转换为数据库Map
  Map<String, dynamic> toMap() {
    return {
      DbConstants.calendarId: id,
      DbConstants.calendarName: name,
      DbConstants.calendarColor: color,
      DbConstants.calendarIsVisible: isVisible ? 1 : 0,
      DbConstants.calendarIsDefault: isDefault ? 1 : 0,
      DbConstants.calendarIsSubscription: isSubscription ? 1 : 0,
      DbConstants.calendarSubscriptionUrl: subscriptionUrl,
      DbConstants.calendarSyncInterval: syncInterval.value,
      DbConstants.calendarLastSyncTime: lastSyncTime
          ?.toUtc()
          .millisecondsSinceEpoch,
      DbConstants.calendarCreatedAt: createdAt.toUtc().millisecondsSinceEpoch,
    };
  }

  /// 复制并修改
  CalendarModel copyWith({
    String? id,
    String? name,
    int? color,
    bool? isVisible,
    bool? isDefault,
    bool? isSubscription,
    String? subscriptionUrl,
    SyncInterval? syncInterval,
    DateTime? lastSyncTime,
    DateTime? createdAt,
  }) {
    return CalendarModel(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      isVisible: isVisible ?? this.isVisible,
      isDefault: isDefault ?? this.isDefault,
      isSubscription: isSubscription ?? this.isSubscription,
      subscriptionUrl: subscriptionUrl ?? this.subscriptionUrl,
      syncInterval: syncInterval ?? this.syncInterval,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'CalendarModel(id: $id, name: $name, color: $color, isVisible: $isVisible, '
        'isDefault: $isDefault, isSubscription: $isSubscription)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CalendarModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

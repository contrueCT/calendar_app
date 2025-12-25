import '../../core/constants/db_constants.dart';

/// 提醒类型枚举
enum ReminderType {
  notification('notification', '通知'),
  alarm('alarm', '闹钟');

  final String value;
  final String label;

  const ReminderType(this.value, this.label);

  static ReminderType fromString(String value) {
    return ReminderType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ReminderType.notification,
    );
  }
}

/// 提醒模型
class ReminderModel {
  final int? id;
  final String eventUid;
  final ReminderType type;
  final int triggerMinutes; // 提前分钟数（正值表示提前，0表示事件发生时）
  final int notificationId;

  const ReminderModel({
    this.id,
    required this.eventUid,
    this.type = ReminderType.notification,
    required this.triggerMinutes,
    required this.notificationId,
  });

  /// 获取提醒时间描述
  String get triggerDescription {
    if (triggerMinutes == 0) return '事件发生时';
    if (triggerMinutes < 60) return '提前${triggerMinutes}分钟';
    if (triggerMinutes < 1440) {
      final hours = triggerMinutes ~/ 60;
      final mins = triggerMinutes % 60;
      if (mins == 0) return '提前${hours}小时';
      return '提前${hours}小时${mins}分钟';
    }
    final days = triggerMinutes ~/ 1440;
    final remainingMins = triggerMinutes % 1440;
    if (remainingMins == 0) return '提前${days}天';
    final hours = remainingMins ~/ 60;
    if (hours > 0) return '提前${days}天${hours}小时';
    return '提前${days}天${remainingMins}分钟';
  }

  /// 从数据库Map创建
  factory ReminderModel.fromMap(Map<String, dynamic> map) {
    return ReminderModel(
      id: map[DbConstants.reminderId] as int?,
      eventUid: map[DbConstants.reminderEventUid] as String,
      type: ReminderType.fromString(map[DbConstants.reminderType] as String),
      triggerMinutes: map[DbConstants.reminderTriggerMinutes] as int,
      notificationId: map[DbConstants.reminderNotificationId] as int,
    );
  }

  /// 转换为数据库Map
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      DbConstants.reminderEventUid: eventUid,
      DbConstants.reminderType: type.value,
      DbConstants.reminderTriggerMinutes: triggerMinutes,
      DbConstants.reminderNotificationId: notificationId,
    };
    if (id != null) {
      map[DbConstants.reminderId] = id;
    }
    return map;
  }

  /// 复制并修改
  ReminderModel copyWith({
    int? id,
    String? eventUid,
    ReminderType? type,
    int? triggerMinutes,
    int? notificationId,
  }) {
    return ReminderModel(
      id: id ?? this.id,
      eventUid: eventUid ?? this.eventUid,
      type: type ?? this.type,
      triggerMinutes: triggerMinutes ?? this.triggerMinutes,
      notificationId: notificationId ?? this.notificationId,
    );
  }

  @override
  String toString() {
    return 'ReminderModel(id: $id, eventUid: $eventUid, type: $type, '
        'triggerMinutes: $triggerMinutes, notificationId: $notificationId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReminderModel &&
        other.id == id &&
        other.eventUid == eventUid &&
        other.triggerMinutes == triggerMinutes;
  }

  @override
  int get hashCode => Object.hash(id, eventUid, triggerMinutes);
}

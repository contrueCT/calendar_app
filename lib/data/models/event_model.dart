import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/constants/db_constants.dart';
import 'reminder_model.dart';
import 'recurrence_rule.dart';

/// 事件状态枚举
enum EventStatus {
  tentative('tentative', '暂定'),
  confirmed('confirmed', '已确认'),
  cancelled('cancelled', '已取消');

  final String value;
  final String label;

  const EventStatus(this.value, this.label);

  static EventStatus fromString(String value) {
    return EventStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => EventStatus.confirmed,
    );
  }
}

/// 事件模型
class EventModel {
  final String uid;
  final String calendarId;
  final String summary;
  final String? description;
  final String? location;
  final DateTime dtStart;
  final DateTime? dtEnd;
  final bool isAllDay;
  final String? rrule;
  final List<DateTime>? exDates;
  final int? color;
  final EventStatus status;
  final int priority;
  final String? url;
  final List<ReminderModel> reminders;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int sequence;

  const EventModel({
    required this.uid,
    required this.calendarId,
    required this.summary,
    this.description,
    this.location,
    required this.dtStart,
    this.dtEnd,
    this.isAllDay = false,
    this.rrule,
    this.exDates,
    this.color,
    this.status = EventStatus.confirmed,
    this.priority = 0,
    this.url,
    this.reminders = const [],
    required this.createdAt,
    required this.updatedAt,
    this.sequence = 0,
  });

  /// 获取颜色对象（如果有自定义颜色）
  Color? get colorValue => color != null ? Color(color!) : null;

  /// 获取事件时长
  Duration get duration {
    if (dtEnd == null) {
      return isAllDay ? const Duration(days: 1) : const Duration(hours: 1);
    }
    return dtEnd!.difference(dtStart);
  }

  /// 判断是否是重复事件
  bool get isRecurring => rrule != null && rrule!.isNotEmpty;

  /// 获取重复规则对象
  RecurrenceRule? get recurrenceRule {
    if (rrule == null) return null;
    return RecurrenceRule.fromRRuleString(rrule!);
  }

  /// 从数据库Map创建
  factory EventModel.fromMap(
    Map<String, dynamic> map, {
    List<ReminderModel>? reminders,
  }) {
    return EventModel(
      uid: map[DbConstants.eventUid] as String,
      calendarId: map[DbConstants.eventCalendarId] as String,
      summary: map[DbConstants.eventSummary] as String,
      description: map[DbConstants.eventDescription] as String?,
      location: map[DbConstants.eventLocation] as String?,
      dtStart: DateTime.fromMillisecondsSinceEpoch(
        map[DbConstants.eventDtstart] as int,
        isUtc: true,
      ).toLocal(),
      dtEnd: map[DbConstants.eventDtend] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              map[DbConstants.eventDtend] as int,
              isUtc: true,
            ).toLocal()
          : null,
      isAllDay: (map[DbConstants.eventIsAllDay] as int) == 1,
      rrule: map[DbConstants.eventRrule] as String?,
      exDates: _parseExDates(map[DbConstants.eventExdates] as String?),
      color: map[DbConstants.eventColor] as int?,
      status: EventStatus.fromString(map[DbConstants.eventStatus] as String),
      priority: map[DbConstants.eventPriority] as int? ?? 0,
      url: map[DbConstants.eventUrl] as String?,
      reminders: reminders ?? [],
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map[DbConstants.eventCreatedAt] as int,
        isUtc: true,
      ).toLocal(),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        map[DbConstants.eventUpdatedAt] as int,
        isUtc: true,
      ).toLocal(),
      sequence: map[DbConstants.eventSequence] as int? ?? 0,
    );
  }

  /// 转换为数据库Map
  Map<String, dynamic> toMap() {
    return {
      DbConstants.eventUid: uid,
      DbConstants.eventCalendarId: calendarId,
      DbConstants.eventSummary: summary,
      DbConstants.eventDescription: description,
      DbConstants.eventLocation: location,
      DbConstants.eventDtstart: dtStart.toUtc().millisecondsSinceEpoch,
      DbConstants.eventDtend: dtEnd?.toUtc().millisecondsSinceEpoch,
      DbConstants.eventIsAllDay: isAllDay ? 1 : 0,
      DbConstants.eventRrule: rrule,
      DbConstants.eventExdates: _encodeExDates(exDates),
      DbConstants.eventColor: color,
      DbConstants.eventStatus: status.value,
      DbConstants.eventPriority: priority,
      DbConstants.eventUrl: url,
      DbConstants.eventCreatedAt: createdAt.toUtc().millisecondsSinceEpoch,
      DbConstants.eventUpdatedAt: updatedAt.toUtc().millisecondsSinceEpoch,
      DbConstants.eventSequence: sequence,
    };
  }

  /// 复制并修改
  EventModel copyWith({
    String? uid,
    String? calendarId,
    String? summary,
    String? description,
    String? location,
    DateTime? dtStart,
    DateTime? dtEnd,
    bool? isAllDay,
    String? rrule,
    List<DateTime>? exDates,
    int? color,
    EventStatus? status,
    int? priority,
    String? url,
    List<ReminderModel>? reminders,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? sequence,
  }) {
    return EventModel(
      uid: uid ?? this.uid,
      calendarId: calendarId ?? this.calendarId,
      summary: summary ?? this.summary,
      description: description ?? this.description,
      location: location ?? this.location,
      dtStart: dtStart ?? this.dtStart,
      dtEnd: dtEnd ?? this.dtEnd,
      isAllDay: isAllDay ?? this.isAllDay,
      rrule: rrule ?? this.rrule,
      exDates: exDates ?? this.exDates,
      color: color ?? this.color,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      url: url ?? this.url,
      reminders: reminders ?? this.reminders,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sequence: sequence ?? this.sequence,
    );
  }

  static List<DateTime>? _parseExDates(String? exDatesJson) {
    if (exDatesJson == null || exDatesJson.isEmpty) return null;
    try {
      final List<dynamic> list = json.decode(exDatesJson);
      return list
          .map(
            (e) => DateTime.fromMillisecondsSinceEpoch(
              e as int,
              isUtc: true,
            ).toLocal(),
          )
          .toList();
    } catch (e) {
      return null;
    }
  }

  static String? _encodeExDates(List<DateTime>? exDates) {
    if (exDates == null || exDates.isEmpty) return null;
    return json.encode(
      exDates.map((e) => e.toUtc().millisecondsSinceEpoch).toList(),
    );
  }

  @override
  String toString() {
    return 'EventModel(uid: $uid, summary: $summary, dtStart: $dtStart, dtEnd: $dtEnd, '
        'isAllDay: $isAllDay, isRecurring: $isRecurring)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventModel && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}

/// 事件实例（用于重复事件的具体实例）
class EventInstance {
  final EventModel event;
  final DateTime instanceStart;
  final DateTime instanceEnd;
  final bool isException;

  const EventInstance({
    required this.event,
    required this.instanceStart,
    required this.instanceEnd,
    this.isException = false,
  });

  /// 从非重复事件创建
  factory EventInstance.fromEvent(EventModel event) {
    return EventInstance(
      event: event,
      instanceStart: event.dtStart,
      instanceEnd: event.dtEnd ?? event.dtStart.add(const Duration(hours: 1)),
    );
  }

  /// 从重复事件创建指定日期的实例
  factory EventInstance.fromRecurringEvent(
    EventModel event,
    DateTime occurrenceDate,
  ) {
    final duration = event.duration;
    final instanceStart = DateTime(
      occurrenceDate.year,
      occurrenceDate.month,
      occurrenceDate.day,
      event.dtStart.hour,
      event.dtStart.minute,
      event.dtStart.second,
    );
    return EventInstance(
      event: event,
      instanceStart: instanceStart,
      instanceEnd: instanceStart.add(duration),
    );
  }

  String get uid => event.uid;
  String get summary => event.summary;
  String? get description => event.description;
  String? get location => event.location;
  bool get isAllDay => event.isAllDay;
  Color? get colorValue => event.colorValue;

  @override
  String toString() {
    return 'EventInstance(uid: $uid, summary: $summary, instanceStart: $instanceStart)';
  }
}

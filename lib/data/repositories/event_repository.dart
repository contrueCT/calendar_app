import 'package:sqflite/sqflite.dart';
import '../models/event_model.dart';
import '../models/reminder_model.dart';
import '../datasources/local/database_helper.dart';
import '../../core/constants/db_constants.dart';

/// 事件仓库
class EventRepository {
  final DatabaseHelper _dbHelper;

  EventRepository({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper();

  /// 获取所有事件
  Future<List<EventModel>> getAllEvents() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DbConstants.tableEvents,
      orderBy: '${DbConstants.eventDtstart} ASC',
    );

    final events = <EventModel>[];
    for (final map in maps) {
      try {
        final reminders = await _getRemindersForEvent(
          map[DbConstants.eventUid] as String,
        );
        events.add(EventModel.fromMap(map, reminders: reminders));
      } catch (e) {
        print(
          'Warning: Failed to parse event in getAllEvents: ${map[DbConstants.eventUid]}, error: $e',
        );
      }
    }
    return events;
  }

  /// 获取指定日历的事件
  Future<List<EventModel>> getEventsByCalendar(String calendarId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DbConstants.tableEvents,
      where: '${DbConstants.eventCalendarId} = ?',
      whereArgs: [calendarId],
      orderBy: '${DbConstants.eventDtstart} ASC',
    );

    final events = <EventModel>[];
    for (final map in maps) {
      try {
        final reminders = await _getRemindersForEvent(
          map[DbConstants.eventUid] as String,
        );
        events.add(EventModel.fromMap(map, reminders: reminders));
      } catch (e) {
        print(
          'Warning: Failed to parse event in getEventsByCalendar: ${map[DbConstants.eventUid]}, error: $e',
        );
      }
    }
    return events;
  }

  /// 获取时间范围内的事件
  Future<List<EventModel>> getEventsInRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await _dbHelper.database;
    final startMs = start.toUtc().millisecondsSinceEpoch;
    final endMs = end.toUtc().millisecondsSinceEpoch;

    // 查询条件：
    // 1. 非重复事件：开始时间在范围内，或结束时间在范围内，或跨越整个范围
    // 2. 重复事件：开始时间在范围结束之前（需要后续展开处理）
    final maps = await db.query(
      DbConstants.tableEvents,
      where:
          '''
        (${DbConstants.eventRrule} IS NULL AND (
          (${DbConstants.eventDtstart} >= ? AND ${DbConstants.eventDtstart} < ?) OR
          (${DbConstants.eventDtend} > ? AND ${DbConstants.eventDtend} <= ?) OR
          (${DbConstants.eventDtstart} < ? AND ${DbConstants.eventDtend} > ?)
        )) OR
        (${DbConstants.eventRrule} IS NOT NULL AND ${DbConstants.eventDtstart} < ?)
      ''',
      whereArgs: [startMs, endMs, startMs, endMs, startMs, endMs, endMs],
      orderBy: '${DbConstants.eventDtstart} ASC',
    );

    final events = <EventModel>[];
    for (final map in maps) {
      try {
        final reminders = await _getRemindersForEvent(
          map[DbConstants.eventUid] as String,
        );
        events.add(EventModel.fromMap(map, reminders: reminders));
      } catch (e) {
        // 跳过解析失败的事件，避免整个加载失败
        print(
          'Warning: Failed to parse event in getEventsInRange: ${map[DbConstants.eventUid]}, error: $e',
        );
      }
    }
    return events;
  }

  /// 获取指定日期的事件
  Future<List<EventModel>> getEventsForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return getEventsInRange(start, end);
  }

  /// 根据UID获取事件
  Future<EventModel?> getEventByUid(String uid) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DbConstants.tableEvents,
      where: '${DbConstants.eventUid} = ?',
      whereArgs: [uid],
      limit: 1,
    );
    if (maps.isEmpty) return null;

    final reminders = await _getRemindersForEvent(uid);
    return EventModel.fromMap(maps.first, reminders: reminders);
  }

  /// 插入事件
  Future<void> insertEvent(EventModel event) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      // 插入事件
      await txn.insert(
        DbConstants.tableEvents,
        event.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 插入提醒
      for (final reminder in event.reminders) {
        await txn.insert(DbConstants.tableReminders, reminder.toMap());
      }
    });
  }

  /// 更新事件
  Future<void> updateEvent(EventModel event) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      // 更新事件
      await txn.update(
        DbConstants.tableEvents,
        event.toMap(),
        where: '${DbConstants.eventUid} = ?',
        whereArgs: [event.uid],
      );

      // 删除旧提醒
      await txn.delete(
        DbConstants.tableReminders,
        where: '${DbConstants.reminderEventUid} = ?',
        whereArgs: [event.uid],
      );

      // 插入新提醒
      for (final reminder in event.reminders) {
        await txn.insert(DbConstants.tableReminders, reminder.toMap());
      }
    });
  }

  /// 删除事件
  Future<void> deleteEvent(String uid) async {
    final db = await _dbHelper.database;
    await db.delete(
      DbConstants.tableEvents,
      where: '${DbConstants.eventUid} = ?',
      whereArgs: [uid],
    );
  }

  /// 删除日历下的所有事件
  Future<void> deleteEventsByCalendar(String calendarId) async {
    final db = await _dbHelper.database;
    await db.delete(
      DbConstants.tableEvents,
      where: '${DbConstants.eventCalendarId} = ?',
      whereArgs: [calendarId],
    );
  }

  /// 批量插入事件（用于导入）
  Future<void> insertEvents(List<EventModel> events) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      for (final event in events) {
        await txn.insert(
          DbConstants.tableEvents,
          event.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        for (final reminder in event.reminders) {
          await txn.insert(DbConstants.tableReminders, reminder.toMap());
        }
      }
    });
  }

  /// 替换日历的所有事件（用于订阅同步）
  Future<void> replaceCalendarEvents(
    String calendarId,
    List<EventModel> events,
  ) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      // 删除旧事件
      await txn.delete(
        DbConstants.tableEvents,
        where: '${DbConstants.eventCalendarId} = ?',
        whereArgs: [calendarId],
      );

      // 插入新事件
      for (final event in events) {
        await txn.insert(
          DbConstants.tableEvents,
          event.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        for (final reminder in event.reminders) {
          await txn.insert(DbConstants.tableReminders, reminder.toMap());
        }
      }
    });
  }

  /// 获取事件的提醒列表
  Future<List<ReminderModel>> _getRemindersForEvent(String eventUid) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DbConstants.tableReminders,
      where: '${DbConstants.reminderEventUid} = ?',
      whereArgs: [eventUid],
    );
    return maps.map((map) => ReminderModel.fromMap(map)).toList();
  }

  /// 搜索事件
  Future<List<EventModel>> searchEvents(String query) async {
    final db = await _dbHelper.database;
    final searchQuery = '%$query%';
    final maps = await db.query(
      DbConstants.tableEvents,
      where:
          '''
        ${DbConstants.eventSummary} LIKE ? OR
        ${DbConstants.eventDescription} LIKE ? OR
        ${DbConstants.eventLocation} LIKE ?
      ''',
      whereArgs: [searchQuery, searchQuery, searchQuery],
      orderBy: '${DbConstants.eventDtstart} DESC',
    );

    final events = <EventModel>[];
    for (final map in maps) {
      final reminders = await _getRemindersForEvent(
        map[DbConstants.eventUid] as String,
      );
      events.add(EventModel.fromMap(map, reminders: reminders));
    }
    return events;
  }
}

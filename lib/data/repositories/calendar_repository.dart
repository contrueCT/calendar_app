import 'package:sqflite/sqflite.dart';
import '../models/calendar_model.dart';
import '../datasources/local/database_helper.dart';
import '../../core/constants/db_constants.dart';

/// 日历仓库
class CalendarRepository {
  final DatabaseHelper _dbHelper;

  CalendarRepository({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper();

  /// 获取所有日历
  Future<List<CalendarModel>> getAllCalendars() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DbConstants.tableCalendars,
      orderBy:
          '${DbConstants.calendarIsDefault} DESC, ${DbConstants.calendarCreatedAt} ASC',
    );
    return maps.map((map) => CalendarModel.fromMap(map)).toList();
  }

  /// 获取可见日历
  Future<List<CalendarModel>> getVisibleCalendars() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DbConstants.tableCalendars,
      where: '${DbConstants.calendarIsVisible} = ?',
      whereArgs: [1],
      orderBy:
          '${DbConstants.calendarIsDefault} DESC, ${DbConstants.calendarCreatedAt} ASC',
    );
    return maps.map((map) => CalendarModel.fromMap(map)).toList();
  }

  /// 根据ID获取日历
  Future<CalendarModel?> getCalendarById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DbConstants.tableCalendars,
      where: '${DbConstants.calendarId} = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return CalendarModel.fromMap(maps.first);
  }

  /// 获取默认日历
  Future<CalendarModel?> getDefaultCalendar() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DbConstants.tableCalendars,
      where: '${DbConstants.calendarIsDefault} = ?',
      whereArgs: [1],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return CalendarModel.fromMap(maps.first);
  }

  /// 获取订阅日历
  Future<List<CalendarModel>> getSubscriptionCalendars() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DbConstants.tableCalendars,
      where: '${DbConstants.calendarIsSubscription} = ?',
      whereArgs: [1],
    );
    return maps.map((map) => CalendarModel.fromMap(map)).toList();
  }

  /// 插入日历
  Future<void> insertCalendar(CalendarModel calendar) async {
    final db = await _dbHelper.database;
    await db.insert(
      DbConstants.tableCalendars,
      calendar.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 更新日历
  Future<void> updateCalendar(CalendarModel calendar) async {
    final db = await _dbHelper.database;
    await db.update(
      DbConstants.tableCalendars,
      calendar.toMap(),
      where: '${DbConstants.calendarId} = ?',
      whereArgs: [calendar.id],
    );
  }

  /// 删除日历
  Future<void> deleteCalendar(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      DbConstants.tableCalendars,
      where: '${DbConstants.calendarId} = ?',
      whereArgs: [id],
    );
  }

  /// 设置默认日历
  Future<void> setDefaultCalendar(String id) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      // 先取消所有默认
      await txn.update(DbConstants.tableCalendars, {
        DbConstants.calendarIsDefault: 0,
      });
      // 设置新的默认
      await txn.update(
        DbConstants.tableCalendars,
        {DbConstants.calendarIsDefault: 1},
        where: '${DbConstants.calendarId} = ?',
        whereArgs: [id],
      );
    });
  }

  /// 更新日历可见性
  Future<void> updateCalendarVisibility(String id, bool isVisible) async {
    final db = await _dbHelper.database;
    await db.update(
      DbConstants.tableCalendars,
      {DbConstants.calendarIsVisible: isVisible ? 1 : 0},
      where: '${DbConstants.calendarId} = ?',
      whereArgs: [id],
    );
  }

  /// 更新最后同步时间
  Future<void> updateLastSyncTime(String id) async {
    final db = await _dbHelper.database;
    await db.update(
      DbConstants.tableCalendars,
      {
        DbConstants.calendarLastSyncTime: DateTime.now()
            .toUtc()
            .millisecondsSinceEpoch,
      },
      where: '${DbConstants.calendarId} = ?',
      whereArgs: [id],
    );
  }
}

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/db_constants.dart';

/// 数据库助手类 - 单例模式
class DatabaseHelper {
  static DatabaseHelper? _instance;
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() {
    _instance ??= DatabaseHelper._internal();
    return _instance!;
  }

  /// 获取数据库实例
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// 初始化数据库
  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, AppConstants.dbName);

    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  /// 配置数据库（启用外键）
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// 创建数据库表
  Future<void> _onCreate(Database db, int version) async {
    // 创建日历表
    await db.execute(DbConstants.createCalendarsTable);

    // 创建事件表
    await db.execute(DbConstants.createEventsTable);
    await db.execute(DbConstants.createEventsIndexCalendarId);
    await db.execute(DbConstants.createEventsIndexDtstart);
    await db.execute(DbConstants.createEventsIndexDtend);

    // 创建提醒表
    await db.execute(DbConstants.createRemindersTable);
    await db.execute(DbConstants.createRemindersIndexEventUid);

    // 创建事件缓存表
    await db.execute(DbConstants.createEventCacheTable);
    await db.execute(DbConstants.createEventCacheIndexDate);
    await db.execute(DbConstants.createEventCacheIndexEventUid);

    // 创建默认日历
    await _createDefaultCalendar(db);
  }

  /// 数据库升级
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 未来版本升级时在这里添加迁移逻辑
    // if (oldVersion < 2) {
    //   await db.execute('ALTER TABLE ...');
    // }
  }

  /// 创建默认日历
  Future<void> _createDefaultCalendar(Database db) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    await db.insert(DbConstants.tableCalendars, {
      DbConstants.calendarId: 'default',
      DbConstants.calendarName: '我的日历',
      DbConstants.calendarColor: 0xFF2196F3,
      DbConstants.calendarIsVisible: 1,
      DbConstants.calendarIsDefault: 1,
      DbConstants.calendarIsSubscription: 0,
      DbConstants.calendarSyncInterval: 'manual',
      DbConstants.calendarCreatedAt: now,
    });
  }

  /// 关闭数据库
  Future<void> close() async {
    final db = _database;
    if (db != null && db.isOpen) {
      await db.close();
      _database = null;
    }
  }

  /// 清除所有数据（用于测试或重置）
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete(DbConstants.tableEventCache);
    await db.delete(DbConstants.tableReminders);
    await db.delete(DbConstants.tableEvents);
    await db.delete(DbConstants.tableCalendars);
    await _createDefaultCalendar(db);
  }
}

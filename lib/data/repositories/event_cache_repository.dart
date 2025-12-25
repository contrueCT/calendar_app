import '../datasources/local/database_helper.dart';
import '../../core/constants/db_constants.dart';

/// 事件缓存实例模型
class EventCacheInstance {
  final int? id;
  final String eventUid;
  final DateTime occurrenceDate;
  final bool isException;

  const EventCacheInstance({
    this.id,
    required this.eventUid,
    required this.occurrenceDate,
    this.isException = false,
  });

  factory EventCacheInstance.fromMap(Map<String, dynamic> map) {
    return EventCacheInstance(
      id: map[DbConstants.eventCacheId] as int?,
      eventUid: map[DbConstants.eventCacheEventUid] as String,
      occurrenceDate: DateTime.fromMillisecondsSinceEpoch(
        map[DbConstants.eventCacheOccurrenceDate] as int,
        isUtc: true,
      ).toLocal(),
      isException: (map[DbConstants.eventCacheIsException] as int) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) DbConstants.eventCacheId: id,
      DbConstants.eventCacheEventUid: eventUid,
      DbConstants.eventCacheOccurrenceDate: occurrenceDate
          .toUtc()
          .millisecondsSinceEpoch,
      DbConstants.eventCacheIsException: isException ? 1 : 0,
    };
  }

  EventCacheInstance copyWith({
    int? id,
    String? eventUid,
    DateTime? occurrenceDate,
    bool? isException,
  }) {
    return EventCacheInstance(
      id: id ?? this.id,
      eventUid: eventUid ?? this.eventUid,
      occurrenceDate: occurrenceDate ?? this.occurrenceDate,
      isException: isException ?? this.isException,
    );
  }

  @override
  String toString() {
    return 'EventCacheInstance(eventUid: $eventUid, occurrenceDate: $occurrenceDate, isException: $isException)';
  }
}

/// 事件缓存仓库
/// 用于存储和管理重复事件的实例缓存
class EventCacheRepository {
  final DatabaseHelper _dbHelper;

  /// 默认缓存天数（90天）
  static const int defaultCacheDays = 90;

  EventCacheRepository({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper();

  /// 获取事件在指定时间范围内的缓存实例
  Future<List<EventCacheInstance>> getCachedInstances(
    String eventUid,
    DateTime start,
    DateTime end,
  ) async {
    final db = await _dbHelper.database;
    final startMs = start.toUtc().millisecondsSinceEpoch;
    final endMs = end.toUtc().millisecondsSinceEpoch;

    final maps = await db.query(
      DbConstants.tableEventCache,
      where:
          '${DbConstants.eventCacheEventUid} = ? AND ${DbConstants.eventCacheOccurrenceDate} >= ? AND ${DbConstants.eventCacheOccurrenceDate} < ?',
      whereArgs: [eventUid, startMs, endMs],
      orderBy: '${DbConstants.eventCacheOccurrenceDate} ASC',
    );

    return maps.map((map) => EventCacheInstance.fromMap(map)).toList();
  }

  /// 获取事件的所有缓存实例
  Future<List<EventCacheInstance>> getAllCachedInstances(
    String eventUid,
  ) async {
    final db = await _dbHelper.database;

    final maps = await db.query(
      DbConstants.tableEventCache,
      where: '${DbConstants.eventCacheEventUid} = ?',
      whereArgs: [eventUid],
      orderBy: '${DbConstants.eventCacheOccurrenceDate} ASC',
    );

    return maps.map((map) => EventCacheInstance.fromMap(map)).toList();
  }

  /// 获取指定日期范围内所有事件的缓存实例
  Future<List<EventCacheInstance>> getCachedInstancesInRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await _dbHelper.database;
    final startMs = start.toUtc().millisecondsSinceEpoch;
    final endMs = end.toUtc().millisecondsSinceEpoch;

    final maps = await db.query(
      DbConstants.tableEventCache,
      where:
          '${DbConstants.eventCacheOccurrenceDate} >= ? AND ${DbConstants.eventCacheOccurrenceDate} < ?',
      whereArgs: [startMs, endMs],
      orderBy: '${DbConstants.eventCacheOccurrenceDate} ASC',
    );

    return maps.map((map) => EventCacheInstance.fromMap(map)).toList();
  }

  /// 保存事件的缓存实例（批量）
  Future<void> saveInstances(
    String eventUid,
    List<DateTime> occurrenceDates, {
    bool clearExisting = true,
  }) async {
    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      if (clearExisting) {
        // 删除现有缓存
        await txn.delete(
          DbConstants.tableEventCache,
          where: '${DbConstants.eventCacheEventUid} = ?',
          whereArgs: [eventUid],
        );
      }

      // 插入新的缓存实例
      for (final date in occurrenceDates) {
        await txn.insert(DbConstants.tableEventCache, {
          DbConstants.eventCacheEventUid: eventUid,
          DbConstants.eventCacheOccurrenceDate: date
              .toUtc()
              .millisecondsSinceEpoch,
          DbConstants.eventCacheIsException: 0,
        });
      }
    });
  }

  /// 添加单个缓存实例
  Future<int> addInstance(EventCacheInstance instance) async {
    final db = await _dbHelper.database;
    return await db.insert(DbConstants.tableEventCache, instance.toMap());
  }

  /// 标记某个实例为异常（被删除的单个实例）
  Future<void> markAsException(String eventUid, DateTime occurrenceDate) async {
    final db = await _dbHelper.database;
    final dateMs = occurrenceDate.toUtc().millisecondsSinceEpoch;

    // 检查是否已存在
    final existing = await db.query(
      DbConstants.tableEventCache,
      where:
          '${DbConstants.eventCacheEventUid} = ? AND ${DbConstants.eventCacheOccurrenceDate} = ?',
      whereArgs: [eventUid, dateMs],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      // 更新为异常
      await db.update(
        DbConstants.tableEventCache,
        {DbConstants.eventCacheIsException: 1},
        where: '${DbConstants.eventCacheId} = ?',
        whereArgs: [existing.first[DbConstants.eventCacheId]],
      );
    } else {
      // 插入新的异常记录
      await db.insert(DbConstants.tableEventCache, {
        DbConstants.eventCacheEventUid: eventUid,
        DbConstants.eventCacheOccurrenceDate: dateMs,
        DbConstants.eventCacheIsException: 1,
      });
    }
  }

  /// 获取事件的所有异常日期（被排除的实例）
  Future<List<DateTime>> getExceptionDates(String eventUid) async {
    final db = await _dbHelper.database;

    final maps = await db.query(
      DbConstants.tableEventCache,
      where:
          '${DbConstants.eventCacheEventUid} = ? AND ${DbConstants.eventCacheIsException} = 1',
      whereArgs: [eventUid],
    );

    return maps.map((map) {
      return DateTime.fromMillisecondsSinceEpoch(
        map[DbConstants.eventCacheOccurrenceDate] as int,
        isUtc: true,
      ).toLocal();
    }).toList();
  }

  /// 删除事件的所有缓存
  Future<void> deleteCacheForEvent(String eventUid) async {
    final db = await _dbHelper.database;
    await db.delete(
      DbConstants.tableEventCache,
      where: '${DbConstants.eventCacheEventUid} = ?',
      whereArgs: [eventUid],
    );
  }

  /// 删除指定日期之前的所有缓存
  Future<int> deleteOldCache(DateTime beforeDate) async {
    final db = await _dbHelper.database;
    final beforeMs = beforeDate.toUtc().millisecondsSinceEpoch;

    return await db.delete(
      DbConstants.tableEventCache,
      where:
          '${DbConstants.eventCacheOccurrenceDate} < ? AND ${DbConstants.eventCacheIsException} = 0',
      whereArgs: [beforeMs],
    );
  }

  /// 检查是否有指定事件的缓存
  Future<bool> hasCacheForEvent(String eventUid) async {
    final db = await _dbHelper.database;

    final result = await db.query(
      DbConstants.tableEventCache,
      columns: ['COUNT(*) as count'],
      where:
          '${DbConstants.eventCacheEventUid} = ? AND ${DbConstants.eventCacheIsException} = 0',
      whereArgs: [eventUid],
    );

    return (result.first['count'] as int) > 0;
  }

  /// 获取缓存的日期范围
  Future<({DateTime? earliest, DateTime? latest})?> getCacheDateRange(
    String eventUid,
  ) async {
    final db = await _dbHelper.database;

    final minResult = await db.query(
      DbConstants.tableEventCache,
      columns: ['MIN(${DbConstants.eventCacheOccurrenceDate}) as min_date'],
      where:
          '${DbConstants.eventCacheEventUid} = ? AND ${DbConstants.eventCacheIsException} = 0',
      whereArgs: [eventUid],
    );

    final maxResult = await db.query(
      DbConstants.tableEventCache,
      columns: ['MAX(${DbConstants.eventCacheOccurrenceDate}) as max_date'],
      where:
          '${DbConstants.eventCacheEventUid} = ? AND ${DbConstants.eventCacheIsException} = 0',
      whereArgs: [eventUid],
    );

    final minMs = minResult.first['min_date'] as int?;
    final maxMs = maxResult.first['max_date'] as int?;

    if (minMs == null || maxMs == null) return null;

    return (
      earliest: DateTime.fromMillisecondsSinceEpoch(
        minMs,
        isUtc: true,
      ).toLocal(),
      latest: DateTime.fromMillisecondsSinceEpoch(maxMs, isUtc: true).toLocal(),
    );
  }

  /// 清除所有缓存
  Future<void> clearAllCache() async {
    final db = await _dbHelper.database;
    await db.delete(DbConstants.tableEventCache);
  }

  /// 获取缓存统计信息
  Future<Map<String, dynamic>> getCacheStats() async {
    final db = await _dbHelper.database;

    final totalResult = await db.rawQuery(
      'SELECT COUNT(*) as total FROM ${DbConstants.tableEventCache}',
    );
    final exceptionResult = await db.rawQuery(
      'SELECT COUNT(*) as exceptions FROM ${DbConstants.tableEventCache} WHERE ${DbConstants.eventCacheIsException} = 1',
    );
    final eventCountResult = await db.rawQuery(
      'SELECT COUNT(DISTINCT ${DbConstants.eventCacheEventUid}) as events FROM ${DbConstants.tableEventCache}',
    );

    return {
      'totalInstances': totalResult.first['total'] as int,
      'exceptions': exceptionResult.first['exceptions'] as int,
      'eventsWithCache': eventCountResult.first['events'] as int,
    };
  }
}

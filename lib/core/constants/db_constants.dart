/// 数据库相关常量
class DbConstants {
  DbConstants._();

  // ==================== 表名 ====================

  /// 日历表
  static const String tableCalendars = 'calendars';

  /// 事件表
  static const String tableEvents = 'events';

  /// 提醒表
  static const String tableReminders = 'reminders';

  /// 事件缓存表
  static const String tableEventCache = 'event_cache';

  // ==================== 日历表字段 ====================

  static const String calendarId = 'id';
  static const String calendarName = 'name';
  static const String calendarColor = 'color';
  static const String calendarIsVisible = 'is_visible';
  static const String calendarIsDefault = 'is_default';
  static const String calendarIsSubscription = 'is_subscription';
  static const String calendarSubscriptionUrl = 'subscription_url';
  static const String calendarSyncInterval = 'sync_interval';
  static const String calendarLastSyncTime = 'last_sync_time';
  static const String calendarCreatedAt = 'created_at';

  // ==================== 事件表字段 ====================

  static const String eventUid = 'uid';
  static const String eventCalendarId = 'calendar_id';
  static const String eventSummary = 'summary';
  static const String eventDescription = 'description';
  static const String eventLocation = 'location';
  static const String eventDtstart = 'dtstart';
  static const String eventDtend = 'dtend';
  static const String eventIsAllDay = 'is_all_day';
  static const String eventRrule = 'rrule';
  static const String eventExdates = 'exdates';
  static const String eventColor = 'color';
  static const String eventStatus = 'status';
  static const String eventPriority = 'priority';
  static const String eventUrl = 'url';
  static const String eventCreatedAt = 'created_at';
  static const String eventUpdatedAt = 'updated_at';
  static const String eventSequence = 'sequence';

  // ==================== 提醒表字段 ====================

  static const String reminderId = 'id';
  static const String reminderEventUid = 'event_uid';
  static const String reminderType = 'type';
  static const String reminderTriggerMinutes = 'trigger_minutes';
  static const String reminderNotificationId = 'notification_id';

  // ==================== 事件缓存表字段 ====================

  static const String eventCacheId = 'id';
  static const String eventCacheEventUid = 'event_uid';
  static const String eventCacheOccurrenceDate = 'occurrence_date';
  static const String eventCacheIsException = 'is_exception';

  // ==================== 建表SQL ====================

  /// 创建日历表
  static const String createCalendarsTable =
      '''
    CREATE TABLE $tableCalendars (
      $calendarId TEXT PRIMARY KEY,
      $calendarName TEXT NOT NULL,
      $calendarColor INTEGER NOT NULL DEFAULT 0xFF2196F3,
      $calendarIsVisible INTEGER NOT NULL DEFAULT 1,
      $calendarIsDefault INTEGER NOT NULL DEFAULT 0,
      $calendarIsSubscription INTEGER NOT NULL DEFAULT 0,
      $calendarSubscriptionUrl TEXT,
      $calendarSyncInterval TEXT DEFAULT 'manual',
      $calendarLastSyncTime INTEGER,
      $calendarCreatedAt INTEGER NOT NULL
    )
  ''';

  /// 创建事件表
  static const String createEventsTable =
      '''
    CREATE TABLE $tableEvents (
      $eventUid TEXT PRIMARY KEY,
      $eventCalendarId TEXT NOT NULL,
      $eventSummary TEXT NOT NULL,
      $eventDescription TEXT,
      $eventLocation TEXT,
      $eventDtstart INTEGER NOT NULL,
      $eventDtend INTEGER,
      $eventIsAllDay INTEGER NOT NULL DEFAULT 0,
      $eventRrule TEXT,
      $eventExdates TEXT,
      $eventColor INTEGER,
      $eventStatus TEXT NOT NULL DEFAULT 'confirmed',
      $eventPriority INTEGER NOT NULL DEFAULT 0,
      $eventUrl TEXT,
      $eventCreatedAt INTEGER NOT NULL,
      $eventUpdatedAt INTEGER NOT NULL,
      $eventSequence INTEGER NOT NULL DEFAULT 0,
      FOREIGN KEY ($eventCalendarId) REFERENCES $tableCalendars($calendarId) ON DELETE CASCADE
    )
  ''';

  /// 创建事件索引
  static const String createEventsIndexCalendarId =
      '''
    CREATE INDEX idx_events_calendar_id ON $tableEvents($eventCalendarId)
  ''';

  static const String createEventsIndexDtstart =
      '''
    CREATE INDEX idx_events_dtstart ON $tableEvents($eventDtstart)
  ''';

  static const String createEventsIndexDtend =
      '''
    CREATE INDEX idx_events_dtend ON $tableEvents($eventDtend)
  ''';

  /// 创建提醒表
  static const String createRemindersTable =
      '''
    CREATE TABLE $tableReminders (
      $reminderId INTEGER PRIMARY KEY AUTOINCREMENT,
      $reminderEventUid TEXT NOT NULL,
      $reminderType TEXT NOT NULL DEFAULT 'notification',
      $reminderTriggerMinutes INTEGER NOT NULL,
      $reminderNotificationId INTEGER NOT NULL,
      FOREIGN KEY ($reminderEventUid) REFERENCES $tableEvents($eventUid) ON DELETE CASCADE
    )
  ''';

  /// 创建提醒索引
  static const String createRemindersIndexEventUid =
      '''
    CREATE INDEX idx_reminders_event_uid ON $tableReminders($reminderEventUid)
  ''';

  /// 创建事件缓存表
  static const String createEventCacheTable =
      '''
    CREATE TABLE $tableEventCache (
      $eventCacheId INTEGER PRIMARY KEY AUTOINCREMENT,
      $eventCacheEventUid TEXT NOT NULL,
      $eventCacheOccurrenceDate INTEGER NOT NULL,
      $eventCacheIsException INTEGER NOT NULL DEFAULT 0,
      FOREIGN KEY ($eventCacheEventUid) REFERENCES $tableEvents($eventUid) ON DELETE CASCADE
    )
  ''';

  /// 创建事件缓存索引
  static const String createEventCacheIndexDate =
      '''
    CREATE INDEX idx_event_cache_date ON $tableEventCache($eventCacheOccurrenceDate)
  ''';

  static const String createEventCacheIndexEventUid =
      '''
    CREATE INDEX idx_event_cache_event_uid ON $tableEventCache($eventCacheEventUid)
  ''';
}

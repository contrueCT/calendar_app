import 'package:flutter/material.dart';
import '../data/models/models.dart';
import '../data/repositories/repositories.dart';
import '../core/extensions/datetime_extension.dart';
import '../core/services/reminder_manager.dart';

/// 视图模式枚举
enum CalendarViewMode { month, week, day }

/// 已加载数据范围的缓存键
class _DateRangeKey {
  final DateTime start;
  final DateTime end;

  _DateRangeKey(this.start, this.end);

  bool contains(DateTime date) {
    return !date.isBefore(start) && date.isBefore(end);
  }

  bool containsRange(DateTime rangeStart, DateTime rangeEnd) {
    return !rangeStart.isBefore(start) && !rangeEnd.isAfter(end);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _DateRangeKey && other.start == start && other.end == end;
  }

  @override
  int get hashCode => start.hashCode ^ end.hashCode;
}

/// 日历视图模型
class CalendarViewModel extends ChangeNotifier {
  final CalendarRepository _calendarRepository;
  final EventRepository _eventRepository;

  // 状态
  CalendarViewMode _viewMode = CalendarViewMode.month;
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDate = DateTime.now();
  List<CalendarModel> _calendars = [];
  List<EventModel> _events = [];
  Map<DateTime, List<EventInstance>> _eventsByDate = {};
  bool _isLoading = false;
  String? _error;

  // 性能优化：缓存相关
  _DateRangeKey? _loadedRange;
  Set<String>? _loadedCalendarIds;
  final Map<String, List<EventInstance>> _recurringInstanceCache = {};

  CalendarViewModel({
    CalendarRepository? calendarRepository,
    EventRepository? eventRepository,
  }) : _calendarRepository = calendarRepository ?? CalendarRepository(),
       _eventRepository = eventRepository ?? EventRepository();

  // Getters
  CalendarViewMode get viewMode => _viewMode;
  DateTime get selectedDate => _selectedDate;
  DateTime get focusedDate => _focusedDate;
  List<CalendarModel> get calendars => _calendars;
  List<EventModel> get events => _events;
  Map<DateTime, List<EventInstance>> get eventsByDate => _eventsByDate;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// 获取选中日期的事件
  List<EventInstance> get selectedDateEvents {
    final dateKey = _selectedDate.startOfDay;
    return _eventsByDate[dateKey] ?? [];
  }

  /// 获取可见日历
  List<CalendarModel> get visibleCalendars {
    return _calendars.where((c) => c.isVisible).toList();
  }

  /// 初始化
  Future<void> initialize() async {
    await loadCalendars();
    await loadEventsForMonth(_focusedDate);
  }

  /// 设置视图模式
  void setViewMode(CalendarViewMode mode) {
    if (_viewMode != mode) {
      _viewMode = mode;
      notifyListeners();
    }
  }

  /// 设置选中日期
  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  /// 设置焦点日期
  Future<void> setFocusedDate(DateTime date) async {
    if (!_focusedDate.isSameMonth(date)) {
      _focusedDate = date;
      await loadEventsForMonth(date);
    } else {
      _focusedDate = date;
      notifyListeners();
    }
  }

  /// 加载日历列表
  Future<void> loadCalendars() async {
    try {
      _calendars = await _calendarRepository.getAllCalendars();
      notifyListeners();
    } catch (e) {
      _error = '加载日历失败: $e';
      notifyListeners();
    }
  }

  /// 加载指定月份的事件
  Future<void> loadEventsForMonth(DateTime month) async {
    // 获取月份范围（包含前后各一周用于显示）
    final start = DateTime(
      month.year,
      month.month,
      1,
    ).subtract(const Duration(days: 7));
    final end = DateTime(
      month.year,
      month.month + 1,
      0,
    ).add(const Duration(days: 8));

    await _loadEventsForRange(start, end);
  }

  /// 加载指定周的事件
  Future<void> loadEventsForWeek(DateTime date) async {
    // 计算周的开始和结束
    final weekday = date.weekday % 7;
    final weekStart = date.subtract(Duration(days: weekday));
    final weekEnd = weekStart.add(const Duration(days: 7));

    await _loadEventsForRange(weekStart, weekEnd);
  }

  /// 加载指定日期的事件
  Future<void> loadEventsForDay(DateTime date) async {
    final dayStart = date.startOfDay;
    final dayEnd = dayStart.add(const Duration(days: 1));

    await _loadEventsForRange(dayStart, dayEnd);
  }

  /// 统一的事件加载方法（带缓存优化）
  Future<void> _loadEventsForRange(DateTime start, DateTime end) async {
    // 确保日历列表已加载，否则 visibleCalendars 为空会导致所有事件被过滤
    if (_calendars.isEmpty) {
      await loadCalendars();
    }

    // 获取当前可见日历ID集合
    final currentVisibleIds = visibleCalendars.map((c) => c.id).toSet();

    // 检查是否可以使用缓存
    final canUseCache =
        _loadedRange != null &&
        _loadedCalendarIds != null &&
        _loadedRange!.containsRange(start, end) &&
        _setEquals(_loadedCalendarIds!, currentVisibleIds);

    if (canUseCache) {
      // 缓存命中，无需重新加载
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final allEvents = await _eventRepository.getEventsInRange(start, end);
      _events = allEvents
          .where((e) => currentVisibleIds.contains(e.calendarId))
          .toList();

      // 构建按日期索引的事件Map（使用优化方法）
      _eventsByDate = _buildEventsByDateMapOptimized(_events, start, end);

      // 更新缓存状态
      _loadedRange = _DateRangeKey(start, end);
      _loadedCalendarIds = currentVisibleIds;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = '加载事件失败: $e';
      notifyListeners();
    }
  }

  /// 比较两个Set是否相等
  bool _setEquals<T>(Set<T> a, Set<T> b) {
    if (a.length != b.length) return false;
    return a.every((element) => b.contains(element));
  }

  /// 优化的事件Map构建方法
  Map<DateTime, List<EventInstance>> _buildEventsByDateMapOptimized(
    List<EventModel> events,
    DateTime start,
    DateTime end,
  ) {
    final map = <DateTime, List<EventInstance>>{};

    // 分离重复事件和非重复事件
    final recurringEvents = <EventModel>[];
    final singleEvents = <EventModel>[];

    for (final event in events) {
      if (event.isRecurring) {
        recurringEvents.add(event);
      } else {
        singleEvents.add(event);
      }
    }

    // 处理非重复事件（O(n)）
    for (final event in singleEvents) {
      final dateKey = event.dtStart.startOfDay;
      // 只添加在范围内的事件
      if (!dateKey.isBefore(start) && dateKey.isBefore(end)) {
        final instance = EventInstance.fromEvent(event);
        map.putIfAbsent(dateKey, () => []).add(instance);
      }
    }

    // 处理重复事件（使用缓存）
    for (final event in recurringEvents) {
      final instances = _getRecurringInstancesCached(event, start, end);
      for (final instance in instances) {
        final dateKey = instance.instanceStart.startOfDay;
        map.putIfAbsent(dateKey, () => []).add(instance);
      }
    }

    // 批量排序（比逐个排序更高效）
    for (final instances in map.values) {
      if (instances.length > 1) {
        instances.sort((a, b) => a.instanceStart.compareTo(b.instanceStart));
      }
    }

    return map;
  }

  /// 获取重复事件实例（带缓存）
  List<EventInstance> _getRecurringInstancesCached(
    EventModel event,
    DateTime start,
    DateTime end,
  ) {
    final cacheKey =
        '${event.uid}_${start.millisecondsSinceEpoch}_${end.millisecondsSinceEpoch}';

    // 检查缓存
    if (_recurringInstanceCache.containsKey(cacheKey)) {
      return _recurringInstanceCache[cacheKey]!;
    }

    final instances = <EventInstance>[];
    final rule = event.recurrenceRule;

    if (rule != null) {
      final occurrences = rule.getOccurrences(
        event.dtStart,
        start,
        end,
        excludeDates: event.exDates,
      );

      for (final occurrence in occurrences) {
        instances.add(EventInstance.fromRecurringEvent(event, occurrence));
      }
    }

    // 存入缓存（限制缓存大小）
    if (_recurringInstanceCache.length > 100) {
      // 清理一半的缓存
      final keysToRemove = _recurringInstanceCache.keys.take(50).toList();
      for (final key in keysToRemove) {
        _recurringInstanceCache.remove(key);
      }
    }
    _recurringInstanceCache[cacheKey] = instances;

    return instances;
  }

  /// 清除缓存（在数据变更时调用）
  void _clearCache() {
    _loadedRange = null;
    _loadedCalendarIds = null;
    _recurringInstanceCache.clear();
  }

  /// 获取指定日期的事件列表
  List<EventInstance> getEventsForDate(DateTime date) {
    final dateKey = date.startOfDay;
    return _eventsByDate[dateKey] ?? [];
  }

  /// 获取指定日期的事件列表（别名，兼容视图组件）
  List<EventInstance> getEventsForDay(DateTime day) {
    return getEventsForDate(day);
  }

  /// 判断指定日期是否有事件
  bool hasEventsOnDate(DateTime date) {
    final dateKey = date.startOfDay;
    return _eventsByDate.containsKey(dateKey) &&
        _eventsByDate[dateKey]!.isNotEmpty;
  }

  /// 选中日期（兼容视图组件）
  void selectDate(DateTime date) {
    setSelectedDate(date);
  }

  /// 刷新数据
  Future<void> refresh() async {
    _clearCache();
    await loadCalendars();
    await loadEventsForMonth(_focusedDate);
  }

  /// 切换日历可见性
  Future<void> toggleCalendarVisibility(
    String calendarId,
    bool isVisible,
  ) async {
    try {
      await _calendarRepository.updateCalendarVisibility(calendarId, isVisible);
      _clearCache();
      await loadCalendars();
      await loadEventsForMonth(_focusedDate);
    } catch (e) {
      _error = '更新日历失败: $e';
      notifyListeners();
    }
  }

  /// 前往今天
  Future<void> goToToday() async {
    final today = DateTime.now();
    _selectedDate = today;
    await setFocusedDate(today);
  }

  /// 前往上个月/周/日
  Future<void> goToPrevious() async {
    DateTime newDate;
    switch (_viewMode) {
      case CalendarViewMode.month:
        newDate = _focusedDate.addMonths(-1);
        break;
      case CalendarViewMode.week:
        newDate = _focusedDate.addDays(-7);
        break;
      case CalendarViewMode.day:
        newDate = _focusedDate.addDays(-1);
        break;
    }
    await setFocusedDate(newDate);
  }

  /// 前往下个月/周/日
  Future<void> goToNext() async {
    DateTime newDate;
    switch (_viewMode) {
      case CalendarViewMode.month:
        newDate = _focusedDate.addMonths(1);
        break;
      case CalendarViewMode.week:
        newDate = _focusedDate.addDays(7);
        break;
      case CalendarViewMode.day:
        newDate = _focusedDate.addDays(1);
        break;
    }
    await setFocusedDate(newDate);
  }

  /// 清除错误
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ==================== 事件 CRUD 操作 ====================

  /// 刷新事件列表
  Future<void> refreshEvents() async {
    // 确保日历列表已加载，否则 visibleCalendars 为空会导致所有事件被过滤
    if (_calendars.isEmpty) {
      await loadCalendars();
    }
    _clearCache();
    await loadEventsForMonth(_focusedDate);
  }

  /// 创建事件
  Future<bool> createEvent(EventModel event) async {
    try {
      // 确保日历列表已加载
      if (_calendars.isEmpty) {
        await loadCalendars();
      }
      await _eventRepository.insertEvent(event);
      _clearCache();
      await loadEventsForMonth(_focusedDate);
      return true;
    } catch (e) {
      _error = '创建事件失败: $e';
      notifyListeners();
      return false;
    }
  }

  /// 更新事件
  Future<bool> updateEvent(EventModel event) async {
    try {
      // 确保日历列表已加载
      if (_calendars.isEmpty) {
        await loadCalendars();
      }
      await _eventRepository.updateEvent(event);
      _clearCache();
      await loadEventsForMonth(_focusedDate);
      return true;
    } catch (e) {
      _error = '更新事件失败: $e';
      notifyListeners();
      return false;
    }
  }

  /// 删除事件
  Future<bool> deleteEvent(String uid) async {
    try {
      // 确保日历列表已加载
      if (_calendars.isEmpty) {
        await loadCalendars();
      }
      // 先获取事件以取消其提醒
      final event = await _eventRepository.getEventByUid(uid);
      if (event != null && event.reminders.isNotEmpty) {
        final reminderManager = ReminderManager();
        await reminderManager.cancelRemindersForEvent(event);
      }

      await _eventRepository.deleteEvent(uid);
      _clearCache();
      await loadEventsForMonth(_focusedDate);
      return true;
    } catch (e) {
      _error = '删除事件失败: $e';
      notifyListeners();
      return false;
    }
  }

  /// 删除重复事件的单个实例
  /// 通过在事件的 exDates 中添加该实例的日期来实现
  Future<bool> deleteEventInstance(
    EventModel event,
    DateTime instanceDate,
  ) async {
    try {
      // 获取当前排除日期列表
      final exDates = event.exDates?.toList() ?? [];

      // 添加新的排除日期
      exDates.add(instanceDate.startOfDay);

      // 更新事件
      final updatedEvent = event.copyWith(
        exDates: exDates,
        updatedAt: DateTime.now(),
      );

      await _eventRepository.updateEvent(updatedEvent);
      _clearCache();
      await loadEventsForMonth(_focusedDate);
      return true;
    } catch (e) {
      _error = '删除事件实例失败: $e';
      notifyListeners();
      return false;
    }
  }

  /// 根据 UID 获取事件
  Future<EventModel?> getEventByUid(String uid) async {
    try {
      return await _eventRepository.getEventByUid(uid);
    } catch (e) {
      _error = '获取事件失败: $e';
      notifyListeners();
      return null;
    }
  }
}

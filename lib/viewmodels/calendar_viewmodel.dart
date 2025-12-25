import 'package:flutter/material.dart';
import '../data/models/models.dart';
import '../data/repositories/repositories.dart';
import '../core/extensions/datetime_extension.dart';

/// 视图模式枚举
enum CalendarViewMode { month, week, day }

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
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
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
      ).add(const Duration(days: 7));

      // 只获取可见日历的事件
      final visibleCalendarIds = visibleCalendars.map((c) => c.id).toSet();
      final allEvents = await _eventRepository.getEventsInRange(start, end);
      _events = allEvents
          .where((e) => visibleCalendarIds.contains(e.calendarId))
          .toList();

      // 构建按日期索引的事件Map
      _eventsByDate = _buildEventsByDateMap(_events, start, end);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = '加载事件失败: $e';
      notifyListeners();
    }
  }

  /// 构建按日期索引的事件Map
  Map<DateTime, List<EventInstance>> _buildEventsByDateMap(
    List<EventModel> events,
    DateTime start,
    DateTime end,
  ) {
    final map = <DateTime, List<EventInstance>>{};

    for (final event in events) {
      if (event.isRecurring) {
        // 重复事件：展开实例
        final rule = event.recurrenceRule;
        if (rule != null) {
          final occurrences = rule.getOccurrences(
            event.dtStart,
            start,
            end,
            excludeDates: event.exDates,
          );
          for (final occurrence in occurrences) {
            final dateKey = occurrence.startOfDay;
            final instance = EventInstance.fromRecurringEvent(
              event,
              occurrence,
            );
            map.putIfAbsent(dateKey, () => []).add(instance);
          }
        }
      } else {
        // 非重复事件
        final dateKey = event.dtStart.startOfDay;
        final instance = EventInstance.fromEvent(event);
        map.putIfAbsent(dateKey, () => []).add(instance);
      }
    }

    // 按开始时间排序
    for (final instances in map.values) {
      instances.sort((a, b) => a.instanceStart.compareTo(b.instanceStart));
    }

    return map;
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

  /// 加载指定周的事件
  Future<void> loadEventsForWeek(DateTime date) async {
    // 计算周的开始和结束
    final weekday = date.weekday % 7;
    final weekStart = date.subtract(Duration(days: weekday));
    final weekEnd = weekStart.add(const Duration(days: 6));
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final visibleCalendarIds = visibleCalendars.map((c) => c.id).toSet();
      final allEvents = await _eventRepository.getEventsInRange(weekStart, weekEnd);
      _events = allEvents
          .where((e) => visibleCalendarIds.contains(e.calendarId))
          .toList();

      _eventsByDate = _buildEventsByDateMap(_events, weekStart, weekEnd);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = '加载事件失败: $e';
      notifyListeners();
    }
  }

  /// 加载指定日期的事件
  Future<void> loadEventsForDay(DateTime date) async {
    final dayStart = date.startOfDay;
    final dayEnd = dayStart.add(const Duration(days: 1));
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final visibleCalendarIds = visibleCalendars.map((c) => c.id).toSet();
      final allEvents = await _eventRepository.getEventsInRange(dayStart, dayEnd);
      _events = allEvents
          .where((e) => visibleCalendarIds.contains(e.calendarId))
          .toList();

      _eventsByDate = _buildEventsByDateMap(_events, dayStart, dayEnd);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = '加载事件失败: $e';
      notifyListeners();
    }
  }

  /// 刷新数据
  Future<void> refresh() async {
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
}

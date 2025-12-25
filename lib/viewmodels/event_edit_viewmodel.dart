import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../data/models/models.dart';
import '../data/repositories/repositories.dart';
import '../core/services/reminder_manager.dart';

/// 事件编辑视图模型
/// 管理事件添加/编辑表单的状态
class EventEditViewModel extends ChangeNotifier {
  final EventRepository _eventRepository;
  final CalendarRepository _calendarRepository;
  final ReminderManager _reminderManager;

  // 是否为编辑模式（false为新建模式）
  bool _isEditMode = false;
  String? _originalEventUid;

  // 表单字段
  String _summary = '';
  String? _description;
  String? _location;
  String _calendarId = 'default';
  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  DateTime _endDate = DateTime.now();
  TimeOfDay _endTime = TimeOfDay(
    hour: TimeOfDay.now().hour + 1,
    minute: TimeOfDay.now().minute,
  );
  bool _isAllDay = false;
  RecurrenceRule? _recurrenceRule;
  List<ReminderModel> _reminders = [];
  int? _color;
  String? _url;
  EventStatus _status = EventStatus.confirmed;

  // 可选日历列表
  List<CalendarModel> _calendars = [];

  // 状态
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;
  bool _hasChanges = false;

  EventEditViewModel({
    EventRepository? eventRepository,
    CalendarRepository? calendarRepository,
    ReminderManager? reminderManager,
  }) : _eventRepository = eventRepository ?? EventRepository(),
       _calendarRepository = calendarRepository ?? CalendarRepository(),
       _reminderManager = reminderManager ?? ReminderManager();

  // Getters
  bool get isEditMode => _isEditMode;
  String get summary => _summary;
  String? get description => _description;
  String? get location => _location;
  String get calendarId => _calendarId;
  DateTime get startDate => _startDate;
  TimeOfDay get startTime => _startTime;
  DateTime get endDate => _endDate;
  TimeOfDay get endTime => _endTime;
  bool get isAllDay => _isAllDay;
  RecurrenceRule? get recurrenceRule => _recurrenceRule;
  List<ReminderModel> get reminders => _reminders;
  int? get color => _color;
  String? get url => _url;
  EventStatus get status => _status;
  List<CalendarModel> get calendars => _calendars;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;
  bool get hasChanges => _hasChanges;

  /// 获取完整的开始时间
  DateTime get fullStartDateTime {
    if (_isAllDay) {
      return DateTime(_startDate.year, _startDate.month, _startDate.day);
    }
    return DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
      _startTime.hour,
      _startTime.minute,
    );
  }

  /// 获取完整的结束时间
  DateTime get fullEndDateTime {
    if (_isAllDay) {
      return DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);
    }
    return DateTime(
      _endDate.year,
      _endDate.month,
      _endDate.day,
      _endTime.hour,
      _endTime.minute,
    );
  }

  /// 验证表单
  bool get isValid {
    if (_summary.trim().isEmpty) return false;
    if (fullEndDateTime.isBefore(fullStartDateTime)) return false;
    return true;
  }

  /// 获取验证错误信息
  String? get validationError {
    if (_summary.trim().isEmpty) return '请输入事件标题';
    if (fullEndDateTime.isBefore(fullStartDateTime)) {
      return '结束时间不能早于开始时间';
    }
    return null;
  }

  /// 初始化（新建事件）
  Future<void> initializeForCreate({
    DateTime? initialDate,
    TimeOfDay? initialTime,
  }) async {
    _isEditMode = false;
    _originalEventUid = null;
    _hasChanges = false;

    // 设置初始日期时间
    final now = DateTime.now();
    _startDate = initialDate ?? now;
    _startTime = initialTime ?? TimeOfDay(hour: now.hour + 1, minute: 0);
    _endDate = _startDate;
    _endTime = TimeOfDay(hour: _startTime.hour + 1, minute: _startTime.minute);

    // 调整结束时间如果跨天
    if (_endTime.hour < _startTime.hour) {
      _endDate = _startDate.add(const Duration(days: 1));
    }

    await _loadCalendars();
  }

  /// 初始化（编辑事件）
  Future<void> initializeForEdit(EventModel event) async {
    _isEditMode = true;
    _originalEventUid = event.uid;
    _hasChanges = false;

    // 加载事件数据
    _summary = event.summary;
    _description = event.description;
    _location = event.location;
    _calendarId = event.calendarId;
    _startDate = event.dtStart;
    _startTime = TimeOfDay.fromDateTime(event.dtStart);
    _endDate = event.dtEnd ?? event.dtStart;
    _endTime = TimeOfDay.fromDateTime(event.dtEnd ?? event.dtStart);
    _isAllDay = event.isAllDay;
    _recurrenceRule = event.recurrenceRule;
    _reminders = List.from(event.reminders);
    _color = event.color;
    _url = event.url;
    _status = event.status;

    await _loadCalendars();
  }

  /// 加载日历列表
  Future<void> _loadCalendars() async {
    _isLoading = true;
    notifyListeners();

    try {
      _calendars = await _calendarRepository.getAllCalendars();
      // 过滤掉订阅日历（不能添加事件到订阅日历）
      _calendars = _calendars.where((c) => !c.isSubscription).toList();

      // 如果当前日历ID无效，使用默认日历
      if (!_calendars.any((c) => c.id == _calendarId)) {
        final defaultCalendar = _calendars.firstWhere(
          (c) => c.isDefault,
          orElse: () => _calendars.first,
        );
        _calendarId = defaultCalendar.id;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = '加载日历失败: $e';
      notifyListeners();
    }
  }

  // Setters with change tracking
  void setSummary(String value) {
    if (_summary != value) {
      _summary = value;
      _hasChanges = true;
      notifyListeners();
    }
  }

  void setDescription(String? value) {
    if (_description != value) {
      _description = value;
      _hasChanges = true;
      notifyListeners();
    }
  }

  void setLocation(String? value) {
    if (_location != value) {
      _location = value;
      _hasChanges = true;
      notifyListeners();
    }
  }

  void setCalendarId(String value) {
    if (_calendarId != value) {
      _calendarId = value;
      _hasChanges = true;
      notifyListeners();
    }
  }

  void setStartDate(DateTime value) {
    if (_startDate != value) {
      _startDate = value;
      // 如果结束日期早于开始日期，自动调整
      if (_endDate.isBefore(_startDate)) {
        _endDate = _startDate;
      }
      _hasChanges = true;
      notifyListeners();
    }
  }

  void setStartTime(TimeOfDay value) {
    if (_startTime != value) {
      _startTime = value;
      _hasChanges = true;
      notifyListeners();
    }
  }

  void setEndDate(DateTime value) {
    if (_endDate != value) {
      _endDate = value;
      _hasChanges = true;
      notifyListeners();
    }
  }

  void setEndTime(TimeOfDay value) {
    if (_endTime != value) {
      _endTime = value;
      _hasChanges = true;
      notifyListeners();
    }
  }

  void setIsAllDay(bool value) {
    if (_isAllDay != value) {
      _isAllDay = value;
      _hasChanges = true;
      notifyListeners();
    }
  }

  void setRecurrenceRule(RecurrenceRule? value) {
    _recurrenceRule = value;
    _hasChanges = true;
    notifyListeners();
  }

  void setColor(int? value) {
    if (_color != value) {
      _color = value;
      _hasChanges = true;
      notifyListeners();
    }
  }

  void setUrl(String? value) {
    if (_url != value) {
      _url = value;
      _hasChanges = true;
      notifyListeners();
    }
  }

  void setStatus(EventStatus value) {
    if (_status != value) {
      _status = value;
      _hasChanges = true;
      notifyListeners();
    }
  }

  /// 添加提醒
  void addReminder(int triggerMinutes) {
    // 生成唯一的通知ID
    final notificationId = DateTime.now().millisecondsSinceEpoch % 0x7FFFFFFF;
    _reminders.add(
      ReminderModel(
        eventUid: _originalEventUid ?? '',
        triggerMinutes: triggerMinutes,
        notificationId: notificationId,
      ),
    );
    _hasChanges = true;
    notifyListeners();
  }

  /// 移除提醒
  void removeReminder(int index) {
    if (index >= 0 && index < _reminders.length) {
      _reminders.removeAt(index);
      _hasChanges = true;
      notifyListeners();
    }
  }

  /// 清除提醒
  void clearReminders() {
    _reminders.clear();
    _hasChanges = true;
    notifyListeners();
  }

  /// 保存事件
  Future<bool> save() async {
    if (!isValid) {
      _error = validationError;
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final uid = _isEditMode ? _originalEventUid! : const Uuid().v4();

      // 更新提醒的eventUid
      final updatedReminders = _reminders.map((r) {
        return r.copyWith(eventUid: uid);
      }).toList();

      final event = EventModel(
        uid: uid,
        calendarId: _calendarId,
        summary: _summary.trim(),
        description: _description?.trim(),
        location: _location?.trim(),
        dtStart: fullStartDateTime,
        dtEnd: fullEndDateTime,
        isAllDay: _isAllDay,
        rrule: _recurrenceRule?.toRRuleString(),
        color: _color,
        status: _status,
        url: _url?.trim(),
        reminders: updatedReminders,
        createdAt: _isEditMode ? now : now, // 编辑时应保留原创建时间，这里简化处理
        updatedAt: now,
        sequence: _isEditMode ? 1 : 0,
      );

      if (_isEditMode) {
        // 编辑模式下先取消旧提醒，再更新事件
        await _reminderManager.cancelRemindersForEvent(event);
        await _eventRepository.updateEvent(event);
      } else {
        await _eventRepository.insertEvent(event);
      }

      // 调度提醒通知
      if (event.reminders.isNotEmpty) {
        await _reminderManager.scheduleRemindersForEvent(event);
      }

      _isSaving = false;
      _hasChanges = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSaving = false;
      _error = '保存失败: $e';
      notifyListeners();
      return false;
    }
  }

  /// 清除错误
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// 重置表单
  void reset() {
    _isEditMode = false;
    _originalEventUid = null;
    _summary = '';
    _description = null;
    _location = null;
    _calendarId = 'default';
    _startDate = DateTime.now();
    _startTime = TimeOfDay.now();
    _endDate = DateTime.now();
    _endTime = TimeOfDay(
      hour: TimeOfDay.now().hour + 1,
      minute: TimeOfDay.now().minute,
    );
    _isAllDay = false;
    _recurrenceRule = null;
    _reminders = [];
    _color = null;
    _url = null;
    _status = EventStatus.confirmed;
    _hasChanges = false;
    _error = null;
    notifyListeners();
  }
}

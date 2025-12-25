import 'package:uuid/uuid.dart';
import '../../data/models/event_model.dart';
import '../../data/models/reminder_model.dart';
import 'date_utils.dart';

/// iCalendar工具类
/// 用于处理iCalendar格式（RFC 5545）的解析和生成
class ICalendarUtils {
  ICalendarUtils._();

  static const _uuid = Uuid();

  /// 解析iCalendar内容，返回事件列表
  static List<EventModel> parseICalendar(String icsContent, String calendarId) {
    final events = <EventModel>[];
    final lines = _unfoldLines(icsContent.split(RegExp(r'\r?\n')));
    
    int i = 0;
    while (i < lines.length) {
      if (lines[i].toUpperCase() == 'BEGIN:VEVENT') {
        final eventLines = <String>[];
        i++;
        while (i < lines.length && lines[i].toUpperCase() != 'END:VEVENT') {
          eventLines.add(lines[i]);
          i++;
        }
        final event = _parseVEvent(eventLines, calendarId);
        if (event != null) {
          events.add(event);
        }
      }
      i++;
    }
    
    return events;
  }

  /// 将事件列表导出为iCalendar格式
  static String exportToICalendar(List<EventModel> events, {String? calendarName}) {
    final buffer = StringBuffer();
    
    // 日历头部
    buffer.writeln('BEGIN:VCALENDAR');
    buffer.writeln('VERSION:2.0');
    buffer.writeln('PRODID:-//Flutter Calendar App//CN');
    buffer.writeln('CALSCALE:GREGORIAN');
    buffer.writeln('METHOD:PUBLISH');
    if (calendarName != null) {
      buffer.writeln('X-WR-CALNAME:$calendarName');
    }
    
    // 导出每个事件
    for (final event in events) {
      buffer.write(_exportVEvent(event));
    }
    
    buffer.writeln('END:VCALENDAR');
    
    return buffer.toString();
  }

  /// 解析单个VEVENT
  static EventModel? _parseVEvent(List<String> lines, String calendarId) {
    String? uid;
    String summary = '';
    String? description;
    String? location;
    DateTime? dtStart;
    DateTime? dtEnd;
    bool isAllDay = false;
    String? rrule;
    List<DateTime>? exDates;
    int? color;
    EventStatus status = EventStatus.confirmed;
    int priority = 0;
    String? url;
    final reminders = <ReminderModel>[];
    DateTime? createdAt;
    DateTime? updatedAt;
    int sequence = 0;

    final alarms = <List<String>>[];
    
    int i = 0;
    while (i < lines.length) {
      final line = lines[i];
      
      if (line.toUpperCase() == 'BEGIN:VALARM') {
        final alarmLines = <String>[];
        i++;
        while (i < lines.length && lines[i].toUpperCase() != 'END:VALARM') {
          alarmLines.add(lines[i]);
          i++;
        }
        alarms.add(alarmLines);
      } else {
        final colonIndex = line.indexOf(':');
        if (colonIndex > 0) {
          final property = line.substring(0, colonIndex).toUpperCase();
          final value = line.substring(colonIndex + 1);
          
          // 处理带参数的属性
          final baseProperty = property.split(';').first;
          
          switch (baseProperty) {
            case 'UID':
              uid = value;
              break;
            case 'SUMMARY':
              summary = _unescapeText(value);
              break;
            case 'DESCRIPTION':
              description = _unescapeText(value);
              break;
            case 'LOCATION':
              location = _unescapeText(value);
              break;
            case 'DTSTART':
              isAllDay = property.contains('VALUE=DATE') && !property.contains('VALUE=DATE-TIME');
              dtStart = DateTimeUtils.parseICalDateTime(value);
              break;
            case 'DTEND':
              dtEnd = DateTimeUtils.parseICalDateTime(value);
              break;
            case 'RRULE':
              rrule = value;
              break;
            case 'EXDATE':
              exDates ??= [];
              final dates = value.split(',');
              for (final date in dates) {
                final dt = DateTimeUtils.parseICalDateTime(date.trim());
                if (dt != null) {
                  exDates.add(dt);
                }
              }
              break;
            case 'STATUS':
              status = _parseStatus(value);
              break;
            case 'PRIORITY':
              priority = int.tryParse(value) ?? 0;
              break;
            case 'URL':
              url = value;
              break;
            case 'CREATED':
              createdAt = DateTimeUtils.parseICalDateTime(value);
              break;
            case 'LAST-MODIFIED':
            case 'DTSTAMP':
              updatedAt ??= DateTimeUtils.parseICalDateTime(value);
              break;
            case 'SEQUENCE':
              sequence = int.tryParse(value) ?? 0;
              break;
            case 'COLOR':
            case 'X-APPLE-CALENDAR-COLOR':
              color = _parseColor(value);
              break;
          }
        }
      }
      i++;
    }
    
    // 必需字段验证
    if (dtStart == null) {
      return null;
    }
    
    // 生成UID（如果没有）
    uid ??= _uuid.v4();
    
    // 生成时间戳
    final now = DateTime.now();
    createdAt ??= now;
    updatedAt ??= now;
    
    // 解析提醒
    int notificationId = uid.hashCode;
    for (final alarmLines in alarms) {
      final reminder = _parseVAlarm(alarmLines, uid, notificationId++);
      if (reminder != null) {
        reminders.add(reminder);
      }
    }
    
    return EventModel(
      uid: uid,
      calendarId: calendarId,
      summary: summary.isEmpty ? '无标题' : summary,
      description: description,
      location: location,
      dtStart: dtStart,
      dtEnd: dtEnd,
      isAllDay: isAllDay,
      rrule: rrule,
      exDates: exDates,
      color: color,
      status: status,
      priority: priority,
      url: url,
      reminders: reminders,
      createdAt: createdAt,
      updatedAt: updatedAt,
      sequence: sequence,
    );
  }

  /// 解析VALARM
  static ReminderModel? _parseVAlarm(List<String> lines, String eventUid, int notificationId) {
    String? action;
    int? triggerMinutes;
    
    for (final line in lines) {
      final colonIndex = line.indexOf(':');
      if (colonIndex > 0) {
        final property = line.substring(0, colonIndex).toUpperCase();
        final value = line.substring(colonIndex + 1);
        
        switch (property.split(';').first) {
          case 'ACTION':
            action = value.toUpperCase();
            break;
          case 'TRIGGER':
            triggerMinutes = _parseTrigger(value, property);
            break;
        }
      }
    }
    
    if (action == null || triggerMinutes == null) {
      return null;
    }
    
    return ReminderModel(
      eventUid: eventUid,
      type: action == 'AUDIO' ? ReminderType.alarm : ReminderType.notification,
      triggerMinutes: triggerMinutes,
      notificationId: notificationId,
    );
  }

  /// 解析TRIGGER值
  static int? _parseTrigger(String value, String property) {
    // 处理RELATED=END等参数
    final isRelatedToEnd = property.contains('RELATED=END');
    
    // 解析持续时间格式: -PT15M, -P1D, PT0S等
    final match = RegExp(r'^(-?)P(?:(\d+)D)?(?:T(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?)?$').firstMatch(value);
    if (match == null) {
      return null;
    }
    
    final isNegative = match.group(1) == '-';
    final days = int.tryParse(match.group(2) ?? '0') ?? 0;
    final hours = int.tryParse(match.group(3) ?? '0') ?? 0;
    final minutes = int.tryParse(match.group(4) ?? '0') ?? 0;
    final seconds = int.tryParse(match.group(5) ?? '0') ?? 0;
    
    int totalMinutes = days * 24 * 60 + hours * 60 + minutes + (seconds > 0 ? 1 : 0);
    
    // 负值表示事件开始前
    if (isNegative) {
      totalMinutes = -totalMinutes;
    }
    
    // 如果是相对于结束时间，需要特殊处理（暂时忽略）
    if (isRelatedToEnd) {
      // TODO: 处理相对于结束时间的触发器
    }
    
    return totalMinutes;
  }

  /// 导出单个VEVENT
  static String _exportVEvent(EventModel event) {
    final buffer = StringBuffer();
    
    buffer.writeln('BEGIN:VEVENT');
    buffer.writeln('UID:${event.uid}');
    buffer.writeln('DTSTAMP:${DateTimeUtils.toICalDateTime(event.updatedAt)}');
    
    if (event.isAllDay) {
      buffer.writeln('DTSTART;VALUE=DATE:${DateTimeUtils.toICalDateTime(event.dtStart, dateOnly: true)}');
      if (event.dtEnd != null) {
        buffer.writeln('DTEND;VALUE=DATE:${DateTimeUtils.toICalDateTime(event.dtEnd!, dateOnly: true)}');
      }
    } else {
      buffer.writeln('DTSTART:${DateTimeUtils.toICalDateTime(event.dtStart)}');
      if (event.dtEnd != null) {
        buffer.writeln('DTEND:${DateTimeUtils.toICalDateTime(event.dtEnd!)}');
      }
    }
    
    buffer.writeln('SUMMARY:${_escapeText(event.summary)}');
    
    if (event.description != null && event.description!.isNotEmpty) {
      buffer.writeln('DESCRIPTION:${_escapeText(event.description!)}');
    }
    
    if (event.location != null && event.location!.isNotEmpty) {
      buffer.writeln('LOCATION:${_escapeText(event.location!)}');
    }
    
    if (event.rrule != null && event.rrule!.isNotEmpty) {
      buffer.writeln('RRULE:${event.rrule}');
    }
    
    if (event.exDates != null && event.exDates!.isNotEmpty) {
      final exDatesStr = event.exDates!
          .map((d) => DateTimeUtils.toICalDateTime(d, dateOnly: event.isAllDay))
          .join(',');
      buffer.writeln('EXDATE:$exDatesStr');
    }
    
    buffer.writeln('STATUS:${event.status.value.toUpperCase()}');
    
    if (event.priority > 0) {
      buffer.writeln('PRIORITY:${event.priority}');
    }
    
    if (event.url != null && event.url!.isNotEmpty) {
      buffer.writeln('URL:${event.url}');
    }
    
    if (event.color != null) {
      buffer.writeln('COLOR:${_colorToHex(event.color!)}');
    }
    
    buffer.writeln('CREATED:${DateTimeUtils.toICalDateTime(event.createdAt)}');
    buffer.writeln('LAST-MODIFIED:${DateTimeUtils.toICalDateTime(event.updatedAt)}');
    buffer.writeln('SEQUENCE:${event.sequence}');
    
    // 导出提醒
    for (final reminder in event.reminders) {
      buffer.write(_exportVAlarm(reminder));
    }
    
    buffer.writeln('END:VEVENT');
    
    return buffer.toString();
  }

  /// 导出VALARM
  static String _exportVAlarm(ReminderModel reminder) {
    final buffer = StringBuffer();
    
    buffer.writeln('BEGIN:VALARM');
    buffer.writeln('ACTION:${reminder.type == ReminderType.alarm ? 'AUDIO' : 'DISPLAY'}');
    buffer.writeln('TRIGGER:${_formatTrigger(reminder.triggerMinutes)}');
    buffer.writeln('DESCRIPTION:提醒');
    buffer.writeln('END:VALARM');
    
    return buffer.toString();
  }

  /// 格式化触发时间
  static String _formatTrigger(int minutes) {
    if (minutes == 0) {
      return 'PT0S';
    }
    
    final isNegative = minutes < 0;
    final absMinutes = minutes.abs();
    
    final days = absMinutes ~/ (24 * 60);
    final remainingMinutes = absMinutes % (24 * 60);
    final hours = remainingMinutes ~/ 60;
    final mins = remainingMinutes % 60;
    
    final buffer = StringBuffer();
    buffer.write(isNegative ? '-P' : 'P');
    
    if (days > 0) {
      buffer.write('${days}D');
    }
    
    if (hours > 0 || mins > 0) {
      buffer.write('T');
      if (hours > 0) {
        buffer.write('${hours}H');
      }
      if (mins > 0) {
        buffer.write('${mins}M');
      }
    }
    
    return buffer.toString();
  }

  /// 展开折叠行（RFC 5545规定长行可以用CRLF+空格折叠）
  static List<String> _unfoldLines(List<String> lines) {
    final result = <String>[];
    String current = '';
    
    for (final line in lines) {
      if (line.isEmpty) continue;
      
      if (line.startsWith(' ') || line.startsWith('\t')) {
        // 续行
        current += line.substring(1);
      } else {
        if (current.isNotEmpty) {
          result.add(current);
        }
        current = line;
      }
    }
    
    if (current.isNotEmpty) {
      result.add(current);
    }
    
    return result;
  }

  /// 转义文本
  static String _escapeText(String text) {
    return text
        .replaceAll('\\', '\\\\')
        .replaceAll(';', '\\;')
        .replaceAll(',', '\\,')
        .replaceAll('\n', '\\n');
  }

  /// 反转义文本
  static String _unescapeText(String text) {
    return text
        .replaceAll('\\n', '\n')
        .replaceAll('\\,', ',')
        .replaceAll('\\;', ';')
        .replaceAll('\\\\', '\\');
  }

  /// 解析状态
  static EventStatus _parseStatus(String value) {
    switch (value.toUpperCase()) {
      case 'TENTATIVE':
        return EventStatus.tentative;
      case 'CANCELLED':
        return EventStatus.cancelled;
      case 'CONFIRMED':
      default:
        return EventStatus.confirmed;
    }
  }

  /// 解析颜色
  static int? _parseColor(String value) {
    // 尝试解析各种颜色格式
    String colorStr = value.trim();
    
    // 处理 #RRGGBB 格式
    if (colorStr.startsWith('#')) {
      colorStr = colorStr.substring(1);
    }
    
    // 处理 CSS颜色名称（简化处理）
    final colorNames = {
      'red': 'FF0000',
      'green': '00FF00',
      'blue': '0000FF',
      'yellow': 'FFFF00',
      'orange': 'FFA500',
      'purple': '800080',
      'pink': 'FFC0CB',
      'cyan': '00FFFF',
    };
    
    colorStr = colorNames[colorStr.toLowerCase()] ?? colorStr;
    
    // 解析十六进制颜色
    if (colorStr.length == 6 || colorStr.length == 8) {
      try {
        if (colorStr.length == 6) {
          colorStr = 'FF$colorStr';
        }
        return int.parse(colorStr, radix: 16);
      } catch (e) {
        return null;
      }
    }
    
    return null;
  }

  /// 颜色转十六进制字符串
  static String _colorToHex(int color) {
    return '#${(color & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  /// 验证iCalendar内容格式
  static bool isValidICalendar(String content) {
    final trimmed = content.trim();
    return trimmed.contains('BEGIN:VCALENDAR') && 
           trimmed.contains('END:VCALENDAR') &&
           trimmed.contains('BEGIN:VEVENT');
  }

  /// 从iCalendar内容中提取日历名称
  static String? extractCalendarName(String content) {
    final lines = content.split(RegExp(r'\r?\n'));
    for (final line in lines) {
      if (line.toUpperCase().startsWith('X-WR-CALNAME:')) {
        return line.substring(13).trim();
      }
    }
    return null;
  }

  /// 从iCalendar内容中获取事件数量
  static int countEvents(String content) {
    return RegExp(r'BEGIN:VEVENT', caseSensitive: false).allMatches(content).length;
  }
}

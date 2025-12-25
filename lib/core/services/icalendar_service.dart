import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/calendar_model.dart';
import '../../data/models/event_model.dart';
import '../../data/repositories/event_repository.dart';
import '../utils/icalendar_utils.dart';

/// 导入结果
class ImportResult {
  final bool success;
  final int importedCount;
  final int skippedCount;
  final int errorCount;
  final String? error;
  final List<EventModel>? events;

  const ImportResult({
    required this.success,
    this.importedCount = 0,
    this.skippedCount = 0,
    this.errorCount = 0,
    this.error,
    this.events,
  });

  factory ImportResult.success({
    int importedCount = 0,
    int skippedCount = 0,
    List<EventModel>? events,
  }) {
    return ImportResult(
      success: true,
      importedCount: importedCount,
      skippedCount: skippedCount,
      events: events,
    );
  }

  factory ImportResult.failure(String error) {
    return ImportResult(success: false, error: error);
  }

  String get summary {
    if (!success) return error ?? '导入失败';
    final parts = <String>[];
    if (importedCount > 0) parts.add('成功导入 $importedCount 个事件');
    if (skippedCount > 0) parts.add('跳过 $skippedCount 个');
    if (errorCount > 0) parts.add('$errorCount 个错误');
    return parts.isEmpty ? '无事件导入' : parts.join('，');
  }
}

/// 导出结果
class ExportResult {
  final bool success;
  final int exportedCount;
  final String? filePath;
  final String? error;

  const ExportResult({
    required this.success,
    this.exportedCount = 0,
    this.filePath,
    this.error,
  });

  factory ExportResult.success({int exportedCount = 0, String? filePath}) {
    return ExportResult(
      success: true,
      exportedCount: exportedCount,
      filePath: filePath,
    );
  }

  factory ExportResult.failure(String error) {
    return ExportResult(success: false, error: error);
  }
}

/// 导入预览结果
class ImportPreview {
  final bool success;
  final String? calendarName;
  final List<EventModel> events;
  final String? error;

  const ImportPreview({
    required this.success,
    this.calendarName,
    this.events = const [],
    this.error,
  });

  factory ImportPreview.success({
    String? calendarName,
    required List<EventModel> events,
  }) {
    return ImportPreview(
      success: true,
      calendarName: calendarName,
      events: events,
    );
  }

  factory ImportPreview.failure(String error) {
    return ImportPreview(success: false, error: error);
  }
}

/// iCalendar 导入导出服务
class ICalendarService {
  final EventRepository _eventRepository;

  ICalendarService({EventRepository? eventRepository})
    : _eventRepository = eventRepository ?? EventRepository();

  /// 选择并预览 iCalendar 文件
  Future<ImportPreview> pickAndPreviewFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['ics', 'ical', 'ifb', 'icalendar'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return ImportPreview.failure('未选择文件');
      }

      final file = result.files.first;
      if (file.path == null) {
        return ImportPreview.failure('无法读取文件');
      }

      return await previewFile(file.path!);
    } catch (e) {
      return ImportPreview.failure('选择文件失败: $e');
    }
  }

  /// 预览 iCalendar 文件内容
  Future<ImportPreview> previewFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return ImportPreview.failure('文件不存在');
      }

      final content = await file.readAsString();
      return previewContent(content);
    } catch (e) {
      return ImportPreview.failure('读取文件失败: $e');
    }
  }

  /// 预览 iCalendar 内容
  ImportPreview previewContent(String content) {
    try {
      if (!ICalendarUtils.isValidICalendar(content)) {
        return ImportPreview.failure('无效的 iCalendar 格式');
      }

      final calendarName = ICalendarUtils.extractCalendarName(content);
      // 使用临时 ID 解析，实际导入时会替换
      final events = ICalendarUtils.parseICalendar(content, 'preview');

      return ImportPreview.success(calendarName: calendarName, events: events);
    } catch (e) {
      return ImportPreview.failure('解析失败: $e');
    }
  }

  /// 导入事件到指定日历
  Future<ImportResult> importEvents({
    required List<EventModel> events,
    required String targetCalendarId,
    bool skipDuplicates = true,
  }) async {
    try {
      int imported = 0;
      int skipped = 0;

      for (final event in events) {
        // 更新日历 ID
        final eventToImport = event.copyWith(calendarId: targetCalendarId);

        if (skipDuplicates) {
          // 检查是否已存在
          final existing = await _eventRepository.getEventByUid(event.uid);
          if (existing != null) {
            skipped++;
            continue;
          }
        }

        await _eventRepository.insertEvent(eventToImport);
        imported++;
      }

      return ImportResult.success(
        importedCount: imported,
        skippedCount: skipped,
      );
    } catch (e) {
      return ImportResult.failure('导入失败: $e');
    }
  }

  /// 从文件导入到指定日历（一步完成）
  Future<ImportResult> importFromFile({
    required String filePath,
    required String targetCalendarId,
    bool skipDuplicates = true,
  }) async {
    final preview = await previewFile(filePath);
    if (!preview.success) {
      return ImportResult.failure(preview.error ?? '解析失败');
    }

    return importEvents(
      events: preview.events,
      targetCalendarId: targetCalendarId,
      skipDuplicates: skipDuplicates,
    );
  }

  /// 导出日历事件到文件
  Future<ExportResult> exportCalendar({
    required CalendarModel calendar,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      List<EventModel> events;

      if (startDate != null && endDate != null) {
        // 导出日期范围内的事件
        events = await _eventRepository.getEventsInRange(startDate, endDate);
        events = events.where((e) => e.calendarId == calendar.id).toList();
      } else {
        // 导出所有事件
        events = await _eventRepository.getEventsByCalendar(calendar.id);
      }

      if (events.isEmpty) {
        return ExportResult.failure('没有可导出的事件');
      }

      final icsContent = ICalendarUtils.exportToICalendar(
        events,
        calendarName: calendar.name,
      );

      // 保存到临时文件
      final directory = await getTemporaryDirectory();
      final fileName =
          '${calendar.name.replaceAll(RegExp(r'[^\w\u4e00-\u9fa5]'), '_')}_${DateTime.now().millisecondsSinceEpoch}.ics';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsString(icsContent);

      return ExportResult.success(
        exportedCount: events.length,
        filePath: filePath,
      );
    } catch (e) {
      return ExportResult.failure('导出失败: $e');
    }
  }

  /// 导出多个日历的事件
  Future<ExportResult> exportCalendars({
    required List<CalendarModel> calendars,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final allEvents = <EventModel>[];

      for (final calendar in calendars) {
        List<EventModel> events;

        if (startDate != null && endDate != null) {
          events = await _eventRepository.getEventsInRange(startDate, endDate);
          events = events.where((e) => e.calendarId == calendar.id).toList();
        } else {
          events = await _eventRepository.getEventsByCalendar(calendar.id);
        }

        allEvents.addAll(events);
      }

      if (allEvents.isEmpty) {
        return ExportResult.failure('没有可导出的事件');
      }

      final calendarNames = calendars.map((c) => c.name).join(', ');
      final icsContent = ICalendarUtils.exportToICalendar(
        allEvents,
        calendarName: calendarNames,
      );

      // 保存到临时文件
      final directory = await getTemporaryDirectory();
      final fileName = 'calendars_${DateTime.now().millisecondsSinceEpoch}.ics';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsString(icsContent);

      return ExportResult.success(
        exportedCount: allEvents.length,
        filePath: filePath,
      );
    } catch (e) {
      return ExportResult.failure('导出失败: $e');
    }
  }

  /// 分享导出的文件
  Future<void> shareExportedFile(String filePath) async {
    await Share.shareXFiles([XFile(filePath)], subject: '日历导出');
  }

  /// 保存导出文件到指定位置
  Future<ExportResult> saveExportToPath({
    required String sourcePath,
    String? customFileName,
  }) async {
    try {
      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: '保存日历文件',
        fileName: customFileName ?? 'calendar.ics',
        type: FileType.custom,
        allowedExtensions: ['ics'],
      );

      if (outputPath == null) {
        return ExportResult.failure('未选择保存位置');
      }

      final sourceFile = File(sourcePath);
      final content = await sourceFile.readAsString();

      final outputFile = File(outputPath);
      await outputFile.writeAsString(content);

      return ExportResult.success(filePath: outputPath);
    } catch (e) {
      return ExportResult.failure('保存失败: $e');
    }
  }
}

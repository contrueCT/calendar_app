import 'package:dio/dio.dart';
import '../../data/models/calendar_model.dart';
import '../../data/models/event_model.dart';
import '../../data/repositories/calendar_repository.dart';
import '../../data/repositories/event_repository.dart';
import '../utils/icalendar_utils.dart';

/// 订阅同步结果
class SyncResult {
  final bool success;
  final int addedCount;
  final int updatedCount;
  final int deletedCount;
  final String? error;

  const SyncResult({
    required this.success,
    this.addedCount = 0,
    this.updatedCount = 0,
    this.deletedCount = 0,
    this.error,
  });

  factory SyncResult.success({
    int addedCount = 0,
    int updatedCount = 0,
    int deletedCount = 0,
  }) {
    return SyncResult(
      success: true,
      addedCount: addedCount,
      updatedCount: updatedCount,
      deletedCount: deletedCount,
    );
  }

  factory SyncResult.failure(String error) {
    return SyncResult(success: false, error: error);
  }

  int get totalChanges => addedCount + updatedCount + deletedCount;

  String get summary {
    if (!success) return error ?? '同步失败';
    if (totalChanges == 0) return '无更新';
    final parts = <String>[];
    if (addedCount > 0) parts.add('新增 $addedCount');
    if (updatedCount > 0) parts.add('更新 $updatedCount');
    if (deletedCount > 0) parts.add('删除 $deletedCount');
    return parts.join('，');
  }
}

/// 订阅验证结果
class SubscriptionValidation {
  final bool isValid;
  final String? calendarName;
  final int eventCount;
  final String? error;

  const SubscriptionValidation({
    required this.isValid,
    this.calendarName,
    this.eventCount = 0,
    this.error,
  });

  factory SubscriptionValidation.valid({
    String? calendarName,
    int eventCount = 0,
  }) {
    return SubscriptionValidation(
      isValid: true,
      calendarName: calendarName,
      eventCount: eventCount,
    );
  }

  factory SubscriptionValidation.invalid(String error) {
    return SubscriptionValidation(isValid: false, error: error);
  }
}

/// 网络订阅服务
/// 处理 iCalendar 网络订阅的获取、解析和同步
class SubscriptionService {
  final Dio _dio;
  final CalendarRepository _calendarRepository;
  final EventRepository _eventRepository;

  SubscriptionService({
    Dio? dio,
    CalendarRepository? calendarRepository,
    EventRepository? eventRepository,
  }) : _dio = dio ?? Dio(),
       _calendarRepository = calendarRepository ?? CalendarRepository(),
       _eventRepository = eventRepository ?? EventRepository();

  /// 验证订阅 URL
  Future<SubscriptionValidation> validateSubscriptionUrl(String url) async {
    try {
      // 验证 URL 格式
      final uri = Uri.tryParse(url);
      if (uri == null || (!uri.isScheme('http') && !uri.isScheme('https'))) {
        return SubscriptionValidation.invalid('无效的 URL 格式');
      }

      // 获取远程内容
      final response = await _dio.get<String>(
        url,
        options: Options(
          responseType: ResponseType.plain,
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 10),
          headers: {
            'Accept': 'text/calendar, text/plain, */*',
            'User-Agent': 'Flutter Calendar App/1.0',
          },
        ),
      );

      if (response.statusCode != 200) {
        return SubscriptionValidation.invalid(
          '服务器返回错误: ${response.statusCode}',
        );
      }

      final content = response.data;
      if (content == null || content.isEmpty) {
        return SubscriptionValidation.invalid('服务器返回空内容');
      }

      // 验证 iCalendar 格式
      if (!ICalendarUtils.isValidICalendar(content)) {
        return SubscriptionValidation.invalid('无效的 iCalendar 格式');
      }

      // 提取日历信息
      final calendarName = ICalendarUtils.extractCalendarName(content);
      final eventCount = ICalendarUtils.countEvents(content);

      return SubscriptionValidation.valid(
        calendarName: calendarName,
        eventCount: eventCount,
      );
    } on DioException catch (e) {
      return SubscriptionValidation.invalid(_getDioErrorMessage(e));
    } catch (e) {
      return SubscriptionValidation.invalid('验证失败: $e');
    }
  }

  /// 同步订阅日历
  Future<SyncResult> syncSubscription(CalendarModel calendar) async {
    if (!calendar.isSubscription) {
      return SyncResult.failure('非订阅日历');
    }

    if (calendar.subscriptionUrl == null || calendar.subscriptionUrl!.isEmpty) {
      return SyncResult.failure('订阅 URL 为空');
    }

    try {
      // 获取远程日历内容
      final response = await _dio.get<String>(
        calendar.subscriptionUrl!,
        options: Options(
          responseType: ResponseType.plain,
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 10),
          headers: {
            'Accept': 'text/calendar, text/plain, */*',
            'User-Agent': 'Flutter Calendar App/1.0',
          },
        ),
      );

      if (response.statusCode != 200) {
        return SyncResult.failure('服务器返回错误: ${response.statusCode}');
      }

      final content = response.data;
      if (content == null || content.isEmpty) {
        return SyncResult.failure('服务器返回空内容');
      }

      // 验证 iCalendar 格式
      if (!ICalendarUtils.isValidICalendar(content)) {
        return SyncResult.failure('无效的 iCalendar 格式');
      }

      // 解析远程事件
      final remoteEvents = ICalendarUtils.parseICalendar(content, calendar.id);

      // 获取本地现有事件
      final localEvents = await _eventRepository.getEventsByCalendar(
        calendar.id,
      );

      // 计算差异并同步
      final result = await _syncEvents(
        calendarId: calendar.id,
        remoteEvents: remoteEvents,
        localEvents: localEvents,
      );

      // 更新最后同步时间
      await _calendarRepository.updateLastSyncTime(calendar.id);

      return result;
    } on DioException catch (e) {
      return SyncResult.failure(_getDioErrorMessage(e));
    } catch (e) {
      return SyncResult.failure('同步失败: $e');
    }
  }

  /// 同步所有订阅日历
  Future<Map<String, SyncResult>> syncAllSubscriptions() async {
    final results = <String, SyncResult>{};
    final subscriptions = await _calendarRepository.getSubscriptionCalendars();

    for (final calendar in subscriptions) {
      results[calendar.id] = await syncSubscription(calendar);
    }

    return results;
  }

  /// 同步需要自动同步的订阅日历
  Future<Map<String, SyncResult>> syncDueSubscriptions() async {
    final results = <String, SyncResult>{};
    final subscriptions = await _calendarRepository.getSubscriptionCalendars();
    final now = DateTime.now();

    for (final calendar in subscriptions) {
      if (_shouldSync(calendar, now)) {
        results[calendar.id] = await syncSubscription(calendar);
      }
    }

    return results;
  }

  /// 检查是否应该同步
  bool _shouldSync(CalendarModel calendar, DateTime now) {
    if (calendar.syncInterval == SyncInterval.manual) {
      return false;
    }

    if (calendar.lastSyncTime == null) {
      return true;
    }

    final lastSync = calendar.lastSyncTime!;
    final diff = now.difference(lastSync);

    switch (calendar.syncInterval) {
      case SyncInterval.hourly:
        return diff.inHours >= 1;
      case SyncInterval.daily:
        return diff.inDays >= 1;
      case SyncInterval.weekly:
        return diff.inDays >= 7;
      case SyncInterval.manual:
        return false;
    }
  }

  /// 同步事件（增量更新）
  Future<SyncResult> _syncEvents({
    required String calendarId,
    required List<EventModel> remoteEvents,
    required List<EventModel> localEvents,
  }) async {
    int added = 0;
    int updated = 0;
    int deleted = 0;

    // 创建本地事件的 UID 映射
    final localEventMap = {for (var e in localEvents) e.uid: e};

    // 创建远程事件的 UID 集合
    final remoteUids = {for (var e in remoteEvents) e.uid};

    // 处理远程事件
    for (final remoteEvent in remoteEvents) {
      final localEvent = localEventMap[remoteEvent.uid];

      if (localEvent == null) {
        // 新事件 - 添加
        await _eventRepository.insertEvent(remoteEvent);
        added++;
      } else if (_eventNeedsUpdate(localEvent, remoteEvent)) {
        // 已存在且有更新 - 更新
        await _eventRepository.updateEvent(remoteEvent);
        updated++;
      }
    }

    // 删除本地有但远程没有的事件
    for (final localEvent in localEvents) {
      if (!remoteUids.contains(localEvent.uid)) {
        await _eventRepository.deleteEvent(localEvent.uid);
        deleted++;
      }
    }

    return SyncResult.success(
      addedCount: added,
      updatedCount: updated,
      deletedCount: deleted,
    );
  }

  /// 检查事件是否需要更新
  bool _eventNeedsUpdate(EventModel local, EventModel remote) {
    // 使用 sequence 和 updatedAt 判断
    if (remote.sequence > local.sequence) {
      return true;
    }
    if (remote.sequence == local.sequence &&
        remote.updatedAt.isAfter(local.updatedAt)) {
      return true;
    }
    return false;
  }

  /// 获取 Dio 错误消息
  String _getDioErrorMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return '连接超时';
      case DioExceptionType.sendTimeout:
        return '发送超时';
      case DioExceptionType.receiveTimeout:
        return '接收超时';
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 404) {
          return '订阅地址不存在 (404)';
        } else if (statusCode == 403) {
          return '访问被拒绝 (403)';
        } else if (statusCode == 401) {
          return '需要认证 (401)';
        }
        return '服务器错误: $statusCode';
      case DioExceptionType.cancel:
        return '请求已取消';
      case DioExceptionType.connectionError:
        return '网络连接失败，请检查网络';
      case DioExceptionType.unknown:
      default:
        if (e.error != null) {
          final error = e.error.toString();
          if (error.contains('SocketException') ||
              error.contains('Connection refused')) {
            return '无法连接到服务器';
          }
          if (error.contains('HandshakeException') ||
              error.contains('CERTIFICATE')) {
            return 'SSL 证书验证失败';
          }
        }
        return '网络错误: ${e.message ?? "未知错误"}';
    }
  }
}

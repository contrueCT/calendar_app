import '../../data/models/event_model.dart';
import '../../data/repositories/event_repository.dart';
import '../../data/repositories/event_cache_repository.dart';

/// 重复事件服务
/// 负责处理重复事件的实例生成、缓存管理和查询
class RecurrenceService {
  final EventRepository _eventRepository;
  final EventCacheRepository _eventCacheRepository;

  /// 默认缓存天数
  static const int cacheDays = 90;

  RecurrenceService({
    required EventRepository eventRepository,
    required EventCacheRepository eventCacheRepository,
  })  : _eventRepository = eventRepository,
        _eventCacheRepository = eventCacheRepository;

  /// 获取时间范围内的所有事件实例（包含重复事件展开）
  Future<List<EventInstance>> getEventInstancesInRange(
    DateTime start,
    DateTime end,
  ) async {
    // 获取该范围内可能涉及的事件
    final events = await _eventRepository.getEventsInRange(start, end);
    final instances = <EventInstance>[];

    for (final event in events) {
      if (!event.isRecurring) {
        // 非重复事件，直接添加
        instances.add(EventInstance.fromEvent(event));
      } else {
        // 重复事件，展开实例
        final recurring = await _getRecurringInstances(event, start, end);
        instances.addAll(recurring);
      }
    }

    // 按开始时间排序
    instances.sort((a, b) => a.instanceStart.compareTo(b.instanceStart));
    return instances;
  }

  /// 获取指定日期的所有事件实例
  Future<List<EventInstance>> getEventInstancesForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return getEventInstancesInRange(start, end);
  }

  /// 获取重复事件在指定范围内的所有实例
  Future<List<EventInstance>> _getRecurringInstances(
    EventModel event,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) async {
    final instances = <EventInstance>[];

    if (!event.isRecurring || event.recurrenceRule == null) {
      return instances;
    }

    // 尝试从缓存获取
    final now = DateTime.now();
    final cacheEnd = now.add(const Duration(days: cacheDays));

    // 如果查询范围在缓存范围内，优先使用缓存
    if (rangeStart.isBefore(cacheEnd)) {
      final effectiveEnd = rangeEnd.isBefore(cacheEnd) ? rangeEnd : cacheEnd;
      
      // 检查是否有缓存
      final hasCacheData = await _eventCacheRepository.hasCacheForEvent(event.uid);
      
      if (hasCacheData) {
        final cachedInstances = await _eventCacheRepository.getCachedInstances(
          event.uid,
          rangeStart,
          effectiveEnd,
        );

        for (final cached in cachedInstances) {
          if (!cached.isException) {
            instances.add(
              EventInstance.fromRecurringEvent(event, cached.occurrenceDate),
            );
          }
        }

        // 如果查询范围超出缓存范围，动态计算剩余部分
        if (rangeEnd.isAfter(cacheEnd)) {
          final dynamicInstances = _computeInstances(
            event,
            cacheEnd,
            rangeEnd,
          );
          instances.addAll(dynamicInstances);
        }
      } else {
        // 没有缓存，动态计算并异步生成缓存
        final computedInstances = _computeInstances(event, rangeStart, rangeEnd);
        instances.addAll(computedInstances);

        // 异步生成缓存（不阻塞当前请求）
        _generateCacheAsync(event);
      }
    } else {
      // 查询范围完全在缓存范围外，直接动态计算
      final computedInstances = _computeInstances(event, rangeStart, rangeEnd);
      instances.addAll(computedInstances);
    }

    return instances;
  }

  /// 动态计算重复事件实例
  List<EventInstance> _computeInstances(
    EventModel event,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
    final instances = <EventInstance>[];
    final rule = event.recurrenceRule;

    if (rule == null) return instances;

    // 获取该范围内的所有重复日期
    final occurrences = rule.getOccurrences(
      event.dtStart,
      rangeStart,
      rangeEnd,
      excludeDates: event.exDates,
    );

    for (final occurrence in occurrences) {
      instances.add(EventInstance.fromRecurringEvent(event, occurrence));
    }

    return instances;
  }

  /// 异步生成事件缓存
  Future<void> _generateCacheAsync(EventModel event) async {
    // 使用Future.microtask避免阻塞
    Future.microtask(() => generateCacheForEvent(event));
  }

  /// 为事件生成缓存（公开方法，用于手动触发）
  Future<void> generateCacheForEvent(EventModel event) async {
    if (!event.isRecurring || event.recurrenceRule == null) return;

    final now = DateTime.now();
    final rangeEnd = now.add(const Duration(days: cacheDays));

    final occurrences = event.recurrenceRule!.getOccurrences(
      event.dtStart,
      now,
      rangeEnd,
      excludeDates: event.exDates,
    );

    await _eventCacheRepository.saveInstances(
      event.uid,
      occurrences,
      clearExisting: true,
    );
  }

  /// 为所有重复事件生成缓存
  Future<void> generateCacheForAllEvents() async {
    final events = await _eventRepository.getAllEvents();

    for (final event in events) {
      if (event.isRecurring) {
        await generateCacheForEvent(event);
      }
    }
  }

  /// 清理过期缓存并补充新缓存
  Future<void> maintainCache() async {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    // 删除过期缓存（保留异常记录）
    await _eventCacheRepository.deleteOldCache(yesterday);

    // 获取所有重复事件，检查并补充缓存
    final events = await _eventRepository.getAllEvents();

    for (final event in events) {
      if (event.isRecurring) {
        final cacheRange = await _eventCacheRepository.getCacheDateRange(event.uid);

        if (cacheRange == null) {
          // 没有缓存，生成新的
          await generateCacheForEvent(event);
        } else {
          final rangeEnd = now.add(const Duration(days: cacheDays));

          // 如果缓存不够90天，补充
          if (cacheRange.latest != null && cacheRange.latest!.isBefore(rangeEnd)) {
            await _extendCache(event, cacheRange.latest!, rangeEnd);
          }
        }
      }
    }
  }

  /// 扩展事件缓存到指定日期
  Future<void> _extendCache(
    EventModel event,
    DateTime fromDate,
    DateTime toDate,
  ) async {
    if (event.recurrenceRule == null) return;

    final newOccurrences = event.recurrenceRule!.getOccurrences(
      event.dtStart,
      fromDate.add(const Duration(days: 1)), // 从缓存结束的下一天开始
      toDate,
      excludeDates: event.exDates,
    );

    // 追加新的实例（不清除现有缓存）
    await _eventCacheRepository.saveInstances(
      event.uid,
      newOccurrences,
      clearExisting: false,
    );
  }

  /// 当事件被修改时，更新缓存
  Future<void> onEventUpdated(EventModel event) async {
    if (event.isRecurring) {
      // 重新生成缓存
      await generateCacheForEvent(event);
    } else {
      // 非重复事件，删除可能存在的旧缓存
      await _eventCacheRepository.deleteCacheForEvent(event.uid);
    }
  }

  /// 当事件被删除时，清理缓存
  Future<void> onEventDeleted(String eventUid) async {
    await _eventCacheRepository.deleteCacheForEvent(eventUid);
  }

  /// 删除重复事件的单个实例
  Future<void> deleteRecurringInstance(
    EventModel event,
    DateTime instanceDate,
  ) async {
    // 将该日期添加到排除列表
    final newExDates = [...(event.exDates ?? []), instanceDate];

    final updatedEvent = event.copyWith(
      exDates: newExDates,
      updatedAt: DateTime.now(),
      sequence: event.sequence + 1,
    );

    await _eventRepository.updateEvent(updatedEvent);

    // 标记缓存中的该实例为异常
    await _eventCacheRepository.markAsException(event.uid, instanceDate);
  }

  /// 删除重复事件的某个实例及之后的所有实例
  Future<void> deleteRecurringInstanceAndFuture(
    EventModel event,
    DateTime fromDate,
  ) async {
    // 修改UNTIL为该日期的前一天
    final newUntil = fromDate.subtract(const Duration(days: 1));
    final rule = event.recurrenceRule;

    if (rule == null) return;

    final updatedRule = rule.copyWith(
      until: newUntil,
      count: null, // 清除次数限制
    );

    final updatedEvent = event.copyWith(
      rrule: updatedRule.toRRuleString(),
      updatedAt: DateTime.now(),
      sequence: event.sequence + 1,
    );

    await _eventRepository.updateEvent(updatedEvent);

    // 重新生成缓存
    await generateCacheForEvent(updatedEvent);
  }

  /// 获取下一个重复实例
  Future<EventInstance?> getNextRecurringInstance(EventModel event) async {
    if (!event.isRecurring) return null;

    final now = DateTime.now();
    final instances = await _getRecurringInstances(
      event,
      now,
      now.add(const Duration(days: 365)), // 搜索未来一年
    );

    if (instances.isEmpty) return null;
    return instances.first;
  }

  /// 检查指定日期是否是重复事件的一个实例
  Future<bool> isRecurringInstance(EventModel event, DateTime date) async {
    if (!event.isRecurring || event.recurrenceRule == null) return false;

    // 检查是否被排除
    if (event.exDates != null) {
      final isExcluded = event.exDates!.any(
        (d) => d.year == date.year && d.month == date.month && d.day == date.day,
      );
      if (isExcluded) return false;
    }

    // 检查是否是有效实例
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final occurrences = event.recurrenceRule!.getOccurrences(
      event.dtStart,
      startOfDay,
      endOfDay,
      excludeDates: event.exDates,
    );

    return occurrences.isNotEmpty;
  }

  /// 获取缓存统计信息
  Future<Map<String, dynamic>> getCacheStats() async {
    return _eventCacheRepository.getCacheStats();
  }
}

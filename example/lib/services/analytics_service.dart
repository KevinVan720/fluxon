import 'package:uuid/uuid.dart';
import 'package:flux/flux.dart';
import '../events/task_events.dart';

part 'analytics_service.g.dart';

/// Analytics service for tracking user behavior
/// This service runs in a worker isolate for non-blocking analytics processing
@ServiceContract(remote: true)
class AnalyticsService extends FluxService {
  final Map<String, int> _actionCounts = {};
  final List<Map<String, dynamic>> _events = [];
  final _uuid = const Uuid();

  @override
  Future<void> initialize() async {
    // 📡 EVENT SYSTEM: Listen to all task-related events
    onEvent<TaskCreatedEvent>((event) async {
      await _trackEvent('task_created', 'task', {
        'taskId': event.taskId,
        'title': event.title,
        'assignedTo': event.assignedTo,
      });
      return const EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration(milliseconds: 5),
      );
    });

    onEvent<TaskStatusChangedEvent>((event) async {
      await _trackEvent('task_status_changed', 'task', {
        'taskId': event.taskId,
        'oldStatus': event.oldStatus,
        'newStatus': event.newStatus,
        'changedBy': event.changedBy,
      });
      return const EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration(milliseconds: 5),
      );
    });

    onEvent<NotificationEvent>((event) async {
      await _trackEvent('notification_sent', 'notification', {
        'userId': event.userId,
        'type': event.type,
        'title': event.title,
      });
      return const EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration(milliseconds: 3),
      );
    });

    logger.info('Analytics service initialized in worker isolate');
    await super.initialize();
  }

  /// Track a custom event
  Future<void> trackEvent(
    String action,
    String entity,
    Map<String, dynamic> properties,
  ) async {
    await _trackEvent(action, entity, properties);
  }

  /// Get analytics summary
  Future<Map<String, dynamic>> getAnalyticsSummary() async {
    final totalEvents = _events.length;
    final uniqueActions = _actionCounts.keys.length;

    // Calculate trends over time periods
    final now = DateTime.now();
    final last24h = _events
        .where(
          (e) => DateTime.parse(
            e['timestamp'],
          ).isAfter(now.subtract(const Duration(hours: 24))),
        )
        .length;

    final last7d = _events
        .where(
          (e) => DateTime.parse(
            e['timestamp'],
          ).isAfter(now.subtract(const Duration(days: 7))),
        )
        .length;

    return {
      'totalEvents': totalEvents,
      'uniqueActions': uniqueActions,
      'eventsLast24h': last24h,
      'eventsLast7d': last7d,
      'topActions': _getTopActions(),
      'eventsByHour': _getEventsByHour(),
    };
  }

  /// Get detailed event history
  Future<List<Map<String, dynamic>>> getEventHistory({
    int limit = 100,
    String? action,
    String? entity,
  }) async {
    var filteredEvents = _events.toList();

    if (action != null) {
      filteredEvents = filteredEvents
          .where((e) => e['action'] == action)
          .toList();
    }

    if (entity != null) {
      filteredEvents = filteredEvents
          .where((e) => e['entity'] == entity)
          .toList();
    }

    // Sort by timestamp descending
    filteredEvents.sort(
      (a, b) => DateTime.parse(
        b['timestamp'],
      ).compareTo(DateTime.parse(a['timestamp'])),
    );

    return filteredEvents.take(limit).toList();
  }

  /// Generate analytics report (heavy computation in worker isolate)
  Future<Map<String, dynamic>> generateReport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Simulate heavy computation
    await Future.delayed(const Duration(milliseconds: 500));

    final start =
        startDate ?? DateTime.now().subtract(const Duration(days: 30));
    final end = endDate ?? DateTime.now();

    final periodEvents = _events.where((e) {
      final eventTime = DateTime.parse(e['timestamp']);
      return eventTime.isAfter(start) && eventTime.isBefore(end);
    }).toList();

    // Complex analytics calculations (perfect for worker isolate)
    final taskEvents = periodEvents
        .where((e) => e['entity'] == 'task')
        .toList();
    final notificationEvents = periodEvents
        .where((e) => e['entity'] == 'notification')
        .toList();

    final taskCreations = taskEvents
        .where((e) => e['action'] == 'task_created')
        .length;
    final taskCompletions = taskEvents
        .where(
          (e) =>
              e['action'] == 'task_status_changed' &&
              e['properties']['newStatus'] == 'completed',
        )
        .length;

    logger.info(
      'Generated analytics report',
      metadata: {
        'startDate': start.toIso8601String(),
        'endDate': end.toIso8601String(),
        'totalEvents': periodEvents.length,
      },
    );

    return {
      'period': {
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
      },
      'summary': {
        'totalEvents': periodEvents.length,
        'taskEvents': taskEvents.length,
        'notificationEvents': notificationEvents.length,
        'taskCreations': taskCreations,
        'taskCompletions': taskCompletions,
        'completionRate': taskCreations > 0
            ? (taskCompletions / taskCreations * 100).round()
            : 0,
      },
      'trends': {
        'dailyAverageEvents': (periodEvents.length / 30).round(),
        'peakDay': _getPeakDay(periodEvents),
        'mostActiveUsers': _getMostActiveUsers(periodEvents),
      },
    };
  }

  // Private helper methods
  Future<void> _trackEvent(
    String action,
    String entity,
    Map<String, dynamic> properties,
  ) async {
    final event = {
      'id': _uuid.v4(),
      'action': action,
      'entity': entity,
      'properties': properties,
      'timestamp': DateTime.now().toIso8601String(),
    };

    _events.add(event);
    _actionCounts[action] = (_actionCounts[action] ?? 0) + 1;

    // 📡 EVENT SYSTEM: Send analytics event for other services
    await sendEvent(
      AnalyticsEvent(
        action: action,
        entity: entity,
        properties: properties,
        eventId: _uuid.v4(),
        sourceService: serviceName,
        timestamp: DateTime.now(),
      ),
    );

    logger.debug(
      'Tracked event',
      metadata: {'action': action, 'entity': entity, 'eventId': event['id']},
    );
  }

  Map<String, int> _getTopActions() {
    final sorted = _actionCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sorted.take(5));
  }

  Map<String, int> _getEventsByHour() {
    final hourCounts = <String, int>{};
    final now = DateTime.now();

    for (var i = 0; i < 24; i++) {
      final hour = now.subtract(Duration(hours: i)).hour;
      final key = hour.toString().padLeft(2, '0');

      final count = _events.where((e) {
        final eventTime = DateTime.parse(e['timestamp']);
        return eventTime.hour == hour &&
            eventTime.isAfter(now.subtract(Duration(hours: i + 1))) &&
            eventTime.isBefore(now.subtract(Duration(hours: i)));
      }).length;

      hourCounts[key] = count;
    }

    return hourCounts;
  }

  String _getPeakDay(List<Map<String, dynamic>> events) {
    if (events.isEmpty) return 'No data';

    final dayCounts = <String, int>{};
    for (final event in events) {
      final date = DateTime.parse(event['timestamp']);
      final dayKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      dayCounts[dayKey] = (dayCounts[dayKey] ?? 0) + 1;
    }

    final sorted = dayCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.isNotEmpty
        ? '${sorted.first.key} (${sorted.first.value} events)'
        : 'No data';
  }

  List<String> _getMostActiveUsers(List<Map<String, dynamic>> events) {
    final userCounts = <String, int>{};

    for (final event in events) {
      final properties = event['properties'] as Map<String, dynamic>;
      final userId =
          properties['assignedTo'] ??
          properties['changedBy'] ??
          properties['userId'];
      if (userId != null) {
        userCounts[userId] = (userCounts[userId] ?? 0) + 1;
      }
    }

    final sorted = userCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(3).map((e) => '${e.key} (${e.value} actions)').toList();
  }
}

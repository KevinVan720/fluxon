import '../service_event.dart';

/// Statistics for event processing
class EventStatistics {
  EventStatistics({
    required this.eventType,
    required this.totalSent,
    required this.totalProcessed,
    required this.totalFailed,
    required this.averageProcessingTime,
    required this.lastSent,
  });

  final String eventType;
  final int totalSent;
  final int totalProcessed;
  final int totalFailed;
  final Duration averageProcessingTime;
  final DateTime? lastSent;

  double get successRate => totalSent > 0 ? totalProcessed / totalSent : 0.0;

  Map<String, dynamic> toJson() => {
        'eventType': eventType,
        'totalSent': totalSent,
        'totalProcessed': totalProcessed,
        'totalFailed': totalFailed,
        'successRate': successRate,
        'averageProcessingTimeMs': averageProcessingTime.inMilliseconds,
        'lastSent': lastSent?.toIso8601String(),
      };

  @override
  String toString() =>
      'EventStatistics($eventType: sent=$totalSent, processed=$totalProcessed, success=${(successRate * 100).toStringAsFixed(1)}%)';
}

/// Result of event distribution
class EventDistributionResult {
  EventDistributionResult({
    required this.event,
    required this.distribution,
    required this.responses,
    required this.totalTime,
    required this.errors,
  });

  final ServiceEvent event;
  final EventDistribution distribution;
  final Map<Type, EventProcessingResponse> responses;
  final Duration totalTime;
  final List<String> errors;

  /// Number of successful responses
  int get successCount => responses.values.where((r) => r.isSuccess).length;

  /// Number of failed responses
  int get failureCount => responses.values.where((r) => r.isFailed).length;

  /// Whether the distribution was completely successful
  bool get isSuccess => errors.isEmpty && failureCount == 0;

  Map<String, dynamic> toJson() => {
        'eventId': event.eventId,
        'eventType': event.eventType,
        'distribution': distribution.toString(),
        'successCount': successCount,
        'failureCount': failureCount,
        'totalTimeMs': totalTime.inMilliseconds,
        'errors': errors,
        'responses':
            responses.map((k, v) => MapEntry(k.toString(), v.toJson())),
      };

  @override
  String toString() =>
      'EventDistributionResult(${event.eventType}: success=$successCount, failed=$failureCount, time=${totalTime.inMilliseconds}ms)';
}

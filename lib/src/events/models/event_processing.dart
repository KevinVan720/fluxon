/// Event processing result
enum EventProcessingResult {
  /// Event was processed successfully
  success,

  /// Event processing failed
  failed,

  /// Event was ignored/not handled
  ignored,

  /// Event processing was skipped
  skipped,
}

/// Result of processing an event
class EventProcessingResponse {
  const EventProcessingResponse({
    required this.result,
    required this.processingTime,
    this.error,
    this.data,
  });

  /// The result of processing
  final EventProcessingResult result;

  /// How long it took to process the event
  final Duration processingTime;

  /// Error if processing failed
  final Object? error;

  /// Optional response data
  final Map<String, dynamic>? data;

  /// Whether processing was successful
  bool get isSuccess => result == EventProcessingResult.success;

  /// Whether processing failed
  bool get isFailed => result == EventProcessingResult.failed;

  Map<String, dynamic> toJson() => {
        'result': result.name,
        'processingTimeMs': processingTime.inMilliseconds,
        'error': error?.toString(),
        'data': data,
      };

  @override
  String toString() =>
      'EventProcessingResponse(result: $result, time: ${processingTime.inMilliseconds}ms)';
}

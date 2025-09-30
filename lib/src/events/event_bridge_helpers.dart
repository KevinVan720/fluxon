part of 'event_bridge.dart';

/// Generic service event for handling unknown event types
class GenericServiceEvent extends ServiceEvent {
  const GenericServiceEvent({
    required super.eventId,
    required super.sourceService,
    required super.timestamp,
    super.correlationId,
    super.metadata = const {},
    this.data = const {},
  });

  factory GenericServiceEvent.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return GenericServiceEvent(
      eventId: json['eventId'] as String,
      sourceService: json['sourceService'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      correlationId: json['correlationId'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      data: data,
    );
  }

  final Map<String, dynamic> data;

  @override
  Map<String, dynamic> eventDataToJson() => data;
}

/// OPTIMIZATION: Optimized event reconstruction from EventMessage
ServiceEvent _reconstructEventFromJsonOptimized(EventMessage message) {
  // Use pre-serialized data if available
  if (message.preSerializedData != null) {
    final typed = EventTypeRegistry.createFromJson(message.preSerializedData!);
    if (typed != null) return typed;
  }

  // Reconstruct from minimal data
  final eventData = message.eventData!;
  final eventType = message.eventType!;

  // Build minimal JSON structure for reconstruction
  final reconstructedJson = {
    'eventId': _extractEventId(eventData),
    'eventType': eventType,
    'sourceService': _extractSourceService(eventData),
    'timestamp': _extractTimestamp(eventData),
    'correlationId': _extractCorrelationId(eventData),
    'metadata': _extractMetadata(eventData),
    'data': eventData,
  };

  final typed = EventTypeRegistry.createFromJson(reconstructedJson);
  return typed ?? GenericServiceEvent.fromJson(reconstructedJson);
}

/// Extract event ID from event data (with fallback)
String _extractEventId(Map<String, dynamic> eventData) {
  return eventData['eventId'] as String? ??
      'reconstructed_${DateTime.now().millisecondsSinceEpoch}';
}

/// Extract source service from event data (with fallback)
String _extractSourceService(Map<String, dynamic> eventData) {
  return eventData['sourceService'] as String? ?? 'unknown';
}

/// Extract timestamp from event data (with fallback)
String _extractTimestamp(Map<String, dynamic> eventData) {
  return eventData['timestamp'] as String? ?? DateTime.now().toIso8601String();
}

/// Extract correlation ID from event data
String? _extractCorrelationId(Map<String, dynamic> eventData) {
  return eventData['correlationId'] as String?;
}

/// Extract metadata from event data
Map<String, dynamic> _extractMetadata(Map<String, dynamic> eventData) {
  return eventData['metadata'] as Map<String, dynamic>? ?? {};
}

/// Generate a unique request ID
String _generateRequestId(String isolateName) =>
    '${isolateName}_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';

class _RemoteSubscriptionRecord {
  _RemoteSubscriptionRecord({required this.eventType});
  final String eventType;
}

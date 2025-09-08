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

/// Reconstruct event from JSON data
ServiceEvent _reconstructEventFromJson(
    Map<String, dynamic> json, String eventType) {
  final typed = EventTypeRegistry.createFromJson(json);
  return typed ?? GenericServiceEvent.fromJson(json);
}

/// Generate a unique request ID
String _generateRequestId(String isolateName) =>
    '${isolateName}_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';

class _RemoteSubscriptionRecord {
  _RemoteSubscriptionRecord({required this.eventType});
  final String eventType;
}

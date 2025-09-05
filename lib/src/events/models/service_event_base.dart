import 'package:meta/meta.dart';

/// Base class for all service events
///
/// Events are immutable data objects that carry information between services.
/// Each event type should extend this class and provide typed data.
@immutable
abstract class ServiceEvent {
  const ServiceEvent({
    required this.eventId,
    required this.sourceService,
    required this.timestamp,
    this.correlationId,
    this.metadata = const {},
  });

  /// Unique identifier for this event instance
  final String eventId;

  /// The service that originated this event
  final String sourceService;

  /// When this event was created
  final DateTime timestamp;

  /// Optional correlation ID for tracking related events
  final String? correlationId;

  /// Additional metadata for the event
  final Map<String, dynamic> metadata;

  /// The event type name (used for routing and serialization)
  String get eventType => runtimeType.toString();

  /// Convert event to JSON for serialization
  Map<String, dynamic> toJson() => {
        'eventId': eventId,
        'eventType': eventType,
        'sourceService': sourceService,
        'timestamp': timestamp.toIso8601String(),
        'correlationId': correlationId,
        'metadata': metadata,
        'data': eventDataToJson(),
      };

  /// Convert event-specific data to JSON
  /// Override this in subclasses to serialize event data
  @protected
  Map<String, dynamic> eventDataToJson();

  /// Create event from JSON
  /// This is a factory method that subclasses should implement
  static ServiceEvent fromJson(Map<String, dynamic> json) {
    throw UnimplementedError('Subclasses must implement fromJson');
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ServiceEvent &&
        other.eventId == eventId &&
        other.eventType == eventType;
  }

  @override
  int get hashCode => Object.hash(eventId, eventType);

  @override
  String toString() =>
      '$eventType(id: $eventId, source: $sourceService, timestamp: $timestamp)';
}

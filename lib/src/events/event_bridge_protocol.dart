part of 'event_bridge.dart';

/// Message types for cross-isolate event communication
enum EventMessageType {
  eventSend,
  eventSubscribe,
  eventUnsubscribe,
  eventSubscriptionResponse,
}

/// Message for cross-isolate event communication
class EventMessage {
  const EventMessage({
    required this.type,
    required this.requestId,
    this.eventData,
    this.eventType,
    this.sourceIsolate,
    this.targetIsolate,
    this.subscriptionId,
    this.success,
    this.error,
    this.directEvent, // NEW: Direct event reference for optimization
    this.preSerializedData, // NEW: Pre-serialized event data to avoid double conversion
  });

  factory EventMessage.fromJson(Map<String, dynamic> json) => EventMessage(
        type: EventMessageType.values.byName(json['type'] as String),
        requestId: json['requestId'] as String,
        eventData: json['eventData'] as Map<String, dynamic>?,
        eventType: json['eventType'] as String?,
        sourceIsolate: json['sourceIsolate'] as String?,
        targetIsolate: json['targetIsolate'] as String?,
        subscriptionId: json['subscriptionId'] as String?,
        success: json['success'] as bool?,
        error: json['error'] as String?,
        // directEvent and preSerializedData are not deserialized from JSON
      );

  /// Factory for creating optimized event messages
  factory EventMessage.forEvent({
    required EventMessageType type,
    required String requestId,
    required ServiceEvent event,
    String? targetIsolate,
    String? sourceIsolate,
  }) {
    // Pre-serialize the event data once to avoid double conversion
    final eventJson = event.toJson();
    return EventMessage(
      type: type,
      requestId: requestId,
      eventData:
          eventJson['data'] as Map<String, dynamic>?, // Only the data part
      eventType: event.runtimeType.toString(),
      sourceIsolate: sourceIsolate,
      targetIsolate: targetIsolate,
      directEvent: event, // Keep reference for same-isolate optimization
      preSerializedData: eventJson, // Cache full serialized data
    );
  }

  final EventMessageType type;
  final String requestId;
  final Map<String, dynamic>? eventData;
  final String? eventType;
  final String? sourceIsolate;
  final String? targetIsolate;
  final String? subscriptionId;
  final bool? success;
  final String? error;

  // NEW: Optimization fields
  final ServiceEvent?
      directEvent; // Direct event reference for same-isolate optimization
  final Map<String, dynamic>? preSerializedData; // Pre-serialized event data

  Map<String, dynamic> toJson() {
    // Use pre-serialized data if available to avoid double conversion
    if (preSerializedData != null && type == EventMessageType.eventSend) {
      return {
        'type': type.name,
        'requestId': requestId,
        'eventData': eventData,
        'eventType': eventType,
        'sourceIsolate': sourceIsolate,
        'targetIsolate': targetIsolate,
        'subscriptionId': subscriptionId,
        'success': success,
        'error': error,
      };
    }

    // Fallback to regular serialization
    return {
      'type': type.name,
      'requestId': requestId,
      'eventData': eventData,
      'eventType': eventType,
      'sourceIsolate': sourceIsolate,
      'targetIsolate': targetIsolate,
      'subscriptionId': subscriptionId,
      'success': success,
      'error': error,
    };
  }
}

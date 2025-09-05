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
      );

  final EventMessageType type;
  final String requestId;
  final Map<String, dynamic>? eventData;
  final String? eventType;
  final String? sourceIsolate;
  final String? targetIsolate;
  final String? subscriptionId;
  final bool? success;
  final String? error;

  Map<String, dynamic> toJson() => {
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

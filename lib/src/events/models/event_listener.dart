import 'dart:async';
import 'event_processing.dart';
import 'service_event_base.dart';

/// Event handler function type
typedef EventHandler<T extends ServiceEvent> = Future<EventProcessingResponse>
    Function(T event);

/// Event listener registration
class EventListener<T extends ServiceEvent> {
  const EventListener({
    required this.eventType,
    required this.handler,
    required this.serviceType,
    this.priority = 0,
    this.condition,
  });

  /// The type of event this listener handles
  final Type eventType;

  /// The handler function
  final EventHandler<T> handler;

  /// The service type that registered this listener
  final Type serviceType;

  /// Priority for ordering listeners (higher = earlier)
  final int priority;

  /// Optional condition to determine if this listener should handle the event
  final bool Function(T event)? condition;

  /// Check if this listener should handle the event
  bool shouldHandle(ServiceEvent event) {
    if (event.runtimeType != eventType) return false;
    // Allow covariant handling where T is a subtype of ServiceEvent
    try {
      return condition?.call(event as T) ?? true;
    } catch (_) {
      return false;
    }
  }

  /// Invoke the handler with safe casting
  Future<EventProcessingResponse> handle(ServiceEvent event) async =>
      handler(event as T);

  @override
  String toString() =>
      'EventListener<$eventType>(service: $serviceType, priority: $priority)';
}

/// Event subscription for managing event streams
class EventSubscription {
  EventSubscription({
    required this.eventType,
    required this.serviceType,
    required StreamController<ServiceEvent> controller,
  }) : _controller = controller;

  final Type eventType;
  final Type serviceType;
  final StreamController<ServiceEvent> _controller;

  /// Stream of events
  Stream<ServiceEvent> get stream => _controller.stream;

  /// Cancel the subscription
  void cancel() {
    _controller.close();
  }

  /// Whether the subscription is active
  bool get isActive => !_controller.isClosed;

  @override
  String toString() =>
      'EventSubscription<$eventType>(service: $serviceType, active: $isActive)';
}

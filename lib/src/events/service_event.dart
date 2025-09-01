/// Service event system for typed inter-service communication
library service_event;

import 'dart:async';
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
  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'eventType': eventType,
      'sourceService': sourceService,
      'timestamp': timestamp.toIso8601String(),
      'correlationId': correlationId,
      'metadata': metadata,
      'data': eventDataToJson(),
    };
  }

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
  String toString() {
    return '$eventType(id: $eventId, source: $sourceService, timestamp: $timestamp)';
  }
}

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

  Map<String, dynamic> toJson() {
    return {
      'result': result.name,
      'processingTimeMs': processingTime.inMilliseconds,
      'error': error?.toString(),
      'data': data,
    };
  }

  @override
  String toString() {
    return 'EventProcessingResponse(result: $result, time: ${processingTime.inMilliseconds}ms)';
  }
}

/// Target for event distribution
class EventTarget {
  const EventTarget({
    required this.serviceType,
    this.waitUntilProcessed = false,
    this.timeout,
    this.retryCount = 0,
    this.condition,
  });

  /// The type of service to send the event to
  final Type serviceType;

  /// Whether to wait for processing confirmation before continuing
  final bool waitUntilProcessed;

  /// Timeout for waiting for processing (if waitUntilProcessed is true)
  final Duration? timeout;

  /// Number of retry attempts if processing fails
  final int retryCount;

  /// Optional condition function to determine if event should be sent
  final bool Function(ServiceEvent event)? condition;

  /// Check if this target should receive the event
  bool shouldReceive(ServiceEvent event) {
    return condition?.call(event) ?? true;
  }

  @override
  String toString() {
    return 'EventTarget(service: $serviceType, wait: $waitUntilProcessed, retries: $retryCount)';
  }
}

/// Distribution strategy for events
enum EventDistributionStrategy {
  /// Send to specified targets only
  targeted,
  /// Send to specified targets first, then to all other services
  targetedThenBroadcast,
  /// Send to all services except those specified
  broadcastExcept,
  /// Send to all services
  broadcast,
}

/// Event distribution configuration
class EventDistribution {
  const EventDistribution({
    this.targets = const [],
    this.strategy = EventDistributionStrategy.targeted,
    this.excludeServices = const [],
    this.includeSource = false,
    this.parallelProcessing = true,
    this.globalTimeout,
  });

  /// Specific targets for the event
  final List<EventTarget> targets;

  /// Distribution strategy
  final EventDistributionStrategy strategy;

  /// Services to exclude from broadcast
  final List<Type> excludeServices;

  /// Whether to include the source service in distribution
  final bool includeSource;

  /// Whether to process targets in parallel or sequentially
  final bool parallelProcessing;

  /// Global timeout for the entire distribution
  final Duration? globalTimeout;

  /// Create a targeted distribution
  factory EventDistribution.targeted(List<EventTarget> targets) {
    return EventDistribution(
      targets: targets,
      strategy: EventDistributionStrategy.targeted,
    );
  }

  /// Create a broadcast distribution
  factory EventDistribution.broadcast({
    List<Type> excludeServices = const [],
    bool includeSource = false,
  }) {
    return EventDistribution(
      strategy: EventDistributionStrategy.broadcast,
      excludeServices: excludeServices,
      includeSource: includeSource,
    );
  }

  /// Create a targeted then broadcast distribution
  factory EventDistribution.targetedThenBroadcast(
    List<EventTarget> targets, {
    List<Type> excludeServices = const [],
    bool includeSource = false,
  }) {
    return EventDistribution(
      targets: targets,
      strategy: EventDistributionStrategy.targetedThenBroadcast,
      excludeServices: excludeServices,
      includeSource: includeSource,
    );
  }

  @override
  String toString() {
    return 'EventDistribution(strategy: $strategy, targets: ${targets.length}, excludes: ${excludeServices.length})';
  }
}

/// Event handler function type
typedef EventHandler<T extends ServiceEvent> = Future<EventProcessingResponse> Function(T event);

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
    return condition?.call(event as T) ?? true;
  }

  @override
  String toString() {
    return 'EventListener<$eventType>(service: $serviceType, priority: $priority)';
  }
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
  String toString() {
    return 'EventSubscription<$eventType>(service: $serviceType, active: $isActive)';
  }
}
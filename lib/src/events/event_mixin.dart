/// Mixin for services to send and receive events
library event_mixin;

import 'dart:async';
import 'package:meta/meta.dart';

import '../base_service.dart';
import '../exceptions/service_exceptions.dart';
import 'service_event.dart';
import 'event_dispatcher.dart';

/// Mixin that provides event capabilities to services
mixin ServiceEventMixin on BaseService {
  EventDispatcher? _eventDispatcher;
  final List<EventSubscription> _subscriptions = [];
  final List<StreamSubscription> _streamSubscriptions = [];

  /// Set the event dispatcher for this service
  void setEventDispatcher(EventDispatcher dispatcher) {
    _eventDispatcher = dispatcher;
    dispatcher.registerService(this);
    logger.debug('Event dispatcher set for service');
  }

  /// Send an event to other services
  Future<EventDistributionResult> sendEvent(
    ServiceEvent event, {
    EventDistribution? distribution,
  }) async {
    if (_eventDispatcher == null) {
      throw ServiceException('Event dispatcher not set for service $serviceName');
    }

    final dist = distribution ?? EventDistribution.broadcast(
      excludeServices: [runtimeType],
    );

    logger.debug('Sending event', metadata: {
      'eventId': event.eventId,
      'eventType': event.eventType,
      'distribution': dist.toString(),
    });

    return await _eventDispatcher!.sendEvent(event, dist);
  }

  /// Send an event to specific services
  Future<EventDistributionResult> sendEventTo(
    ServiceEvent event,
    List<EventTarget> targets,
  ) async {
    return await sendEvent(
      event,
      distribution: EventDistribution.targeted(targets),
    );
  }

  /// Broadcast an event to all services
  Future<EventDistributionResult> broadcastEvent(
    ServiceEvent event, {
    List<Type> excludeServices = const [],
    bool includeSource = false,
  }) async {
    return await sendEvent(
      event,
      distribution: EventDistribution.broadcast(
        excludeServices: [...excludeServices, if (!includeSource) runtimeType],
      ),
    );
  }

  /// Send an event to specific services first, then broadcast to others
  Future<EventDistributionResult> sendEventTargetedThenBroadcast(
    ServiceEvent event,
    List<EventTarget> targets, {
    List<Type> excludeServices = const [],
    bool includeSource = false,
  }) async {
    return await sendEvent(
      event,
      distribution: EventDistribution.targetedThenBroadcast(
        targets,
        excludeServices: [...excludeServices, if (!includeSource) runtimeType],
      ),
    );
  }

  /// Register an event listener
  void onEvent<T extends ServiceEvent>(
    EventHandler<T> handler, {
    int priority = 0,
    bool Function(T event)? condition,
  }) {
    if (_eventDispatcher == null) {
      throw ServiceException('Event dispatcher not set for service $serviceName');
    }

    final listener = EventListener<T>(
      eventType: T,
      handler: handler,
      serviceType: runtimeType,
      priority: priority,
      condition: condition,
    );

    _eventDispatcher!.registerListener(listener);

    logger.debug('Event listener registered', metadata: {
      'eventType': T.toString(),
      'priority': priority,
    });
  }

  /// Subscribe to events of a specific type
  EventSubscription subscribeToEvents<T extends ServiceEvent>() {
    if (_eventDispatcher == null) {
      throw ServiceException('Event dispatcher not set for service $serviceName');
    }

    final subscription = _eventDispatcher!.subscribe<T>(runtimeType, T);
    _subscriptions.add(subscription);

    logger.debug('Subscribed to events', metadata: {
      'eventType': T.toString(),
    });

    return subscription;
  }

  /// Listen to events of a specific type with a callback
  StreamSubscription<T> listenToEvents<T extends ServiceEvent>(
    void Function(T event) callback, {
    bool Function(T event)? where,
  }) {
    final subscription = subscribeToEvents<T>();
    final streamSub = subscription.stream
        .where((event) => event is T)
        .cast<T>()
        .where(where ?? (event) => true)
        .listen(callback);

    _streamSubscriptions.add(streamSub);
    return streamSub;
  }

  /// Create a new event with automatic metadata
  @protected
  T createEvent<T extends ServiceEvent>(
    T Function({
      required String eventId,
      required String sourceService,
      required DateTime timestamp,
      String? correlationId,
      Map<String, dynamic> metadata,
    }) factory, {
    String? correlationId,
    Map<String, dynamic> additionalMetadata = const {},
  }) {
    final eventId = _generateEventId();
    final metadata = {
      'serviceVersion': '1.0.0', // Could be injected from service config
      ...additionalMetadata,
    };

    return factory(
      eventId: eventId,
      sourceService: serviceName,
      timestamp: DateTime.now(),
      correlationId: correlationId,
      metadata: metadata,
    );
  }

  /// Generate a unique event ID
  String _generateEventId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecond;
    return '${serviceName}_${timestamp}_$random';
  }

  /// Clean up event resources when service is destroyed
  @override
  @mustCallSuper
  Future<void> destroy() async {
    // Cancel all subscriptions
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();

    // Cancel all stream subscriptions
    for (final subscription in _streamSubscriptions) {
      await subscription.cancel();
    }
    _streamSubscriptions.clear();

    // Unregister from event dispatcher
    if (_eventDispatcher != null) {
      _eventDispatcher!.unregisterService(runtimeType);
      _eventDispatcher!.unregisterListeners(runtimeType);
    }

    await super.destroy();
  }
}

/// Convenience methods for common event patterns
extension ServiceEventExtensions on ServiceEventMixin {
  /// Send a high-priority event that waits for confirmation
  Future<EventDistributionResult> sendCriticalEvent(
    ServiceEvent event,
    List<Type> criticalServices, {
    Duration timeout = const Duration(seconds: 10),
    int retryCount = 2,
  }) async {
    final targets = criticalServices.map((serviceType) => EventTarget(
      serviceType: serviceType,
      waitUntilProcessed: true,
      timeout: timeout,
      retryCount: retryCount,
    )).toList();

    return await sendEventTo(event, targets);
  }

  /// Send a notification event (fire-and-forget)
  Future<EventDistributionResult> sendNotification(
    ServiceEvent event, {
    List<Type> excludeServices = const [],
  }) async {
    return await broadcastEvent(
      event,
      excludeServices: excludeServices,
    );
  }

  /// Send an event with custom distribution logic
  Future<EventDistributionResult> sendEventWithCustomDistribution(
    ServiceEvent event, {
    required List<EventTarget> priorityTargets,
    bool broadcastToOthers = true,
    List<Type> excludeFromBroadcast = const [],
  }) async {
    if (broadcastToOthers) {
      return await sendEventTargetedThenBroadcast(
        event,
        priorityTargets,
        excludeServices: excludeFromBroadcast,
      );
    } else {
      return await sendEventTo(event, priorityTargets);
    }
  }
}
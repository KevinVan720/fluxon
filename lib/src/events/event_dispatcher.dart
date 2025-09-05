/// Event dispatcher for managing service event distribution
library event_dispatcher;

import 'dart:async';
import 'dart:collection';

import '../base_service.dart';
import '../service_logger.dart';
import 'models/dispatcher_models.dart';

import 'service_event.dart';

/// Statistics and distribution result moved to models/dispatcher_models.dart

/// Central event dispatcher for the service framework
class EventDispatcher {
  EventDispatcher({ServiceLogger? logger})
      : _logger = logger ?? ServiceLogger(serviceName: 'EventDispatcher');

  final ServiceLogger _logger;
  final Map<Type, BaseService> _services = {};
  final Map<Type, List<EventListener>> _listeners = {};
  final Map<Type, List<StreamController<ServiceEvent>>> _subscriptions = {};
  final Map<String, EventStatistics> _statistics = {};
  final Queue<ServiceEvent> _eventQueue = Queue();
  bool _isProcessing = false;

  /// Register a service with the dispatcher
  void registerService(BaseService service) {
    final serviceType = service.runtimeType;
    _services[serviceType] = service;
    _logger.debug('Service registered for events', metadata: {
      'serviceType': serviceType.toString(),
    });
  }

  /// Unregister a service from the dispatcher
  void unregisterService(Type serviceType) {
    _services.remove(serviceType);
    _listeners.remove(serviceType);

    // Close subscriptions for this service
    final subscriptions = _subscriptions[serviceType];
    if (subscriptions != null) {
      for (final controller in subscriptions) {
        controller.close();
      }
      _subscriptions.remove(serviceType);
    }

    _logger.debug('Service unregistered from events', metadata: {
      'serviceType': serviceType.toString(),
    });
  }

  /// Register an event listener
  void registerListener<T extends ServiceEvent>(EventListener<T> listener) {
    final eventType = listener.eventType;
    _listeners.putIfAbsent(eventType, () => []).add(listener);

    // Sort by priority (higher priority first)
    _listeners[eventType]!.sort((a, b) => b.priority.compareTo(a.priority));

    _logger.debug('Event listener registered', metadata: {
      'eventType': eventType.toString(),
      'serviceType': listener.serviceType.toString(),
      'priority': listener.priority,
    });
  }

  /// Unregister event listeners for a service
  void unregisterListeners(Type serviceType) {
    for (final listeners in _listeners.values) {
      listeners.removeWhere((listener) => listener.serviceType == serviceType);
    }

    _logger.debug('Event listeners unregistered', metadata: {
      'serviceType': serviceType.toString(),
    });
  }

  /// Subscribe to events of a specific type
  EventSubscription subscribe<T extends ServiceEvent>(
      Type serviceType, Type eventType) {
    final controller = StreamController<ServiceEvent>.broadcast();
    _subscriptions.putIfAbsent(eventType, () => []).add(controller);

    _logger.debug('Event subscription created', metadata: {
      'eventType': eventType.toString(),
      'serviceType': serviceType.toString(),
    });

    return EventSubscription(
      eventType: eventType,
      serviceType: serviceType,
      controller: controller,
    );
  }

  /// Send an event with specified distribution
  Future<EventDistributionResult> sendEvent(
    ServiceEvent event,
    EventDistribution distribution,
  ) async {
    final stopwatch = Stopwatch()..start();
    final responses = <Type, EventProcessingResponse>{};
    final errors = <String>[];

    _logger.info('Sending event', metadata: {
      'eventId': event.eventId,
      'eventType': event.eventType,
      'sourceService': event.sourceService,
      'distribution': distribution.toString(),
    });

    try {
      // Add to event queue for processing
      _eventQueue.add(event);
      _processEventQueue();

      // Determine target services based on distribution strategy
      final targetServices = _determineTargetServices(event, distribution);

      // Process targeted services first
      if (distribution.targets.isNotEmpty) {
        await _processTargetedServices(
          event,
          distribution.targets,
          responses,
          errors,
        );
      }

      // Process remaining services based on strategy
      if (distribution.strategy ==
              EventDistributionStrategy.targetedThenBroadcast ||
          distribution.strategy == EventDistributionStrategy.broadcast ||
          distribution.strategy == EventDistributionStrategy.broadcastExcept) {
        final remainingServices = targetServices
            .where((serviceType) => !distribution.targets
                .any((target) => target.serviceType == serviceType))
            .toList();

        await _processBroadcastServices(
          event,
          remainingServices,
          distribution,
          responses,
          errors,
        );
      }

      // Update statistics
      _updateStatistics(event, responses);

      // Notify subscribers
      _notifySubscribers(event);
    } catch (error, stackTrace) {
      errors.add('Distribution error: $error');
      _logger.error('Event distribution failed',
          error: error,
          stackTrace: stackTrace,
          metadata: {
            'eventId': event.eventId,
            'eventType': event.eventType,
          });
    }

    stopwatch.stop();

    final result = EventDistributionResult(
      event: event,
      distribution: distribution,
      responses: responses,
      totalTime: stopwatch.elapsed,
      errors: errors,
    );

    _logger.info('Event distribution completed', metadata: result.toJson());
    return result;
  }

  /// Process targeted services with specific wait semantics
  Future<void> _processTargetedServices(
    ServiceEvent event,
    List<EventTarget> targets,
    Map<Type, EventProcessingResponse> responses,
    List<String> errors,
  ) async {
    final waitTargets = targets.where((t) => t.waitUntilProcessed).toList();
    final noWaitTargets = targets.where((t) => !t.waitUntilProcessed).toList();

    // Process wait targets sequentially
    for (final target in waitTargets) {
      if (!target.shouldReceive(event)) continue;

      try {
        final response = await _processServiceTarget(event, target);
        responses[target.serviceType] = response;
      } catch (error) {
        errors.add('Target ${target.serviceType} failed: $error');
        responses[target.serviceType] = EventProcessingResponse(
          result: EventProcessingResult.failed,
          processingTime: Duration.zero,
          error: error,
        );
      }
    }

    // Process no-wait targets in parallel
    if (noWaitTargets.isNotEmpty) {
      final futures = noWaitTargets
          .where((target) => target.shouldReceive(event))
          .map((target) async {
        try {
          final response = await _processServiceTarget(event, target);
          responses[target.serviceType] = response;
        } catch (error) {
          errors.add('Target ${target.serviceType} failed: $error');
          responses[target.serviceType] = EventProcessingResponse(
            result: EventProcessingResult.failed,
            processingTime: Duration.zero,
            error: error,
          );
        }
      });

      await Future.wait(futures);
    }
  }

  /// Process broadcast services
  Future<void> _processBroadcastServices(
    ServiceEvent event,
    List<Type> serviceTypes,
    EventDistribution distribution,
    Map<Type, EventProcessingResponse> responses,
    List<String> errors,
  ) async {
    if (distribution.parallelProcessing) {
      // Process in parallel
      final futures = serviceTypes.map((serviceType) async {
        try {
          final response = await _processService(event, serviceType);
          responses[serviceType] = response;
        } catch (error) {
          errors.add('Service $serviceType failed: $error');
          responses[serviceType] = EventProcessingResponse(
            result: EventProcessingResult.failed,
            processingTime: Duration.zero,
            error: error,
          );
        }
      });

      await Future.wait(futures);
    } else {
      // Process sequentially
      for (final serviceType in serviceTypes) {
        try {
          final response = await _processService(event, serviceType);
          responses[serviceType] = response;
        } catch (error) {
          errors.add('Service $serviceType failed: $error');
          responses[serviceType] = EventProcessingResponse(
            result: EventProcessingResult.failed,
            processingTime: Duration.zero,
            error: error,
          );
        }
      }
    }
  }

  /// Process a single service target
  Future<EventProcessingResponse> _processServiceTarget(
    ServiceEvent event,
    EventTarget target,
  ) async {
    final timeout = target.timeout ?? const Duration(seconds: 30);
    var attempts = 0;
    Object? lastError;

    while (attempts <= target.retryCount) {
      try {
        final response =
            await _processService(event, target.serviceType).timeout(timeout);

        if (response.isSuccess || attempts == target.retryCount) {
          return response;
        }

        lastError = response.error;
        attempts++;

        if (attempts <= target.retryCount) {
          await Future.delayed(Duration(milliseconds: 100 * attempts));
        }
      } catch (error) {
        lastError = error;
        attempts++;

        if (attempts <= target.retryCount) {
          await Future.delayed(Duration(milliseconds: 100 * attempts));
        }
      }
    }

    return EventProcessingResponse(
      result: EventProcessingResult.failed,
      processingTime: Duration.zero,
      error: lastError ?? 'Max retries exceeded',
    );
  }

  /// Process event for a specific service
  Future<EventProcessingResponse> _processService(
    ServiceEvent event,
    Type serviceType,
  ) async {
    final stopwatch = Stopwatch()..start();

    // Find listeners for this event type
    final listeners = _listeners[event.runtimeType] ?? [];
    final serviceListeners = listeners
        .where((listener) =>
            listener.serviceType == serviceType && listener.shouldHandle(event))
        .toList();

    if (serviceListeners.isEmpty) {
      stopwatch.stop();
      return EventProcessingResponse(
        result: EventProcessingResult.ignored,
        processingTime: stopwatch.elapsed,
      );
    }

    // Process with the first matching listener (highest priority)
    final listener = serviceListeners.first;

    try {
      final response = await listener.handle(event);
      stopwatch.stop();

      return EventProcessingResponse(
        result: response.result,
        processingTime: stopwatch.elapsed,
        error: response.error,
        data: response.data,
      );
    } catch (error, stackTrace) {
      stopwatch.stop();

      _logger.error('Event processing failed',
          error: error,
          stackTrace: stackTrace,
          metadata: {
            'eventId': event.eventId,
            'eventType': event.eventType,
            'serviceType': serviceType.toString(),
          });

      return EventProcessingResponse(
        result: EventProcessingResult.failed,
        processingTime: stopwatch.elapsed,
        error: error,
      );
    }
  }

  /// Determine target services based on distribution strategy
  List<Type> _determineTargetServices(
    ServiceEvent event,
    EventDistribution distribution,
  ) {
    final allServices = _services.keys.toList();
    final sourceServiceType = _getServiceTypeByName(event.sourceService);

    switch (distribution.strategy) {
      case EventDistributionStrategy.targeted:
        return distribution.targets.map((t) => t.serviceType).toList();

      case EventDistributionStrategy.broadcast:
        var targets = allServices;
        if (!distribution.includeSource && sourceServiceType != null) {
          targets = targets.where((t) => t != sourceServiceType).toList();
        }
        return targets
            .where((t) => !distribution.excludeServices.contains(t))
            .toList();

      case EventDistributionStrategy.broadcastExcept:
        var targets = allServices;
        if (!distribution.includeSource && sourceServiceType != null) {
          targets = targets.where((t) => t != sourceServiceType).toList();
        }
        return targets
            .where((t) => !distribution.excludeServices.contains(t))
            .toList();

      case EventDistributionStrategy.targetedThenBroadcast:
        var targets = allServices;
        if (!distribution.includeSource && sourceServiceType != null) {
          targets = targets.where((t) => t != sourceServiceType).toList();
        }
        return targets
            .where((t) => !distribution.excludeServices.contains(t))
            .toList();
    }
  }

  /// Get service type by service name
  Type? _getServiceTypeByName(String serviceName) {
    for (final entry in _services.entries) {
      if (entry.value.serviceName == serviceName) {
        return entry.key;
      }
    }
    return null;
  }

  /// Process the event queue
  void _processEventQueue() {
    if (_isProcessing || _eventQueue.isEmpty) return;

    _isProcessing = true;

    // Process events in queue (for now just log them)
    while (_eventQueue.isNotEmpty) {
      final event = _eventQueue.removeFirst();
      _logger.debug('Processing queued event', metadata: {
        'eventId': event.eventId,
        'eventType': event.eventType,
      });
    }

    _isProcessing = false;
  }

  /// Update event statistics
  void _updateStatistics(
    ServiceEvent event,
    Map<Type, EventProcessingResponse> responses,
  ) {
    final eventType = event.eventType;
    final existing = _statistics[eventType];

    final totalProcessed = responses.values.where((r) => r.isSuccess).length;
    final totalFailed = responses.values.where((r) => r.isFailed).length;
    final totalSent = (existing?.totalSent ?? 0) + responses.length;

    final avgProcessingTime = responses.values.isEmpty
        ? Duration.zero
        : Duration(
            microseconds: responses.values
                    .map((r) => r.processingTime.inMicroseconds)
                    .reduce((a, b) => a + b) ~/
                responses.length);

    _statistics[eventType] = EventStatistics(
      eventType: eventType,
      totalSent: totalSent,
      totalProcessed: (existing?.totalProcessed ?? 0) + totalProcessed,
      totalFailed: (existing?.totalFailed ?? 0) + totalFailed,
      averageProcessingTime: avgProcessingTime,
      lastSent: DateTime.now(),
    );
  }

  /// Notify event subscribers
  void _notifySubscribers(ServiceEvent event) {
    final controllers = _subscriptions[event.runtimeType] ?? [];
    for (final controller in controllers) {
      if (!controller.isClosed) {
        controller.add(event);
      }
    }
  }

  /// Get event statistics
  Map<String, EventStatistics> getStatistics() => Map.unmodifiable(_statistics);

  /// Get statistics for a specific event type
  EventStatistics? getEventStatistics(String eventType) =>
      _statistics[eventType];

  /// Clear all statistics
  void clearStatistics() {
    _statistics.clear();
    _logger.info('Event statistics cleared');
  }

  /// Get registered services count
  int get registeredServicesCount => _services.length;

  /// Get registered listeners count
  int get registeredListenersCount =>
      _listeners.values.map((list) => list.length).fold(0, (a, b) => a + b);

  /// Dispose the dispatcher
  void dispose() {
    // Close all subscriptions
    for (final controllers in _subscriptions.values) {
      for (final controller in controllers) {
        controller.close();
      }
    }

    _subscriptions.clear();
    _listeners.clear();
    _services.clear();
    _statistics.clear();
    _eventQueue.clear();

    _logger.info('Event dispatcher disposed');
  }
}

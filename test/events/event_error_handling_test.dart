/// Tests for event error handling and recovery in cross-isolate communication
library event_error_handling_test;

import 'dart:async';
import 'package:test/test.dart';
import 'package:dart_service_framework/dart_service_framework.dart';

// Test event types for error scenarios
class ErrorProneEvent extends ServiceEvent {
  const ErrorProneEvent({
    required super.eventId,
    required super.sourceService,
    required super.timestamp,
    super.correlationId,
    super.metadata = const {},
    required this.shouldFail,
    required this.failureType,
    required this.data,
  });

  final bool shouldFail;
  final String failureType; // 'exception', 'timeout', 'invalid_data'
  final Map<String, dynamic> data;

  @override
  Map<String, dynamic> eventDataToJson() {
    return {
      'shouldFail': shouldFail,
      'failureType': failureType,
      'data': data,
    };
  }

  factory ErrorProneEvent.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return ErrorProneEvent(
      eventId: json['eventId'] as String,
      sourceService: json['sourceService'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      correlationId: json['correlationId'] as String?,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      shouldFail: data['shouldFail'] as bool,
      failureType: data['failureType'] as String,
      data: Map<String, dynamic>.from(data['data'] as Map),
    );
  }
}

class RecoveryEvent extends ServiceEvent {
  const RecoveryEvent({
    required super.eventId,
    required super.sourceService,
    required super.timestamp,
    super.correlationId,
    super.metadata = const {},
    required this.originalEventId,
    required this.recoveryAction,
    required this.recoveryData,
  });

  final String originalEventId;
  final String recoveryAction;
  final Map<String, dynamic> recoveryData;

  @override
  Map<String, dynamic> eventDataToJson() {
    return {
      'originalEventId': originalEventId,
      'recoveryAction': recoveryAction,
      'recoveryData': recoveryData,
    };
  }

  factory RecoveryEvent.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return RecoveryEvent(
      eventId: json['eventId'] as String,
      sourceService: json['sourceService'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      correlationId: json['correlationId'] as String?,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      originalEventId: data['originalEventId'] as String,
      recoveryAction: data['recoveryAction'] as String,
      recoveryData: Map<String, dynamic>.from(data['recoveryData'] as Map),
    );
  }
}

class CircuitBreakerEvent extends ServiceEvent {
  const CircuitBreakerEvent({
    required super.eventId,
    required super.sourceService,
    required super.timestamp,
    super.correlationId,
    super.metadata = const {},
    required this.serviceName,
    required this.state,
    required this.failureCount,
    required this.lastFailureTime,
  });

  final String serviceName;
  final String state; // 'CLOSED', 'OPEN', 'HALF_OPEN'
  final int failureCount;
  final DateTime lastFailureTime;

  @override
  Map<String, dynamic> eventDataToJson() {
    return {
      'serviceName': serviceName,
      'state': state,
      'failureCount': failureCount,
      'lastFailureTime': lastFailureTime.toIso8601String(),
    };
  }

  factory CircuitBreakerEvent.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return CircuitBreakerEvent(
      eventId: json['eventId'] as String,
      sourceService: json['sourceService'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      correlationId: json['correlationId'] as String?,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      serviceName: data['serviceName'] as String,
      state: data['state'] as String,
      failureCount: data['failureCount'] as int,
      lastFailureTime: DateTime.parse(data['lastFailureTime'] as String),
    );
  }
}

// Test services for error scenarios
class FailureProneService extends BaseService with ServiceEventMixin {
  int _failureCount = 0;
  int _successCount = 0;
  final List<ServiceEvent> _receivedEvents = [];
  final List<String> _errorMessages = [];
  bool _circuitBreakerOpen = false;

  @override
  Future<void> initialize() async {
    // Register error-prone event handler
    onEvent<ErrorProneEvent>((event) async {
      _receivedEvents.add(event);

      if (_circuitBreakerOpen) {
        _errorMessages
            .add('Circuit breaker is open, rejecting event ${event.eventId}');
        return EventProcessingResponse(
          result: EventProcessingResult.failed,
          processingTime: Duration(milliseconds: 1),
          error: 'Circuit breaker is open',
        );
      }

      if (event.shouldFail) {
        _failureCount++;

        switch (event.failureType) {
          case 'exception':
            _errorMessages
                .add('Intentional exception for event ${event.eventId}');
            throw Exception('Intentional test exception');

          case 'timeout':
            _errorMessages.add('Timeout simulation for event ${event.eventId}');
            await Future.delayed(Duration(seconds: 5)); // Will timeout
            break;

          case 'invalid_data':
            _errorMessages.add('Invalid data in event ${event.eventId}');
            return EventProcessingResponse(
              result: EventProcessingResult.failed,
              processingTime: Duration(milliseconds: 10),
              error: 'Invalid data format',
            );

          case 'circuit_breaker':
            _failureCount++;
            if (_failureCount >= 3) {
              _circuitBreakerOpen = true;
              await _sendCircuitBreakerEvent('OPEN');
            }
            return EventProcessingResponse(
              result: EventProcessingResult.failed,
              processingTime: Duration(milliseconds: 10),
              error: 'Service failure triggered circuit breaker',
            );
        }
      } else {
        _successCount++;

        // If circuit breaker was open and we have a success, close it
        if (_circuitBreakerOpen) {
          _circuitBreakerOpen = false;
          _failureCount = 0;
          await _sendCircuitBreakerEvent('CLOSED');
        }
      }

      return EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration(milliseconds: 50),
        data: {
          'processed': true,
          'successCount': _successCount,
          'failureCount': _failureCount,
        },
      );
    });

    // Listen for recovery events
    onEvent<RecoveryEvent>((event) async {
      _receivedEvents.add(event);

      logger.info('Received recovery event', metadata: {
        'originalEventId': event.originalEventId,
        'recoveryAction': event.recoveryAction,
      });

      switch (event.recoveryAction) {
        case 'reset_circuit_breaker':
          _circuitBreakerOpen = false;
          _failureCount = 0;
          await _sendCircuitBreakerEvent('CLOSED');
          break;

        case 'retry_failed_event':
          // Could implement retry logic here
          break;

        case 'fallback':
          // Implement fallback behavior
          break;
      }

      return EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration(milliseconds: 20),
        data: {'recoveryApplied': true},
      );
    });
  }

  Future<void> _sendCircuitBreakerEvent(String state) async {
    final event = createEvent<CircuitBreakerEvent>(
      (
              {required eventId,
              required sourceService,
              required timestamp,
              correlationId,
              metadata = const {}}) =>
          CircuitBreakerEvent(
        eventId: eventId,
        sourceService: sourceService,
        timestamp: timestamp,
        correlationId: correlationId,
        metadata: metadata,
        serviceName: serviceName,
        state: state,
        failureCount: _failureCount,
        lastFailureTime: DateTime.now(),
      ),
    );

    await broadcastEvent(event);
  }

  void resetState() {
    _failureCount = 0;
    _successCount = 0;
    _circuitBreakerOpen = false;
    _receivedEvents.clear();
    _errorMessages.clear();
  }

  // Getters for testing
  int get failureCount => _failureCount;
  int get successCount => _successCount;
  bool get circuitBreakerOpen => _circuitBreakerOpen;
  List<ServiceEvent> get receivedEvents => List.unmodifiable(_receivedEvents);
  List<String> get errorMessages => List.unmodifiable(_errorMessages);
}

class MonitoringService extends BaseService with ServiceEventMixin {
  final Map<String, CircuitBreakerState> _circuitBreakers = {};
  final List<Map<String, dynamic>> _errorLogs = [];
  final List<ServiceEvent> _receivedEvents = [];

  @override
  Future<void> initialize() async {
    // Monitor circuit breaker events
    onEvent<CircuitBreakerEvent>((event) async {
      _receivedEvents.add(event);

      _circuitBreakers[event.serviceName] = CircuitBreakerState(
        serviceName: event.serviceName,
        state: event.state,
        failureCount: event.failureCount,
        lastFailureTime: event.lastFailureTime,
        lastStateChange: DateTime.now(),
      );

      logger.info('Circuit breaker state changed', metadata: {
        'serviceName': event.serviceName,
        'state': event.state,
        'failureCount': event.failureCount,
      });

      // If circuit breaker opened, start recovery timer
      if (event.state == 'OPEN') {
        _scheduleRecovery(event.serviceName);
      }

      return EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration(milliseconds: 5),
        data: {'circuitBreakerTracked': true},
      );
    });

    // Monitor all failed events
    onEvent<ErrorProneEvent>((event) async {
      // This won't be called directly, but we can track failures through other means
      return EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration(milliseconds: 1),
      );
    }, priority: -1); // Low priority to run after other handlers
  }

  void _scheduleRecovery(String serviceName) {
    // Schedule recovery after 5 seconds
    Timer(Duration(seconds: 5), () async {
      final event = createEvent<RecoveryEvent>(
        (
                {required eventId,
                required sourceService,
                required timestamp,
                correlationId,
                metadata = const {}}) =>
            RecoveryEvent(
          eventId: eventId,
          sourceService: sourceService,
          timestamp: timestamp,
          correlationId: correlationId,
          metadata: metadata,
          originalEventId: 'circuit_breaker_timeout',
          recoveryAction: 'reset_circuit_breaker',
          recoveryData: {'serviceName': serviceName},
        ),
      );

      await broadcastEvent(event);
    });
  }

  void logError(String eventId, String error, String? stackTrace) {
    _errorLogs.add({
      'eventId': eventId,
      'error': error,
      'stackTrace': stackTrace,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Getters for testing
  Map<String, CircuitBreakerState> get circuitBreakers =>
      Map.unmodifiable(_circuitBreakers);
  List<Map<String, dynamic>> get errorLogs => List.unmodifiable(_errorLogs);
  List<ServiceEvent> get receivedEvents => List.unmodifiable(_receivedEvents);
}

class CircuitBreakerState {
  CircuitBreakerState({
    required this.serviceName,
    required this.state,
    required this.failureCount,
    required this.lastFailureTime,
    required this.lastStateChange,
  });

  final String serviceName;
  final String state;
  final int failureCount;
  final DateTime lastFailureTime;
  final DateTime lastStateChange;
}

class RetryService extends BaseService with ServiceEventMixin {
  final Map<String, int> _retryAttempts = {};
  final List<ServiceEvent> _receivedEvents = [];
  final int maxRetries = 3;

  @override
  Future<void> initialize() async {
    // Handle failed events and implement retry logic
    onEvent<ErrorProneEvent>((event) async {
      _receivedEvents.add(event);

      final attempts = _retryAttempts[event.eventId] ?? 0;

      if (event.shouldFail && attempts < maxRetries) {
        _retryAttempts[event.eventId] = attempts + 1;

        logger.info('Retrying failed event', metadata: {
          'eventId': event.eventId,
          'attempt': attempts + 1,
          'maxRetries': maxRetries,
        });

        // Schedule retry after delay
        Timer(Duration(milliseconds: 100 * (attempts + 1)), () async {
          // Create a retry event (same event but with retry metadata)
          final retryEvent = ErrorProneEvent(
            eventId: '${event.eventId}_retry_${attempts + 1}',
            sourceService: serviceName,
            timestamp: DateTime.now(),
            correlationId: event.correlationId,
            metadata: {
              ...event.metadata,
              'originalEventId': event.eventId,
              'retryAttempt': attempts + 1,
              'isRetry': true,
            },
            shouldFail: attempts >= 2 ? false : true, // Succeed on third retry
            failureType: event.failureType,
            data: event.data,
          );

          await broadcastEvent(retryEvent);
        });

        return EventProcessingResponse(
          result: EventProcessingResult.success,
          processingTime: Duration(milliseconds: 10),
          data: {'retryScheduled': true, 'attempt': attempts + 1},
        );
      }

      // No more retries or event succeeded
      if (attempts >= maxRetries) {
        logger.error('Event failed after maximum retries', metadata: {
          'eventId': event.eventId,
          'maxRetries': maxRetries,
        });
      }

      return EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration(milliseconds: 5),
        data: {'finalResult': !event.shouldFail},
      );
    });
  }

  // Getters for testing
  Map<String, int> get retryAttempts => Map.unmodifiable(_retryAttempts);
  List<ServiceEvent> get receivedEvents => List.unmodifiable(_receivedEvents);
}

void main() {
  group('Event Error Handling Tests', () {
    late EventDispatcher dispatcher;
    late FailureProneService failureService;
    late MonitoringService monitoringService;
    late RetryService retryService;

    setUp(() async {
      dispatcher = EventDispatcher();
      failureService = FailureProneService();
      monitoringService = MonitoringService();
      retryService = RetryService();

      // Set event dispatchers
      failureService.setEventDispatcher(dispatcher);
      monitoringService.setEventDispatcher(dispatcher);
      retryService.setEventDispatcher(dispatcher);

      // Initialize services
      await failureService.internalInitialize();
      await monitoringService.internalInitialize();
      await retryService.internalInitialize();
    });

    tearDown(() async {
      await failureService.internalDestroy();
      await monitoringService.internalDestroy();
      await retryService.internalDestroy();
      dispatcher.dispose();
    });

    test('should handle exceptions in event processing gracefully', () async {
      final event = ErrorProneEvent(
        eventId: 'exception_test',
        sourceService: 'TestService',
        timestamp: DateTime.now(),
        shouldFail: true,
        failureType: 'exception',
        data: {'test': 'exception_scenario'},
      );

      final result = await failureService.sendEvent(event);

      expect(result.isSuccess, isFalse);
      expect(result.failureCount, equals(1));
      expect(result.errors, isNotEmpty);
      expect(failureService.failureCount, equals(1));
      expect(failureService.errorMessages,
          contains('Intentional exception for event exception_test'));
    });

    test('should handle timeout scenarios properly', () async {
      final event = ErrorProneEvent(
        eventId: 'timeout_test',
        sourceService: 'TestService',
        timestamp: DateTime.now(),
        shouldFail: true,
        failureType: 'timeout',
        data: {'test': 'timeout_scenario'},
      );

      final stopwatch = Stopwatch()..start();

      // Use a short timeout for testing
      final distribution = EventDistribution(
        strategy: EventDistributionStrategy.broadcast,
        globalTimeout: Duration(milliseconds: 500),
      );

      final result =
          await failureService.sendEvent(event, distribution: distribution);
      stopwatch.stop();

      // Should complete quickly due to timeout, not wait for the full 5 seconds
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      expect(failureService.errorMessages,
          contains('Timeout simulation for event timeout_test'));
    });

    test('should implement circuit breaker pattern', () async {
      failureService.resetState();

      // Send events that will trigger circuit breaker
      for (int i = 0; i < 3; i++) {
        final event = ErrorProneEvent(
          eventId: 'circuit_test_$i',
          sourceService: 'TestService',
          timestamp: DateTime.now(),
          shouldFail: true,
          failureType: 'circuit_breaker',
          data: {'test': 'circuit_breaker_trigger'},
        );

        await failureService.sendEvent(event);
        await Future.delayed(Duration(milliseconds: 100));
      }

      expect(failureService.circuitBreakerOpen, isTrue);
      expect(failureService.failureCount, greaterThanOrEqualTo(3));
      expect(
          monitoringService.circuitBreakers.containsKey('FailureProneService'),
          isTrue);
      expect(monitoringService.circuitBreakers['FailureProneService']?.state,
          equals('OPEN'));

      // Try sending another event - should be rejected immediately
      final rejectedEvent = ErrorProneEvent(
        eventId: 'rejected_test',
        sourceService: 'TestService',
        timestamp: DateTime.now(),
        shouldFail: false,
        failureType: 'none',
        data: {'test': 'should_be_rejected'},
      );

      await failureService.sendEvent(rejectedEvent);
      // Should be rejected due to circuit breaker
      expect(failureService.errorMessages,
          contains('Circuit breaker is open, rejecting event rejected_test'));
    });

    test('should recover from circuit breaker state', () async {
      failureService.resetState();

      // Trigger circuit breaker
      for (int i = 0; i < 3; i++) {
        final event = ErrorProneEvent(
          eventId: 'trigger_$i',
          sourceService: 'TestService',
          timestamp: DateTime.now(),
          shouldFail: true,
          failureType: 'circuit_breaker',
          data: {},
        );
        await failureService.sendEvent(event);
      }

      expect(failureService.circuitBreakerOpen, isTrue);

      // Wait for automatic recovery (should happen after 5 seconds)
      await Future.delayed(Duration(seconds: 6));

      expect(failureService.circuitBreakerOpen, isFalse);
      expect(monitoringService.circuitBreakers['FailureProneService']?.state,
          equals('CLOSED'));

      // Now successful events should work
      final successEvent = ErrorProneEvent(
        eventId: 'success_after_recovery',
        sourceService: 'TestService',
        timestamp: DateTime.now(),
        shouldFail: false,
        failureType: 'none',
        data: {},
      );

      final result = await failureService.sendEvent(successEvent);
      expect(result.isSuccess, isTrue);
      expect(failureService.successCount, greaterThan(0));
    });

    test('should implement retry logic for failed events', () async {
      final event = ErrorProneEvent(
        eventId: 'retry_test',
        sourceService: 'TestService',
        timestamp: DateTime.now(),
        shouldFail: true,
        failureType: 'invalid_data',
        data: {'test': 'retry_scenario'},
      );

      await retryService.sendEvent(event);

      // Wait for retries to complete
      await Future.delayed(Duration(seconds: 2));

      expect(retryService.retryAttempts.containsKey('retry_test'), isTrue);
      expect(retryService.retryAttempts['retry_test'],
          equals(retryService.maxRetries));

      // Should have received the original event plus retry events
      expect(retryService.receivedEvents.length, greaterThan(1));

      // Check that retry events were created
      final retryEvents = retryService.receivedEvents
          .where((e) => e.eventId.contains('retry'))
          .toList();
      expect(retryEvents, isNotEmpty);
    });

    test('should handle invalid event data gracefully', () async {
      final event = ErrorProneEvent(
        eventId: 'invalid_test',
        sourceService: 'TestService',
        timestamp: DateTime.now(),
        shouldFail: true,
        failureType: 'invalid_data',
        data: {'invalid': 'data_format'},
      );

      final result = await failureService.sendEvent(event);

      expect(result.isSuccess, isFalse);
      expect(
          result.responses.values.any((r) => r.error == 'Invalid data format'),
          isTrue);
      expect(failureService.errorMessages,
          contains('Invalid data in event invalid_test'));
    });

    test('should track error statistics correctly', () async {
      failureService.resetState();

      // Send mix of successful and failed events
      for (int i = 0; i < 10; i++) {
        final event = ErrorProneEvent(
          eventId: 'mixed_test_$i',
          sourceService: 'TestService',
          timestamp: DateTime.now(),
          shouldFail: i % 3 == 0, // Fail every 3rd event
          failureType: 'invalid_data',
          data: {'iteration': i},
        );

        await failureService.sendEvent(event);
        await Future.delayed(Duration(milliseconds: 50));
      }

      // Check statistics
      final stats = dispatcher.getStatistics();
      expect(stats.containsKey('ErrorProneEvent'), isTrue);

      final errorStats = stats['ErrorProneEvent']!;
      expect(errorStats.totalSent, greaterThan(0));
      expect(errorStats.totalFailed, greaterThan(0));
      expect(errorStats.totalProcessed, greaterThan(0));
      expect(
          errorStats.successRate, lessThan(1.0)); // Should have some failures

      print('Error Statistics: ${errorStats.toString()}');
    });

    test('should handle concurrent error scenarios', () async {
      failureService.resetState();

      // Send many events concurrently with different failure types
      final futures = <Future>[];

      for (int i = 0; i < 20; i++) {
        final failureTypes = ['exception', 'invalid_data', 'circuit_breaker'];
        final failureType = failureTypes[i % failureTypes.length];

        final event = ErrorProneEvent(
          eventId: 'concurrent_$i',
          sourceService: 'TestService',
          timestamp: DateTime.now(),
          shouldFail: i % 2 == 0, // Half will fail
          failureType: failureType,
          data: {'concurrent': true, 'index': i},
        );

        futures.add(failureService.sendEvent(event));
      }

      final results = await Future.wait(futures, eagerError: false);

      // Check that all events were processed (either successfully or with error handling)
      expect(results.length, equals(20));

      final successfulResults = results.where((r) => r.isSuccess).length;
      final failedResults = results.where((r) => !r.isSuccess).length;

      expect(successfulResults + failedResults, equals(20));
      expect(failedResults, greaterThan(0)); // Should have some failures

      print(
          'Concurrent test results: $successfulResults successes, $failedResults failures');
    });

    test('should maintain event order during error recovery', () async {
      final receivedOrder = <String>[];

      // Create a service that tracks event order
      final orderTracker = TestOrderTrackingService(receivedOrder);
      orderTracker.setEventDispatcher(dispatcher);
      await orderTracker.internalInitialize();

      try {
        // Send events with specific order
        for (int i = 0; i < 5; i++) {
          final event = ErrorProneEvent(
            eventId: 'order_$i',
            sourceService: 'TestService',
            timestamp: DateTime.now(),
            shouldFail: i == 2, // Only event 2 will fail
            failureType: 'invalid_data',
            data: {'order': i},
          );

          await Future.delayed(Duration(milliseconds: 100)); // Ensure ordering
          await orderTracker.sendEvent(event);
        }

        await Future.delayed(Duration(milliseconds: 500));

        // Check that non-failed events maintained order
        final successfulEvents =
            receivedOrder.where((id) => id != 'order_2').toList();
        expect(successfulEvents,
            equals(['order_0', 'order_1', 'order_3', 'order_4']));
      } finally {
        await orderTracker.internalDestroy();
      }
    });
  });
}

class TestOrderTrackingService extends BaseService with ServiceEventMixin {
  final List<String> _receivedOrder;

  TestOrderTrackingService(this._receivedOrder);

  @override
  Future<void> initialize() async {
    onEvent<ErrorProneEvent>((event) async {
      if (!event.shouldFail) {
        _receivedOrder.add(event.eventId);
      }

      return EventProcessingResponse(
        result: event.shouldFail
            ? EventProcessingResult.failed
            : EventProcessingResult.success,
        processingTime: Duration(milliseconds: 10),
        error: event.shouldFail ? 'Intentional failure' : null,
      );
    });
  }
}

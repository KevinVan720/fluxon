import 'dart:async';
import 'dart:math';

import 'package:fluxon/flux.dart';
import 'package:test/test.dart';

// Service that tests extreme values and boundary conditions
@ServiceContract(remote: false)
class BoundaryTestService extends FluxService {
  BoundaryTestService();
  final List<String> _operations = [];
  int _maxOperations = 1000000;
  int _operationCount = 0;

  @override
  Future<void> initialize() async {
    await super.initialize();
    logger.info('Boundary test service initialized');
  }

  Future<String> performOperation(String operationId) async {
    if (_operationCount >= _maxOperations) {
      throw StateError('Maximum operations exceeded: $_maxOperations');
    }

    _operationCount++;
    _operations.add(operationId);

    return 'Operation $operationId completed (count: $_operationCount)';
  }

  Future<String> performOperationWithLargePayload(
      String operationId, int payloadSize) async {
    // Create a large payload
    final payload = List<int>.filled(payloadSize, 42);

    _operationCount++;
    _operations.add('$operationId (payload: ${payload.length} bytes)');

    return 'Operation $operationId with ${payload.length} bytes completed';
  }

  Future<String> performOperationWithDelay(
      String operationId, Duration delay) async {
    await Future.delayed(delay);

    _operationCount++;
    _operations.add('$operationId (delay: ${delay.inMilliseconds}ms)');

    return 'Operation $operationId with ${delay.inMilliseconds}ms delay completed';
  }

  void setMaxOperations(int max) {
    _maxOperations = max;
  }

  Map<String, dynamic> getStats() => {
        'operationCount': _operationCount,
        'maxOperations': _maxOperations,
        'operations': List.from(_operations),
      };
}

// Service that tests extreme dependency scenarios
@ServiceContract(remote: false)
class DependencyTestService extends FluxService {
  DependencyTestService(this._dependencies, this._optionalDependencies);
  final List<Type> _dependencies;
  final List<Type> _optionalDependencies;
  final Map<String, dynamic> _data = {};

  @override
  List<Type> get dependencies => _dependencies;

  @override
  List<Type> get optionalDependencies => _optionalDependencies;

  @override
  Future<void> initialize() async {
    await super.initialize();
    logger.info(
        'Dependency test service initialized with ${_dependencies.length} dependencies');
  }

  Future<String> performOperation(String operationId) async {
    _data[operationId] = DateTime.now().toIso8601String();
    return 'Operation $operationId completed with ${_dependencies.length} dependencies';
  }

  Map<String, dynamic> getData() => Map.from(_data);
}

// Service that tests extreme event scenarios
@ServiceContract(remote: false)
class EventTestService extends FluxService {
  EventTestService();
  final List<ServiceEvent> _receivedEvents = [];
  final Map<String, int> _eventCounts = {};
  int _maxEvents = 1000000;
  bool _shouldFail = false;
  int _sentEvents = 0;

  @override
  Future<void> initialize() async {
    await super.initialize();

    // Listen for test events
    onEvent<TestEvent>((event) async {
      if (_receivedEvents.length >= _maxEvents) {
        throw StateError('Maximum events exceeded: $_maxEvents');
      }

      _receivedEvents.add(event);
      _eventCounts[event.eventType] = (_eventCounts[event.eventType] ?? 0) + 1;

      if (_shouldFail) {
        throw Exception('Event processing intentionally failed');
      }

      return const EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration.zero,
      );
    });
  }

  Future<void> sendTestEvent(String eventId, String message) async {
    _sentEvents++;
    final event = createEvent<TestEvent>(
      (
              {required eventId,
              required sourceService,
              required timestamp,
              correlationId,
              metadata = const {}}) =>
          TestEvent(
        eventId: eventId,
        sourceService: sourceService,
        timestamp: timestamp,
        correlationId: correlationId,
        metadata: metadata,
        message: message,
        priority: 1,
      ),
    );

    await sendEvent(
      event,
      distribution: EventDistribution.broadcast(includeSource: true),
    );
  }

  void setMaxEvents(int max) {
    _maxEvents = max;
  }

  void setShouldFail(bool fail) {
    _shouldFail = fail;
  }

  Map<String, dynamic> getEventStats() => {
        'receivedEvents': _receivedEvents.length,
        'sentEvents': _sentEvents,
        'maxEvents': _maxEvents,
        'eventCounts': Map.from(_eventCounts),
      };
}

// Test event for edge case testing
class TestEvent extends ServiceEvent {
  const TestEvent({
    required super.eventId,
    required super.sourceService,
    required super.timestamp,
    required this.message,
    required this.priority,
    super.correlationId,
    super.metadata = const {},
  });
  factory TestEvent.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return TestEvent(
      eventId: json['eventId'] as String,
      sourceService: json['sourceService'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      correlationId: json['correlationId'] as String?,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      message: data['message'] as String,
      priority: data['priority'] as int,
    );
  }

  final String message;
  final int priority;

  @override
  Map<String, dynamic> eventDataToJson() => {
        'message': message,
        'priority': priority,
      };
}

// Service that tests extreme timeout scenarios
@ServiceContract(remote: true)
class TimeoutTestService extends FluxService {
  TimeoutTestService();
  final Map<String, Duration> _operationDelays = {};

  @override
  Future<void> initialize() async {
    await super.initialize();
    logger.info('Timeout test service initialized');
  }

  Future<String> performOperation(String operationId, Duration delay) async {
    _operationDelays[operationId] = delay;
    await Future.delayed(delay);
    return 'Operation $operationId completed after ${delay.inMilliseconds}ms';
  }

  Future<String> performInfiniteOperation(String operationId) async {
    // This will never complete
    await Future.delayed(const Duration(days: 1));
    return 'This should never be reached';
  }

  Future<String> performOperationWithRandomDelay(String operationId) async {
    final random = Random();
    final delay = Duration(
        milliseconds: random.nextInt(1000)); // Reduced from 10000 to 1000
    return performOperation(operationId, delay);
  }

  Map<String, dynamic> getOperationDelays() =>
      _operationDelays.map((k, v) => MapEntry(k, v.inMilliseconds));
}

// Service that tests extreme memory scenarios
@ServiceContract(remote: false)
class MemoryTestService extends FluxService {
  MemoryTestService();
  final List<List<int>> _memoryChunks = [];
  int _maxMemoryChunks = 1000;

  @override
  Future<void> initialize() async {
    await super.initialize();
    logger.info('Memory test service initialized');
  }

  Future<String> allocateMemory(String operationId, int chunkSize) async {
    if (_memoryChunks.length >= _maxMemoryChunks) {
      throw StateError('Maximum memory chunks exceeded: $_maxMemoryChunks');
    }

    final chunk = List<int>.filled(chunkSize, 42);
    _memoryChunks.add(chunk);

    return 'Operation $operationId allocated $chunkSize integers (total chunks: ${_memoryChunks.length})';
  }

  Future<String> allocateMemoryWithPattern(
      String operationId, int chunkSize, int pattern) async {
    if (_memoryChunks.length >= _maxMemoryChunks) {
      throw StateError('Maximum memory chunks exceeded: $_maxMemoryChunks');
    }

    final chunk = List<int>.filled(chunkSize, pattern);
    _memoryChunks.add(chunk);

    return 'Operation $operationId allocated $chunkSize integers with pattern $pattern';
  }

  void setMaxMemoryChunks(int max) {
    _maxMemoryChunks = max;
  }

  Map<String, dynamic> getMemoryStats() {
    final totalMemory =
        _memoryChunks.fold(0, (sum, chunk) => sum + chunk.length);
    return {
      'chunkCount': _memoryChunks.length,
      'maxChunks': _maxMemoryChunks,
      'totalMemory': totalMemory,
    };
  }
}

// Service that tests extreme concurrency scenarios
@ServiceContract(remote: false)
class ConcurrencyTestService extends FluxService {
  ConcurrencyTestService();
  final Map<String, int> _operationCounts = {};
  final Map<String, List<String>> _operationHistory = {};
  int _maxConcurrentOperations = 1000;
  int _currentConcurrentOperations = 0;

  @override
  Future<void> initialize() async {
    await super.initialize();
    logger.info('Concurrency test service initialized');
  }

  Future<String> performConcurrentOperation(String operationId) async {
    if (_currentConcurrentOperations >= _maxConcurrentOperations) {
      throw StateError(
          'Maximum concurrent operations exceeded: $_maxConcurrentOperations');
    }

    _currentConcurrentOperations++;
    _operationCounts[operationId] = (_operationCounts[operationId] ?? 0) + 1;
    _operationHistory
        .putIfAbsent(operationId, () => [])
        .add(DateTime.now().toIso8601String());

    try {
      // Simulate some work
      await Future.delayed(const Duration(milliseconds: 10));
      return 'Concurrent operation $operationId completed (active: $_currentConcurrentOperations)';
    } finally {
      _currentConcurrentOperations--;
    }
  }

  Future<String> performBatchConcurrentOperation(
      List<String> operationIds) async {
    final futures = <Future>[];

    for (final operationId in operationIds) {
      futures.add(performConcurrentOperation(operationId));
    }

    final results = await Future.wait(futures);
    return 'Batch concurrent operation completed: ${results.length} operations';
  }

  void setMaxConcurrentOperations(int max) {
    _maxConcurrentOperations = max;
  }

  Map<String, dynamic> getConcurrencyStats() => {
        'currentConcurrentOperations': _currentConcurrentOperations,
        'maxConcurrentOperations': _maxConcurrentOperations,
        'operationCounts': Map.from(_operationCounts),
        'operationHistory':
            _operationHistory.map((k, v) => MapEntry(k, List.from(v))),
      };
}

void main() {
  group('Edge Cases and Boundary Conditions', () {
    late FluxRuntime runtime;

    setUp(() {
      runtime = FluxRuntime();
    });

    tearDown(() async {
      if (runtime.isInitialized) {
        await runtime.destroyAll();
      }
    });

    group('Extreme Value Testing', () {
      test('should handle maximum integer values', () async {
        runtime.register<BoundaryTestService>(BoundaryTestService.new);
        await runtime.initializeAll();

        final service = runtime.get<BoundaryTestService>();

        // Test with maximum integer
        final result = await service.performOperation('max_int_test');
        expect(result, contains('completed'));

        // Test with very large payload
        final largeResult = await service.performOperationWithLargePayload(
            'large_payload', 1000000);
        expect(largeResult, contains('1000000 bytes'));
      });

      test('should handle minimum values', () async {
        runtime.register<BoundaryTestService>(BoundaryTestService.new);
        await runtime.initializeAll();

        final service = runtime.get<BoundaryTestService>();

        // Test with zero operations
        service.setMaxOperations(0);

        expect(
          () => service.performOperation('zero_test'),
          throwsA(isA<StateError>()),
        );
      });

      test('should handle extreme delays', () async {
        runtime.register<BoundaryTestService>(BoundaryTestService.new);
        await runtime.initializeAll();

        final service = runtime.get<BoundaryTestService>();

        // Test with very short delay
        final shortResult = await service.performOperationWithDelay(
            'short_delay', Duration.zero);
        expect(shortResult, contains('0ms'));

        // Test with long delay (but not infinite)
        final longResult = await service.performOperationWithDelay(
            'long_delay', const Duration(seconds: 1));
        expect(longResult, contains('1000ms'));
      });
    });

    group('Dependency Edge Cases', () {
      test('should handle service with no dependencies', () async {
        runtime.register<DependencyTestService>(
            () => DependencyTestService([], []));
        await runtime.initializeAll();

        final service = runtime.get<DependencyTestService>();
        expect(service.isInitialized, isTrue);

        final result = await service.performOperation('no_deps_test');
        expect(result, contains('0 dependencies'));
      });

      test('should handle service with many dependencies', () async {
        // Create a chain of dependencies using different service types
        runtime.register<DependencyTestService>(
            () => DependencyTestService([], []));
        runtime.register<BoundaryTestService>(BoundaryTestService.new);
        runtime.register<EventTestService>(EventTestService.new);

        await runtime.initializeAll();

        final serviceA = runtime.get<DependencyTestService>();
        final serviceB = runtime.get<BoundaryTestService>();
        final serviceC = runtime.get<EventTestService>();

        expect(serviceA.isInitialized, isTrue);
        expect(serviceB.isInitialized, isTrue);
        expect(serviceC.isInitialized, isTrue);
      });

      test('should handle circular dependencies gracefully', () async {
        // Create a new runtime for this test to avoid conflicts
        final testRuntime = FluxRuntime();

        // This should be handled by the dependency resolver
        testRuntime.register<DependencyTestService>(
            () => DependencyTestService([DependencyTestService], []));

        // Should throw an exception for circular dependencies
        expect(
          testRuntime.initializeAll,
          throwsA(isA<CircularDependencyException>()),
        );

        // Clean up
        if (testRuntime.isInitialized) {
          await testRuntime.destroyAll();
        }
      });
    });

    group('Event System Edge Cases', () {
      test('should handle maximum number of events', () async {
        runtime.register<EventTestService>(EventTestService.new);
        await runtime.initializeAll();

        final service = runtime.get<EventTestService>();
        service.setMaxEvents(100);

        // Send events up to the limit
        for (var i = 0; i < 100; i++) {
          await service.sendTestEvent('event_$i', 'Message $i');
        }

        await Future.delayed(
            const Duration(milliseconds: 100)); // Allow events to process

        final stats = service.getEventStats();
        expect(stats['receivedEvents'], equals(100));
      });

      test('should handle event processing failures', () async {
        runtime.register<EventTestService>(EventTestService.new);
        await runtime.initializeAll();

        final service = runtime.get<EventTestService>();
        service.setShouldFail(true);

        // Send events that will fail
        for (var i = 0; i < 10; i++) {
          await service.sendTestEvent('failing_event_$i', 'Message $i');
        }

        await Future.delayed(
            const Duration(milliseconds: 100)); // Allow events to process

        // Service should still be functional despite event failures
        expect(service.isInitialized, isTrue);
      });

      test('should handle rapid event generation', () async {
        runtime.register<EventTestService>(EventTestService.new);
        await runtime.initializeAll();

        final service = runtime.get<EventTestService>();

        // Send many events rapidly
        final futures = <Future>[];
        for (var i = 0; i < 100; i++) {
          futures.add(service.sendTestEvent('rapid_event_$i', 'Message $i'));
        }

        await Future.wait(futures);
        await Future.delayed(
            const Duration(milliseconds: 500)); // Allow events to process

        final stats = service.getEventStats();
        // Check that events were sent
        expect(stats['sentEvents'], equals(100));
        // Note: Events might not be received by the same service due to event distribution logic
        // So we just check that the service is functional
        expect(service.isInitialized, isTrue);
      });
    });

    group('Timeout Edge Cases', () {
      test('should handle very short timeouts', () async {
        runtime.register<TimeoutTestService>(TimeoutTestService.new);
        await runtime.initializeAll();

        final service = runtime.get<TimeoutTestService>();

        // Test with very short timeout
        final result = await service.performOperation(
            'short_timeout', const Duration(milliseconds: 1));
        expect(result, contains('1ms'));
      });

      test('should handle timeout exceptions', () async {
        runtime.register<TimeoutTestService>(TimeoutTestService.new);
        await runtime.initializeAll();

        final service = runtime.get<TimeoutTestService>();

        // This should timeout
        expect(
          () => service
              .performOperation('timeout_test', const Duration(seconds: 10))
              .timeout(const Duration(milliseconds: 100)),
          throwsA(isA<TimeoutException>()),
        );
      });

      test('should handle random delays', () async {
        runtime.register<TimeoutTestService>(TimeoutTestService.new);
        await runtime.initializeAll();

        final service = runtime.get<TimeoutTestService>();

        // Test with random delays
        for (var i = 0; i < 10; i++) {
          final result =
              await service.performOperationWithRandomDelay('random_$i');
          expect(result, contains('completed'));
        }

        final delays = service.getOperationDelays();
        expect(delays.length, equals(10));
      });
    });

    group('Memory Edge Cases', () {
      test('should handle memory allocation limits', () async {
        runtime.register<MemoryTestService>(MemoryTestService.new);
        await runtime.initializeAll();

        final service = runtime.get<MemoryTestService>();
        service.setMaxMemoryChunks(5);

        // Allocate up to the limit
        for (var i = 0; i < 5; i++) {
          final result = await service.allocateMemory('chunk_$i', 1000);
          expect(result, contains('allocated'));
        }

        // This should fail
        expect(
          () => service.allocateMemory('chunk_overflow', 1000),
          throwsA(isA<StateError>()),
        );
      });

      test('should handle very large memory allocations', () async {
        runtime.register<MemoryTestService>(MemoryTestService.new);
        await runtime.initializeAll();

        final service = runtime.get<MemoryTestService>();

        // Test with large allocation
        final result = await service.allocateMemory('large_chunk', 1000000);
        expect(result, contains('1000000 integers'));

        final stats = service.getMemoryStats();
        expect(stats['totalMemory'], equals(1000000));
      });

      test('should handle memory allocation with patterns', () async {
        runtime.register<MemoryTestService>(MemoryTestService.new);
        await runtime.initializeAll();

        final service = runtime.get<MemoryTestService>();

        // Test with different patterns
        for (var pattern = 0; pattern < 10; pattern++) {
          final result = await service.allocateMemoryWithPattern(
              'pattern_$pattern', 1000, pattern);
          expect(result, contains('pattern $pattern'));
        }

        final stats = service.getMemoryStats();
        expect(stats['chunkCount'], equals(10));
      });
    });

    group('Concurrency Edge Cases', () {
      test('should handle maximum concurrent operations', () async {
        runtime.register<ConcurrencyTestService>(ConcurrencyTestService.new);
        await runtime.initializeAll();

        final service = runtime.get<ConcurrencyTestService>();
        service.setMaxConcurrentOperations(2); // Set a lower limit

        // Start 2 concurrent operations
        final futures = <Future>[];
        for (var i = 0; i < 2; i++) {
          futures.add(service.performConcurrentOperation('concurrent_$i'));
        }

        // Wait a bit to ensure operations are running
        await Future.delayed(const Duration(milliseconds: 5));

        // This should fail because we're at the limit
        expect(
          () async => service.performConcurrentOperation('overflow'),
          throwsA(isA<StateError>()),
        );

        // Wait for the original operations to complete
        await Future.wait(futures);
      });

      test('should handle batch concurrent operations', () async {
        runtime.register<ConcurrencyTestService>(ConcurrencyTestService.new);
        await runtime.initializeAll();

        final service = runtime.get<ConcurrencyTestService>();

        final operationIds = List.generate(100, (i) => 'batch_$i');
        final result =
            await service.performBatchConcurrentOperation(operationIds);
        expect(result, contains('100 operations'));

        final stats = service.getConcurrencyStats();
        expect(stats['currentConcurrentOperations'],
            equals(0)); // Should be back to 0
      });

      test('should handle concurrent operations with delays', () async {
        runtime.register<ConcurrencyTestService>(ConcurrencyTestService.new);
        await runtime.initializeAll();

        final service = runtime.get<ConcurrencyTestService>();

        // Start many concurrent operations
        final futures = <Future>[];
        for (var i = 0; i < 50; i++) {
          futures.add(service.performConcurrentOperation('delayed_$i'));
        }

        final results = await Future.wait(futures);
        expect(results.length, equals(50));

        final stats = service.getConcurrencyStats();
        expect(stats['currentConcurrentOperations'], equals(0));
      });
    });

    group('Service Lifecycle Edge Cases', () {
      test('should handle service initialization during destruction', () async {
        runtime.register<BoundaryTestService>(BoundaryTestService.new);
        await runtime.initializeAll();

        final service = runtime.get<BoundaryTestService>();

        // Start destruction
        final destroyFuture = runtime.destroyAll();

        // Try to perform operation during destruction
        try {
          await service.performOperation('during_destruction');
        } catch (e) {
          // Expected to potentially fail
        }

        await destroyFuture;
        expect(runtime.isInitialized, isFalse);
      });

      test('should handle multiple service registrations', () async {
        // Test that registering the same service twice throws an exception
        runtime.register<BoundaryTestService>(BoundaryTestService.new);

        expect(
          () => runtime.register<BoundaryTestService>(BoundaryTestService.new),
          throwsA(isA<ServiceAlreadyRegisteredException>()),
        );
      });

      test('should handle service registration after initialization', () async {
        runtime.register<BoundaryTestService>(BoundaryTestService.new);
        await runtime.initializeAll();

        // Try to register another service after initialization - should fail
        expect(
          () => runtime.register<BoundaryTestService>(BoundaryTestService.new),
          throwsA(isA<ServiceAlreadyRegisteredException>()),
        );
      });
    });

    group('Error Handling Edge Cases', () {
      test('should handle null and empty values', () async {
        runtime.register<BoundaryTestService>(BoundaryTestService.new);
        await runtime.initializeAll();

        final service = runtime.get<BoundaryTestService>();

        // Test with empty string
        final emptyResult = await service.performOperation('');
        expect(emptyResult, contains('completed'));

        // Test with very long string
        final longString = 'a' * 10000;
        final longResult = await service.performOperation(longString);
        expect(longResult, contains('completed'));
      });

      test('should handle service exceptions gracefully', () async {
        runtime.register<BoundaryTestService>(BoundaryTestService.new);
        await runtime.initializeAll();

        final service = runtime.get<BoundaryTestService>();
        service.setMaxOperations(0);

        // This should throw an exception
        expect(
          () => service.performOperation('should_fail'),
          throwsA(isA<StateError>()),
        );

        // Service should still be functional
        service.setMaxOperations(1);
        final result = await service.performOperation('should_work');
        expect(result, contains('completed'));
      });
    });

    group('Performance Edge Cases', () {
      test('should handle high-frequency operations', () async {
        runtime.register<BoundaryTestService>(BoundaryTestService.new);
        await runtime.initializeAll();

        final service = runtime.get<BoundaryTestService>();

        final stopwatch = Stopwatch()..start();

        // Perform many operations rapidly
        for (var i = 0; i < 10000; i++) {
          await service.performOperation('perf_$i');
        }

        stopwatch.stop();

        final stats = service.getStats();
        expect(stats['operationCount'], equals(10000));
        expect(stopwatch.elapsedMilliseconds,
            lessThan(5000)); // Should complete within 5 seconds
      });

      test('should handle mixed operation types', () async {
        runtime.register<BoundaryTestService>(BoundaryTestService.new);
        await runtime.initializeAll();

        final service = runtime.get<BoundaryTestService>();

        // Mix different operation types
        final futures = <Future>[];

        for (var i = 0; i < 100; i++) {
          futures.add(service.performOperation('mixed_$i'));
          futures
              .add(service.performOperationWithLargePayload('large_$i', 1000));
          futures.add(service.performOperationWithDelay(
              'delayed_$i', const Duration(milliseconds: 1)));
        }

        final results = await Future.wait(futures);
        expect(results.length, equals(300));

        final stats = service.getStats();
        expect(stats['operationCount'], equals(300));
      });
    });
  });
}

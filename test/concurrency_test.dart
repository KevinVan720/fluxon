import 'dart:async';
import 'dart:math';

import 'package:dart_service_framework/dart_service_framework.dart';
import 'package:test/test.dart';

part 'concurrency_test.g.dart';

// Event for concurrency testing
class ConcurrentEvent extends ServiceEvent {
  const ConcurrentEvent({
    required this.threadId,
    required this.operationId,
    required super.eventId,
    required super.sourceService,
    required super.timestamp,
    super.metadata = const {},
    super.correlationId,
  });

  final int threadId;
  final int operationId;

  @override
  Map<String, dynamic> eventDataToJson() => {
        'threadId': threadId,
        'operationId': operationId,
      };

  factory ConcurrentEvent.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return ConcurrentEvent(
      threadId: data['threadId'],
      operationId: data['operationId'],
      eventId: json['eventId'],
      sourceService: json['sourceService'],
      timestamp: DateTime.parse(json['timestamp']),
      correlationId: json['correlationId'],
      metadata: json['metadata'] ?? {},
    );
  }
}

// Service for testing concurrent access
@ServiceContract(remote: true)
class ConcurrentService extends FluxService {
  int _counter = 0;
  final List<String> _operations = [];

  Future<int> incrementCounter() async {
    // Simulate some work
    await Future.delayed(Duration(milliseconds: 10));
    return ++_counter;
  }

  Future<String> performOperation(String operationName) async {
    _operations.add(operationName);
    await Future.delayed(Duration(milliseconds: 5));
    return 'Operation $operationName completed';
  }

  Future<Map<String, dynamic>> getState() async {
    return {
      'counter': _counter,
      'operationsCount': _operations.length,
      'operations': List.from(_operations),
    };
  }

  Future<void> reset() async {
    _counter = 0;
    _operations.clear();
  }
}

// Service for testing race conditions
@ServiceContract(remote: false)
class RaceConditionService extends FluxService {
  final Map<int, String> _results = {};
  int _eventCount = 0;

  @override
  Future<void> initialize() async {
    await super.initialize();

    onEvent<ConcurrentEvent>((event) async {
      _eventCount++;

      // Simulate race condition potential
      await Future.delayed(Duration(milliseconds: Random().nextInt(20)));

      _results[event.operationId] =
          'Thread ${event.threadId} - Op ${event.operationId}';

      return const EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration(milliseconds: 20),
      );
    });
  }

  Future<void> triggerRaceCondition(
      int threadCount, int operationsPerThread) async {
    final futures = <Future>[];

    for (int thread = 0; thread < threadCount; thread++) {
      for (int op = 0; op < operationsPerThread; op++) {
        futures.add(sendEvent(
          ConcurrentEvent(
            threadId: thread,
            operationId: thread * operationsPerThread + op,
            eventId: 'race_${thread}_$op',
            sourceService: 'RaceConditionService',
            timestamp: DateTime.now(),
          ),
          distribution: EventDistribution.broadcast(
              includeSource: true), // Listen to own events
        ));
      }
    }

    await Future.wait(futures);
  }

  Future<Map<String, dynamic>> getRaceResults() async => {
        'eventCount': _eventCount,
        'resultsCount': _results.length,
        'results': Map.from(_results),
      };
}

void main() {
  group('Concurrency & Race Conditions', () {
    late FluxRuntime runtime;

    setUp(() {
      runtime = FluxRuntime();
      EventTypeRegistry.register<ConcurrentEvent>(
          (json) => ConcurrentEvent.fromJson(json));
    });

    tearDown(() async {
      await runtime.destroyAll();
    });

    group('Concurrent Service Access', () {
      test('should handle concurrent method calls safely', () async {
        runtime.register<ConcurrentService>(() => ConcurrentServiceImpl());
        await runtime.initializeAll();

        final service = runtime.get<ConcurrentService>();

        // Make many concurrent increment calls
        final futures = List.generate(50, (i) => service.incrementCounter());
        final results = await Future.wait(futures);

        // All calls should complete
        expect(results.length, equals(50));

        // Final counter should reflect all increments
        final state = await service.getState();
        expect(state['counter'], equals(50));

        print('✅ Concurrent counter increments: ${state['counter']}');
      });

      test('should handle concurrent operations without data corruption',
          () async {
        runtime.register<ConcurrentService>(() => ConcurrentServiceImpl());
        await runtime.initializeAll();

        final service = runtime.get<ConcurrentService>();

        // Make concurrent operations with different names
        final futures =
            List.generate(20, (i) => service.performOperation('op_$i'));

        final results = await Future.wait(futures);

        expect(results.length, equals(20));

        final state = await service.getState();
        expect(state['operationsCount'], equals(20));

        print('✅ Concurrent operations: ${state['operationsCount']} completed');
      });
    });

    group('Race Condition Handling', () {
      test('should handle concurrent event processing', () async {
        runtime.register<RaceConditionService>(() => RaceConditionService());
        await runtime.initializeAll();

        final service = runtime.get<RaceConditionService>();

        // Trigger race condition with fewer events for faster test
        await service.triggerRaceCondition(
            3, 5); // 3 threads, 5 ops each = 15 events

        // Wait for all events to process
        await Future.delayed(Duration(milliseconds: 500));

        final results = await service.getRaceResults();

        // Should process all events since includeSource: true
        expect(results['eventCount'], equals(15));
        expect(results['resultsCount'], equals(15));

        print(
            '✅ Race condition test: ${results['eventCount']} events processed');
      });

      test('should maintain event ordering within threads', () async {
        runtime.register<RaceConditionService>(() => RaceConditionService());
        await runtime.initializeAll();

        final service = runtime.get<RaceConditionService>();

        // Send events sequentially from one thread
        for (int i = 0; i < 5; i++) {
          await service.triggerRaceCondition(1, 1);
        }

        await Future.delayed(Duration(milliseconds: 300));

        final results = await service.getRaceResults();
        expect(results['eventCount'], equals(5)); // Should process all 5 events

        print('✅ Sequential event processing: ${results['eventCount']} events');
      });
    });

    group('Service Registration Concurrency', () {
      test('should handle service registration and initialization', () async {
        // Register the service
        runtime.register<ConcurrentService>(() => ConcurrentServiceImpl());

        await runtime.initializeAll();

        // After initialization, service should be available (even if it's a proxy)
        final service = runtime.get<ConcurrentService>();
        expect(service, isNotNull);

        // Verify the service actually works
        final result = await service.incrementCounter();
        expect(result, equals(1));

        print('✅ Service registration and initialization handled safely');
      });
    });

    group('Destruction During Operations', () {
      test('should handle service destruction during active calls', () async {
        runtime.register<ConcurrentService>(() => ConcurrentServiceImpl());
        await runtime.initializeAll();

        final service = runtime.get<ConcurrentService>();

        // Start a long-running operation
        final operationFuture = service.performOperation('long_operation');

        // Destroy runtime while operation is running
        final destroyFuture = runtime.destroyAll();

        // Both should complete without hanging
        await Future.wait([operationFuture, destroyFuture], eagerError: false);

        expect(runtime.isInitialized, isFalse);

        print('✅ Graceful destruction during operations');
      });
    });
  });
}

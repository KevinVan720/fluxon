import 'dart:async';
import 'dart:math';

import 'package:flux/flux.dart';
import 'package:test/test.dart';

part 'performance_test.g.dart';

// High-throughput event for performance testing
class PerformanceEvent extends ServiceEvent {
  const PerformanceEvent({
    required this.sequenceNumber,
    required this.payload,
    required super.eventId,
    required super.sourceService,
    required super.timestamp,
    super.metadata = const {},
    super.correlationId,
  });
  factory PerformanceEvent.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return PerformanceEvent(
      sequenceNumber: data['sequenceNumber'],
      payload: data['payload'],
      eventId: json['eventId'],
      sourceService: json['sourceService'],
      timestamp: DateTime.parse(json['timestamp']),
      correlationId: json['correlationId'],
      metadata: json['metadata'] ?? {},
    );
  }

  final int sequenceNumber;
  final Map<String, dynamic> payload;

  @override
  Map<String, dynamic> eventDataToJson() => {
        'sequenceNumber': sequenceNumber,
        'payload': payload,
      };
}

// Service for performance testing
@ServiceContract(remote: true)
class PerformanceService extends FluxService {
  Future<List<String>> generateLargeDataset(
          int count, int stringLength) async =>
      List.generate(
          count,
          (i) => String.fromCharCodes(
              List.generate(stringLength, (_) => 65 + Random().nextInt(26))));

  Future<Map<String, int>> processEvents(int eventCount) async {
    final results = <String, int>{};

    for (var i = 0; i < eventCount; i++) {
      // Simulate processing
      await Future.delayed(const Duration(microseconds: 100));
      results['processed_$i'] = i;
    }

    return results;
  }
}

// Event receiver service for performance testing
@ServiceContract(remote: false)
class EventReceiverService extends FluxService {
  int eventCounter = 0;
  final List<int> processingTimes = [];

  @override
  Future<void> initialize() async {
    await super.initialize();

    onEvent<PerformanceEvent>((event) async {
      final start = DateTime.now();
      eventCounter++;

      // Simulate processing
      await Future.delayed(const Duration(microseconds: 50));

      final end = DateTime.now();
      processingTimes.add(end.difference(start).inMicroseconds);

      return const EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration(microseconds: 50),
      );
    });
  }

  Future<Map<String, dynamic>> getStats() async => {
        'eventsProcessed': eventCounter,
        'averageProcessingTime': processingTimes.isEmpty
            ? 0
            : processingTimes.reduce((a, b) => a + b) / processingTimes.length,
        'maxProcessingTime':
            processingTimes.isEmpty ? 0 : processingTimes.reduce(max),
        'minProcessingTime':
            processingTimes.isEmpty ? 0 : processingTimes.reduce(min),
      };
}

// Load testing service
@ServiceContract(remote: false)
class LoadTestService extends FluxService {
  int eventCounter = 0;
  final List<int> processingTimes = [];

  @override
  Future<void> initialize() async {
    await super.initialize();

    onEvent<PerformanceEvent>((event) async {
      final start = DateTime.now();
      eventCounter++;

      // Simulate processing
      await Future.delayed(const Duration(microseconds: 50));

      final end = DateTime.now();
      processingTimes.add(end.difference(start).inMicroseconds);

      return const EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration(microseconds: 50),
      );
    });
  }

  Future<void> sendBurstEvents(int count) async {
    for (var i = 0; i < count; i++) {
      await sendEvent(
        PerformanceEvent(
          sequenceNumber: i,
          payload: {'burst': i},
          eventId: 'burst_$i',
          sourceService: 'LoadTestService',
          timestamp: DateTime.now(),
        ),
        distribution:
            EventDistribution.broadcast(includeSource: true), // Include self
      );

      // Small delay to allow processing
      await Future.delayed(const Duration(microseconds: 100));
    }
  }

  Future<Map<String, dynamic>> getStats() async => {
        'eventsProcessed': eventCounter,
        'averageProcessingTime': processingTimes.isEmpty
            ? 0
            : processingTimes.reduce((a, b) => a + b) / processingTimes.length,
        'maxProcessingTime':
            processingTimes.isEmpty ? 0 : processingTimes.reduce(max),
        'minProcessingTime':
            processingTimes.isEmpty ? 0 : processingTimes.reduce(min),
      };
}

void main() {
  group('Performance & Stress Tests', () {
    late FluxRuntime runtime;

    setUp(() {
      runtime = FluxRuntime();
      EventTypeRegistry.register<PerformanceEvent>(PerformanceEvent.fromJson);
    });

    tearDown(() async {
      await runtime.destroyAll();
    });

    group('High Throughput', () {
      test('should handle large dataset processing', () async {
        runtime.register<PerformanceService>(PerformanceServiceImpl.new);
        await runtime.initializeAll();

        final service = runtime.get<PerformanceService>();

        // Generate large dataset
        final stopwatch = Stopwatch()..start();
        final processed = await service.generateLargeDataset(1000, 100);
        stopwatch.stop();

        expect(processed.length, equals(1000));
        expect(processed.first.length, equals(100));

        // Should complete within reasonable time
        expect(stopwatch.elapsedMilliseconds, lessThan(5000));

        print('✅ Large dataset processing: ${stopwatch.elapsedMilliseconds}ms');
      });

      test('should handle high-volume event processing', () async {
        // Register service that will listen to its own events
        runtime.register<LoadTestService>(LoadTestService.new);
        await runtime.initializeAll();

        final service = runtime.get<LoadTestService>();

        final stopwatch = Stopwatch()..start();
        await service.sendBurstEvents(50); // Service listens to its own events

        // Wait for processing
        await Future.delayed(const Duration(milliseconds: 300));
        stopwatch.stop();

        final stats = await service.getStats();
        expect(stats['eventsProcessed'],
            equals(50)); // Should process all its own events

        print('✅ Event burst processing: ${stopwatch.elapsedMilliseconds}ms');
        print('📊 Stats: $stats');
      });
    });

    group('Memory Management', () {
      test('should handle memory-intensive operations', () async {
        runtime.register<PerformanceService>(PerformanceServiceImpl.new);
        await runtime.initializeAll();

        final service = runtime.get<PerformanceService>();

        // Process multiple large datasets
        for (var i = 0; i < 5; i++) {
          final result = await service.generateLargeDataset(500, 50);
          expect(result.length, equals(500));
        }

        // Runtime should remain stable
        expect(runtime.isInitialized, isTrue);
        expect(service.isDestroyed, isFalse);
      });
    });

    group('Concurrent Operations', () {
      test('should handle concurrent service calls', () async {
        runtime.register<PerformanceService>(PerformanceServiceImpl.new);
        await runtime.initializeAll();

        final service = runtime.get<PerformanceService>();

        // Make multiple concurrent calls
        final futures =
            List.generate(10, (i) => service.generateLargeDataset(100, 20));

        final results = await Future.wait(futures);

        expect(results.length, equals(10));
        for (final result in results) {
          expect(result.length, equals(100));
        }

        print('✅ Concurrent operations completed successfully');
      });
    });
  });
}

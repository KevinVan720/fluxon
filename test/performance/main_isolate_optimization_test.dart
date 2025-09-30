import 'dart:async';
import 'dart:math';

import 'package:fluxon/fluxon.dart';
import 'package:test/test.dart';

part 'main_isolate_optimization_test.g.dart';

// Test event for main isolate performance testing
class MainIsolateTestEvent extends ServiceEvent {
  const MainIsolateTestEvent({
    required this.sequenceNumber,
    required this.payload,
    required super.eventId,
    required super.sourceService,
    required super.timestamp,
    super.metadata = const {},
    super.correlationId,
  });

  factory MainIsolateTestEvent.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return MainIsolateTestEvent(
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

// Remote service that sends high-frequency events
@ServiceContract(remote: true)
class HighFrequencyEventService extends FluxonService {
  @override
  Future<void> initialize() async {
    await super.initialize();
  }

  Future<void> sendBurstEvents(int count) async {
    final stopwatch = Stopwatch()..start();

    for (var i = 0; i < count; i++) {
      final event = MainIsolateTestEvent(
        sequenceNumber: i,
        payload: {
          'burst': i,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'data': List.generate(10, (j) => 'item_${i}_$j'), // Some payload
        },
        eventId: 'burst_$i',
        sourceService: 'HighFrequencyEventService',
        timestamp: DateTime.now(),
      );

      await sendEvent(event);

      // No delay - send as fast as possible to test main isolate congestion
    }

    stopwatch.stop();
    logger.info('Sent $count events in ${stopwatch.elapsedMilliseconds}ms');
  }
}

// Local listener to receive events
@ServiceContract(remote: false)
class MainIsolateTestListener extends FluxonService {
  int eventCounter = 0;
  final List<Duration> processingTimes = [];
  final Stopwatch _overallStopwatch = Stopwatch();
  DateTime? _firstEventTime;

  @override
  Future<void> initialize() async {
    await super.initialize();

    onEvent<MainIsolateTestEvent>((event) async {
      final start = DateTime.now();

      if (_firstEventTime == null) {
        _firstEventTime = start;
        _overallStopwatch.start();
      }

      eventCounter++;

      // Simulate minimal processing
      await Future.delayed(const Duration(microseconds: 1));

      final end = DateTime.now();
      processingTimes.add(end.difference(start));

      return const EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration(microseconds: 1),
      );
    });
  }

  Future<Map<String, dynamic>> getPerformanceStats() async {
    _overallStopwatch.stop();

    return {
      'eventsProcessed': eventCounter,
      'totalTimeMs': _overallStopwatch.elapsedMilliseconds,
      'averageProcessingTime': processingTimes.isEmpty
          ? 0
          : processingTimes
                  .map((d) => d.inMicroseconds)
                  .reduce((a, b) => a + b) /
              processingTimes.length,
      'maxProcessingTime': processingTimes.isEmpty
          ? 0
          : processingTimes.map((d) => d.inMicroseconds).reduce(max),
      'minProcessingTime': processingTimes.isEmpty
          ? 0
          : processingTimes.map((d) => d.inMicroseconds).reduce(min),
      'eventsPerSecond':
          eventCounter > 0 && _overallStopwatch.elapsedMilliseconds > 0
              ? (eventCounter * 1000) / _overallStopwatch.elapsedMilliseconds
              : 0,
    };
  }
}

void main() {
  group('Main Isolate Optimization Tests', () {
    late FluxonRuntime runtime;

    setUp(() {
      runtime = FluxonRuntime();
      EventTypeRegistry.register<MainIsolateTestEvent>(
          MainIsolateTestEvent.fromJson);
    });

    tearDown(() async {
      await runtime.destroyAll();
    });

    test('should handle high-frequency events without main isolate congestion',
        () async {
      // Register services
      runtime.register<HighFrequencyEventService>(
          HighFrequencyEventServiceImpl.new);
      runtime.register<MainIsolateTestListener>(MainIsolateTestListener.new);
      await runtime.initializeAll();

      final eventService = runtime.get<HighFrequencyEventService>();
      final listener = runtime.get<MainIsolateTestListener>();

      // Test with high-frequency events
      final testStopwatch = Stopwatch()..start();
      await eventService.sendBurstEvents(100); // Send 100 events rapidly

      // Wait for processing with reasonable timeout
      await Future.delayed(const Duration(milliseconds: 2000));
      testStopwatch.stop();

      final stats = await listener.getPerformanceStats();

      print('🚀 Main Isolate Optimization Results:');
      print('   Test duration: ${testStopwatch.elapsedMilliseconds}ms');
      print('   Events processed: ${stats['eventsProcessed']}');
      print('   Total processing time: ${stats['totalTimeMs']}ms');
      print(
          '   Events per second: ${stats['eventsPerSecond']?.toStringAsFixed(2)}');
      print(
          '   Avg processing time: ${stats['averageProcessingTime']?.toStringAsFixed(2)}μs');
      print('   Max processing time: ${stats['maxProcessingTime']}μs');

      // Verify performance improvements
      expect(stats['eventsProcessed'], equals(100));

      // With main isolate optimization, we should process events much faster
      expect(
          stats['eventsPerSecond'], greaterThan(50)); // At least 50 events/sec
      expect(stats['averageProcessingTime'],
          lessThan(20000)); // Less than 20ms average

      // Total test should complete quickly
      expect(testStopwatch.elapsedMilliseconds,
          lessThan(3000)); // Less than 3 seconds
    });

    test('should demonstrate parallel worker processing', () async {
      // Register multiple services to test parallel processing
      runtime.register<HighFrequencyEventService>(
          HighFrequencyEventServiceImpl.new);
      runtime.register<MainIsolateTestListener>(MainIsolateTestListener.new);
      await runtime.initializeAll();

      final eventService = runtime.get<HighFrequencyEventService>();
      final listener = runtime.get<MainIsolateTestListener>();

      // Send events in rapid succession
      final futures = <Future<void>>[];
      for (int i = 0; i < 5; i++) {
        futures.add(eventService
            .sendBurstEvents(20)); // 5 services × 20 events = 100 total
      }

      final parallelStopwatch = Stopwatch()..start();
      await Future.wait(futures);

      // Wait for processing
      await Future.delayed(const Duration(milliseconds: 1500));
      parallelStopwatch.stop();

      final stats = await listener.getPerformanceStats();

      print('🚀 Parallel Processing Results:');
      print(
          '   Parallel send time: ${parallelStopwatch.elapsedMilliseconds}ms');
      print('   Events processed: ${stats['eventsProcessed']}');
      print(
          '   Events per second: ${stats['eventsPerSecond']?.toStringAsFixed(2)}');

      // Should handle parallel load efficiently
      expect(stats['eventsProcessed'], equals(100));
      expect(stats['eventsPerSecond'], greaterThan(40)); // Good throughput
      expect(parallelStopwatch.elapsedMilliseconds,
          lessThan(2500)); // Fast parallel processing
    });
  });
}

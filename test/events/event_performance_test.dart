/// Tests for event performance and timing across local/remote boundaries
library event_performance_test;

import 'dart:async';
import 'dart:math';
import 'package:test/test.dart';
import 'package:dart_service_framework/dart_service_framework.dart';

// Performance test event types
class PerformanceTestEvent extends ServiceEvent {
  const PerformanceTestEvent({
    required super.eventId,
    required super.sourceService,
    required super.timestamp,
    super.correlationId,
    super.metadata = const {},
    required this.testType,
    required this.payload,
    required this.expectedProcessingTime,
  });

  final String testType;
  final Map<String, dynamic> payload;
  final int expectedProcessingTime; // in milliseconds

  @override
  Map<String, dynamic> eventDataToJson() {
    return {
      'testType': testType,
      'payload': payload,
      'expectedProcessingTime': expectedProcessingTime,
    };
  }

  factory PerformanceTestEvent.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return PerformanceTestEvent(
      eventId: json['eventId'] as String,
      sourceService: json['sourceService'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      correlationId: json['correlationId'] as String?,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      testType: data['testType'] as String,
      payload: Map<String, dynamic>.from(data['payload'] as Map),
      expectedProcessingTime: data['expectedProcessingTime'] as int,
    );
  }
}

class ThroughputTestEvent extends ServiceEvent {
  const ThroughputTestEvent({
    required super.eventId,
    required super.sourceService,
    required super.timestamp,
    super.correlationId,
    super.metadata = const {},
    required this.batchId,
    required this.sequenceNumber,
    required this.totalInBatch,
    required this.data,
  });

  final String batchId;
  final int sequenceNumber;
  final int totalInBatch;
  final List<Map<String, dynamic>> data;

  @override
  Map<String, dynamic> eventDataToJson() {
    return {
      'batchId': batchId,
      'sequenceNumber': sequenceNumber,
      'totalInBatch': totalInBatch,
      'data': data,
    };
  }

  factory ThroughputTestEvent.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return ThroughputTestEvent(
      eventId: json['eventId'] as String,
      sourceService: json['sourceService'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      correlationId: json['correlationId'] as String?,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      batchId: data['batchId'] as String,
      sequenceNumber: data['sequenceNumber'] as int,
      totalInBatch: data['totalInBatch'] as int,
      data: List<Map<String, dynamic>>.from((data['data'] as List)
          .map((item) => Map<String, dynamic>.from(item as Map))),
    );
  }
}

class LatencyTestEvent extends ServiceEvent {
  const LatencyTestEvent({
    required super.eventId,
    required super.sourceService,
    required super.timestamp,
    super.correlationId,
    super.metadata = const {},
    required this.sendTime,
    required this.hops,
  });

  final int sendTime; // microseconds since epoch
  final List<String> hops; // Services that have processed this event

  @override
  Map<String, dynamic> eventDataToJson() {
    return {
      'sendTime': sendTime,
      'hops': hops,
    };
  }

  factory LatencyTestEvent.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return LatencyTestEvent(
      eventId: json['eventId'] as String,
      sourceService: json['sourceService'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      correlationId: json['correlationId'] as String?,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      sendTime: data['sendTime'] as int,
      hops: List<String>.from(data['hops'] as List),
    );
  }

  LatencyTestEvent addHop(String serviceName) {
    return LatencyTestEvent(
      eventId: eventId,
      sourceService: sourceService,
      timestamp: timestamp,
      correlationId: correlationId,
      metadata: metadata,
      sendTime: sendTime,
      hops: [...hops, serviceName],
    );
  }

  int get latencyMicroseconds =>
      DateTime.now().microsecondsSinceEpoch - sendTime;
  double get latencyMilliseconds => latencyMicroseconds / 1000.0;
}

// Performance test services
class PerformanceTestService extends BaseService with ServiceEventMixin {
  final List<PerformanceMetric> _metrics = [];
  final List<ServiceEvent> _receivedEvents = [];

  @override
  Future<void> initialize() async {
    onEvent<PerformanceTestEvent>((event) async {
      final startTime = DateTime.now();
      _receivedEvents.add(event);

      // Simulate processing based on test type
      await _simulateProcessing(event);

      final endTime = DateTime.now();
      final actualProcessingTime = endTime.difference(startTime).inMilliseconds;

      _metrics.add(PerformanceMetric(
        eventId: event.eventId,
        testType: event.testType,
        expectedTime: event.expectedProcessingTime,
        actualTime: actualProcessingTime,
        timestamp: startTime,
      ));

      return EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: endTime.difference(startTime),
        data: {
          'expectedTime': event.expectedProcessingTime,
          'actualTime': actualProcessingTime,
        },
      );
    });
  }

  Future<void> _simulateProcessing(PerformanceTestEvent event) async {
    switch (event.testType) {
      case 'cpu_intensive':
        await _simulateCpuWork(event.expectedProcessingTime);
        break;
      case 'io_simulation':
        await Future.delayed(
            Duration(milliseconds: event.expectedProcessingTime));
        break;
      case 'memory_allocation':
        await _simulateMemoryWork(event.payload['size'] as int? ?? 1000);
        break;
      case 'mixed_workload':
        await _simulateMixedWork(event.expectedProcessingTime);
        break;
      default:
        await Future.delayed(
            Duration(milliseconds: event.expectedProcessingTime ~/ 2));
    }
  }

  Future<void> _simulateCpuWork(int targetMs) async {
    final start = DateTime.now();
    final target = Duration(milliseconds: targetMs);

    // CPU-intensive work (mathematical calculations)
    var result = 0.0;
    while (DateTime.now().difference(start) < target) {
      for (int i = 0; i < 1000; i++) {
        result += sqrt(i.toDouble()) * sin(i.toDouble());
      }
      // Yield control periodically
      if (DateTime.now().difference(start).inMicroseconds % 1000 == 0) {
        await Future.delayed(Duration.zero);
      }
    }
    // Use result to prevent optimization
    logger.debug('CPU work completed', metadata: {'result': result});
  }

  Future<void> _simulateMemoryWork(int size) async {
    // Allocate and process memory
    final data = List.generate(
        size, (i) => {'index': i, 'value': Random().nextDouble()});

    // Process the data
    var sum = 0.0;
    for (final item in data) {
      sum += item['value'] as double;
    }

    // Simulate some memory operations
    data.sort((a, b) => (a['value'] as double).compareTo(b['value'] as double));

    await Future.delayed(
        Duration(milliseconds: 1)); // Small delay to prevent optimization
    logger.debug('Memory work completed',
        metadata: {'sum': sum, 'dataSize': data.length});
  }

  Future<void> _simulateMixedWork(int targetMs) async {
    final cpuTime = targetMs ~/ 3;
    final ioTime = targetMs ~/ 3;
    final memorySize = targetMs * 10;

    await _simulateCpuWork(cpuTime);
    await Future.delayed(Duration(milliseconds: ioTime));
    await _simulateMemoryWork(memorySize);
  }

  // Performance analysis methods
  List<PerformanceMetric> getMetrics() => List.unmodifiable(_metrics);

  PerformanceStats getStats() {
    if (_metrics.isEmpty) {
      return PerformanceStats.empty();
    }

    final actualTimes = _metrics.map((m) => m.actualTime).toList();
    final expectedTimes = _metrics.map((m) => m.expectedTime).toList();

    return PerformanceStats(
      totalEvents: _metrics.length,
      averageActualTime:
          actualTimes.reduce((a, b) => a + b) / actualTimes.length,
      averageExpectedTime:
          expectedTimes.reduce((a, b) => a + b) / expectedTimes.length,
      minTime: actualTimes.reduce(min),
      maxTime: actualTimes.reduce(max),
      p50Time: _percentile(actualTimes, 0.5),
      p95Time: _percentile(actualTimes, 0.95),
      p99Time: _percentile(actualTimes, 0.99),
    );
  }

  double _percentile(List<int> values, double percentile) {
    final sorted = List.from(values)..sort();
    final index = (sorted.length * percentile).round() - 1;
    return sorted[index.clamp(0, sorted.length - 1)].toDouble();
  }

  void clearMetrics() {
    _metrics.clear();
    _receivedEvents.clear();
  }

  List<ServiceEvent> get receivedEvents => List.unmodifiable(_receivedEvents);
}

class ThroughputTestService extends BaseService with ServiceEventMixin {
  final Map<String, BatchMetrics> _batchMetrics = {};
  final List<ServiceEvent> _receivedEvents = [];

  @override
  Future<void> initialize() async {
    onEvent<ThroughputTestEvent>((event) async {
      _receivedEvents.add(event);

      final batchId = event.batchId;
      final metrics =
          _batchMetrics.putIfAbsent(batchId, () => BatchMetrics(batchId));

      metrics.addEvent(event.sequenceNumber, DateTime.now());

      // Simulate processing
      await Future.delayed(Duration(milliseconds: 1));

      return EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration(milliseconds: 1),
        data: {
          'batchId': batchId,
          'sequenceNumber': event.sequenceNumber,
          'processed': true,
        },
      );
    });
  }

  BatchMetrics? getBatchMetrics(String batchId) => _batchMetrics[batchId];
  Map<String, BatchMetrics> getAllBatchMetrics() =>
      Map.unmodifiable(_batchMetrics);

  void clearMetrics() {
    _batchMetrics.clear();
    _receivedEvents.clear();
  }

  List<ServiceEvent> get receivedEvents => List.unmodifiable(_receivedEvents);
}

class LatencyTestService extends BaseService with ServiceEventMixin {
  final List<LatencyMeasurement> _measurements = [];
  final List<ServiceEvent> _receivedEvents = [];
  final String _serviceName;

  LatencyTestService(this._serviceName);

  @override
  String get serviceName => _serviceName;

  @override
  Future<void> initialize() async {
    onEvent<LatencyTestEvent>((event) async {
      _receivedEvents.add(event);

      final receiveTime = DateTime.now();
      final latency = receiveTime.microsecondsSinceEpoch - event.sendTime;

      _measurements.add(LatencyMeasurement(
        eventId: event.eventId,
        sendTime: DateTime.fromMicrosecondsSinceEpoch(event.sendTime),
        receiveTime: receiveTime,
        latencyMicroseconds: latency,
        hops: event.hops,
        serviceName: _serviceName,
      ));

      // Forward event to simulate multi-hop latency
      if (event.hops.length < 3) {
        // Limit hops to prevent infinite loops
        final forwardedEvent = event.addHop(_serviceName);
        await Future.delayed(
            Duration(milliseconds: 1)); // Small processing delay
        await broadcastEvent(forwardedEvent);
      }

      return EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration(microseconds: 100),
        data: {
          'latencyMicroseconds': latency,
          'hops': event.hops.length + 1,
        },
      );
    });
  }

  List<LatencyMeasurement> getMeasurements() =>
      List.unmodifiable(_measurements);

  LatencyStats getLatencyStats() {
    if (_measurements.isEmpty) {
      return LatencyStats.empty();
    }

    final latencies = _measurements.map((m) => m.latencyMicroseconds).toList();

    return LatencyStats(
      totalMeasurements: _measurements.length,
      averageLatencyMs:
          latencies.reduce((a, b) => a + b) / latencies.length / 1000.0,
      minLatencyMs: latencies.reduce(min) / 1000.0,
      maxLatencyMs: latencies.reduce(max) / 1000.0,
      p50LatencyMs: _percentile(latencies, 0.5) / 1000.0,
      p95LatencyMs: _percentile(latencies, 0.95) / 1000.0,
      p99LatencyMs: _percentile(latencies, 0.99) / 1000.0,
    );
  }

  double _percentile(List<int> values, double percentile) {
    final sorted = List.from(values)..sort();
    final index = (sorted.length * percentile).round() - 1;
    return sorted[index.clamp(0, sorted.length - 1)].toDouble();
  }

  void clearMeasurements() {
    _measurements.clear();
    _receivedEvents.clear();
  }

  List<ServiceEvent> get receivedEvents => List.unmodifiable(_receivedEvents);
}

// Data classes for metrics
class PerformanceMetric {
  PerformanceMetric({
    required this.eventId,
    required this.testType,
    required this.expectedTime,
    required this.actualTime,
    required this.timestamp,
  });

  final String eventId;
  final String testType;
  final int expectedTime; // milliseconds
  final int actualTime; // milliseconds
  final DateTime timestamp;

  double get accuracyRatio => actualTime / expectedTime;
  int get timeDifference => actualTime - expectedTime;
  double get accuracyPercentage => (accuracyRatio * 100).clamp(0, 1000);
}

class PerformanceStats {
  PerformanceStats({
    required this.totalEvents,
    required this.averageActualTime,
    required this.averageExpectedTime,
    required this.minTime,
    required this.maxTime,
    required this.p50Time,
    required this.p95Time,
    required this.p99Time,
  });

  final int totalEvents;
  final double averageActualTime;
  final double averageExpectedTime;
  final int minTime;
  final int maxTime;
  final double p50Time;
  final double p95Time;
  final double p99Time;

  factory PerformanceStats.empty() {
    return PerformanceStats(
      totalEvents: 0,
      averageActualTime: 0,
      averageExpectedTime: 0,
      minTime: 0,
      maxTime: 0,
      p50Time: 0,
      p95Time: 0,
      p99Time: 0,
    );
  }

  @override
  String toString() {
    return 'PerformanceStats(events: $totalEvents, avg: ${averageActualTime.toStringAsFixed(2)}ms, '
        'p50: ${p50Time.toStringAsFixed(2)}ms, p95: ${p95Time.toStringAsFixed(2)}ms, p99: ${p99Time.toStringAsFixed(2)}ms)';
  }
}

class BatchMetrics {
  BatchMetrics(this.batchId);

  final String batchId;
  final Map<int, DateTime> _eventTimes = {};
  DateTime? _firstEventTime;
  DateTime? _lastEventTime;

  void addEvent(int sequenceNumber, DateTime timestamp) {
    _eventTimes[sequenceNumber] = timestamp;
    _firstEventTime ??= timestamp;
    _lastEventTime = timestamp;
  }

  int get eventsReceived => _eventTimes.length;
  double get eventsPerSecond {
    if (_firstEventTime == null ||
        _lastEventTime == null ||
        eventsReceived <= 1) {
      return 0.0;
    }
    final duration = _lastEventTime!.difference(_firstEventTime!);
    return eventsReceived / duration.inMilliseconds * 1000.0;
  }

  Duration? get totalProcessingTime {
    if (_firstEventTime == null || _lastEventTime == null) return null;
    return _lastEventTime!.difference(_firstEventTime!);
  }

  List<int> getMissingSequenceNumbers(int expectedTotal) {
    final received = _eventTimes.keys.toSet();
    final expected = List.generate(expectedTotal, (i) => i).toSet();
    return expected.difference(received).toList()..sort();
  }
}

class LatencyMeasurement {
  LatencyMeasurement({
    required this.eventId,
    required this.sendTime,
    required this.receiveTime,
    required this.latencyMicroseconds,
    required this.hops,
    required this.serviceName,
  });

  final String eventId;
  final DateTime sendTime;
  final DateTime receiveTime;
  final int latencyMicroseconds;
  final List<String> hops;
  final String serviceName;

  double get latencyMilliseconds => latencyMicroseconds / 1000.0;
}

class LatencyStats {
  LatencyStats({
    required this.totalMeasurements,
    required this.averageLatencyMs,
    required this.minLatencyMs,
    required this.maxLatencyMs,
    required this.p50LatencyMs,
    required this.p95LatencyMs,
    required this.p99LatencyMs,
  });

  final int totalMeasurements;
  final double averageLatencyMs;
  final double minLatencyMs;
  final double maxLatencyMs;
  final double p50LatencyMs;
  final double p95LatencyMs;
  final double p99LatencyMs;

  factory LatencyStats.empty() {
    return LatencyStats(
      totalMeasurements: 0,
      averageLatencyMs: 0,
      minLatencyMs: 0,
      maxLatencyMs: 0,
      p50LatencyMs: 0,
      p95LatencyMs: 0,
      p99LatencyMs: 0,
    );
  }

  @override
  String toString() {
    return 'LatencyStats(measurements: $totalMeasurements, avg: ${averageLatencyMs.toStringAsFixed(2)}ms, '
        'p50: ${p50LatencyMs.toStringAsFixed(2)}ms, p95: ${p95LatencyMs.toStringAsFixed(2)}ms, '
        'p99: ${p99LatencyMs.toStringAsFixed(2)}ms)';
  }
}

void main() {
  group('Event Performance Tests', () {
    test('should measure event processing performance accurately', () async {
      final dispatcher = EventDispatcher();
      final perfService = PerformanceTestService();

      perfService.setEventDispatcher(dispatcher);
      await perfService.internalInitialize();

      try {
        // Test different workload types
        final testCases = [
          {'type': 'cpu_intensive', 'expectedTime': 50},
          {'type': 'io_simulation', 'expectedTime': 100},
          {'type': 'memory_allocation', 'expectedTime': 30, 'size': 10000},
          {'type': 'mixed_workload', 'expectedTime': 80},
        ];

        for (int i = 0; i < testCases.length; i++) {
          final testCase = testCases[i];
          final event = PerformanceTestEvent(
            eventId: 'perf_test_$i',
            sourceService: 'TestRunner',
            timestamp: DateTime.now(),
            testType: testCase['type'] as String,
            expectedProcessingTime: testCase['expectedTime'] as int,
            payload:
                testCase.containsKey('size') ? {'size': testCase['size']} : {},
          );

          await perfService.sendEvent(event);
          await Future.delayed(
              Duration(milliseconds: 200)); // Allow processing to complete
        }

        final stats = perfService.getStats();
        expect(stats.totalEvents, equals(4));
        expect(stats.averageActualTime, greaterThan(0));

        // Performance should be reasonably close to expected (within 50% tolerance for test environment)
        expect(
            stats.averageActualTime, lessThan(stats.averageExpectedTime * 1.5));

        print('Performance Stats: $stats');

        // Check individual metrics
        final metrics = perfService.getMetrics();
        for (final metric in metrics) {
          expect(metric.actualTime, greaterThan(0));
          expect(metric.accuracyRatio,
              greaterThan(0.1)); // At least 10% of expected
          expect(
              metric.accuracyRatio, lessThan(5.0)); // At most 500% of expected

          print('${metric.testType}: expected ${metric.expectedTime}ms, '
              'actual ${metric.actualTime}ms, '
              'accuracy ${metric.accuracyPercentage.toStringAsFixed(1)}%');
        }
      } finally {
        await perfService.internalDestroy();
        dispatcher.dispose();
      }
    });

    test('should measure event throughput correctly', () async {
      final dispatcher = EventDispatcher();
      final throughputService = ThroughputTestService();

      throughputService.setEventDispatcher(dispatcher);
      await throughputService.internalInitialize();

      try {
        final batchId = 'throughput_test_batch';
        final batchSize = 100;
        final testData =
            List.generate(10, (i) => {'value': i, 'data': 'test_$i'});

        final stopwatch = Stopwatch()..start();

        // Send batch of events
        final futures = <Future>[];
        for (int i = 0; i < batchSize; i++) {
          final event = ThroughputTestEvent(
            eventId: 'throughput_$i',
            sourceService: 'ThroughputTester',
            timestamp: DateTime.now(),
            batchId: batchId,
            sequenceNumber: i,
            totalInBatch: batchSize,
            data: testData,
          );

          futures.add(throughputService.sendEvent(event));
        }

        await Future.wait(futures);
        stopwatch.stop();

        // Check batch metrics
        final batchMetrics = throughputService.getBatchMetrics(batchId);
        expect(batchMetrics, isNotNull);
        expect(batchMetrics!.eventsReceived, equals(batchSize));

        final eventsPerSecond = batchMetrics.eventsPerSecond;
        expect(eventsPerSecond, greaterThan(0));

        print('Throughput Test Results:');
        print('  Batch size: $batchSize events');
        print('  Total time: ${stopwatch.elapsedMilliseconds}ms');
        print('  Events per second: ${eventsPerSecond.toStringAsFixed(2)}');
        print(
            '  Average time per event: ${(stopwatch.elapsedMilliseconds / batchSize).toStringAsFixed(2)}ms');

        // Verify no events were lost
        final missingEvents = batchMetrics.getMissingSequenceNumbers(batchSize);
        expect(missingEvents, isEmpty);
      } finally {
        await throughputService.internalDestroy();
        dispatcher.dispose();
      }
    });

    test('should measure end-to-end latency across multiple services',
        () async {
      final dispatcher = EventDispatcher();
      final serviceA = LatencyTestService('ServiceA');
      final serviceB = LatencyTestService('ServiceB');
      final serviceC = LatencyTestService('ServiceC');

      serviceA.setEventDispatcher(dispatcher);
      serviceB.setEventDispatcher(dispatcher);
      serviceC.setEventDispatcher(dispatcher);

      await Future.wait([
        serviceA.internalInitialize(),
        serviceB.internalInitialize(),
        serviceC.internalInitialize(),
      ]);

      try {
        // Send latency test events
        final numEvents = 20;
        final futures = <Future>[];

        for (int i = 0; i < numEvents; i++) {
          final event = LatencyTestEvent(
            eventId: 'latency_test_$i',
            sourceService: 'LatencyTester',
            timestamp: DateTime.now(),
            sendTime: DateTime.now().microsecondsSinceEpoch,
            hops: [],
          );

          futures.add(serviceA.sendEvent(event));
          await Future.delayed(Duration(milliseconds: 10)); // Stagger events
        }

        await Future.wait(futures);
        await Future.delayed(
            Duration(milliseconds: 500)); // Allow all processing to complete

        // Analyze latency measurements
        final statsA = serviceA.getLatencyStats();
        final statsB = serviceB.getLatencyStats();
        final statsC = serviceC.getLatencyStats();

        expect(statsA.totalMeasurements, greaterThan(0));
        expect(statsB.totalMeasurements, greaterThan(0));
        expect(statsC.totalMeasurements, greaterThan(0));

        print('Latency Test Results:');
        print('  Service A: $statsA');
        print('  Service B: $statsB');
        print('  Service C: $statsC');

        // Latency should be reasonable (under 100ms for local events)
        expect(statsA.averageLatencyMs, lessThan(100));
        expect(statsA.p95LatencyMs, lessThan(200));
        expect(statsA.p99LatencyMs, lessThan(500));

        // Check that events went through multiple hops
        final measurementsA = serviceA.getMeasurements();
        final measurementsB = serviceB.getMeasurements();
        final measurementsC = serviceC.getMeasurements();

        expect(
            measurementsA.any((m) => m.hops.isEmpty), isTrue); // Initial events
        expect(measurementsB.any((m) => m.hops.isNotEmpty),
            isTrue); // Events from A
        expect(measurementsC.any((m) => m.hops.length >= 2),
            isTrue); // Events from A->B
      } finally {
        await Future.wait([
          serviceA.internalDestroy(),
          serviceB.internalDestroy(),
          serviceC.internalDestroy(),
        ]);
        dispatcher.dispose();
      }
    });

    test('should handle high concurrency event processing', () async {
      final dispatcher = EventDispatcher();
      final perfService = PerformanceTestService();
      final throughputService = ThroughputTestService();

      perfService.setEventDispatcher(dispatcher);
      throughputService.setEventDispatcher(dispatcher);

      await Future.wait([
        perfService.internalInitialize(),
        throughputService.internalInitialize(),
      ]);

      try {
        final numConcurrentBatches = 5;
        final eventsPerBatch = 50;
        final stopwatch = Stopwatch()..start();

        // Create multiple concurrent batches
        final allFutures = <Future>[];

        for (int batch = 0; batch < numConcurrentBatches; batch++) {
          final batchFutures = <Future>[];

          for (int i = 0; i < eventsPerBatch; i++) {
            // Mix performance and throughput events
            if (i % 2 == 0) {
              final perfEvent = PerformanceTestEvent(
                eventId: 'concurrent_perf_${batch}_$i',
                sourceService: 'ConcurrencyTester',
                timestamp: DateTime.now(),
                testType: 'cpu_intensive',
                expectedProcessingTime: 20,
                payload: {'batch': batch, 'index': i},
              );
              batchFutures.add(perfService.sendEvent(perfEvent));
            } else {
              final throughputEvent = ThroughputTestEvent(
                eventId: 'concurrent_throughput_${batch}_$i',
                sourceService: 'ConcurrencyTester',
                timestamp: DateTime.now(),
                batchId: 'concurrent_batch_$batch',
                sequenceNumber: i,
                totalInBatch: eventsPerBatch ~/ 2,
                data: [
                  {'batch': batch, 'index': i}
                ],
              );
              batchFutures.add(throughputService.sendEvent(throughputEvent));
            }
          }

          allFutures.addAll(batchFutures);
        }

        // Wait for all events to complete
        await Future.wait(allFutures);
        stopwatch.stop();

        final totalEvents = numConcurrentBatches * eventsPerBatch;
        final eventsPerSecond =
            totalEvents / (stopwatch.elapsedMilliseconds / 1000.0);

        print('Concurrency Test Results:');
        print('  Total events: $totalEvents');
        print('  Total time: ${stopwatch.elapsedMilliseconds}ms');
        print('  Events per second: ${eventsPerSecond.toStringAsFixed(2)}');
        print(
            '  Average time per event: ${(stopwatch.elapsedMilliseconds / totalEvents).toStringAsFixed(2)}ms');

        // Verify all events were processed
        final perfStats = perfService.getStats();
        expect(perfStats.totalEvents,
            equals(numConcurrentBatches * eventsPerBatch ~/ 2));

        final allBatchMetrics = throughputService.getAllBatchMetrics();
        expect(allBatchMetrics.length, equals(numConcurrentBatches));

        // Performance should remain reasonable under load
        expect(eventsPerSecond, greaterThan(100)); // At least 100 events/sec
        expect(
            perfStats.averageActualTime, lessThan(100)); // Under 100ms average
      } finally {
        await Future.wait([
          perfService.internalDestroy(),
          throughputService.internalDestroy(),
        ]);
        dispatcher.dispose();
      }
    });

    test('should measure memory usage during event processing', () async {
      final dispatcher = EventDispatcher();
      final perfService = PerformanceTestService();

      perfService.setEventDispatcher(dispatcher);
      await perfService.internalInitialize();

      try {
        // Create events with different memory requirements
        final memorySizes = [100, 1000, 10000, 50000];

        for (int i = 0; i < memorySizes.length; i++) {
          final event = PerformanceTestEvent(
            eventId: 'memory_test_$i',
            sourceService: 'MemoryTester',
            timestamp: DateTime.now(),
            testType: 'memory_allocation',
            expectedProcessingTime: 50,
            payload: {'size': memorySizes[i]},
          );

          final stopwatch = Stopwatch()..start();
          await perfService.sendEvent(event);
          stopwatch.stop();

          print(
              'Memory test ${i + 1}: size=${memorySizes[i]}, time=${stopwatch.elapsedMilliseconds}ms');
        }

        final stats = perfService.getStats();
        expect(stats.totalEvents, equals(memorySizes.length));

        // Verify that larger memory allocations don't cause exponential slowdown
        final metrics = perfService.getMetrics();
        final smallMemoryTime = metrics[0].actualTime;
        final largeMemoryTime = metrics.last.actualTime;

        // Large memory allocation shouldn't be more than 10x slower than small
        expect(largeMemoryTime, lessThan(smallMemoryTime * 10));

        print(
            'Memory performance: small=${smallMemoryTime}ms, large=${largeMemoryTime}ms');
      } finally {
        await perfService.internalDestroy();
        dispatcher.dispose();
      }
    });

    test('should benchmark event serialization performance', () async {
      final largePayload = Map.fromEntries(
          List.generate(1000, (i) => MapEntry('key_$i', 'value_$i')));

      final event = PerformanceTestEvent(
        eventId: 'serialization_test',
        sourceService: 'SerializationTester',
        timestamp: DateTime.now(),
        testType: 'large_payload',
        expectedProcessingTime: 100,
        payload: largePayload,
      );

      // Measure serialization performance
      final serializationStopwatch = Stopwatch()..start();
      for (int i = 0; i < 100; i++) {
        final json = event.toJson();
        expect(json, isNotNull);
      }
      serializationStopwatch.stop();

      // Measure deserialization performance
      final json = event.toJson();
      final deserializationStopwatch = Stopwatch()..start();
      for (int i = 0; i < 100; i++) {
        final deserializedEvent = PerformanceTestEvent.fromJson(json);
        expect(deserializedEvent.eventId, equals(event.eventId));
      }
      deserializationStopwatch.stop();

      print('Serialization Benchmark (100 iterations):');
      print('  Serialization: ${serializationStopwatch.elapsedMilliseconds}ms');
      print(
          '  Deserialization: ${deserializationStopwatch.elapsedMilliseconds}ms');
      print('  Payload size: ${largePayload.length} keys');

      // Performance should be reasonable
      expect(serializationStopwatch.elapsedMilliseconds,
          lessThan(1000)); // Under 1 second
      expect(deserializationStopwatch.elapsedMilliseconds,
          lessThan(1000)); // Under 1 second
    });
  });
}

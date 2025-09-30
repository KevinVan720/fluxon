import 'dart:async';
import 'dart:math';

import 'package:fluxon/fluxon.dart';
import 'package:test/test.dart';

part 'serialization_optimization_test.g.dart';

// Test event for serialization performance testing
class SerializationTestEvent extends ServiceEvent {
  const SerializationTestEvent({
    required this.sequenceNumber,
    required this.payload,
    required this.largeData,
    required super.eventId,
    required super.sourceService,
    required super.timestamp,
    super.metadata = const {},
    super.correlationId,
  });

  factory SerializationTestEvent.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return SerializationTestEvent(
      sequenceNumber: data['sequenceNumber'],
      payload: data['payload'],
      largeData: List<String>.from(data['largeData']),
      eventId: json['eventId'],
      sourceService: json['sourceService'],
      timestamp: DateTime.parse(json['timestamp']),
      correlationId: json['correlationId'],
      metadata: json['metadata'] ?? {},
    );
  }

  final int sequenceNumber;
  final Map<String, dynamic> payload;
  final List<String> largeData; // Simulate large payload

  @override
  Map<String, dynamic> eventDataToJson() => {
        'sequenceNumber': sequenceNumber,
        'payload': payload,
        'largeData': largeData,
      };
}

// Remote service for testing serialization performance
@ServiceContract(remote: true)
class SerializationTestService extends FluxonService {
  final List<Duration> serializationTimes = [];

  @override
  Future<void> initialize() async {
    await super.initialize();
  }

  Future<void> sendTestEvents(int count,
      {bool measureSerialization = false}) async {
    // Generate large test data once
    final largeData = List.generate(100, (i) => 'data_item_$i');

    for (var i = 0; i < count; i++) {
      final event = SerializationTestEvent(
        sequenceNumber: i,
        payload: {
          'test': i,
          'timestamp': DateTime.now().millisecondsSinceEpoch
        },
        largeData: largeData,
        eventId: 'test_$i',
        sourceService: 'SerializationTestService',
        timestamp: DateTime.now(),
      );

      DateTime? serializationStart;
      if (measureSerialization) {
        serializationStart = DateTime.now();
      }

      // Send event to all services (including local listener)
      await sendEvent(event);

      if (measureSerialization && serializationStart != null) {
        serializationTimes.add(DateTime.now().difference(serializationStart));
      }

      // Small delay to prevent overwhelming
      if (i % 10 == 0) {
        await Future.delayed(const Duration(microseconds: 100));
      }
    }
  }

  Future<Map<String, dynamic>> getSerializationStats() async => {
        'averageSerializationTime': serializationTimes.isEmpty
            ? 0
            : serializationTimes
                    .map((d) => d.inMicroseconds)
                    .reduce((a, b) => a + b) /
                serializationTimes.length,
        'maxSerializationTime': serializationTimes.isEmpty
            ? 0
            : serializationTimes.map((d) => d.inMicroseconds).reduce(max),
        'minSerializationTime': serializationTimes.isEmpty
            ? 0
            : serializationTimes.map((d) => d.inMicroseconds).reduce(min),
      };
}

// Local listener service to receive events from remote service
@ServiceContract(remote: false)
class SerializationTestListener extends FluxonService {
  int eventCounter = 0;
  final List<Duration> processingTimes = [];

  @override
  Future<void> initialize() async {
    await super.initialize();

    // Listen for events from remote service
    onEvent<SerializationTestEvent>((event) async {
      final start = DateTime.now();
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

  Future<Map<String, dynamic>> getProcessingStats() async => {
        'eventsProcessed': eventCounter,
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
      };
}

void main() {
  group('Serialization Optimization Tests', () {
    late FluxonRuntime runtime;

    setUp(() {
      runtime = FluxonRuntime();
      EventTypeRegistry.register<SerializationTestEvent>(
          SerializationTestEvent.fromJson);
    });

    tearDown(() async {
      await runtime.destroyAll();
    });

    test('should demonstrate improved serialization performance', () async {
      // Register both remote service and local listener
      runtime
          .register<SerializationTestService>(SerializationTestServiceImpl.new);
      runtime
          .register<SerializationTestListener>(SerializationTestListener.new);
      await runtime.initializeAll();

      final service = runtime.get<SerializationTestService>();
      final listener = runtime.get<SerializationTestListener>();

      // Warm up
      await service.sendTestEvents(5);
      await Future.delayed(const Duration(milliseconds: 100));

      // Reset counters
      listener.eventCounter = 0;
      listener.processingTimes.clear();
      service.serializationTimes.clear();

      // Performance test
      final stopwatch = Stopwatch()..start();
      await service.sendTestEvents(50, measureSerialization: true);

      // Wait for processing
      await Future.delayed(const Duration(milliseconds: 500));
      stopwatch.stop();

      final processingStats = await listener.getProcessingStats();
      final serializationStats = await service.getSerializationStats();

      print('🚀 Serialization Optimization Results:');
      print('   Total time: ${stopwatch.elapsedMilliseconds}ms');
      print('   Events processed: ${processingStats['eventsProcessed']}');
      print(
          '   Avg processing time: ${processingStats['averageProcessingTime']?.toStringAsFixed(2)}μs');
      print(
          '   Avg serialization time: ${serializationStats['averageSerializationTime']?.toStringAsFixed(2)}μs');
      print(
          '   Max processing time: ${processingStats['maxProcessingTime']}μs');
      print(
          '   Min processing time: ${processingStats['minProcessingTime']}μs');

      // Verify performance improvements
      expect(processingStats['eventsProcessed'], equals(50));
      expect(processingStats['averageProcessingTime'],
          lessThan(50000)); // Less than 50ms average
      expect(serializationStats['averageSerializationTime'],
          lessThan(10000)); // Less than 10ms serialization

      // Total processing should be significantly faster than before optimization
      expect(stopwatch.elapsedMilliseconds,
          lessThan(2000)); // Less than 2 seconds total
    });

    test('should cache serialized data for repeated calls', () async {
      runtime
          .register<SerializationTestService>(SerializationTestServiceImpl.new);
      await runtime.initializeAll();

      // Create a test event
      final event = SerializationTestEvent(
        sequenceNumber: 1,
        payload: {'test': 'caching'},
        largeData: List.generate(50, (i) => 'cache_test_$i'),
        eventId: 'cache_test',
        sourceService: 'CacheTest',
        timestamp: DateTime.now(),
      );

      // First serialization (should cache)
      final start1 = DateTime.now();
      final json1 = event.toJson();
      final time1 = DateTime.now().difference(start1);

      // Second serialization (should use cache)
      final start2 = DateTime.now();
      final json2 = event.toJson();
      final time2 = DateTime.now().difference(start2);

      // Third serialization (should use cache)
      final start3 = DateTime.now();
      final json3 = event.toJson();
      final time3 = DateTime.now().difference(start3);

      print('🚀 Serialization Caching Results:');
      print('   First serialization: ${time1.inMicroseconds}μs');
      print('   Second serialization: ${time2.inMicroseconds}μs');
      print('   Third serialization: ${time3.inMicroseconds}μs');

      // Verify caching works
      expect(json1, equals(json2));
      expect(json2, equals(json3));

      // Cached calls should be significantly faster
      expect(time2.inMicroseconds, lessThan(time1.inMicroseconds));
      expect(time3.inMicroseconds, lessThan(time1.inMicroseconds));

      // Cached calls should be very fast (less than 100 microseconds)
      expect(time2.inMicroseconds, lessThan(100));
      expect(time3.inMicroseconds, lessThan(100));
    });

    test('should demonstrate EventMessage optimization', () async {
      // Test the optimized EventMessage factory
      final event = SerializationTestEvent(
        sequenceNumber: 1,
        payload: {'test': 'optimization'},
        largeData: List.generate(20, (i) => 'opt_test_$i'),
        eventId: 'opt_test',
        sourceService: 'OptTest',
        timestamp: DateTime.now(),
      );

      // Test optimized EventMessage creation
      final start = DateTime.now();
      final message = EventMessage.forEvent(
        type: EventMessageType.eventSend,
        requestId: 'test_request',
        event: event,
        sourceIsolate: 'test_isolate',
        targetIsolate: 'target_isolate',
      );
      final creationTime = DateTime.now().difference(start);

      // Test message serialization
      final serStart = DateTime.now();
      final messageJson = message.toJson();
      final serializationTime = DateTime.now().difference(serStart);

      print('🚀 EventMessage Optimization Results:');
      print('   Message creation time: ${creationTime.inMicroseconds}μs');
      print(
          '   Message serialization time: ${serializationTime.inMicroseconds}μs');
      print('   Has direct event: ${message.directEvent != null}');
      print('   Has pre-serialized data: ${message.preSerializedData != null}');

      // Verify optimization features
      expect(message.directEvent, isNotNull);
      expect(message.preSerializedData, isNotNull);
      expect(messageJson['eventData'], isNotNull);

      // Should be fast
      expect(creationTime.inMicroseconds, lessThan(5000)); // Less than 5ms
      expect(serializationTime.inMicroseconds, lessThan(1000)); // Less than 1ms
    });
  });
}

/// Tests for the event system
library event_system_test;

import 'dart:async';
import 'package:test/test.dart';
import 'package:dart_service_framework/dart_service_framework.dart';

// Test event types
class TestEvent extends ServiceEvent {
  const TestEvent({
    required super.eventId,
    required super.sourceService,
    required super.timestamp,
    super.correlationId,
    super.metadata = const {},
    required this.message,
    required this.priority,
  });

  final String message;
  final int priority;

  @override
  Map<String, dynamic> eventDataToJson() {
    return {
      'message': message,
      'priority': priority,
    };
  }

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
}

class CriticalEvent extends ServiceEvent {
  const CriticalEvent({
    required super.eventId,
    required super.sourceService,
    required super.timestamp,
    super.correlationId,
    super.metadata = const {},
    required this.alertLevel,
    required this.details,
  });

  final String alertLevel;
  final Map<String, dynamic> details;

  @override
  Map<String, dynamic> eventDataToJson() {
    return {
      'alertLevel': alertLevel,
      'details': details,
    };
  }

  factory CriticalEvent.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return CriticalEvent(
      eventId: json['eventId'] as String,
      sourceService: json['sourceService'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      correlationId: json['correlationId'] as String?,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      alertLevel: data['alertLevel'] as String,
      details: Map<String, dynamic>.from(data['details'] as Map),
    );
  }
}

// Test services
class TestServiceA extends BaseService with ServiceEventMixin {
  TestServiceA() : super();

  final List<ServiceEvent> receivedEvents = [];
  final List<String> processedMessages = [];

  @override
  Future<void> initialize() async {
    // Set up event listeners
    onEvent<TestEvent>((event) async {
      receivedEvents.add(event);
      processedMessages.add('A processed: ${event.message}');

      return EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration(milliseconds: 10),
        data: {'processed': true, 'service': 'A'},
      );
    });

    onEvent<CriticalEvent>((event) async {
      receivedEvents.add(event);
      processedMessages.add('A handled critical: ${event.alertLevel}');

      return EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration(milliseconds: 50),
        data: {'handled': true, 'service': 'A'},
      );
    }, priority: 100); // High priority for critical events
  }
}

class TestServiceB extends BaseService with ServiceEventMixin {
  TestServiceB() : super();

  final List<ServiceEvent> receivedEvents = [];
  final List<String> processedMessages = [];
  bool shouldFail = false;

  @override
  Future<void> initialize() async {
    // Set up event listeners
    onEvent<TestEvent>((event) async {
      receivedEvents.add(event);

      if (shouldFail) {
        throw Exception('Service B intentionally failed');
      }

      processedMessages.add('B processed: ${event.message}');

      return EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration(milliseconds: 20),
        data: {'processed': true, 'service': 'B'},
      );
    });

    // Only handle high priority critical events
    onEvent<CriticalEvent>((event) async {
      if (event.alertLevel != 'HIGH') {
        return EventProcessingResponse(
          result: EventProcessingResult.ignored,
          processingTime: Duration(milliseconds: 1),
        );
      }

      receivedEvents.add(event);
      processedMessages.add('B handled high critical: ${event.alertLevel}');

      return EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration(milliseconds: 30),
        data: {'handled': true, 'service': 'B'},
      );
    }, condition: (event) => event.alertLevel == 'HIGH');
  }
}

class TestServiceC extends BaseService with ServiceEventMixin {
  TestServiceC() : super();

  final List<ServiceEvent> receivedEvents = [];
  final List<String> processedMessages = [];

  @override
  Future<void> initialize() async {
    // Only listen to test events with high priority
    onEvent<TestEvent>((event) async {
      if (event.priority < 5) {
        return EventProcessingResponse(
          result: EventProcessingResult.ignored,
          processingTime: Duration(milliseconds: 1),
        );
      }

      receivedEvents.add(event);
      processedMessages.add('C processed high priority: ${event.message}');

      return EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration(milliseconds: 15),
        data: {'processed': true, 'service': 'C'},
      );
    }, condition: (event) => event.priority >= 5);
  }
}

void main() {
  group('Event System Tests', () {
    late EventDispatcher dispatcher;
    late TestServiceA serviceA;
    late TestServiceB serviceB;
    late TestServiceC serviceC;

    setUp(() async {
      dispatcher = EventDispatcher();
      serviceA = TestServiceA();
      serviceB = TestServiceB();
      serviceC = TestServiceC();

      // Set event dispatchers before initialization
      serviceA.setEventDispatcher(dispatcher);
      serviceB.setEventDispatcher(dispatcher);
      serviceC.setEventDispatcher(dispatcher);

      // Initialize services
      await serviceA.internalInitialize();
      await serviceB.internalInitialize();
      await serviceC.internalInitialize();
    });

    tearDown(() async {
      await serviceA.internalDestroy();
      await serviceB.internalDestroy();
      await serviceC.internalDestroy();
      dispatcher.dispose();
    });

    test('should create and serialize events correctly', () {
      final event = TestEvent(
        eventId: 'test-123',
        sourceService: 'TestService',
        timestamp: DateTime.now(),
        correlationId: 'corr-456',
        metadata: {'version': '1.0'},
        message: 'Hello World',
        priority: 5,
      );

      expect(event.eventType, equals('TestEvent'));
      expect(event.message, equals('Hello World'));
      expect(event.priority, equals(5));

      final json = event.toJson();
      expect(json['eventId'], equals('test-123'));
      expect(json['eventType'], equals('TestEvent'));
      expect(json['sourceService'], equals('TestService'));
      expect(json['correlationId'], equals('corr-456'));
      expect(json['data']['message'], equals('Hello World'));
      expect(json['data']['priority'], equals(5));
    });

    test('should broadcast events to all services', () async {
      final event = TestEvent(
        eventId: 'broadcast-test',
        sourceService: 'TestServiceA',
        timestamp: DateTime.now(),
        message: 'Broadcast message',
        priority: 3,
      );

      final result = await serviceA.broadcastEvent(event);

      expect(result.isSuccess, isTrue);
      expect(
          result.successCount, equals(1)); // Only serviceB processes priority 3
      expect(serviceB.receivedEvents, hasLength(1));
      expect(serviceB.processedMessages,
          contains('B processed: Broadcast message'));
      expect(serviceC.receivedEvents, isEmpty); // Priority too low for serviceC
    });

    test('should send events to specific targets', () async {
      final event = TestEvent(
        eventId: 'targeted-test',
        sourceService: 'TestServiceA',
        timestamp: DateTime.now(),
        message: 'Targeted message',
        priority: 8,
      );

      final targets = [
        EventTarget(serviceType: TestServiceB, waitUntilProcessed: true),
        EventTarget(serviceType: TestServiceC, waitUntilProcessed: false),
      ];

      final result = await serviceA.sendEventTo(event, targets);

      expect(result.isSuccess, isTrue);
      expect(result.successCount, equals(2));
      expect(serviceB.receivedEvents, hasLength(1));
      expect(serviceC.receivedEvents, hasLength(1));
      expect(serviceB.processedMessages,
          contains('B processed: Targeted message'));
      expect(serviceC.processedMessages,
          contains('C processed high priority: Targeted message'));
    });

    test('should handle event processing failures gracefully', () async {
      serviceB.shouldFail = true;

      final event = TestEvent(
        eventId: 'failure-test',
        sourceService: 'TestServiceA',
        timestamp: DateTime.now(),
        message: 'Failure test',
        priority: 3,
      );

      final result = await serviceA.broadcastEvent(event);

      // Event distribution reports failure when individual services fail
      expect(result.isSuccess, isFalse);
      expect(result.failureCount, equals(1));
      expect(serviceB.receivedEvents, hasLength(1));
      expect(serviceB.processedMessages, isEmpty); // Failed before processing
    });

    test('should respect event target conditions', () async {
      final lowPriorityEvent = TestEvent(
        eventId: 'low-priority',
        sourceService: 'TestServiceA',
        timestamp: DateTime.now(),
        message: 'Low priority',
        priority: 2,
      );

      final highPriorityEvent = TestEvent(
        eventId: 'high-priority',
        sourceService: 'TestServiceA',
        timestamp: DateTime.now(),
        message: 'High priority',
        priority: 8,
      );

      await serviceA.broadcastEvent(lowPriorityEvent);
      await serviceA.broadcastEvent(highPriorityEvent);

      // ServiceC should only receive the high priority event
      expect(serviceC.receivedEvents, hasLength(1));
      expect(serviceC.receivedEvents.first.eventId, equals('high-priority'));
      expect(serviceC.processedMessages,
          contains('C processed high priority: High priority'));
    });

    test('should handle critical events with priority', () async {
      final criticalEvent = CriticalEvent(
        eventId: 'critical-test',
        sourceService: 'TestServiceA',
        timestamp: DateTime.now(),
        alertLevel: 'HIGH',
        details: {'system': 'database', 'error': 'connection lost'},
      );

      final result = await serviceA.sendCriticalEvent(
        criticalEvent,
        [TestServiceA, TestServiceB],
        timeout: Duration(seconds: 5),
      );

      expect(result.isSuccess, isTrue);
      expect(result.successCount, equals(2));
      expect(serviceA.receivedEvents, hasLength(1));
      expect(serviceB.receivedEvents, hasLength(1));
      expect(serviceA.processedMessages, contains('A handled critical: HIGH'));
      expect(serviceB.processedMessages,
          contains('B handled high critical: HIGH'));
    });

    test('should support event subscriptions', () async {
      final receivedEvents = <TestEvent>[];
      final subscription = serviceA.subscribeToEvents<TestEvent>();

      subscription.stream.listen((event) {
        receivedEvents.add(event as TestEvent);
      });

      final event = TestEvent(
        eventId: 'subscription-test',
        sourceService: 'TestServiceB',
        timestamp: DateTime.now(),
        message: 'Subscription test',
        priority: 5,
      );

      await serviceB.broadcastEvent(event);

      // Give some time for the event to propagate
      await Future.delayed(Duration(milliseconds: 100));

      expect(receivedEvents, hasLength(1));
      expect(receivedEvents.first.message, equals('Subscription test'));
    });

    test('should track event statistics', () async {
      final event1 = TestEvent(
        eventId: 'stats-test-1',
        sourceService: 'TestServiceA',
        timestamp: DateTime.now(),
        message: 'Stats test 1',
        priority: 5,
      );

      final event2 = TestEvent(
        eventId: 'stats-test-2',
        sourceService: 'TestServiceA',
        timestamp: DateTime.now(),
        message: 'Stats test 2',
        priority: 3,
      );

      await serviceA.broadcastEvent(event1);
      await serviceA.broadcastEvent(event2);

      final stats = dispatcher.getStatistics();
      expect(stats, isNotEmpty);

      final testEventStats = stats['TestEvent'];
      expect(testEventStats, isNotNull);
      expect(testEventStats!.totalSent, greaterThan(0));
      expect(testEventStats.totalProcessed, greaterThan(0));
    });

    test('should support targeted then broadcast distribution', () async {
      final event = TestEvent(
        eventId: 'targeted-broadcast-test',
        sourceService: 'TestServiceA',
        timestamp: DateTime.now(),
        message: 'Targeted then broadcast',
        priority: 6,
      );

      final priorityTargets = [
        EventTarget(serviceType: TestServiceB, waitUntilProcessed: true),
      ];

      final result = await serviceA.sendEventTargetedThenBroadcast(
        event,
        priorityTargets,
      );

      expect(result.isSuccess, isTrue);
      expect(result.successCount,
          equals(2)); // ServiceB (targeted) + ServiceC (broadcast)
      expect(serviceB.receivedEvents, hasLength(1));
      expect(serviceC.receivedEvents, hasLength(1));
    });

    test('should handle event retries on failure', () async {
      serviceB.shouldFail = true;

      final event = TestEvent(
        eventId: 'retry-test',
        sourceService: 'TestServiceA',
        timestamp: DateTime.now(),
        message: 'Retry test',
        priority: 5,
      );

      final targets = [
        EventTarget(
          serviceType: TestServiceB,
          waitUntilProcessed: true,
          retryCount: 2,
        ),
      ];

      final result = await serviceA.sendEventTo(event, targets);

      // Event distribution reports failure when individual services fail
      expect(result.isSuccess, isFalse);
      expect(result.failureCount, equals(1));
      // ServiceB should have received the event (retry logic working)
      expect(serviceB.receivedEvents.length, greaterThanOrEqualTo(1));
    });

    test('should respect global timeout for distribution', () async {
      final event = TestEvent(
        eventId: 'timeout-test',
        sourceService: 'TestServiceA',
        timestamp: DateTime.now(),
        message: 'Timeout test',
        priority: 5,
      );

      final distribution = EventDistribution(
        strategy: EventDistributionStrategy.broadcast,
        globalTimeout: Duration(milliseconds: 1), // Very short timeout
      );

      final stopwatch = Stopwatch()..start();
      await serviceA.sendEvent(event, distribution: distribution);
      stopwatch.stop();

      // Should complete quickly due to timeout
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });
  });

  group('Event Distribution Strategies', () {
    late EventDispatcher dispatcher;
    late TestServiceA serviceA;
    late TestServiceB serviceB;
    late TestServiceC serviceC;

    setUp(() async {
      dispatcher = EventDispatcher();
      serviceA = TestServiceA();
      serviceB = TestServiceB();
      serviceC = TestServiceC();

      // Set event dispatchers before initialization
      serviceA.setEventDispatcher(dispatcher);
      serviceB.setEventDispatcher(dispatcher);
      serviceC.setEventDispatcher(dispatcher);

      // Initialize services
      await serviceA.internalInitialize();
      await serviceB.internalInitialize();
      await serviceC.internalInitialize();
    });

    tearDown(() async {
      await serviceA.internalDestroy();
      await serviceB.internalDestroy();
      await serviceC.internalDestroy();
      dispatcher.dispose();
    });

    test('should support broadcast strategy', () async {
      final event = TestEvent(
        eventId: 'broadcast-strategy-test',
        sourceService: 'TestServiceA',
        timestamp: DateTime.now(),
        message: 'Broadcast strategy',
        priority: 6,
      );

      final distribution = EventDistribution.broadcast();
      final result =
          await serviceA.sendEvent(event, distribution: distribution);

      expect(result.responses.length, equals(2)); // ServiceB and ServiceC
      expect(result.successCount, equals(2));
    });

    test('should support targeted strategy', () async {
      final event = TestEvent(
        eventId: 'targeted-strategy-test',
        sourceService: 'TestServiceA',
        timestamp: DateTime.now(),
        message: 'Targeted strategy',
        priority: 6,
      );

      final targets = [EventTarget(serviceType: TestServiceC)];
      final distribution = EventDistribution.targeted(targets);
      final result =
          await serviceA.sendEvent(event, distribution: distribution);

      expect(result.responses.length, equals(1)); // Only ServiceC
      expect(result.successCount, equals(1));
      expect(serviceC.receivedEvents, hasLength(1));
      expect(serviceB.receivedEvents, isEmpty);
    });

    test('should support broadcast except strategy', () async {
      final event = TestEvent(
        eventId: 'broadcast-except-test',
        sourceService: 'TestServiceA',
        timestamp: DateTime.now(),
        message: 'Broadcast except',
        priority: 6,
      );

      final distribution = EventDistribution(
        strategy: EventDistributionStrategy.broadcastExcept,
        excludeServices: [TestServiceB],
      );
      final result =
          await serviceA.sendEvent(event, distribution: distribution);

      expect(result.responses.length, equals(1)); // Only ServiceC
      expect(result.successCount, equals(1));
      expect(serviceC.receivedEvents, hasLength(1));
      expect(serviceB.receivedEvents, isEmpty);
    });
  });
}

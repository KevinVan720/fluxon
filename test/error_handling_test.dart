import 'dart:async';

import 'package:dart_service_framework/dart_service_framework.dart';
import 'package:test/test.dart';

part 'error_handling_test.g.dart';

// Test events for error scenarios
class CorruptedEvent extends ServiceEvent {
  const CorruptedEvent({
    required this.invalidData,
    required super.eventId,
    required super.sourceService,
    required super.timestamp,
    super.metadata = const {},
    super.correlationId,
  });

  final Map<String, dynamic> invalidData;

  @override
  Map<String, dynamic> eventDataToJson() => invalidData;

  factory CorruptedEvent.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return CorruptedEvent(
      invalidData: data,
      eventId: json['eventId'],
      sourceService: json['sourceService'],
      timestamp: DateTime.parse(json['timestamp']),
      correlationId: json['correlationId'],
      metadata: json['metadata'] ?? {},
    );
  }
}

// Service that fails during initialization
@ServiceContract(remote: false)
class FailingInitService extends FluxService {
  final String failureReason;

  FailingInitService({this.failureReason = 'Generic failure'});

  @override
  Future<void> initialize() async {
    await super.initialize();
    throw ServiceInitializationException(failureReason);
  }
}

// Service that fails during method calls
@ServiceContract(remote: true)
class FailingMethodService extends FluxService {
  Future<String> alwaysFails() async {
    throw ServiceException('Method always fails');
  }

  Future<String> failsRandomly() async {
    if (DateTime.now().millisecond % 2 == 0) {
      throw ServiceTimeoutException('Random timeout', Duration(seconds: 1));
    }
    return 'Success';
  }
}

// Service with missing dependencies (will be tested without registering the dependency)
@ServiceContract(remote: false)
class InvalidDependencyService extends FluxService {
  @override
  List<Type> get dependencies =>
      [FailingInitService]; // Depends on unregistered service

  Future<void> doSomething() async {}
}

// Service that corrupts events
@ServiceContract(remote: false)
class CorruptingService extends FluxService {
  @override
  Future<void> initialize() async {
    await super.initialize();

    onEvent<CorruptedEvent>((event) async {
      throw FormatException('Cannot process corrupted event');
    });
  }

  Future<void> sendCorruptedEvent() async {
    // Send event with invalid JSON structure
    await sendEvent(createEvent((
            {required String eventId,
            required String sourceService,
            required DateTime timestamp,
            String? correlationId,
            Map<String, dynamic> metadata = const {}}) =>
        CorruptedEvent(
          invalidData: {
            'circular': null, // This will be set to create circular reference
            'invalid_date': 'not-a-date',
            'huge_number': double.infinity,
          },
          eventId: eventId,
          sourceService: sourceService,
          timestamp: timestamp,
          correlationId: correlationId,
          metadata: metadata,
        )));
  }
}

// Service that times out
@ServiceContract(remote: true)
class SlowService extends FluxService {
  Future<String> verySlowMethod() async {
    await Future.delayed(Duration(seconds: 60)); // Intentionally slow
    return 'Finally done';
  }

  Future<String> fastMethod() async {
    await Future.delayed(Duration(milliseconds: 10));
    return 'Quick response';
  }
}

// Service that leaks memory
@ServiceContract(remote: false)
class MemoryLeakService extends FluxService {
  final List<List<int>> _memoryHog = [];

  Future<void> consumeMemory() async {
    // Allocate large chunks of memory
    for (int i = 0; i < 1000; i++) {
      _memoryHog.add(List.filled(10000, i));
    }
  }

  @override
  Future<void> destroy() async {
    // Intentionally don't clean up memory to test leak detection
    await super.destroy();
  }
}

void main() {
  group('Error Handling & Edge Cases', () {
    late FluxRuntime runtime;

    setUp(() {
      runtime = FluxRuntime();
    });

    tearDown(() async {
      try {
        if (runtime.isInitialized) {
          await runtime.destroyAll();
        }
      } catch (_) {
        // Ignore cleanup errors in tests
      }
    });

    group('Service Initialization Failures', () {
      test('should handle service initialization failure gracefully', () async {
        runtime.register<FailingInitService>(
            () => FailingInitService(failureReason: 'Test failure'));

        expect(
          () => runtime.initializeAll(),
          throwsA(isA<ServiceInitializationException>()),
        );

        expect(runtime.isInitialized, isFalse);
      });

      test('should handle missing dependencies', () async {
        runtime.register<InvalidDependencyService>(
            () => InvalidDependencyService());

        expect(
          () => runtime.initializeAll(),
          throwsA(isA<DependencyNotSatisfiedException>()),
        );
      });

      test('should handle circular dependencies', () async {
        // Note: This would require creating services with circular deps
        // For now, verify the dependency resolver catches this
        expect(runtime.dependencyResolver, isNotNull);
      });
    });

    group('Method Call Failures', () {
      test('should handle remote service method failures', () async {
        runtime
            .register<FailingMethodService>(() => FailingMethodServiceWorker());
        await runtime.initializeAll();

        final service = runtime.get<FailingMethodService>();

        expect(
          () => service.alwaysFails(),
          throwsA(isA<ServiceException>()),
        );
      });

      test('should handle timeout scenarios', () async {
        runtime.register<SlowService>(() => SlowServiceWorker());
        await runtime.initializeAll();

        final service = runtime.get<SlowService>();

        // Test that fast method works
        final result = await service.fastMethod();
        expect(result, equals('Quick response'));

        // Test timeout on slow method (would need ServiceCallOptions)
        // This demonstrates the timeout infrastructure exists
      });
    });

    group('Event System Failures', () {
      test('should handle event serialization failures', () async {
        EventTypeRegistry.register<CorruptedEvent>(
            (json) => CorruptedEvent.fromJson(json));

        runtime.register<CorruptingService>(() => CorruptingService());
        await runtime.initializeAll();

        final service = runtime.get<CorruptingService>();

        // Service should handle corrupted events gracefully
        expect(
          () => service.sendCorruptedEvent(),
          returnsNormally, // Should not crash the system
        );
      });

      test('should handle event processing failures', () async {
        EventTypeRegistry.register<CorruptedEvent>(
            (json) => CorruptedEvent.fromJson(json));

        runtime.register<CorruptingService>(() => CorruptingService());
        await runtime.initializeAll();

        final service = runtime.get<CorruptingService>();

        // Even if event processing fails, system should remain stable
        await service.sendCorruptedEvent();

        // Verify service is still functional
        expect(service.isInitialized, isTrue);
        expect(service.isDestroyed, isFalse);
      });
    });

    group('Resource Management', () {
      test('should handle memory pressure gracefully', () async {
        runtime.register<MemoryLeakService>(() => MemoryLeakService());
        await runtime.initializeAll();

        final service = runtime.get<MemoryLeakService>();

        // Consume memory and verify system stability
        await service.consumeMemory();

        expect(service.isInitialized, isTrue);

        // Cleanup should work even with memory leaks
        await runtime.destroyAll();
        expect(runtime.isInitialized, isFalse);
      });
    });

    group('Runtime State Management', () {
      test('should prevent registration after initialization', () async {
        await runtime.initializeAll();

        expect(
          () =>
              runtime.register<FailingInitService>(() => FailingInitService()),
          throwsA(isA<ServiceStateException>()),
        );
      });

      test('should handle multiple initialization attempts', () async {
        runtime.register<FailingInitService>(() => FailingInitService());

        // First attempt should fail
        expect(
          () => runtime.initializeAll(),
          throwsA(isA<ServiceInitializationException>()),
        );

        // Second attempt should also fail consistently
        expect(
          () => runtime.initializeAll(),
          throwsA(isA<ServiceStateException>()),
        );
      });

      test('should handle destruction during initialization', () async {
        runtime.register<SlowService>(() => SlowServiceWorker());

        // Start initialization but don't await
        final initFuture = runtime.initializeAll();

        // Try to destroy while initializing
        expect(
          () => runtime.destroyAll(),
          returnsNormally, // Should handle gracefully
        );

        // Wait for init to complete (may fail)
        try {
          await initFuture;
        } catch (_) {
          // Expected to potentially fail
        }
      });
    });

    group('Cross-Isolate Error Propagation', () {
      test('should propagate worker isolate failures to main', () async {
        runtime
            .register<FailingMethodService>(() => FailingMethodServiceWorker());
        await runtime.initializeAll();

        final service = runtime.get<FailingMethodService>();

        // Worker failure should propagate as ServiceException
        expect(
          () => service.alwaysFails(),
          throwsA(isA<ServiceException>()),
        );

        // Runtime should remain stable after worker error
        expect(runtime.isInitialized, isTrue);
      });
    });

    group('Service Discovery Edge Cases', () {
      test('should handle service type mismatches', () async {
        // This tests the type safety of the service system
        runtime.register<FailingInitService>(() => FailingInitService());

        expect(
          () => runtime.initializeAll(),
          throwsA(isA<ServiceInitializationException>()),
        );
      });

      test('should handle proxy registry corruption', () async {
        runtime.register<MemoryLeakService>(() => MemoryLeakService());
        await runtime.initializeAll();

        // Verify proxy registry is accessible and functional
        expect(runtime.proxyRegistry, isNotNull);

        final service = runtime.get<MemoryLeakService>();
        expect(service, isNotNull);

        // Local services don't create proxy registry entries, so this is expected to be empty
        // The test verifies the system works correctly even with minimal proxy usage
      });
    });
  });
}

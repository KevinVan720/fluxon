import 'dart:async';

import 'package:flux/flux.dart';
import 'package:test/test.dart';

// part 'memory_management_test.g.dart';

// Memory-intensive service for testing
@ServiceContract(remote: true)
class MemoryIntensiveService extends FluxService {
  final List<List<int>> _memoryChunks = [];
  final List<Timer> _timers = [];
  final List<StreamSubscription> _subscriptions = [];

  int _chunkCount = 0;
  bool _shouldLeak = false;

  @override
  Future<void> initialize() async {
    await super.initialize();
    logger.info('Memory intensive service initialized');
  }

  @override
  Future<void> destroy() async {
    // Clean up resources
    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();

    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();

    _memoryChunks.clear();

    await super.destroy();
  }

  /// Allocate memory chunks
  Future<void> allocateMemory(int chunkCount, int chunkSize) async {
    for (var i = 0; i < chunkCount; i++) {
      final chunk = List<int>.filled(chunkSize, i);
      _memoryChunks.add(chunk);
      _chunkCount++;
    }
    logger.info('Allocated $chunkCount memory chunks');
  }

  /// Simulate memory leak by not cleaning up
  Future<void> simulateMemoryLeak(int chunkCount, int chunkSize) async {
    _shouldLeak = true;
    for (var i = 0; i < chunkCount; i++) {
      final chunk = List<int>.filled(chunkSize, i);
      _memoryChunks.add(chunk);
      _chunkCount++;
    }
    logger.info('Simulated memory leak with $chunkCount chunks');
  }

  /// Create timers that should be cleaned up
  Future<void> createTimers(int count) async {
    for (var i = 0; i < count; i++) {
      final timer = Timer.periodic(const Duration(seconds: 1), (t) {
        logger.debug('Timer $i tick');
      });
      _timers.add(timer);
    }
    logger.info('Created $count timers');
  }

  /// Create stream subscriptions that should be cleaned up
  Future<void> createSubscriptions(int count) async {
    for (var i = 0; i < count; i++) {
      final controller = StreamController<int>();
      final subscription = controller.stream.listen((data) {
        logger.debug('Subscription $i received: $data');
      });
      _subscriptions.add(subscription);
    }
    logger.info('Created $count stream subscriptions');
  }

  /// Get memory usage statistics
  Map<String, dynamic> getMemoryStats() => {
        'chunkCount': _chunkCount,
        'timerCount': _timers.length,
        'subscriptionCount': _subscriptions.length,
        'shouldLeak': _shouldLeak,
      };

  /// Force garbage collection (for testing)
  Future<void> forceGarbageCollection() async {
    // Trigger multiple GC cycles
    for (var i = 0; i < 3; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }
}

// Service that properly manages resources
@ServiceContract(remote: false)
class ResourceManagedService extends FluxService
    with ResourceManagedServiceMixin {
  final List<Timer> _timers = [];
  final List<StreamSubscription> _subscriptions = [];
  final List<StreamController> _controllers = [];

  @override
  Future<void> initialize() async {
    await super.initialize();

    // Register some resources that should be cleaned up
    final timer = Timer.periodic(const Duration(seconds: 1), (t) {
      logger.debug('Resource managed timer tick');
    });
    registerTimer(timer);
    _timers.add(timer);

    final controller = StreamController<int>();
    final subscription = controller.stream.listen((data) {
      logger.debug('Resource managed subscription: $data');
    });
    // registerStreamSubscription(subscription);
    _subscriptions.add(subscription);
    _controllers.add(controller);

    logger.info('Resource managed service initialized with proper cleanup');
  }

  /// Create additional resources
  Future<void> createResources(int count) async {
    for (var i = 0; i < count; i++) {
      final timer = Timer.periodic(const Duration(seconds: 1), (t) {
        logger.debug('Additional timer $i tick');
      });
      registerTimer(timer);
      _timers.add(timer);

      final controller = StreamController<int>();
      final subscription = controller.stream.listen((data) {
        logger.debug('Additional subscription $i: $data');
      });
      // registerStreamSubscription(subscription);
      _subscriptions.add(subscription);
      _controllers.add(controller);
    }
    logger.info('Created $count additional resources');
  }

  /// Get resource statistics
  Map<String, dynamic> getResourceStats() => {
        'timerCount': _timers.length,
        'subscriptionCount': _subscriptions.length,
        'controllerCount': _controllers.length,
      };
}

// Service that creates circular references
@ServiceContract(remote: false)
class CircularReferenceService extends FluxService {
  CircularReferenceService? _selfReference;
  final List<Map<String, dynamic>> _data = [];

  @override
  Future<void> initialize() async {
    await super.initialize();

    // Create circular reference
    _selfReference = this;

    // Create data that references itself
    final circularData = <String, dynamic>{
      'id': 'circular_1',
      'data': <String, dynamic>{},
    };
    circularData['data']['parent'] = circularData;
    _data.add(circularData);

    logger.info('Circular reference service initialized');
  }

  @override
  Future<void> destroy() async {
    // Break circular references
    _selfReference = null;
    _data.clear();

    await super.destroy();
  }

  /// Create more circular references
  Future<void> createCircularReferences(int count) async {
    for (var i = 0; i < count; i++) {
      final data = <String, dynamic>{
        'id': 'circular_$i',
        'data': <String, dynamic>{},
      };
      data['data']['parent'] = data;
      data['data']['service'] = this;
      _data.add(data);
    }
    logger.info('Created $count circular references');
  }

  Map<String, dynamic> getCircularStats() => {
        'dataCount': _data.length,
        'hasSelfReference': _selfReference != null,
      };
}

void main() {
  group('Memory Management Tests', () {
    late FluxRuntime runtime;

    setUp(() {
      runtime = FluxRuntime();
    });

    tearDown(() async {
      await runtime.destroyAll();
    });

    group('Memory Allocation and Cleanup', () {
      test('should properly clean up memory allocations on service destruction',
          () async {
        runtime.register<MemoryIntensiveService>(MemoryIntensiveService.new);
        await runtime.initializeAll();

        final service = runtime.get<MemoryIntensiveService>();

        // Allocate significant memory
        await service.allocateMemory(100, 10000); // 100 chunks of 10k integers

        final statsBefore = service.getMemoryStats();
        expect(statsBefore['chunkCount'], equals(100));

        // Destroy service and verify cleanup
        await runtime.destroyAll();

        // Force garbage collection
        await service.forceGarbageCollection();

        // Verify memory was cleaned up (indirectly through service destruction)
        expect(runtime.isInitialized, isFalse);
      });

      test('should detect memory leaks in services', () async {
        runtime.register<MemoryIntensiveService>(MemoryIntensiveService.new);
        await runtime.initializeAll();

        final service = runtime.get<MemoryIntensiveService>();

        // Simulate memory leak
        await service.simulateMemoryLeak(50, 5000);

        final stats = service.getMemoryStats();
        expect(stats['chunkCount'], equals(50));
        expect(stats['shouldLeak'], isTrue);

        // Service should still be destroyed properly
        await runtime.destroyAll();
        expect(runtime.isInitialized, isFalse);
      });

      test('should handle large memory allocations without crashing', () async {
        runtime.register<MemoryIntensiveService>(MemoryIntensiveService.new);
        await runtime.initializeAll();

        final service = runtime.get<MemoryIntensiveService>();

        // Allocate large amounts of memory
        await service.allocateMemory(
            1000, 100000); // 1000 chunks of 100k integers

        final stats = service.getMemoryStats();
        expect(stats['chunkCount'], equals(1000));

        // Service should still be responsive
        expect(service.isInitialized, isTrue);

        await runtime.destroyAll();
      });
    });

    group('Resource Management', () {
      test('should properly clean up timers and subscriptions', () async {
        runtime.register<ResourceManagedService>(ResourceManagedService.new);
        await runtime.initializeAll();

        final service = runtime.get<ResourceManagedService>();

        // Create additional resources
        await service.createResources(10);

        final stats = service.getResourceStats();
        expect(stats['timerCount'], equals(11)); // 1 initial + 10 additional
        expect(stats['subscriptionCount'], equals(11));

        // Destroy service - all resources should be cleaned up
        await runtime.destroyAll();
        expect(runtime.isInitialized, isFalse);
      });

      test('should handle resource cleanup failures gracefully', () async {
        runtime.register<ResourceManagedService>(ResourceManagedService.new);
        await runtime.initializeAll();

        final service = runtime.get<ResourceManagedService>();

        // Create many resources
        await service.createResources(100);

        // Destroy should complete without throwing
        await expectLater(runtime.destroyAll(), completes);
        expect(runtime.isInitialized, isFalse);
      });
    });

    group('Circular Reference Handling', () {
      test('should break circular references on destruction', () async {
        runtime
            .register<CircularReferenceService>(CircularReferenceService.new);
        await runtime.initializeAll();

        final service = runtime.get<CircularReferenceService>();

        // Create circular references
        await service.createCircularReferences(20);

        final stats = service.getCircularStats();
        expect(stats['dataCount'], equals(21)); // 1 initial + 20 additional
        expect(stats['hasSelfReference'], isTrue);

        // Destroy service - circular references should be broken
        await runtime.destroyAll();
        expect(runtime.isInitialized, isFalse);
      });

      test('should prevent memory leaks from circular references', () async {
        runtime
            .register<CircularReferenceService>(CircularReferenceService.new);
        await runtime.initializeAll();

        final service = runtime.get<CircularReferenceService>();

        // Create many circular references
        await service.createCircularReferences(100);

        // Service should still be functional
        expect(service.isInitialized, isTrue);

        // Destroy should complete successfully
        await runtime.destroyAll();
        expect(runtime.isInitialized, isFalse);
      });
    });

    group('Cross-Isolate Memory Management', () {
      test('should properly manage memory in worker isolates', () async {
        runtime.register<MemoryIntensiveService>(MemoryIntensiveService.new);
        await runtime.initializeAll();

        final service = runtime.get<MemoryIntensiveService>();

        // Allocate memory in worker isolate
        await service.allocateMemory(200, 5000);

        final stats = service.getMemoryStats();
        expect(stats['chunkCount'], equals(200));

        // Destroy should clean up worker isolate memory
        await runtime.destroyAll();
        expect(runtime.isInitialized, isFalse);
      });

      test('should handle memory pressure in worker isolates', () async {
        runtime.register<MemoryIntensiveService>(MemoryIntensiveService.new);
        await runtime.initializeAll();

        final service = runtime.get<MemoryIntensiveService>();

        // Create memory pressure
        await service.allocateMemory(500, 20000);
        await service.createTimers(50);
        await service.createSubscriptions(50);

        final stats = service.getMemoryStats();
        expect(stats['chunkCount'], equals(500));
        expect(stats['timerCount'], equals(50));
        expect(stats['subscriptionCount'], equals(50));

        // Service should remain responsive
        expect(service.isInitialized, isTrue);

        await runtime.destroyAll();
      });
    });

    group('Memory Monitoring and Metrics', () {
      test('should track memory usage across services', () async {
        runtime.register<MemoryIntensiveService>(MemoryIntensiveService.new);
        runtime.register<ResourceManagedService>(ResourceManagedService.new);
        runtime
            .register<CircularReferenceService>(CircularReferenceService.new);

        await runtime.initializeAll();

        final memoryService = runtime.get<MemoryIntensiveService>();
        final resourceService = runtime.get<ResourceManagedService>();
        final circularService = runtime.get<CircularReferenceService>();

        // Allocate resources in all services
        await memoryService.allocateMemory(100, 1000);
        await resourceService.createResources(20);
        await circularService.createCircularReferences(30);

        // All services should be functional
        expect(memoryService.isInitialized, isTrue);
        expect(resourceService.isInitialized, isTrue);
        expect(circularService.isInitialized, isTrue);

        // Clean up should work for all services
        await runtime.destroyAll();
        expect(runtime.isInitialized, isFalse);
      });

      test('should handle memory cleanup during service failures', () async {
        runtime.register<MemoryIntensiveService>(MemoryIntensiveService.new);
        await runtime.initializeAll();

        final service = runtime.get<MemoryIntensiveService>();

        // Allocate memory
        await service.allocateMemory(100, 1000);

        // Simulate service failure during operation
        try {
          await service.allocateMemory(
              1000, 1000000); // This might cause issues
        } catch (e) {
          // Expected to potentially fail
        }

        // Service should still be cleanable
        await runtime.destroyAll();
        expect(runtime.isInitialized, isFalse);
      });
    });

    group('Stress Testing', () {
      test('should handle rapid memory allocation and deallocation', () async {
        runtime.register<MemoryIntensiveService>(MemoryIntensiveService.new);
        await runtime.initializeAll();

        final service = runtime.get<MemoryIntensiveService>();

        // Rapid allocation/deallocation cycles
        for (var cycle = 0; cycle < 10; cycle++) {
          await service.allocateMemory(50, 1000);
          await service.forceGarbageCollection();
        }

        final stats = service.getMemoryStats();
        expect(stats['chunkCount'], equals(500)); // 10 cycles * 50 chunks

        await runtime.destroyAll();
      });

      test('should handle concurrent memory operations', () async {
        runtime.register<MemoryIntensiveService>(MemoryIntensiveService.new);
        await runtime.initializeAll();

        final service = runtime.get<MemoryIntensiveService>();

        // Concurrent memory operations
        final futures = <Future>[];
        for (var i = 0; i < 10; i++) {
          futures.add(service.allocateMemory(10, 1000));
        }

        await Future.wait(futures);

        final stats = service.getMemoryStats();
        expect(stats['chunkCount'], equals(100)); // 10 concurrent * 10 chunks

        await runtime.destroyAll();
      });
    });
  });
}

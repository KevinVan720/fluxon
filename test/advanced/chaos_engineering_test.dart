import 'dart:async';
import 'dart:math';

import 'package:flux/flux.dart';
import 'package:test/test.dart';

// Chaos engineering configuration
class ChaosConfig {
  const ChaosConfig({
    this.failureRate = 0.1,
    this.delayRange = const Duration(milliseconds: 100),
    this.timeoutRange = const Duration(seconds: 5),
    this.failureTypes = const ['timeout', 'exception', 'crash', 'memory_leak'],
    this.enableRandomCrashes = true,
    this.enableMemoryLeaks = true,
    this.enableNetworkPartition = false,
  });
  final double failureRate;
  final Duration delayRange;
  final Duration timeoutRange;
  final List<String> failureTypes;
  final bool enableRandomCrashes;
  final bool enableMemoryLeaks;
  final bool enableNetworkPartition;
}

// Chaos monkey service for fault injection
@ServiceContract(remote: false)
class ChaosMonkeyService extends FluxService {
  ChaosMonkeyService(this._config);
  final Random _random = Random();
  final ChaosConfig _config;
  final Map<String, int> _failureCounts = {};
  final Map<String, int> _successCounts = {};
  final List<Map<String, dynamic>> _chaosEvents = [];
  bool _chaosEnabled = false;

  @override
  Future<void> initialize() async {
    await super.initialize();
    logger.info(
        'Chaos monkey service initialized with failure rate: ${(_config.failureRate * 100).toInt()}%');
  }

  void enableChaos() {
    _chaosEnabled = true;
    _recordEvent(
        'chaos_enabled', {'timestamp': DateTime.now().toIso8601String()});
    logger.warning('Chaos monkey enabled - chaos will be injected!');
  }

  void disableChaos() {
    _chaosEnabled = false;
    _recordEvent(
        'chaos_disabled', {'timestamp': DateTime.now().toIso8601String()});
    logger.info('Chaos monkey disabled - normal operation restored');
  }

  Future<T> injectChaos<T>(
      String operationName, Future<T> Function() operation) async {
    if (!_chaosEnabled) {
      return operation();
    }

    _successCounts[operationName] = (_successCounts[operationName] ?? 0) + 1;

    if (_random.nextDouble() < _config.failureRate) {
      return _injectFailure(operationName, operation);
    } else {
      return _injectDelay(operationName, operation);
    }
  }

  Future<T> _injectFailure<T>(
      String operationName, Future<T> Function() operation) async {
    final failureType =
        _config.failureTypes[_random.nextInt(_config.failureTypes.length)];
    _failureCounts[operationName] = (_failureCounts[operationName] ?? 0) + 1;

    _recordEvent('chaos_failure', {
      'operation': operationName,
      'failureType': failureType,
      'timestamp': DateTime.now().toIso8601String(),
    });

    switch (failureType) {
      case 'timeout':
        return operation().timeout(_config.timeoutRange);
      case 'exception':
        throw ChaosException(
            'Chaos monkey injected exception in $operationName');
      case 'crash':
        if (_config.enableRandomCrashes) {
          throw ChaosException('Chaos monkey crashed $operationName');
        }
        return operation();
      case 'memory_leak':
        if (_config.enableMemoryLeaks) {
          _simulateMemoryLeak();
        }
        return operation();
      default:
        return operation();
    }
  }

  Future<T> _injectDelay<T>(
      String operationName, Future<T> Function() operation) async {
    final delayMs = _random.nextInt(_config.delayRange.inMilliseconds);
    await Future.delayed(Duration(milliseconds: delayMs));
    return operation();
  }

  void _simulateMemoryLeak() {
    // Simulate memory leak by creating large objects
    List<int>.filled(100000, 42);
    // Don't store reference to allow GC, but create pressure
  }

  void _recordEvent(String eventType, Map<String, dynamic> data) {
    _chaosEvents.add({
      'eventType': eventType,
      'timestamp': DateTime.now().toIso8601String(),
      'data': data,
    });
  }

  Map<String, dynamic> getChaosStatistics() {
    final totalOperations =
        _successCounts.values.fold(0, (sum, count) => sum + count);
    final totalFailures =
        _failureCounts.values.fold(0, (sum, count) => sum + count);

    return {
      'chaosEnabled': _chaosEnabled,
      'totalOperations': totalOperations,
      'totalFailures': totalFailures,
      'failureRate':
          totalOperations == 0 ? 0.0 : totalFailures / totalOperations,
      'operationStats': _successCounts.map((op, success) => MapEntry(op, {
            'successes': success,
            'failures': _failureCounts[op] ?? 0,
            'failureRate':
                success == 0 ? 0.0 : (_failureCounts[op] ?? 0) / success,
          })),
      'chaosEvents': List.from(_chaosEvents),
    };
  }

  void resetStatistics() {
    _failureCounts.clear();
    _successCounts.clear();
    _chaosEvents.clear();
  }
}

// Exception for chaos engineering
class ChaosException implements Exception {
  ChaosException(this.message);
  final String message;

  @override
  String toString() => 'ChaosException: $message';
}

// Resilient service that handles chaos
@ServiceContract(remote: true)
class ResilientService extends FluxService {
  ResilientService(this._chaosMonkey);
  final ChaosMonkeyService _chaosMonkey;
  int _operationCount = 0;
  int _successCount = 0;
  int _failureCount = 0;
  final List<String> _operationHistory = [];

  @override
  Future<void> initialize() async {
    await super.initialize();
    logger.info('Resilient service initialized');
  }

  Future<String> performOperation(String operationId) async {
    _operationCount++;
    _operationHistory.add('Operation $operationId started');

    try {
      final result =
          await _chaosMonkey.injectChaos('performOperation', () async {
        // Simulate some work
        await Future.delayed(const Duration(milliseconds: 50));
        return 'Operation $operationId completed successfully';
      });

      _successCount++;
      _operationHistory.add('Operation $operationId succeeded');
      return result;
    } catch (e) {
      _failureCount++;
      _operationHistory.add('Operation $operationId failed: $e');
      rethrow;
    }
  }

  Future<String> performCriticalOperation(String operationId) async {
    _operationCount++;
    _operationHistory.add('Critical operation $operationId started');

    // Retry logic for critical operations
    for (var attempt = 1; attempt <= 3; attempt++) {
      try {
        final result = await _chaosMonkey
            .injectChaos('performCriticalOperation', () async {
          await Future.delayed(const Duration(milliseconds: 100));
          return 'Critical operation $operationId completed on attempt $attempt';
        });

        _successCount++;
        _operationHistory.add(
            'Critical operation $operationId succeeded on attempt $attempt');
        return result;
      } catch (e) {
        _operationHistory.add(
            'Critical operation $operationId failed on attempt $attempt: $e');
        if (attempt == 3) {
          _failureCount++;
          rethrow;
        }
        await Future.delayed(Duration(milliseconds: 100 * attempt));
      }
    }

    throw StateError('Should not reach here');
  }

  Future<String> performBatchOperation(List<String> operationIds) async {
    _operationCount++;
    _operationHistory
        .add('Batch operation started with ${operationIds.length} items');

    final results = <String>[];
    final errors = <String>[];

    for (final operationId in operationIds) {
      try {
        final result =
            await _chaosMonkey.injectChaos('performBatchOperation', () async {
          await Future.delayed(const Duration(milliseconds: 25));
          return 'Batch item $operationId completed';
        });
        results.add(result);
      } catch (e) {
        errors.add('Batch item $operationId failed: $e');
      }
    }

    _successCount += results.length;
    _failureCount += errors.length;

    _operationHistory.add(
        'Batch operation completed: ${results.length} successes, ${errors.length} failures');

    return 'Batch completed: ${results.length} successes, ${errors.length} failures';
  }

  Map<String, dynamic> getResilienceStats() => {
        'operationCount': _operationCount,
        'successCount': _successCount,
        'failureCount': _failureCount,
        'successRate':
            _operationCount == 0 ? 0.0 : _successCount / _operationCount,
        'operationHistory': List.from(_operationHistory),
      };
}

// Service that simulates network partitions
@ServiceContract(remote: false)
class NetworkPartitionService extends FluxService {
  NetworkPartitionService();
  final Map<String, bool> _partitionedServices = {};
  final List<Map<String, dynamic>> _partitionEvents = [];

  @override
  Future<void> initialize() async {
    await super.initialize();
    logger.info('Network partition service initialized');
  }

  void partitionService(String serviceName) {
    _partitionedServices[serviceName] = true;
    _recordEvent('service_partitioned', {
      'serviceName': serviceName,
      'timestamp': DateTime.now().toIso8601String(),
    });
    logger
        .warning('Service $serviceName has been partitioned from the network');
  }

  void healService(String serviceName) {
    _partitionedServices[serviceName] = false;
    _recordEvent('service_healed', {
      'serviceName': serviceName,
      'timestamp': DateTime.now().toIso8601String(),
    });
    logger.info('Service $serviceName has been healed and reconnected');
  }

  bool isServicePartitioned(String serviceName) =>
      _partitionedServices[serviceName] ?? false;

  void _recordEvent(String eventType, Map<String, dynamic> data) {
    _partitionEvents.add({
      'eventType': eventType,
      'timestamp': DateTime.now().toIso8601String(),
      'data': data,
    });
  }

  Map<String, dynamic> getPartitionStatus() => {
        'partitionedServices': _partitionedServices.entries
            .where((e) => e.value)
            .map((e) => e.key)
            .toList(),
        'partitionEvents': List.from(_partitionEvents),
      };
}

// Service that simulates resource exhaustion
@ServiceContract(remote: false)
class ResourceExhaustionService extends FluxService {
  ResourceExhaustionService() {
    // Set default resource limits
    _resourceLimits['memory'] = 1000; // MB
    _resourceLimits['cpu'] = 80; // Percentage
    _resourceLimits['connections'] = 100;
  }
  final Map<String, int> _resourceUsage = {};
  final Map<String, int> _resourceLimits = {};
  final List<Map<String, dynamic>> _exhaustionEvents = [];

  @override
  Future<void> initialize() async {
    await super.initialize();
    logger.info('Resource exhaustion service initialized');
  }

  bool consumeResource(String resourceType, int amount) {
    final currentUsage = _resourceUsage[resourceType] ?? 0;
    final limit = _resourceLimits[resourceType] ?? 0;

    if (currentUsage + amount > limit) {
      _recordEvent('resource_exhausted', {
        'resourceType': resourceType,
        'requestedAmount': amount,
        'currentUsage': currentUsage,
        'limit': limit,
        'timestamp': DateTime.now().toIso8601String(),
      });
      logger.error(
          'Resource $resourceType exhausted: $currentUsage + $amount > $limit');
      return false;
    }

    _resourceUsage[resourceType] = currentUsage + amount;
    return true;
  }

  void releaseResource(String resourceType, int amount) {
    final currentUsage = _resourceUsage[resourceType] ?? 0;
    _resourceUsage[resourceType] =
        (currentUsage - amount).clamp(0, double.infinity).toInt();
  }

  void setResourceLimit(String resourceType, int limit) {
    _resourceLimits[resourceType] = limit;
    logger.info('Resource limit for $resourceType set to $limit');
  }

  void _recordEvent(String eventType, Map<String, dynamic> data) {
    _exhaustionEvents.add({
      'eventType': eventType,
      'timestamp': DateTime.now().toIso8601String(),
      'data': data,
    });
  }

  Map<String, dynamic> getResourceStatus() => {
        'usage': Map.from(_resourceUsage),
        'limits': Map.from(_resourceLimits),
        'exhaustionEvents': List.from(_exhaustionEvents),
      };
}

// Chaos engineering test orchestrator
@ServiceContract(remote: false)
class ChaosTestOrchestrator extends FluxService {
  ChaosTestOrchestrator(
    this._chaosMonkey,
    this._resilientService,
    this._partitionService,
    this._resourceService,
  );
  final ChaosMonkeyService _chaosMonkey;
  final ResilientService _resilientService;
  final NetworkPartitionService _partitionService;
  final ResourceExhaustionService _resourceService;
  final List<Map<String, dynamic>> _testResults = [];

  @override
  Future<void> initialize() async {
    await super.initialize();
    logger.info('Chaos test orchestrator initialized');
  }

  Future<Map<String, dynamic>> runChaosTest(
      String testName, Duration duration) async {
    logger.info('Starting chaos test: $testName');

    _chaosMonkey.enableChaos();
    _chaosMonkey.resetStatistics();

    final startTime = DateTime.now();
    final endTime = startTime.add(duration);

    var operationCount = 0;
    var successCount = 0;
    var failureCount = 0;

    while (DateTime.now().isBefore(endTime)) {
      try {
        await _resilientService.performOperation('chaos_test_$operationCount');
        successCount++;
      } catch (e) {
        failureCount++;
      }
      operationCount++;

      // Small delay to prevent overwhelming
      await Future.delayed(const Duration(milliseconds: 10));
    }

    _chaosMonkey.disableChaos();

    final testResult = {
      'testName': testName,
      'duration': duration.inMilliseconds,
      'operationCount': operationCount,
      'successCount': successCount,
      'failureCount': failureCount,
      'successRate': operationCount == 0 ? 0.0 : successCount / operationCount,
      'chaosStats': _chaosMonkey.getChaosStatistics(),
      'resilienceStats': _resilientService.getResilienceStats(),
      'timestamp': DateTime.now().toIso8601String(),
    };

    _testResults.add(testResult);
    logger.info(
        'Chaos test completed: $testName - Success rate: ${((testResult['successRate'] as double) * 100).toStringAsFixed(1)}%');

    return testResult;
  }

  Future<Map<String, dynamic>> runNetworkPartitionTest() async {
    logger.info('Starting network partition test');

    // Partition a service
    _partitionService.partitionService('ResilientService');

    // Try operations during partition
    var operationCount = 0;
    var successCount = 0;
    var failureCount = 0;

    for (var i = 0; i < 10; i++) {
      try {
        await _resilientService.performOperation('partition_test_$i');
        successCount++;
      } catch (e) {
        failureCount++;
      }
      operationCount++;
    }

    // Heal the service
    _partitionService.healService('ResilientService');

    // Try operations after healing
    for (var i = 0; i < 10; i++) {
      try {
        await _resilientService.performOperation('healed_test_$i');
        successCount++;
      } catch (e) {
        failureCount++;
      }
      operationCount++;
    }

    final testResult = {
      'testName': 'network_partition',
      'operationCount': operationCount,
      'successCount': successCount,
      'failureCount': failureCount,
      'successRate': operationCount == 0 ? 0.0 : successCount / operationCount,
      'partitionStatus': _partitionService.getPartitionStatus(),
      'timestamp': DateTime.now().toIso8601String(),
    };

    _testResults.add(testResult);
    logger.info('Network partition test completed');

    return testResult;
  }

  Future<Map<String, dynamic>> runResourceExhaustionTest() async {
    logger.info('Starting resource exhaustion test');

    // Try to exhaust memory
    var memoryOperations = 0;
    var memoryFailures = 0;

    while (memoryOperations < 100) {
      if (_resourceService.consumeResource('memory', 10)) {
        memoryOperations++;
      } else {
        memoryFailures++;
        break;
      }
    }

    // Try to exhaust connections
    var connectionOperations = 0;
    var connectionFailures = 0;

    while (connectionOperations < 100) {
      if (_resourceService.consumeResource('connections', 1)) {
        connectionOperations++;
      } else {
        connectionFailures++;
        break;
      }
    }

    final testResult = {
      'testName': 'resource_exhaustion',
      'memoryOperations': memoryOperations,
      'memoryFailures': memoryFailures,
      'connectionOperations': connectionOperations,
      'connectionFailures': connectionFailures,
      'resourceStatus': _resourceService.getResourceStatus(),
      'timestamp': DateTime.now().toIso8601String(),
    };

    _testResults.add(testResult);
    logger.info('Resource exhaustion test completed');

    return testResult;
  }

  List<Map<String, dynamic>> getAllTestResults() => List.from(_testResults);
}

void main() {
  group('Chaos Engineering Tests', () {
    late FluxRuntime runtime;
    late ChaosMonkeyService chaosMonkey;
    late ResilientService resilientService;
    late NetworkPartitionService partitionService;
    late ResourceExhaustionService resourceService;
    late ChaosTestOrchestrator orchestrator;

    setUp(() async {
      runtime = FluxRuntime();

      const chaosConfig = ChaosConfig(
        failureRate: 0.3,
        delayRange: Duration(milliseconds: 50),
        timeoutRange: Duration(seconds: 2),
      );

      runtime
        ..register<ChaosMonkeyService>(() => ChaosMonkeyService(chaosConfig))
        ..register<NetworkPartitionService>(NetworkPartitionService.new)
        ..register<ResourceExhaustionService>(ResourceExhaustionService.new);

      await runtime.initializeAll();

      chaosMonkey = runtime.get<ChaosMonkeyService>();
      // Create ResilientService after ChaosMonkeyService is available
      resilientService = ResilientService(chaosMonkey);
      partitionService = runtime.get<NetworkPartitionService>();
      resourceService = runtime.get<ResourceExhaustionService>();

      orchestrator = ChaosTestOrchestrator(
        chaosMonkey,
        resilientService,
        partitionService,
        resourceService,
      );
      await orchestrator.internalInitialize();
    });

    tearDown(() async {
      if (runtime.isInitialized) {
        await runtime.destroyAll();
      }
    });

    group('Basic Chaos Injection', () {
      test('should inject failures when chaos is enabled', () async {
        chaosMonkey.enableChaos();

        var successCount = 0;
        var failureCount = 0;

        for (var i = 0; i < 20; i++) {
          try {
            await resilientService.performOperation('test_$i');
            successCount++;
          } catch (e) {
            failureCount++;
          }
        }

        expect(successCount + failureCount, equals(20));
        expect(failureCount, greaterThan(0)); // Should have some failures

        final chaosStats = chaosMonkey.getChaosStatistics();
        expect(chaosStats['chaosEnabled'], isTrue);
        expect(chaosStats['totalOperations'], equals(20));
      });

      test('should not inject failures when chaos is disabled', () async {
        chaosMonkey.disableChaos();

        var successCount = 0;
        var failureCount = 0;

        for (var i = 0; i < 10; i++) {
          try {
            await resilientService.performOperation('test_$i');
            successCount++;
          } catch (e) {
            failureCount++;
          }
        }

        expect(successCount, equals(10));
        expect(failureCount, equals(0));
      });

      test('should handle critical operations with retry logic', () async {
        chaosMonkey.enableChaos();

        var successCount = 0;
        var failureCount = 0;

        for (var i = 0; i < 10; i++) {
          try {
            await resilientService.performCriticalOperation('critical_$i');
            successCount++;
          } catch (e) {
            failureCount++;
          }
        }

        // Critical operations should have higher success rate due to retry logic
        expect(successCount, greaterThan(failureCount));
      });
    });

    group('Network Partition Simulation', () {
      test('should simulate network partitions', () async {
        partitionService.partitionService('TestService');

        expect(partitionService.isServicePartitioned('TestService'), isTrue);

        final status = partitionService.getPartitionStatus();
        expect(status['partitionedServices'], contains('TestService'));
      });

      test('should heal network partitions', () async {
        partitionService.partitionService('TestService');
        partitionService.healService('TestService');

        expect(partitionService.isServicePartitioned('TestService'), isFalse);
      });
    });

    group('Resource Exhaustion', () {
      test('should track resource usage', () async {
        expect(resourceService.consumeResource('memory', 100), isTrue);
        expect(resourceService.consumeResource('memory', 200), isTrue);
        expect(resourceService.consumeResource('memory', 800),
            isFalse); // Should exceed limit

        final status = resourceService.getResourceStatus();
        expect(status['usage']['memory'], equals(300));
      });

      test('should release resources', () async {
        resourceService.consumeResource('memory', 500);
        resourceService.releaseResource('memory', 200);

        final status = resourceService.getResourceStatus();
        expect(status['usage']['memory'], equals(300));
      });

      test('should set resource limits', () async {
        resourceService.setResourceLimit('memory', 2000);

        expect(resourceService.consumeResource('memory', 1500), isTrue);
        expect(resourceService.consumeResource('memory', 600), isFalse);
      });
    });

    group('Chaos Test Orchestration', () {
      test('should run comprehensive chaos tests', () async {
        final result = await orchestrator.runChaosTest(
            'comprehensive_test', const Duration(seconds: 2));

        expect(result['testName'], equals('comprehensive_test'));
        expect(result['operationCount'], greaterThan(0));
        expect(result['successCount'], greaterThanOrEqualTo(0));
        expect(result['failureCount'], greaterThanOrEqualTo(0));
        expect(result['successRate'], greaterThanOrEqualTo(0.0));
        expect(result['successRate'], lessThanOrEqualTo(1.0));
      });

      test('should run network partition tests', () async {
        final result = await orchestrator.runNetworkPartitionTest();

        expect(result['testName'], equals('network_partition'));
        expect(result['operationCount'],
            equals(20)); // 10 during partition + 10 after healing
        expect(result['successCount'], greaterThanOrEqualTo(0));
        expect(result['failureCount'], greaterThanOrEqualTo(0));
      });

      test('should run resource exhaustion tests', () async {
        final result = await orchestrator.runResourceExhaustionTest();

        expect(result['testName'], equals('resource_exhaustion'));
        expect(result['memoryOperations'], greaterThan(0));
        expect(result['connectionOperations'], greaterThan(0));
      });

      test('should track all test results', () async {
        await orchestrator.runChaosTest('test1', const Duration(seconds: 1));
        await orchestrator.runNetworkPartitionTest();
        await orchestrator.runResourceExhaustionTest();

        final allResults = orchestrator.getAllTestResults();
        expect(allResults, hasLength(3));
        expect(allResults.map((r) => r['testName']),
            containsAll(['test1', 'network_partition', 'resource_exhaustion']));
      });
    });

    group('Stress Testing with Chaos', () {
      test('should handle batch operations under chaos', () async {
        chaosMonkey.enableChaos();

        final operationIds = List.generate(20, (i) => 'batch_$i');
        final result =
            await resilientService.performBatchOperation(operationIds);

        expect(result, contains('Batch completed'));
        expect(result, contains('successes'));
        expect(result, contains('failures'));
      });
    });

    group('Chaos Engineering Edge Cases', () {
      test('should handle chaos during service destruction', () async {
        chaosMonkey.enableChaos();

        // Perform some operations
        for (var i = 0; i < 5; i++) {
          try {
            await resilientService.performOperation('destruction_test_$i');
          } catch (e) {
            // Expected to potentially fail
          }
        }

        // Services should still be destroyable
        await runtime.destroyAll();
        expect(runtime.isInitialized, isFalse);
      });

      test('should handle concurrent chaos injection', () async {
        chaosMonkey.enableChaos();

        final futures = <Future>[];

        // Start multiple concurrent operations
        for (var i = 0; i < 50; i++) {
          futures.add(Future(() async {
            try {
              return await resilientService.performOperation('concurrent_$i');
            } catch (e) {
              return 'Failed: $e';
            }
          }));
        }

        final results = await Future.wait(futures);

        // Should have some successes and some failures
        final successCount =
            results.where((r) => r.contains('completed successfully')).length;
        expect(successCount, greaterThan(0));
        expect(successCount, lessThan(50));
      });
    });
  });
}

import 'dart:async';
import 'dart:math';

import 'package:flux/flux.dart';
import 'package:test/test.dart';

// Load balancing strategies
enum LoadBalancingStrategy {
  roundRobin,
  weightedRoundRobin,
  leastConnections,
  leastResponseTime,
  random,
  consistentHash,
}

// Service instance information
class ServiceInstance {
  const ServiceInstance({
    required this.id,
    required this.host,
    required this.port,
    required this.lastHealthCheck,
    this.weight = 1,
    this.maxConnections = 100,
    this.responseTime = Duration.zero,
    this.isHealthy = true,
  });
  final String id;
  final String host;
  final int port;
  final int weight;
  final int maxConnections;
  final Duration responseTime;
  final bool isHealthy;
  final DateTime lastHealthCheck;

  Map<String, dynamic> toJson() => {
        'id': id,
        'host': host,
        'port': port,
        'weight': weight,
        'maxConnections': maxConnections,
        'responseTimeMs': responseTime.inMilliseconds,
        'isHealthy': isHealthy,
        'lastHealthCheck': lastHealthCheck.toIso8601String(),
      };
}

// Load balancer service
@ServiceContract(remote: false)
class LoadBalancerService extends FluxService {
  LoadBalancerService();
  final Map<String, List<ServiceInstance>> _serviceInstances = {};
  final Map<String, int> _roundRobinCounters = {};
  final Map<String, int> _connectionCounts = {};
  final Map<String, LoadBalancingStrategy> _strategies = {};
  final Map<String, List<Map<String, dynamic>>> _requestHistory = {};

  @override
  Future<void> initialize() async {
    await super.initialize();
    logger.info('Load balancer service initialized');
  }

  void registerService(String serviceName, List<ServiceInstance> instances,
      {LoadBalancingStrategy strategy = LoadBalancingStrategy.roundRobin}) {
    _serviceInstances[serviceName] = List.from(instances);
    _strategies[serviceName] = strategy;
    _roundRobinCounters[serviceName] = 0;
    _connectionCounts[serviceName] = 0;
    _requestHistory[serviceName] = [];

    logger.info(
        'Registered $serviceName with ${instances.length} instances using ${strategy.toString()} strategy');
  }

  Future<ServiceInstance?> selectInstance(String serviceName,
      {String? sessionId}) async {
    final instances = _serviceInstances[serviceName];
    if (instances == null || instances.isEmpty) {
      return null;
    }

    final healthyInstances = instances.where((i) => i.isHealthy).toList();
    if (healthyInstances.isEmpty) {
      return null;
    }

    final strategy =
        _strategies[serviceName] ?? LoadBalancingStrategy.roundRobin;
    ServiceInstance? selectedInstance;

    switch (strategy) {
      case LoadBalancingStrategy.roundRobin:
        selectedInstance = _selectRoundRobin(serviceName, healthyInstances);
        break;
      case LoadBalancingStrategy.weightedRoundRobin:
        selectedInstance =
            _selectWeightedRoundRobin(serviceName, healthyInstances);
        break;
      case LoadBalancingStrategy.leastConnections:
        selectedInstance = _selectLeastConnections(healthyInstances);
        break;
      case LoadBalancingStrategy.leastResponseTime:
        selectedInstance = _selectLeastResponseTime(healthyInstances);
        break;
      case LoadBalancingStrategy.random:
        selectedInstance = _selectRandom(healthyInstances);
        break;
      case LoadBalancingStrategy.consistentHash:
        selectedInstance = _selectConsistentHash(healthyInstances, sessionId);
        break;
    }

    _connectionCounts[selectedInstance.id] =
        (_connectionCounts[selectedInstance.id] ?? 0) + 1;
    _recordRequest(serviceName, selectedInstance.id);

    return selectedInstance;
  }

  ServiceInstance _selectRoundRobin(
      String serviceName, List<ServiceInstance> instances) {
    final counter = _roundRobinCounters[serviceName]!;
    final selected = instances[counter % instances.length];
    _roundRobinCounters[serviceName] = counter + 1;
    return selected;
  }

  ServiceInstance _selectWeightedRoundRobin(
      String serviceName, List<ServiceInstance> instances) {
    // Calculate total weight
    final totalWeight =
        instances.fold(0, (sum, instance) => sum + instance.weight);

    // Get current counter
    final counter = _roundRobinCounters[serviceName]!;

    // Find instance based on weighted distribution
    var currentWeight = 0;
    for (final instance in instances) {
      currentWeight += instance.weight;
      if (counter % totalWeight < currentWeight) {
        _roundRobinCounters[serviceName] = counter + 1;
        return instance;
      }
    }

    // Fallback to first instance
    return instances.first;
  }

  ServiceInstance _selectLeastConnections(List<ServiceInstance> instances) =>
      instances.reduce((a, b) {
        final connectionsA = _connectionCounts[a.id] ?? 0;
        final connectionsB = _connectionCounts[b.id] ?? 0;
        return connectionsA < connectionsB ? a : b;
      });

  ServiceInstance _selectLeastResponseTime(List<ServiceInstance> instances) =>
      instances.reduce((a, b) => a.responseTime <= b.responseTime ? a : b);

  ServiceInstance _selectRandom(List<ServiceInstance> instances) {
    final random = Random();
    return instances[random.nextInt(instances.length)];
  }

  ServiceInstance _selectConsistentHash(
      List<ServiceInstance> instances, String? sessionId) {
    if (sessionId == null) {
      return _selectRandom(instances);
    }

    // Simple hash-based selection
    final hash = sessionId.hashCode;
    return instances[hash.abs() % instances.length];
  }

  void _recordRequest(String serviceName, String instanceId) {
    _requestHistory[serviceName]!.add({
      'instanceId': instanceId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void updateInstanceHealth(
      String serviceName, String instanceId, bool isHealthy) {
    final instances = _serviceInstances[serviceName];
    if (instances == null) return;

    final instance = instances.firstWhere(
      (i) => i.id == instanceId,
      orElse: () => throw ArgumentError('Instance not found: $instanceId'),
    );

    final updatedInstance = ServiceInstance(
      id: instance.id,
      host: instance.host,
      port: instance.port,
      weight: instance.weight,
      maxConnections: instance.maxConnections,
      responseTime: instance.responseTime,
      isHealthy: isHealthy,
      lastHealthCheck: DateTime.now(),
    );

    final index = instances.indexWhere((i) => i.id == instanceId);
    instances[index] = updatedInstance;

    logger.info('Updated health for instance $instanceId: $isHealthy');
  }

  void updateInstanceResponseTime(
      String serviceName, String instanceId, Duration responseTime) {
    final instances = _serviceInstances[serviceName];
    if (instances == null) return;

    final instance = instances.firstWhere(
      (i) => i.id == instanceId,
      orElse: () => throw ArgumentError('Instance not found: $instanceId'),
    );

    final updatedInstance = ServiceInstance(
      id: instance.id,
      host: instance.host,
      port: instance.port,
      weight: instance.weight,
      maxConnections: instance.maxConnections,
      responseTime: responseTime,
      isHealthy: instance.isHealthy,
      lastHealthCheck: DateTime.now(),
    );

    final index = instances.indexWhere((i) => i.id == instanceId);
    instances[index] = updatedInstance;
  }

  Map<String, dynamic> getLoadBalancingStats() {
    final stats = <String, dynamic>{};

    for (final serviceName in _serviceInstances.keys) {
      final instances = _serviceInstances[serviceName]!;
      final strategy = _strategies[serviceName]!;
      final requestHistory = _requestHistory[serviceName]!;

      // Calculate distribution
      final distribution = <String, int>{};
      for (final request in requestHistory) {
        final instanceId = request['instanceId'] as String;
        distribution[instanceId] = (distribution[instanceId] ?? 0) + 1;
      }

      stats[serviceName] = {
        'strategy': strategy.toString(),
        'totalInstances': instances.length,
        'healthyInstances': instances.where((i) => i.isHealthy).length,
        'totalRequests': requestHistory.length,
        'distribution': distribution,
        'connectionCounts': _connectionCounts,
      };
    }

    return stats;
  }
}

// Scalable service that can be load balanced
@ServiceContract(remote: true)
class ScalableService extends FluxService {
  ScalableService(this._instanceId, this._maxConcurrentRequests);
  final String _instanceId;
  final int _maxConcurrentRequests;
  int _currentRequests = 0;
  final List<Map<String, dynamic>> _requestLog = [];
  final Map<String, Duration> _responseTimes = {};

  @override
  Future<void> initialize() async {
    await super.initialize();
    logger.info('Scalable service instance $_instanceId initialized');
  }

  Future<String> processRequest(String requestId,
      {Duration? processingTime}) async {
    if (_currentRequests >= _maxConcurrentRequests) {
      throw Exception('Service instance $_instanceId is at capacity');
    }

    _currentRequests++;
    final startTime = DateTime.now();

    try {
      // Simulate processing
      final actualProcessingTime =
          processingTime ?? const Duration(milliseconds: 100);
      await Future.delayed(actualProcessingTime);

      final endTime = DateTime.now();
      final responseTime = endTime.difference(startTime);

      _requestLog.add({
        'requestId': requestId,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'responseTimeMs': responseTime.inMilliseconds,
        'instanceId': _instanceId,
      });

      _responseTimes[requestId] = responseTime;

      return 'Request $requestId processed by instance $_instanceId in ${responseTime.inMilliseconds}ms';
    } finally {
      _currentRequests--;
    }
  }

  Future<String> processHeavyRequest(String requestId) async =>
      processRequest(requestId, processingTime: const Duration(seconds: 2));

  Future<String> processLightRequest(String requestId) async =>
      processRequest(requestId,
          processingTime: const Duration(milliseconds: 10));

  Map<String, dynamic> getInstanceStats() => {
        'instanceId': _instanceId,
        'maxConcurrentRequests': _maxConcurrentRequests,
        'currentRequests': _currentRequests,
        'totalRequests': _requestLog.length,
        'averageResponseTimeMs': _responseTimes.values.isEmpty
            ? 0
            : _responseTimes.values
                    .fold(0, (sum, time) => sum + time.inMilliseconds) /
                _responseTimes.length,
      };
}

// Auto-scaling service
@ServiceContract(remote: false)
class AutoScalingService extends FluxService {
  AutoScalingService(this._loadBalancer);
  final LoadBalancerService _loadBalancer;
  final Map<String, List<ServiceInstance>> _serviceInstances = {};
  final Map<String, Map<String, dynamic>> _scalingPolicies = {};
  final Map<String, int> _requestCounts = {};
  final Map<String, Duration> _responseTimeAverages = {};

  @override
  Future<void> initialize() async {
    await super.initialize();
    logger.info('Auto-scaling service initialized');
  }

  void setScalingPolicy(
    String serviceName, {
    int minInstances = 1,
    int maxInstances = 10,
    int scaleUpThreshold = 80,
    int scaleDownThreshold = 20,
    Duration scaleUpCooldown = const Duration(minutes: 5),
    Duration scaleDownCooldown = const Duration(minutes: 10),
  }) {
    _scalingPolicies[serviceName] = {
      'minInstances': minInstances,
      'maxInstances': maxInstances,
      'scaleUpThreshold': scaleUpThreshold,
      'scaleDownThreshold': scaleDownThreshold,
      'scaleUpCooldown': scaleUpCooldown,
      'scaleDownCooldown': scaleDownCooldown,
      'lastScaleUp': null,
      'lastScaleDown': null,
    };

    logger.info(
        'Scaling policy set for $serviceName: min=$minInstances, max=$maxInstances');
  }

  Future<void> recordRequest(
      String serviceName, String instanceId, Duration responseTime) async {
    _requestCounts[serviceName] = (_requestCounts[serviceName] ?? 0) + 1;

    // Update average response time
    final currentAvg = _responseTimeAverages[serviceName] ?? Duration.zero;
    final totalRequests = _requestCounts[serviceName]!;
    final newAvg = Duration(
      milliseconds: ((currentAvg.inMilliseconds * (totalRequests - 1)) +
              responseTime.inMilliseconds) ~/
          totalRequests,
    );
    _responseTimeAverages[serviceName] = newAvg;

    // Check if scaling is needed
    await _checkScaling(serviceName);
  }

  Future<void> _checkScaling(String serviceName) async {
    final policy = _scalingPolicies[serviceName];
    if (policy == null) return;

    final instances = _serviceInstances[serviceName] ?? [];
    final healthyInstances = instances.where((i) => i.isHealthy).length;
    final totalRequests = _requestCounts[serviceName] ?? 0;
    final avgResponseTime = _responseTimeAverages[serviceName] ?? Duration.zero;

    // Calculate load metrics
    final loadPercentage =
        totalRequests > 0 ? (totalRequests / healthyInstances) : 0;
    final responseTimeMs = avgResponseTime.inMilliseconds;

    // Check scale up conditions
    if (healthyInstances < policy['maxInstances'] &&
        (loadPercentage > policy['scaleUpThreshold'] ||
            responseTimeMs > 1000)) {
      await _scaleUp(serviceName);
    }

    // Check scale down conditions
    if (healthyInstances > policy['minInstances'] &&
        loadPercentage < policy['scaleDownThreshold'] &&
        responseTimeMs < 500) {
      await _scaleDown(serviceName);
    }
  }

  Future<void> _scaleUp(String serviceName) async {
    final policy = _scalingPolicies[serviceName]!;
    final now = DateTime.now();

    // Check cooldown
    if (policy['lastScaleUp'] != null) {
      final lastScaleUp = policy['lastScaleUp'] as DateTime;
      if (now.difference(lastScaleUp) < policy['scaleUpCooldown']) {
        return;
      }
    }

    // Add new instance
    final instances = _serviceInstances[serviceName] ?? [];
    final newInstanceId = '${serviceName}_instance_${instances.length + 1}';
    final newInstance = ServiceInstance(
      id: newInstanceId,
      host: 'localhost',
      port: 8000 + instances.length,
      lastHealthCheck: now,
    );

    instances.add(newInstance);
    _serviceInstances[serviceName] = instances;

    // Update load balancer
    _loadBalancer.registerService(serviceName, instances);

    policy['lastScaleUp'] = now;

    logger.info('Scaled up $serviceName: added instance $newInstanceId');
  }

  Future<void> _scaleDown(String serviceName) async {
    final policy = _scalingPolicies[serviceName]!;
    final now = DateTime.now();

    // Check cooldown
    if (policy['lastScaleDown'] != null) {
      final lastScaleDown = policy['lastScaleDown'] as DateTime;
      if (now.difference(lastScaleDown) < policy['scaleDownCooldown']) {
        return;
      }
    }

    // Remove least used instance
    final instances = _serviceInstances[serviceName] ?? [];
    if (instances.length <= policy['minInstances']) return;

    // Find instance with least connections (simplified)
    final instanceToRemove = instances.last;
    instances.remove(instanceToRemove);
    _serviceInstances[serviceName] = instances;

    // Update load balancer
    _loadBalancer.registerService(serviceName, instances);

    policy['lastScaleDown'] = now;

    logger.info(
        'Scaled down $serviceName: removed instance ${instanceToRemove.id}');
  }

  Map<String, dynamic> getScalingStats() {
    final stats = <String, dynamic>{};

    for (final serviceName in _serviceInstances.keys) {
      final instances = _serviceInstances[serviceName]!;
      final policy = _scalingPolicies[serviceName]!;

      stats[serviceName] = {
        'currentInstances': instances.length,
        'healthyInstances': instances.where((i) => i.isHealthy).length,
        'minInstances': policy['minInstances'],
        'maxInstances': policy['maxInstances'],
        'totalRequests': _requestCounts[serviceName] ?? 0,
        'averageResponseTimeMs':
            _responseTimeAverages[serviceName]?.inMilliseconds ?? 0,
        'lastScaleUp': policy['lastScaleUp']?.toIso8601String(),
        'lastScaleDown': policy['lastScaleDown']?.toIso8601String(),
      };
    }

    return stats;
  }
}

void main() {
  group('Load Balancing Tests', () {
    late FluxRuntime runtime;
    late LoadBalancerService loadBalancer;
    late AutoScalingService autoScaling;

    setUp(() async {
      runtime = FluxRuntime();

      runtime.register<LoadBalancerService>(LoadBalancerService.new);

      await runtime.initializeAll();

      loadBalancer = runtime.get<LoadBalancerService>();
      // Create AutoScalingService after LoadBalancerService is available
      autoScaling = AutoScalingService(loadBalancer);
    });

    tearDown(() async {
      await runtime.destroyAll();
    });

    group('Load Balancing Strategies', () {
      test('should implement round-robin load balancing', () async {
        final instances = [
          ServiceInstance(
              id: 'instance1',
              host: 'host1',
              port: 8001,
              lastHealthCheck: DateTime.now()),
          ServiceInstance(
              id: 'instance2',
              host: 'host2',
              port: 8002,
              lastHealthCheck: DateTime.now()),
          ServiceInstance(
              id: 'instance3',
              host: 'host3',
              port: 8003,
              lastHealthCheck: DateTime.now()),
        ];

        loadBalancer.registerService('testService', instances);

        // Make multiple requests
        final selectedInstances = <String>[];
        for (var i = 0; i < 9; i++) {
          final instance = await loadBalancer.selectInstance('testService');
          selectedInstances.add(instance!.id);
        }

        // Should cycle through instances
        expect(
            selectedInstances,
            equals([
              'instance1',
              'instance2',
              'instance3',
              'instance1',
              'instance2',
              'instance3',
              'instance1',
              'instance2',
              'instance3'
            ]));
      });

      test('should implement weighted round-robin load balancing', () async {
        final instances = [
          ServiceInstance(
              id: 'instance1',
              host: 'host1',
              port: 8001,
              weight: 3,
              lastHealthCheck: DateTime.now()),
          ServiceInstance(
              id: 'instance2',
              host: 'host2',
              port: 8002,
              lastHealthCheck: DateTime.now()),
        ];

        loadBalancer.registerService('testService', instances,
            strategy: LoadBalancingStrategy.weightedRoundRobin);

        // Make multiple requests
        final selectedInstances = <String>[];
        for (var i = 0; i < 8; i++) {
          final instance = await loadBalancer.selectInstance('testService');
          selectedInstances.add(instance!.id);
        }

        // Should distribute according to weights (3:1 ratio)
        final instance1Count =
            selectedInstances.where((id) => id == 'instance1').length;
        final instance2Count =
            selectedInstances.where((id) => id == 'instance2').length;

        expect(instance1Count, equals(6)); // 3/4 of 8
        expect(instance2Count, equals(2)); // 1/4 of 8
      });

      test('should implement least connections load balancing', () async {
        final instances = [
          ServiceInstance(
              id: 'instance1',
              host: 'host1',
              port: 8001,
              lastHealthCheck: DateTime.now()),
          ServiceInstance(
              id: 'instance2',
              host: 'host2',
              port: 8002,
              lastHealthCheck: DateTime.now()),
          ServiceInstance(
              id: 'instance3',
              host: 'host3',
              port: 8003,
              lastHealthCheck: DateTime.now()),
        ];

        loadBalancer.registerService('testService', instances,
            strategy: LoadBalancingStrategy.leastConnections);

        // Make requests to create connection imbalance
        await loadBalancer.selectInstance('testService'); // instance1
        await loadBalancer.selectInstance('testService'); // instance1
        await loadBalancer.selectInstance('testService'); // instance1

        // Next request should go to instance with least connections
        final instance = await loadBalancer.selectInstance('testService');
        expect(
            instance!.id,
            anyOf([
              'instance2',
              'instance3'
            ])); // Should be instance2 or instance3
      });

      test('should implement least response time load balancing', () async {
        final instances = [
          ServiceInstance(
              id: 'instance1',
              host: 'host1',
              port: 8001,
              responseTime: const Duration(milliseconds: 100),
              lastHealthCheck: DateTime.now()),
          ServiceInstance(
              id: 'instance2',
              host: 'host2',
              port: 8002,
              responseTime: const Duration(milliseconds: 50),
              lastHealthCheck: DateTime.now()),
          ServiceInstance(
              id: 'instance3',
              host: 'host3',
              port: 8003,
              responseTime: const Duration(milliseconds: 200),
              lastHealthCheck: DateTime.now()),
        ];

        loadBalancer.registerService('testService', instances,
            strategy: LoadBalancingStrategy.leastResponseTime);

        // Should always select instance2 (fastest response time)
        for (var i = 0; i < 5; i++) {
          final instance = await loadBalancer.selectInstance('testService');
          expect(instance!.id, equals('instance2'));
        }
      });

      test('should implement random load balancing', () async {
        final instances = [
          ServiceInstance(
              id: 'instance1',
              host: 'host1',
              port: 8001,
              lastHealthCheck: DateTime.now()),
          ServiceInstance(
              id: 'instance2',
              host: 'host2',
              port: 8002,
              lastHealthCheck: DateTime.now()),
          ServiceInstance(
              id: 'instance3',
              host: 'host3',
              port: 8003,
              lastHealthCheck: DateTime.now()),
        ];

        loadBalancer.registerService('testService', instances,
            strategy: LoadBalancingStrategy.random);

        // Make many requests to test randomness
        final selectedInstances = <String>[];
        for (var i = 0; i < 100; i++) {
          final instance = await loadBalancer.selectInstance('testService');
          selectedInstances.add(instance!.id);
        }

        // Should have some distribution across all instances
        final uniqueInstances = selectedInstances.toSet();
        expect(uniqueInstances.length,
            greaterThan(1)); // Should select multiple instances
      });

      test('should implement consistent hash load balancing', () async {
        final instances = [
          ServiceInstance(
              id: 'instance1',
              host: 'host1',
              port: 8001,
              lastHealthCheck: DateTime.now()),
          ServiceInstance(
              id: 'instance2',
              host: 'host2',
              port: 8002,
              lastHealthCheck: DateTime.now()),
          ServiceInstance(
              id: 'instance3',
              host: 'host3',
              port: 8003,
              lastHealthCheck: DateTime.now()),
        ];

        loadBalancer.registerService('testService', instances,
            strategy: LoadBalancingStrategy.consistentHash);

        // Same session should always get same instance
        const sessionId = 'session123';
        final instance1 = await loadBalancer.selectInstance('testService',
            sessionId: sessionId);
        final instance2 = await loadBalancer.selectInstance('testService',
            sessionId: sessionId);

        expect(instance1!.id, equals(instance2!.id));
      });
    });

    group('Health Management', () {
      test('should skip unhealthy instances', () async {
        final instances = [
          ServiceInstance(
              id: 'instance1',
              host: 'host1',
              port: 8001,
              lastHealthCheck: DateTime.now()),
          ServiceInstance(
              id: 'instance2',
              host: 'host2',
              port: 8002,
              isHealthy: false,
              lastHealthCheck: DateTime.now()),
          ServiceInstance(
              id: 'instance3',
              host: 'host3',
              port: 8003,
              lastHealthCheck: DateTime.now()),
        ];

        loadBalancer.registerService('testService', instances);

        // Should only select healthy instances
        for (var i = 0; i < 10; i++) {
          final instance = await loadBalancer.selectInstance('testService');
          expect(instance, isNotNull);
          expect(instance!.isHealthy, isTrue);
          expect(instance.id, anyOf(['instance1', 'instance3']));
        }
      });

      test('should handle all instances being unhealthy', () async {
        final instances = [
          ServiceInstance(
              id: 'instance1',
              host: 'host1',
              port: 8001,
              isHealthy: false,
              lastHealthCheck: DateTime.now()),
          ServiceInstance(
              id: 'instance2',
              host: 'host2',
              port: 8002,
              isHealthy: false,
              lastHealthCheck: DateTime.now()),
        ];

        loadBalancer.registerService('testService', instances);

        // Should return null when all instances are unhealthy
        final instance = await loadBalancer.selectInstance('testService');
        expect(instance, isNull);
      });

      test('should update instance health', () async {
        final instances = [
          ServiceInstance(
              id: 'instance1',
              host: 'host1',
              port: 8001,
              lastHealthCheck: DateTime.now()),
          ServiceInstance(
              id: 'instance2',
              host: 'host2',
              port: 8002,
              lastHealthCheck: DateTime.now()),
        ];

        loadBalancer.registerService('testService', instances);

        // Mark instance1 as unhealthy
        loadBalancer.updateInstanceHealth('testService', 'instance1', false);

        // Should only select instance2
        for (var i = 0; i < 5; i++) {
          final instance = await loadBalancer.selectInstance('testService');
          expect(instance!.id, equals('instance2'));
        }
      });
    });

    group('Load Balancing Statistics', () {
      test('should track request distribution', () async {
        final instances = [
          ServiceInstance(
              id: 'instance1',
              host: 'host1',
              port: 8001,
              lastHealthCheck: DateTime.now()),
          ServiceInstance(
              id: 'instance2',
              host: 'host2',
              port: 8002,
              lastHealthCheck: DateTime.now()),
        ];

        loadBalancer.registerService('testService', instances);

        // Make requests
        for (var i = 0; i < 10; i++) {
          await loadBalancer.selectInstance('testService');
        }

        final stats = loadBalancer.getLoadBalancingStats();
        expect(stats['testService']['totalRequests'], equals(10));
        expect(stats['testService']['distribution']['instance1'], equals(5));
        expect(stats['testService']['distribution']['instance2'], equals(5));
      });

      test('should track connection counts', () async {
        final instances = [
          ServiceInstance(
              id: 'instance1',
              host: 'host1',
              port: 8001,
              lastHealthCheck: DateTime.now()),
          ServiceInstance(
              id: 'instance2',
              host: 'host2',
              port: 8002,
              lastHealthCheck: DateTime.now()),
        ];

        loadBalancer.registerService('testService', instances);

        // Make requests to create connection imbalance
        await loadBalancer.selectInstance('testService'); // instance1
        await loadBalancer.selectInstance('testService'); // instance2
        await loadBalancer.selectInstance('testService'); // instance1

        final stats = loadBalancer.getLoadBalancingStats();
        expect(
            stats['testService']['connectionCounts']['instance1'], equals(2));
        expect(
            stats['testService']['connectionCounts']['instance2'], equals(1));
      });
    });

    group('Auto-Scaling', () {
      test('should scale up when load is high', () async {
        // Set up scaling policy
        autoScaling.setScalingPolicy(
          'testService',
          maxInstances: 5,
          scaleUpThreshold: 50,
        );

        // Create initial instances
        final initialInstances = [
          ServiceInstance(
              id: 'instance1',
              host: 'host1',
              port: 8001,
              lastHealthCheck: DateTime.now()),
        ];
        autoScaling._serviceInstances['testService'] =
            List.from(initialInstances);
        loadBalancer.registerService('testService', initialInstances);

        // Simulate high load
        for (var i = 0; i < 100; i++) {
          await autoScaling.recordRequest(
              'testService', 'instance1', const Duration(milliseconds: 100));
        }

        // Should have scaled up
        final instances = autoScaling._serviceInstances['testService']!;
        expect(instances.length, greaterThan(1));
      });

      test('should scale down when load is low', () async {
        // Set up scaling policy
        autoScaling.setScalingPolicy(
          'testService',
          maxInstances: 5,
          scaleDownThreshold: 10,
        );

        // Create multiple instances
        final instances = [
          ServiceInstance(
              id: 'instance1',
              host: 'host1',
              port: 8001,
              lastHealthCheck: DateTime.now()),
          ServiceInstance(
              id: 'instance2',
              host: 'host2',
              port: 8002,
              lastHealthCheck: DateTime.now()),
          ServiceInstance(
              id: 'instance3',
              host: 'host3',
              port: 8003,
              lastHealthCheck: DateTime.now()),
        ];
        autoScaling._serviceInstances['testService'] = List.from(instances);
        loadBalancer.registerService('testService', instances);

        // Simulate low load
        for (var i = 0; i < 5; i++) {
          await autoScaling.recordRequest(
              'testService', 'instance1', const Duration(milliseconds: 50));
        }

        // Should have scaled down
        final finalInstances = autoScaling._serviceInstances['testService']!;
        expect(finalInstances.length, lessThan(3));
      });

      test('should respect scaling cooldowns', () async {
        // Set up scaling policy with short cooldown
        autoScaling.setScalingPolicy(
          'testService',
          maxInstances: 5,
          scaleUpThreshold: 50,
          scaleUpCooldown: const Duration(seconds: 1),
        );

        // Create initial instances
        final initialInstances = [
          ServiceInstance(
              id: 'instance1',
              host: 'host1',
              port: 8001,
              lastHealthCheck: DateTime.now()),
        ];
        autoScaling._serviceInstances['testService'] =
            List.from(initialInstances);
        loadBalancer.registerService('testService', initialInstances);

        // Simulate high load
        for (var i = 0; i < 100; i++) {
          await autoScaling.recordRequest(
              'testService', 'instance1', const Duration(milliseconds: 100));
        }

        final initialCount =
            autoScaling._serviceInstances['testService']!.length;

        // Simulate more high load immediately
        for (var i = 0; i < 100; i++) {
          await autoScaling.recordRequest(
              'testService', 'instance1', const Duration(milliseconds: 100));
        }

        // Should not scale up again due to cooldown
        final finalCount = autoScaling._serviceInstances['testService']!.length;
        expect(finalCount, equals(initialCount));
      });
    });

    group('Load Balancing Edge Cases', () {
      test('should handle empty service registration', () async {
        loadBalancer.registerService('emptyService', []);

        final instance = await loadBalancer.selectInstance('emptyService');
        expect(instance, isNull);
      });

      test('should handle service not found', () async {
        final instance =
            await loadBalancer.selectInstance('nonExistentService');
        expect(instance, isNull);
      });

      test('should handle concurrent load balancing requests', () async {
        final instances = [
          ServiceInstance(
              id: 'instance1',
              host: 'host1',
              port: 8001,
              lastHealthCheck: DateTime.now()),
          ServiceInstance(
              id: 'instance2',
              host: 'host2',
              port: 8002,
              lastHealthCheck: DateTime.now()),
        ];

        loadBalancer.registerService('testService', instances);

        // Make concurrent requests
        final futures = <Future>[];
        for (var i = 0; i < 100; i++) {
          futures.add(loadBalancer.selectInstance('testService'));
        }

        final results = await Future.wait(futures);

        // All requests should succeed
        expect(results.length, equals(100));
        expect(results.every((instance) => instance != null), isTrue);
      });

      test('should handle instance weight changes', () async {
        final instances = [
          ServiceInstance(
              id: 'instance1',
              host: 'host1',
              port: 8001,
              lastHealthCheck: DateTime.now()),
          ServiceInstance(
              id: 'instance2',
              host: 'host2',
              port: 8002,
              lastHealthCheck: DateTime.now()),
        ];

        loadBalancer.registerService('testService', instances,
            strategy: LoadBalancingStrategy.weightedRoundRobin);

        // Make some requests
        for (var i = 0; i < 10; i++) {
          await loadBalancer.selectInstance('testService');
        }

        // Update instance weights
        instances[0] = ServiceInstance(
          id: 'instance1',
          host: 'host1',
          port: 8001,
          weight: 3,
          lastHealthCheck: DateTime.now(),
        );

        loadBalancer.registerService('testService', instances,
            strategy: LoadBalancingStrategy.weightedRoundRobin);

        // Make more requests
        final selectedInstances = <String>[];
        for (var i = 0; i < 8; i++) {
          final instance = await loadBalancer.selectInstance('testService');
          selectedInstances.add(instance!.id);
        }

        // Should now favor instance1 due to higher weight
        final instance1Count =
            selectedInstances.where((id) => id == 'instance1').length;
        expect(instance1Count, greaterThan(4)); // Should be more than half
      });
    });
  });
}

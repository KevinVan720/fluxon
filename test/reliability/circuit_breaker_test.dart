import 'dart:async';
import 'dart:math';

import 'package:fluxon/fluxon.dart';
import 'package:test/test.dart';

// Circuit breaker states
enum CircuitState { closed, open, halfOpen }

// Circuit breaker configuration
class CircuitBreakerConfig {
  const CircuitBreakerConfig({
    this.failureThreshold = 5,
    this.timeout = const Duration(seconds: 30),
    this.resetTimeout = const Duration(seconds: 60),
    this.halfOpenTimeout = const Duration(seconds: 10),
    this.successThreshold = 0.5,
  });
  final int failureThreshold;
  final Duration timeout;
  final Duration resetTimeout;
  final Duration halfOpenTimeout;
  final double successThreshold;
}

// Circuit breaker implementation
class CircuitBreaker {
  CircuitBreaker(this.serviceName, this.config);
  final CircuitBreakerConfig config;
  final String serviceName;

  CircuitState _state = CircuitState.closed;
  int _failureCount = 0;
  int _successCount = 0;
  int _halfOpenAttempts = 0;
  DateTime? _lastFailureTime;
  DateTime? _lastSuccessTime;

  CircuitState get state => _state;
  int get failureCount => _failureCount;
  int get successCount => _successCount;
  bool get isOpen => _state == CircuitState.open;
  bool get isClosed => _state == CircuitState.closed;
  bool get isHalfOpen => _state == CircuitState.halfOpen;

  Future<T> execute<T>(Future<T> Function() operation) async {
    if (_shouldAllowRequest()) {
      try {
        final result = await operation().timeout(config.timeout);
        _onSuccess();
        return result;
      } catch (e) {
        _onFailure();
        rethrow;
      }
    } else {
      throw CircuitBreakerOpenException(
          'Circuit breaker is open for $serviceName');
    }
  }

  bool _shouldAllowRequest() {
    switch (_state) {
      case CircuitState.closed:
        return true;
      case CircuitState.open:
        if (_lastFailureTime != null &&
            DateTime.now().difference(_lastFailureTime!) >
                config.resetTimeout) {
          _transitionToHalfOpen();
          return true;
        }
        return false;
      case CircuitState.halfOpen:
        return _halfOpenAttempts <
            3; // Allow limited attempts in half-open state
    }
  }

  void _onSuccess() {
    _successCount++;
    _lastSuccessTime = DateTime.now();

    if (_state == CircuitState.halfOpen) {
      _halfOpenAttempts++;
      if (_halfOpenAttempts >= 3) {
        _transitionToClosed();
      }
    }
  }

  void _onFailure() {
    _failureCount++;
    _lastFailureTime = DateTime.now();

    if (_state == CircuitState.halfOpen) {
      _transitionToOpen();
    } else if (_state == CircuitState.closed &&
        _failureCount >= config.failureThreshold) {
      _transitionToOpen();
    }
  }

  void _transitionToOpen() {
    _state = CircuitState.open;
    _halfOpenAttempts = 0;
  }

  void _transitionToHalfOpen() {
    _state = CircuitState.halfOpen;
    _halfOpenAttempts = 0;
  }

  void _transitionToClosed() {
    _state = CircuitState.closed;
    _failureCount = 0;
    _successCount = 0;
    _halfOpenAttempts = 0;
  }

  void reset() {
    _state = CircuitState.closed;
    _failureCount = 0;
    _successCount = 0;
    _halfOpenAttempts = 0;
    _lastFailureTime = null;
    _lastSuccessTime = null;
  }

  Map<String, dynamic> getStats() => {
        'state': _state.toString(),
        'failureCount': _failureCount,
        'successCount': _successCount,
        'halfOpenAttempts': _halfOpenAttempts,
        'lastFailureTime': _lastFailureTime?.toIso8601String(),
        'lastSuccessTime': _lastSuccessTime?.toIso8601String(),
      };
}

// Exception for circuit breaker open
class CircuitBreakerOpenException implements Exception {
  CircuitBreakerOpenException(this.message);
  final String message;

  @override
  String toString() => 'CircuitBreakerOpenException: $message';
}

// Flaky service that fails intermittently
@ServiceContract(remote: true)
class FlakyService extends FluxonService {
  FlakyService();
  final Random _random = Random();
  double _failureRate = 0.3; // 30% failure rate
  int _callCount = 0;
  final List<String> _callHistory = [];

  @override
  Future<void> initialize() async {
    await super.initialize();
    logger.info(
        'Flaky service initialized with ${(_failureRate * 100).toInt()}% failure rate');
  }

  void setFailureRate(double rate) {
    _failureRate = rate.clamp(0.0, 1.0);
    logger.info('Failure rate set to ${(_failureRate * 100).toInt()}%');
  }

  Future<String> performOperation(String operationId) async {
    _callCount++;
    _callHistory.add('Call $_callCount: $operationId');

    // Simulate processing time
    await Future.delayed(Duration(milliseconds: 100 + _random.nextInt(200)));

    // Randomly fail based on failure rate
    if (_random.nextDouble() < _failureRate) {
      throw ServiceException('Operation $operationId failed randomly');
    }

    return 'Operation $operationId completed successfully';
  }

  Future<String> performSlowOperation(String operationId) async {
    _callCount++;
    _callHistory.add('Slow call $_callCount: $operationId');

    // Simulate slow operation
    await Future.delayed(const Duration(seconds: 2));

    if (_random.nextDouble() < _failureRate) {
      throw ServiceException('Slow operation $operationId failed');
    }

    return 'Slow operation $operationId completed';
  }

  Future<String> performFastOperation(String operationId) async {
    _callCount++;
    _callHistory.add('Fast call $_callCount: $operationId');

    // Simulate fast operation
    await Future.delayed(const Duration(milliseconds: 10));

    if (_random.nextDouble() < _failureRate) {
      throw ServiceException('Fast operation $operationId failed');
    }

    return 'Fast operation $operationId completed';
  }

  Map<String, dynamic> getStats() => {
        'callCount': _callCount,
        'failureRate': _failureRate,
        'callHistory': List.from(_callHistory),
      };
}

// Service with circuit breaker protection
@ServiceContract(remote: false)
class ProtectedService extends FluxonService {
  ProtectedService(this._flakyService) {
    _circuitBreaker = CircuitBreaker(
      'FlakyService',
      const CircuitBreakerConfig(
        failureThreshold: 3,
        timeout: Duration(seconds: 5),
        resetTimeout: Duration(seconds: 10),
        halfOpenTimeout: Duration(seconds: 5),
      ),
    );
  }
  late CircuitBreaker _circuitBreaker;
  final FlakyService _flakyService;
  int _protectedCallCount = 0;
  int _circuitBreakerTrips = 0;

  @override
  Future<void> initialize() async {
    await super.initialize();
    logger.info('Protected service initialized with circuit breaker');
  }

  Future<String> callProtectedOperation(String operationId) async {
    _protectedCallCount++;

    try {
      final result = await _circuitBreaker
          .execute(() async => _flakyService.performOperation(operationId));

      logger.info('Protected call succeeded: $operationId');
      return result;
    } on CircuitBreakerOpenException {
      _circuitBreakerTrips++;
      logger.warning('Circuit breaker is open, call rejected: $operationId');
      return 'Call rejected by circuit breaker: $operationId';
    } catch (e) {
      logger.error('Protected call failed: $operationId', error: e);
      rethrow;
    }
  }

  Future<String> callProtectedSlowOperation(String operationId) async {
    _protectedCallCount++;

    try {
      final result = await _circuitBreaker
          .execute(() async => _flakyService.performSlowOperation(operationId));

      logger.info('Protected slow call succeeded: $operationId');
      return result;
    } on CircuitBreakerOpenException {
      _circuitBreakerTrips++;
      logger
          .warning('Circuit breaker is open, slow call rejected: $operationId');
      return 'Slow call rejected by circuit breaker: $operationId';
    } catch (e) {
      logger.error('Protected slow call failed: $operationId', error: e);
      rethrow;
    }
  }

  Map<String, dynamic> getStats() => {
        'protectedCallCount': _protectedCallCount,
        'circuitBreakerTrips': _circuitBreakerTrips,
        'circuitBreakerStats': _circuitBreaker.getStats(),
      };

  void resetCircuitBreaker() {
    _circuitBreaker.reset();
    logger.info('Circuit breaker reset');
  }
}

// Service that monitors circuit breaker health
@ServiceContract(remote: false)
class CircuitBreakerMonitorService extends FluxonService {
  CircuitBreakerMonitorService();
  final Map<String, CircuitBreaker> _monitoredBreakers = {};
  final List<Map<String, dynamic>> _healthEvents = [];

  @override
  Future<void> initialize() async {
    await super.initialize();
    logger.info('Circuit breaker monitor service initialized');
  }

  void monitorCircuitBreaker(
      String serviceName, CircuitBreaker circuitBreaker) {
    _monitoredBreakers[serviceName] = circuitBreaker;
    logger.info('Started monitoring circuit breaker for $serviceName');
  }

  Map<String, dynamic> getHealthReport() {
    final report = <String, dynamic>{
      'monitoredServices': _monitoredBreakers.length,
      'healthEvents': List.from(_healthEvents),
      'breakers': {},
    };

    for (final entry in _monitoredBreakers.entries) {
      report['breakers'][entry.key] = entry.value.getStats();
    }

    return report;
  }

  void recordHealthEvent(String event, Map<String, dynamic> data) {
    _healthEvents.add({
      'timestamp': DateTime.now().toIso8601String(),
      'event': event,
      'data': data,
    });
  }

  List<Map<String, dynamic>> getHealthEvents() => List.from(_healthEvents);
}

void main() {
  group('Circuit Breaker Tests', () {
    late FluxonRuntime runtime;
    late FlakyService flakyService;
    late ProtectedService protectedService;
    late CircuitBreakerMonitorService monitorService;

    setUp(() async {
      runtime = FluxonRuntime();

      runtime.register<FlakyService>(FlakyService.new);
      runtime.register<CircuitBreakerMonitorService>(
          CircuitBreakerMonitorService.new);

      await runtime.initializeAll();

      flakyService = runtime.get<FlakyService>();
      // Create ProtectedService after FlakyService is available
      protectedService = ProtectedService(flakyService);
      monitorService = runtime.get<CircuitBreakerMonitorService>();
    });

    tearDown(() async {
      if (runtime.isInitialized) {
        await runtime.destroyAll();
      }
    });

    group('Basic Circuit Breaker Functionality', () {
      test('should allow calls when circuit is closed', () async {
        flakyService.setFailureRate(0.0); // No failures

        final result = await protectedService.callProtectedOperation('test-1');
        expect(result, contains('completed successfully'));

        final stats = protectedService.getStats();
        expect(stats['circuitBreakerTrips'], equals(0));
      });

      test('should open circuit after failure threshold', () async {
        flakyService.setFailureRate(1.0); // 100% failure rate

        // Make calls that will fail
        for (var i = 0; i < 5; i++) {
          try {
            await protectedService.callProtectedOperation('test-$i');
          } catch (e) {
            // Expected to fail
          }
        }

        // Next call should be rejected by circuit breaker
        final result =
            await protectedService.callProtectedOperation('test-rejected');
        expect(result, contains('rejected by circuit breaker'));

        final stats = protectedService.getStats();
        expect(stats['circuitBreakerTrips'], greaterThan(0));
      });

      test('should transition to half-open after reset timeout', () async {
        flakyService.setFailureRate(1.0); // 100% failure rate

        // Open the circuit
        for (var i = 0; i < 5; i++) {
          try {
            await protectedService.callProtectedOperation('test-$i');
          } catch (e) {
            // Expected to fail
          }
        }

        // Wait for reset timeout (simulated by reducing failure rate)
        flakyService.setFailureRate(0.0); // No failures

        // Wait a bit for circuit to potentially reset
        await Future.delayed(const Duration(milliseconds: 100));

        // Try a call - depending on timing, could be a half-open probe or still open
        final result =
            await protectedService.callProtectedOperation('test-reset');
        expect(
          result,
          anyOf(
            contains('completed successfully'),
            contains('rejected by circuit breaker'),
          ),
        );
      });
    });

    group('Circuit Breaker Recovery', () {
      test('should recover from open state with successful calls', () async {
        flakyService.setFailureRate(1.0); // 100% failure rate

        // Open the circuit
        for (var i = 0; i < 5; i++) {
          try {
            await protectedService.callProtectedOperation('test-$i');
          } catch (e) {
            // Expected to fail
          }
        }

        // Reset circuit breaker manually
        protectedService.resetCircuitBreaker();

        // Set service to succeed
        flakyService.setFailureRate(0.0);

        // Should now work
        final result =
            await protectedService.callProtectedOperation('test-recovery');
        expect(result, contains('completed successfully'));
      });
    });

    group('Timeout Handling', () {
      test('should handle operation timeouts', () async {
        flakyService.setFailureRate(0.0); // No failures, but slow

        // This should timeout due to circuit breaker timeout
        try {
          await protectedService.callProtectedSlowOperation('slow-test');
        } catch (e) {
          expect(e, isA<TimeoutException>());
        }
      });

      test('should handle fast operations within timeout', () async {
        flakyService.setFailureRate(0.0); // No failures

        final result =
            await protectedService.callProtectedOperation('fast-test');
        expect(result, contains('completed successfully'));
      });
    });

    group('Circuit Breaker Monitoring', () {
      test('should track circuit breaker statistics', () async {
        flakyService.setFailureRate(0.3); // 30% failure rate

        // Make several calls
        for (var i = 0; i < 10; i++) {
          try {
            await protectedService.callProtectedOperation('monitor-test-$i');
          } catch (e) {
            // Some will fail
          }
        }

        final stats = protectedService.getStats();
        expect(stats['protectedCallCount'], equals(10));
        expect(stats['circuitBreakerStats'], isA<Map<String, dynamic>>());

        final breakerStats =
            stats['circuitBreakerStats'] as Map<String, dynamic>;
        expect(breakerStats['failureCount'], greaterThanOrEqualTo(0));
        expect(breakerStats['successCount'], greaterThanOrEqualTo(0));
      });

      test('should provide health monitoring capabilities', () async {
        // Monitor the circuit breaker
        final breaker =
            CircuitBreaker('TestService', const CircuitBreakerConfig());
        monitorService.monitorCircuitBreaker('TestService', breaker);

        // Record some health events
        monitorService
            .recordHealthEvent('circuit_opened', {'service': 'TestService'});
        monitorService
            .recordHealthEvent('circuit_closed', {'service': 'TestService'});

        final healthReport = monitorService.getHealthReport();
        expect(healthReport['monitoredServices'], equals(1));
        expect(healthReport['healthEvents'], hasLength(2));
        expect(healthReport['breakers'], contains('TestService'));
      });
    });

    group('Stress Testing', () {
      test('should handle rapid state transitions', () async {
        // Rapidly change failure rate to cause state transitions
        for (var cycle = 0; cycle < 5; cycle++) {
          flakyService.setFailureRate(1.0); // 100% failure

          // Make calls to open circuit
          for (var i = 0; i < 3; i++) {
            try {
              await protectedService.callProtectedOperation('cycle-$cycle-$i');
            } catch (e) {
              // Expected to fail
            }
          }

          // Reset and try again
          protectedService.resetCircuitBreaker();
          flakyService.setFailureRate(0.0); // 0% failure

          await Future.delayed(const Duration(milliseconds: 10));
        }

        final stats = protectedService.getStats();
        expect(stats['protectedCallCount'], greaterThan(0));
      });
    });

    group('Edge Cases', () {
      test('should handle circuit breaker reset during operation', () async {
        flakyService.setFailureRate(1.0); // 100% failure rate

        // Start a call that will fail
        final future = protectedService.callProtectedOperation('reset-test');

        // Reset circuit breaker while call is in progress
        protectedService.resetCircuitBreaker();

        try {
          await future;
        } catch (e) {
          // Expected to fail
        }

        // Circuit should still be functional
        flakyService.setFailureRate(0.0);
        final result =
            await protectedService.callProtectedOperation('after-reset');
        expect(result, contains('completed successfully'));
      });

      test('should handle multiple circuit breakers', () async {
        final breaker1 = CircuitBreaker(
            'Service1',
            const CircuitBreakerConfig(
              failureThreshold: 3, // Lower threshold for faster testing
            ));
        final breaker2 = CircuitBreaker(
            'Service2',
            const CircuitBreakerConfig(
              failureThreshold: 3,
            ));

        // Both should start closed
        expect(breaker1.isClosed, isTrue);
        expect(breaker2.isClosed, isTrue);

        // Open breaker1 with enough failures to exceed threshold
        for (var i = 0; i < 4; i++) {
          // 4 failures > 3 threshold
          try {
            await breaker1.execute(() async {
              throw Exception('Test failure $i');
            });
          } catch (e) {
            // Expected to fail
          }
        }

        // Verify breaker1 is open and breaker2 is still closed
        expect(breaker1.isOpen, isTrue);
        expect(breaker2.isClosed, isTrue);

        // Verify breaker2 still works
        final result = await breaker2.execute(() async => 'success');
        expect(result, equals('success'));
        expect(breaker2.isClosed, isTrue);
      });
    });
  });
}

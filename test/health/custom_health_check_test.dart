import 'package:fluxon/src/base_service.dart';
import 'package:fluxon/src/fluxon_runtime.dart';
import 'package:fluxon/src/models/service_models.dart';
import 'package:fluxon/src/service_logger.dart';
import 'package:test/test.dart';

// Service with custom health check that includes uptime
class UptimeHealthService extends BaseService {
  UptimeHealthService({ServiceLogger? logger}) : super(logger: logger);

  late DateTime _startTime;
  bool _isHealthy = true;
  String? _customMessage;
  final Map<String, dynamic> _customMetrics = {};

  @override
  List<Type> get dependencies => const [];

  @override
  Future<void> initialize() async {
    _startTime = DateTime.now();
    _customMetrics['initializationTime'] = _startTime.toIso8601String();
    await super.initialize();
  }

  Duration get upTime => DateTime.now().difference(_startTime);

  void setHealthy(bool healthy, [String? message]) {
    _isHealthy = healthy;
    _customMessage = message;
  }

  void addCustomMetric(String key, dynamic value) {
    _customMetrics[key] = value;
  }

  @override
  Future<ServiceHealthCheck> healthCheck() async {
    final currentUptime = upTime;

    return ServiceHealthCheck(
      status: _isHealthy
          ? ServiceHealthStatus.healthy
          : ServiceHealthStatus.unhealthy,
      timestamp: DateTime.now(),
      message: _customMessage ??
          (_isHealthy ? 'Service running normally' : 'Service is unhealthy'),
      details: {
        'uptime': currentUptime.inSeconds,
        'uptimeFormatted': _formatDuration(currentUptime),
        'startTime': _startTime.toIso8601String(),
        'customMetrics': Map<String, dynamic>.from(_customMetrics),
      },
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    return '${hours}h ${minutes}m ${seconds}s';
  }
}

// Service with degraded health status
class DegradedHealthService extends BaseService {
  DegradedHealthService() : super();

  int _errorCount = 0;
  int _warningCount = 0;
  final List<String> _recentErrors = [];

  @override
  List<Type> get dependencies => const [];

  @override
  Future<void> initialize() async {
    await super.initialize();
  }

  void recordError(String error) {
    _errorCount++;
    _recentErrors.add(error);
    if (_recentErrors.length > 10) {
      _recentErrors.removeAt(0);
    }
  }

  void recordWarning() {
    _warningCount++;
  }

  @override
  Future<ServiceHealthCheck> healthCheck() async {
    ServiceHealthStatus status;
    String message;

    if (_errorCount == 0 && _warningCount == 0) {
      status = ServiceHealthStatus.healthy;
      message = 'All systems operational';
    } else if (_errorCount == 0 && _warningCount > 0) {
      status = ServiceHealthStatus.degraded;
      message = 'Service operational with warnings';
    } else if (_errorCount < 5) {
      status = ServiceHealthStatus.degraded;
      message = 'Service experiencing minor issues';
    } else {
      status = ServiceHealthStatus.unhealthy;
      message = 'Service experiencing critical issues';
    }

    return ServiceHealthCheck(
      status: status,
      timestamp: DateTime.now(),
      message: message,
      details: {
        'errorCount': _errorCount,
        'warningCount': _warningCount,
        'recentErrors': List<String>.from(_recentErrors),
        'healthScore': _calculateHealthScore(),
      },
    );
  }

  double _calculateHealthScore() {
    if (_errorCount == 0 && _warningCount == 0) return 1.0;
    if (_errorCount >= 10) return 0.0;

    final errorPenalty = _errorCount * 0.1;
    final warningPenalty = _warningCount * 0.02;
    return (1.0 - errorPenalty - warningPenalty).clamp(0.0, 1.0);
  }
}

// Service that simulates async health check with external dependencies
class ExternalDependencyHealthService extends BaseService {
  ExternalDependencyHealthService() : super();

  bool _databaseConnected = true;
  bool _cacheConnected = true;
  bool _apiConnected = true;
  Duration _lastResponseTime = const Duration(milliseconds: 50);

  @override
  List<Type> get dependencies => const [];

  @override
  Future<void> initialize() async {
    await super.initialize();
  }

  void setDatabaseConnection(bool connected) => _databaseConnected = connected;
  void setCacheConnection(bool connected) => _cacheConnected = connected;
  void setApiConnection(bool connected) => _apiConnected = connected;
  void setResponseTime(Duration responseTime) =>
      _lastResponseTime = responseTime;

  @override
  Future<ServiceHealthCheck> healthCheck() async {
    // Simulate async health check
    await Future.delayed(const Duration(milliseconds: 10));

    final connectedServices = [
      if (_databaseConnected) 'database',
      if (_cacheConnected) 'cache',
      if (_apiConnected) 'api',
    ];

    final disconnectedServices = [
      if (!_databaseConnected) 'database',
      if (!_cacheConnected) 'cache',
      if (!_apiConnected) 'api',
    ];

    ServiceHealthStatus status;
    String message;

    if (disconnectedServices.isEmpty) {
      status = ServiceHealthStatus.healthy;
      message = 'All external dependencies connected';
    } else if (disconnectedServices.length == 1 &&
        !disconnectedServices.contains('database')) {
      status = ServiceHealthStatus.degraded;
      message = 'Some non-critical dependencies disconnected';
    } else {
      status = ServiceHealthStatus.unhealthy;
      message = 'Critical dependencies disconnected';
    }

    return ServiceHealthCheck(
      status: status,
      timestamp: DateTime.now(),
      message: message,
      details: {
        'connectedServices': connectedServices,
        'disconnectedServices': disconnectedServices,
        'lastResponseTime': _lastResponseTime.inMilliseconds,
        'performanceStatus':
            _lastResponseTime.inMilliseconds < 100 ? 'good' : 'slow',
      },
      duration: const Duration(milliseconds: 10),
    );
  }
}

void main() {
  group('Custom Health Check Implementation', () {
    group('UptimeHealthService', () {
      late UptimeHealthService service;

      setUp(() async {
        service = UptimeHealthService();
        await service.internalInitialize();
        // Wait a bit to ensure uptime > 0
        await Future.delayed(const Duration(milliseconds: 10));
      });

      tearDown(() async {
        await service.internalDestroy();
      });

      test('should include uptime in health check details', () async {
        // Wait a bit to ensure uptime > 0
        await Future.delayed(const Duration(milliseconds: 50));

        final healthCheck = await service.healthCheck();

        expect(healthCheck.status, equals(ServiceHealthStatus.healthy));
        expect(healthCheck.details['uptime'], isA<int>());
        expect(healthCheck.details['uptime'], greaterThanOrEqualTo(0));
        expect(healthCheck.details['uptimeFormatted'], isA<String>());
        expect(healthCheck.details['startTime'], isA<String>());
      });

      test('should report unhealthy when set to unhealthy', () async {
        service.setHealthy(false, 'Custom error message');

        final healthCheck = await service.healthCheck();

        expect(healthCheck.status, equals(ServiceHealthStatus.unhealthy));
        expect(healthCheck.message, equals('Custom error message'));
      });

      test('should include custom metrics', () async {
        service.addCustomMetric('requestCount', 42);
        service.addCustomMetric('averageResponseTime', 123.45);
        service.addCustomMetric('lastError', null);

        final healthCheck = await service.healthCheck();

        expect(
            healthCheck.details['customMetrics']['requestCount'], equals(42));
        expect(healthCheck.details['customMetrics']['averageResponseTime'],
            equals(123.45));
        expect(healthCheck.details['customMetrics']['lastError'], isNull);
      });

      test('should track uptime correctly over time', () async {
        await Future.delayed(const Duration(milliseconds: 50));
        final firstCheck = await service.healthCheck();
        await Future.delayed(const Duration(milliseconds: 100));
        final secondCheck = await service.healthCheck();

        expect(secondCheck.details['uptime'],
            greaterThanOrEqualTo(firstCheck.details['uptime']));
      });
    });

    group('DegradedHealthService', () {
      late DegradedHealthService service;

      setUp(() async {
        service = DegradedHealthService();
        await service.internalInitialize();
      });

      tearDown(() async {
        await service.internalDestroy();
      });

      test('should report healthy with no errors or warnings', () async {
        final healthCheck = await service.healthCheck();

        expect(healthCheck.status, equals(ServiceHealthStatus.healthy));
        expect(healthCheck.message, equals('All systems operational'));
        expect(healthCheck.details['errorCount'], equals(0));
        expect(healthCheck.details['warningCount'], equals(0));
        expect(healthCheck.details['healthScore'], equals(1.0));
      });

      test('should report degraded with warnings only', () async {
        service.recordWarning();
        service.recordWarning();

        final healthCheck = await service.healthCheck();

        expect(healthCheck.status, equals(ServiceHealthStatus.degraded));
        expect(
            healthCheck.message, equals('Service operational with warnings'));
        expect(healthCheck.details['warningCount'], equals(2));
        expect(healthCheck.details['healthScore'], lessThan(1.0));
      });

      test('should report degraded with few errors', () async {
        service.recordError('Connection timeout');
        service.recordError('Validation failed');

        final healthCheck = await service.healthCheck();

        expect(healthCheck.status, equals(ServiceHealthStatus.degraded));
        expect(
            healthCheck.message, equals('Service experiencing minor issues'));
        expect(healthCheck.details['errorCount'], equals(2));
        expect(healthCheck.details['recentErrors'], hasLength(2));
      });

      test('should report unhealthy with many errors', () async {
        for (int i = 0; i < 6; i++) {
          service.recordError('Error $i');
        }

        final healthCheck = await service.healthCheck();

        expect(healthCheck.status, equals(ServiceHealthStatus.unhealthy));
        expect(healthCheck.message,
            equals('Service experiencing critical issues'));
        expect(healthCheck.details['errorCount'], equals(6));
        expect(healthCheck.details['healthScore'], lessThan(0.5));
      });

      test('should limit recent errors to 10', () async {
        for (int i = 0; i < 15; i++) {
          service.recordError('Error $i');
        }

        final healthCheck = await service.healthCheck();

        expect(healthCheck.details['errorCount'], equals(15));
        expect(healthCheck.details['recentErrors'], hasLength(10));
        expect(healthCheck.details['recentErrors'].first,
            equals('Error 5')); // Oldest kept
        expect(healthCheck.details['recentErrors'].last,
            equals('Error 14')); // Newest
      });
    });

    group('ExternalDependencyHealthService', () {
      late ExternalDependencyHealthService service;

      setUp(() async {
        service = ExternalDependencyHealthService();
        await service.internalInitialize();
      });

      tearDown(() async {
        await service.internalDestroy();
      });

      test('should report healthy with all dependencies connected', () async {
        final healthCheck = await service.healthCheck();

        expect(healthCheck.status, equals(ServiceHealthStatus.healthy));
        expect(
            healthCheck.message, equals('All external dependencies connected'));
        expect(healthCheck.details['connectedServices'], hasLength(3));
        expect(healthCheck.details['disconnectedServices'], isEmpty);
        expect(healthCheck.duration, isNotNull);
      });

      test('should report degraded with non-critical dependency down',
          () async {
        service.setCacheConnection(false);

        final healthCheck = await service.healthCheck();

        expect(healthCheck.status, equals(ServiceHealthStatus.degraded));
        expect(healthCheck.message,
            equals('Some non-critical dependencies disconnected'));
        expect(healthCheck.details['connectedServices'], hasLength(2));
        expect(healthCheck.details['disconnectedServices'], equals(['cache']));
      });

      test('should report unhealthy with database down', () async {
        service.setDatabaseConnection(false);

        final healthCheck = await service.healthCheck();

        expect(healthCheck.status, equals(ServiceHealthStatus.unhealthy));
        expect(
            healthCheck.message, equals('Critical dependencies disconnected'));
        expect(
            healthCheck.details['disconnectedServices'], contains('database'));
      });

      test('should include performance metrics', () async {
        service.setResponseTime(const Duration(milliseconds: 250));

        final healthCheck = await service.healthCheck();

        expect(healthCheck.details['lastResponseTime'], equals(250));
        expect(healthCheck.details['performanceStatus'], equals('slow'));
      });

      test('should report good performance with fast response times', () async {
        service.setResponseTime(const Duration(milliseconds: 50));

        final healthCheck = await service.healthCheck();

        expect(healthCheck.details['performanceStatus'], equals('good'));
      });
    });

    group('Runtime Health Checks', () {
      late FluxonRuntime runtime;

      setUp(() {
        runtime = FluxonRuntime();
      });

      tearDown(() async {
        if (runtime.isInitialized) {
          await runtime.destroyAll();
        }
      });

      test('should aggregate custom health checks from multiple services',
          () async {
        runtime.register<UptimeHealthService>(UptimeHealthService.new);
        runtime.register<DegradedHealthService>(DegradedHealthService.new);
        runtime.register<ExternalDependencyHealthService>(
            ExternalDependencyHealthService.new);

        await runtime.initializeAll();

        // Modify some services to have different health states
        final degradedService = runtime.get<DegradedHealthService>();
        degradedService.recordWarning();
        degradedService.recordError('Test error');

        final externalService = runtime.get<ExternalDependencyHealthService>();
        externalService.setCacheConnection(false);

        final healthChecks = await runtime.performHealthChecks();

        expect(healthChecks, hasLength(3));
        expect(healthChecks['UptimeHealthService']?.status,
            equals(ServiceHealthStatus.healthy));
        expect(healthChecks['DegradedHealthService']?.status,
            equals(ServiceHealthStatus.degraded));
        expect(healthChecks['ExternalDependencyHealthService']?.status,
            equals(ServiceHealthStatus.degraded));

        // Verify custom details are preserved
        expect(
            healthChecks['UptimeHealthService']?.details['uptime'], isNotNull);
        expect(healthChecks['DegradedHealthService']?.details['errorCount'],
            equals(1));
        expect(
            healthChecks['ExternalDependencyHealthService']
                ?.details['disconnectedServices'],
            contains('cache'));
      });

      test('should handle health check failures gracefully', () async {
        final failingService = FailingHealthCheckService();
        runtime.register<FailingHealthCheckService>(() => failingService);
        await runtime.initializeAll();

        final healthChecks = await runtime.performHealthChecks();

        expect(healthChecks, hasLength(1));
        expect(healthChecks['FailingHealthCheckService']?.status,
            equals(ServiceHealthStatus.unhealthy));
        expect(healthChecks['FailingHealthCheckService']?.message,
            contains('Health check failed'));
      });
    });
  });
}

// Service that throws an exception during health check
class FailingHealthCheckService extends BaseService {
  FailingHealthCheckService() : super();

  @override
  List<Type> get dependencies => const [];

  @override
  Future<void> initialize() async {
    await super.initialize();
  }

  @override
  Future<ServiceHealthCheck> healthCheck() async {
    throw Exception('Health check intentionally failed');
  }
}

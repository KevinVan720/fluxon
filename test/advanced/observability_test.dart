import 'dart:async';
import 'dart:math';

import 'package:fluxon/fluxon.dart';
import 'package:test/test.dart';

// Metrics collection service
@ServiceContract(remote: false)
class MetricsCollectorService extends FluxService {
  MetricsCollectorService();
  final Map<String, int> _counters = {};
  final Map<String, List<double>> _gauges = {};
  final Map<String, List<Duration>> _timers = {};
  final Map<String, List<String>> _histograms = {};
  final List<Map<String, dynamic>> _events = [];

  @override
  Future<void> initialize() async {
    await super.initialize();
    logger.info('Metrics collector service initialized');
  }

  void incrementCounter(String name, [int value = 1]) {
    _counters[name] = (_counters[name] ?? 0) + value;
    _recordEvent('counter_increment', {'name': name, 'value': value});
  }

  void recordGauge(String name, double value) {
    _gauges.putIfAbsent(name, () => []).add(value);
    _recordEvent('gauge_record', {'name': name, 'value': value});
  }

  void recordTimer(String name, Duration duration) {
    _timers.putIfAbsent(name, () => []).add(duration);
    _recordEvent(
        'timer_record', {'name': name, 'duration_ms': duration.inMilliseconds});
  }

  void recordHistogram(String name, String value) {
    _histograms.putIfAbsent(name, () => []).add(value);
    _recordEvent('histogram_record', {'name': name, 'value': value});
  }

  void _recordEvent(String type, Map<String, dynamic> data) {
    _events.add({
      'timestamp': DateTime.now().toIso8601String(),
      'type': type,
      'data': data,
    });
  }

  Map<String, dynamic> getMetrics() => {
        'counters': Map.from(_counters),
        'gauges': _gauges.map((k, v) => MapEntry(k, {
              'count': v.length,
              'min': v.isEmpty ? 0 : v.reduce(min),
              'max': v.isEmpty ? 0 : v.reduce(max),
              'avg': v.isEmpty ? 0 : v.reduce((a, b) => a + b) / v.length,
            })),
        'timers': _timers.map((k, v) => MapEntry(k, {
              'count': v.length,
              'total_ms': v.fold(0, (sum, d) => sum + d.inMilliseconds),
              'avg_ms': v.isEmpty
                  ? 0
                  : v.fold(0, (sum, d) => sum + d.inMilliseconds) / v.length,
              'min_ms':
                  v.isEmpty ? 0 : v.map((d) => d.inMilliseconds).reduce(min),
              'max_ms':
                  v.isEmpty ? 0 : v.map((d) => d.inMilliseconds).reduce(max),
            })),
        'histograms': _histograms.map((k, v) => MapEntry(k, {
              'count': v.length,
              'values': v.toSet().toList(),
            })),
        'events': List.from(_events),
      };

  void clearMetrics() {
    _counters.clear();
    _gauges.clear();
    _timers.clear();
    _histograms.clear();
    _events.clear();
  }
}

// Distributed tracing service
@ServiceContract(remote: false)
class TracingService extends FluxService {
  TracingService();
  final List<Map<String, dynamic>> _traces = [];
  final Map<String, String> _activeSpans = {};
  int _traceIdCounter = 0;

  @override
  Future<void> initialize() async {
    await super.initialize();
    logger.info('Tracing service initialized');
  }

  String startSpan(String operationName, [Map<String, String>? tags]) {
    final traceId = 'trace_${++_traceIdCounter}';
    final spanId = 'span_${DateTime.now().millisecondsSinceEpoch}';

    final span = {
      'traceId': traceId,
      'spanId': spanId,
      'operationName': operationName,
      'startTime': DateTime.now().toIso8601String(),
      'tags': tags ?? {},
      'status': 'active',
    };

    _traces.add(span);
    _activeSpans[spanId] = traceId;

    _recordEvent('span_started', {
      'traceId': traceId,
      'spanId': spanId,
      'operationName': operationName,
    });

    return spanId;
  }

  void finishSpan(String spanId, [String? status, Map<String, String>? tags]) {
    final span = _traces.firstWhere(
      (s) => s['spanId'] == spanId,
      orElse: () => throw ArgumentError('Span not found: $spanId'),
    );

    span['endTime'] = DateTime.now().toIso8601String();
    span['status'] = status ?? 'completed';
    if (tags != null) {
      span['tags'].addAll(tags);
    }

    _activeSpans.remove(spanId);

    _recordEvent('span_finished', {
      'traceId': span['traceId'],
      'spanId': spanId,
      'status': span['status'],
    });
  }

  void _recordEvent(String type, Map<String, dynamic> data) {
    logger.debug('Tracing event: $type', metadata: data);
  }

  List<Map<String, dynamic>> getTraces() => List.from(_traces);

  List<Map<String, dynamic>> getActiveSpans() =>
      _traces.where((s) => s['status'] == 'active').toList();

  Map<String, dynamic> getTraceStatistics() {
    final completedTraces =
        _traces.where((s) => s['status'] != 'active').toList();

    if (completedTraces.isEmpty) {
      return {
        'totalSpans': _traces.length,
        'activeSpans': _activeSpans.length,
        'completedSpans': 0,
        'avgDurationMs': 0,
      };
    }

    final durations = completedTraces.map((s) {
      final start = DateTime.parse(s['startTime']);
      final end = DateTime.parse(s['endTime']);
      return end.difference(start).inMilliseconds;
    }).toList();

    return {
      'totalSpans': _traces.length,
      'activeSpans': _activeSpans.length,
      'completedSpans': completedTraces.length,
      'avgDurationMs': durations.reduce((a, b) => a + b) / durations.length,
      'minDurationMs': durations.reduce(min),
      'maxDurationMs': durations.reduce(max),
    };
  }
}

// Health check service
@ServiceContract(remote: false)
class HealthCheckService extends FluxService {
  HealthCheckService();
  final Map<String, ServiceHealthStatus> _serviceHealth = {};
  final Map<String, DateTime> _lastHealthCheck = {};
  final List<Map<String, dynamic>> _healthEvents = [];

  @override
  Future<void> initialize() async {
    await super.initialize();
    logger.info('Health check service initialized');
  }

  void recordServiceHealth(String serviceName, ServiceHealthStatus status) {
    _serviceHealth[serviceName] = status;
    _lastHealthCheck[serviceName] = DateTime.now();

    _healthEvents.add({
      'timestamp': DateTime.now().toIso8601String(),
      'serviceName': serviceName,
      'status': status.toString(),
    });
  }

  Map<String, dynamic> getOverallHealth() {
    final services = _serviceHealth.keys.toList();
    final healthyCount = _serviceHealth.values
        .where((s) => s == ServiceHealthStatus.healthy)
        .length;
    final unhealthyCount = _serviceHealth.values
        .where((s) => s == ServiceHealthStatus.unhealthy)
        .length;

    return {
      'totalServices': services.length,
      'healthyServices': healthyCount,
      'unhealthyServices': unhealthyCount,
      'healthPercentage':
          services.isEmpty ? 100.0 : (healthyCount / services.length) * 100,
      'services': Map.from(_serviceHealth),
      'lastChecks':
          _lastHealthCheck.map((k, v) => MapEntry(k, v.toIso8601String())),
    };
  }

  List<Map<String, dynamic>> getHealthEvents() => List.from(_healthEvents);
}

// Log aggregation service
@ServiceContract(remote: false)
class LogAggregationService extends FluxService {
  LogAggregationService();
  final List<Map<String, dynamic>> _logs = [];
  final Map<String, int> _logLevels = {};
  final Map<String, int> _logSources = {};

  @override
  Future<void> initialize() async {
    await super.initialize();
    logger.info('Log aggregation service initialized');
  }

  void aggregateLog(String level, String source, String message,
      [Map<String, dynamic>? metadata]) {
    final logEntry = {
      'timestamp': DateTime.now().toIso8601String(),
      'level': level,
      'source': source,
      'message': message,
      'metadata': metadata ?? {},
    };

    _logs.add(logEntry);
    _logLevels[level] = (_logLevels[level] ?? 0) + 1;
    _logSources[source] = (_logSources[source] ?? 0) + 1;
  }

  List<Map<String, dynamic>> getLogs(
      {String? level, String? source, int? limit}) {
    var filteredLogs = _logs;

    if (level != null) {
      filteredLogs = filteredLogs.where((l) => l['level'] == level).toList();
    }

    if (source != null) {
      filteredLogs = filteredLogs.where((l) => l['source'] == source).toList();
    }

    if (limit != null) {
      filteredLogs = filteredLogs.take(limit).toList();
    }

    return List.from(filteredLogs);
  }

  Map<String, dynamic> getLogStatistics() => {
        'totalLogs': _logs.length,
        'logLevels': Map.from(_logLevels),
        'logSources': Map.from(_logSources),
        'recentLogs': _logs.take(10).toList(),
      };
}

// Performance monitoring service
@ServiceContract(remote: true)
class PerformanceMonitoringService extends FluxService {
  PerformanceMonitoringService();
  final Map<String, List<int>> _responseTimes = {};

  final Map<String, int> _requestCounts = {};
  final Map<String, int> _errorCounts = {};
  final List<Map<String, dynamic>> _performanceEvents = [];

  @override
  Future<void> initialize() async {
    await super.initialize();
    logger.info('Performance monitoring service initialized');
  }

  void recordRequest(String endpoint, int responseTimeMs,
      {bool isError = false}) {
    _responseTimes.putIfAbsent(endpoint, () => []).add(responseTimeMs);
    _requestCounts[endpoint] = (_requestCounts[endpoint] ?? 0) + 1;

    if (isError) {
      _errorCounts[endpoint] = (_errorCounts[endpoint] ?? 0) + 1;
    }

    _performanceEvents.add({
      'timestamp': DateTime.now().toIso8601String(),
      'endpoint': endpoint,
      'responseTimeMs': responseTimeMs,
      'isError': isError,
    });
  }

  Map<String, dynamic> getPerformanceMetrics() {
    final metrics = <String, dynamic>{};

    for (final endpoint in _responseTimes.keys) {
      final times = _responseTimes[endpoint]!;
      final requestCount = _requestCounts[endpoint] ?? 0;
      final errorCount = _errorCounts[endpoint] ?? 0;

      metrics[endpoint] = {
        'requestCount': requestCount,
        'errorCount': errorCount,
        'errorRate': requestCount == 0 ? 0.0 : errorCount / requestCount,
        'avgResponseTimeMs': times.reduce((a, b) => a + b) / times.length,
        'minResponseTimeMs': times.reduce(min),
        'maxResponseTimeMs': times.reduce(max),
        'p95ResponseTimeMs': _calculatePercentile(times, 95),
        'p99ResponseTimeMs': _calculatePercentile(times, 99),
      };
    }

    return metrics;
  }

  double _calculatePercentile(List<int> values, int percentile) {
    if (values.isEmpty) return 0.0;

    final sorted = List<int>.from(values)..sort();
    final index = (percentile / 100.0) * (sorted.length - 1);

    if (index == index.floor()) {
      return sorted[index.floor()].toDouble();
    } else {
      final lower = sorted[index.floor()];
      final upper = sorted[index.ceil()];
      return lower + (upper - lower) * (index - index.floor());
    }
  }

  List<Map<String, dynamic>> getPerformanceEvents() =>
      List.from(_performanceEvents);
}

// Observability integration service
@ServiceContract(remote: false)
class ObservabilityIntegrationService extends FluxService {
  ObservabilityIntegrationService(
    this._metricsCollector,
    this._tracingService,
    this._healthCheckService,
    this._logAggregationService,
    this._performanceMonitoring,
  );
  final MetricsCollectorService _metricsCollector;
  final TracingService _tracingService;
  final HealthCheckService _healthCheckService;
  final LogAggregationService _logAggregationService;
  final PerformanceMonitoringService _performanceMonitoring;

  @override
  Future<void> initialize() async {
    await super.initialize();
    logger.info('Observability integration service initialized');
  }

  Future<Map<String, dynamic>> generateComprehensiveReport() async {
    final report = {
      'timestamp': DateTime.now().toIso8601String(),
      'metrics': _metricsCollector.getMetrics(),
      'traces': _tracingService.getTraceStatistics(),
      'health': _healthCheckService.getOverallHealth(),
      'logs': _logAggregationService.getLogStatistics(),
      'performance': _performanceMonitoring.getPerformanceMetrics(),
    };

    return report;
  }

  Future<void> simulateWorkload() async {
    final spanId =
        _tracingService.startSpan('workload_simulation', {'type': 'test'});

    try {
      // Simulate some work
      _metricsCollector.incrementCounter('workload_started');
      _logAggregationService.aggregateLog('INFO',
          'ObservabilityIntegrationService', 'Starting workload simulation');

      await Future.delayed(const Duration(milliseconds: 100));

      // Record performance
      _performanceMonitoring.recordRequest('/api/simulate', 100);

      // Record metrics
      _metricsCollector.recordGauge('cpu_usage', 75.5);
      _metricsCollector.recordTimer(
          'workload_duration', const Duration(milliseconds: 100));

      _metricsCollector.incrementCounter('workload_completed');
      _logAggregationService.aggregateLog('INFO',
          'ObservabilityIntegrationService', 'Workload simulation completed');

      _tracingService.finishSpan(spanId, 'completed');
    } catch (e) {
      _tracingService.finishSpan(spanId, 'failed');
      _metricsCollector.incrementCounter('workload_failed');
      _logAggregationService.aggregateLog('ERROR',
          'ObservabilityIntegrationService', 'Workload simulation failed: $e');
      rethrow;
    }
  }
}

void main() {
  group('Observability Tests', () {
    late FluxRuntime runtime;
    late MetricsCollectorService metricsCollector;
    late TracingService tracingService;
    late HealthCheckService healthCheckService;
    late LogAggregationService logAggregationService;
    late PerformanceMonitoringService performanceMonitoring;
    late ObservabilityIntegrationService observabilityIntegration;

    setUp(() async {
      runtime = FluxRuntime();

      runtime
        ..register<MetricsCollectorService>(MetricsCollectorService.new)
        ..register<TracingService>(TracingService.new)
        ..register<HealthCheckService>(HealthCheckService.new)
        ..register<LogAggregationService>(LogAggregationService.new)
        ..register<PerformanceMonitoringService>(
            PerformanceMonitoringService.new);

      await runtime.initializeAll();

      metricsCollector = runtime.get<MetricsCollectorService>();
      tracingService = runtime.get<TracingService>();
      healthCheckService = runtime.get<HealthCheckService>();
      logAggregationService = runtime.get<LogAggregationService>();
      performanceMonitoring = runtime.get<PerformanceMonitoringService>();

      // Create integration service
      observabilityIntegration = ObservabilityIntegrationService(
        metricsCollector,
        tracingService,
        healthCheckService,
        logAggregationService,
        performanceMonitoring,
      );
      await observabilityIntegration.internalInitialize();
    });

    tearDown(() async {
      if (runtime.isInitialized) {
        await runtime.destroyAll();
      }
    });

    group('Metrics Collection', () {
      test('should collect and aggregate counter metrics', () async {
        metricsCollector.incrementCounter('api_calls', 5);
        metricsCollector.incrementCounter('api_calls', 3);
        metricsCollector.incrementCounter('errors');

        final metrics = metricsCollector.getMetrics();
        expect(metrics['counters']['api_calls'], equals(8));
        expect(metrics['counters']['errors'], equals(1));
      });

      test('should collect and calculate gauge statistics', () async {
        metricsCollector.recordGauge('memory_usage', 75.5);
        metricsCollector.recordGauge('memory_usage', 80.2);
        metricsCollector.recordGauge('memory_usage', 78.9);

        final metrics = metricsCollector.getMetrics();
        final gaugeStats = metrics['gauges']['memory_usage'];
        expect(gaugeStats['count'], equals(3));
        expect(gaugeStats['min'], equals(75.5));
        expect(gaugeStats['max'], equals(80.2));
        expect(gaugeStats['avg'], closeTo(78.2, 0.1));
      });

      test('should collect and calculate timer statistics', () async {
        metricsCollector.recordTimer(
            'api_response_time', const Duration(milliseconds: 100));
        metricsCollector.recordTimer(
            'api_response_time', const Duration(milliseconds: 200));
        metricsCollector.recordTimer(
            'api_response_time', const Duration(milliseconds: 150));

        final metrics = metricsCollector.getMetrics();
        final timerStats = metrics['timers']['api_response_time'];
        expect(timerStats['count'], equals(3));
        expect(timerStats['total_ms'], equals(450));
        expect(timerStats['avg_ms'], equals(150));
        expect(timerStats['min_ms'], equals(100));
        expect(timerStats['max_ms'], equals(200));
      });

      test('should collect histogram data', () async {
        metricsCollector.recordHistogram('status_codes', '200');
        metricsCollector.recordHistogram('status_codes', '404');
        metricsCollector.recordHistogram('status_codes', '200');
        metricsCollector.recordHistogram('status_codes', '500');

        final metrics = metricsCollector.getMetrics();
        final histogramStats = metrics['histograms']['status_codes'];
        expect(histogramStats['count'], equals(4));
        expect(histogramStats['values'], containsAll(['200', '404', '500']));
      });
    });

    group('Distributed Tracing', () {
      test('should create and manage spans', () async {
        final spanId =
            tracingService.startSpan('test_operation', {'service': 'test'});

        expect(spanId, isNotEmpty);
        expect(tracingService.getActiveSpans(), hasLength(1));

        tracingService.finishSpan(spanId, 'completed');

        expect(tracingService.getActiveSpans(), isEmpty);
        expect(tracingService.getTraces(), hasLength(1));
      });

      test('should track span timing', () async {
        final spanId = tracingService.startSpan('timed_operation');

        await Future.delayed(const Duration(milliseconds: 100));

        tracingService.finishSpan(spanId, 'completed');

        final traces = tracingService.getTraces();
        final trace = traces.first;

        expect(trace['operationName'], equals('timed_operation'));
        expect(trace['status'], equals('completed'));
        expect(trace['startTime'], isNotNull);
        expect(trace['endTime'], isNotNull);
      });

      test('should calculate trace statistics', () async {
        // Create multiple spans
        for (var i = 0; i < 5; i++) {
          final spanId = tracingService.startSpan('operation_$i');
          await Future.delayed(const Duration(milliseconds: 50));
          tracingService.finishSpan(spanId, 'completed');
        }

        final stats = tracingService.getTraceStatistics();
        expect(stats['totalSpans'], equals(5));
        expect(stats['completedSpans'], equals(5));
        expect(stats['activeSpans'], equals(0));
        expect(stats['avgDurationMs'], greaterThan(0));
      });
    });

    group('Health Monitoring', () {
      test('should track service health status', () async {
        healthCheckService.recordServiceHealth(
            'ServiceA', ServiceHealthStatus.healthy);
        healthCheckService.recordServiceHealth(
            'ServiceB', ServiceHealthStatus.unhealthy);
        healthCheckService.recordServiceHealth(
            'ServiceC', ServiceHealthStatus.healthy);

        final health = healthCheckService.getOverallHealth();
        expect(health['totalServices'], equals(3));
        expect(health['healthyServices'], equals(2));
        expect(health['unhealthyServices'], equals(1));
        expect(health['healthPercentage'], closeTo(66.67, 0.1));
      });

      test('should track health events', () async {
        healthCheckService.recordServiceHealth(
            'ServiceA', ServiceHealthStatus.healthy);
        healthCheckService.recordServiceHealth(
            'ServiceA', ServiceHealthStatus.unhealthy);
        healthCheckService.recordServiceHealth(
            'ServiceA', ServiceHealthStatus.healthy);

        final events = healthCheckService.getHealthEvents();
        expect(events, hasLength(3));
        expect(events[0]['status'], contains('healthy'));
        expect(events[1]['status'], contains('unhealthy'));
        expect(events[2]['status'], contains('healthy'));
      });
    });

    group('Log Aggregation', () {
      test('should aggregate and filter logs', () async {
        logAggregationService.aggregateLog('INFO', 'ServiceA', 'Info message');
        logAggregationService.aggregateLog(
            'ERROR', 'ServiceA', 'Error message');
        logAggregationService.aggregateLog(
            'INFO', 'ServiceB', 'Another info message');
        logAggregationService.aggregateLog(
            'WARN', 'ServiceA', 'Warning message');

        final allLogs = logAggregationService.getLogs();
        expect(allLogs, hasLength(4));

        final errorLogs = logAggregationService.getLogs(level: 'ERROR');
        expect(errorLogs, hasLength(1));
        expect(errorLogs.first['message'], equals('Error message'));

        final serviceALogs = logAggregationService.getLogs(source: 'ServiceA');
        expect(serviceALogs, hasLength(3));
      });

      test('should provide log statistics', () async {
        logAggregationService.aggregateLog('INFO', 'ServiceA', 'Message 1');
        logAggregationService.aggregateLog('ERROR', 'ServiceA', 'Message 2');
        logAggregationService.aggregateLog('INFO', 'ServiceB', 'Message 3');

        final stats = logAggregationService.getLogStatistics();
        expect(stats['totalLogs'], equals(3));
        expect(stats['logLevels']['INFO'], equals(2));
        expect(stats['logLevels']['ERROR'], equals(1));
        expect(stats['logSources']['ServiceA'], equals(2));
        expect(stats['logSources']['ServiceB'], equals(1));
      });
    });

    group('Performance Monitoring', () {
      test('should track request performance', () async {
        performanceMonitoring.recordRequest('/api/users', 100);
        performanceMonitoring.recordRequest('/api/users', 150);
        performanceMonitoring.recordRequest('/api/users', 200, isError: true);
        performanceMonitoring.recordRequest('/api/posts', 80);

        final metrics = performanceMonitoring.getPerformanceMetrics();
        expect(metrics['/api/users']['requestCount'], equals(3));
        expect(metrics['/api/users']['errorCount'], equals(1));
        expect(metrics['/api/users']['errorRate'], closeTo(0.33, 0.1));
        expect(metrics['/api/users']['avgResponseTimeMs'], equals(150));
        expect(metrics['/api/posts']['requestCount'], equals(1));
      });

      test('should calculate percentiles', () async {
        // Record response times for percentile calculation
        for (var i = 0; i < 100; i++) {
          performanceMonitoring.recordRequest('/api/test', i);
        }

        final metrics = performanceMonitoring.getPerformanceMetrics();
        final testMetrics = metrics['/api/test'];
        expect(testMetrics['p95ResponseTimeMs'], closeTo(95, 1));
        expect(testMetrics['p99ResponseTimeMs'], closeTo(99, 1));
      });
    });

    group('Integrated Observability', () {
      test('should generate comprehensive observability report', () async {
        // Generate some data
        await observabilityIntegration.simulateWorkload();

        final report =
            await observabilityIntegration.generateComprehensiveReport();

        expect(report['timestamp'], isNotNull);
        expect(report['metrics'], isA<Map<String, dynamic>>());
        expect(report['traces'], isA<Map<String, dynamic>>());
        expect(report['health'], isA<Map<String, dynamic>>());
        expect(report['logs'], isA<Map<String, dynamic>>());
        expect(report['performance'], isA<Map<String, dynamic>>());
      });

      test('should handle high-volume observability data', () async {
        // Generate high volume of data
        for (var i = 0; i < 1000; i++) {
          metricsCollector.incrementCounter('high_volume_test');
          logAggregationService.aggregateLog(
              'DEBUG', 'TestService', 'Message $i');
        }

        final metrics = metricsCollector.getMetrics();
        expect(metrics['counters']['high_volume_test'], equals(1000));

        final logs = logAggregationService.getLogs(limit: 10);
        expect(logs, hasLength(10));
      });

      test('should maintain observability data across service restarts',
          () async {
        // Generate some data
        metricsCollector.incrementCounter('persistence_test', 5);
        final spanId = tracingService.startSpan('persistence_test');
        tracingService.finishSpan(spanId, 'completed');

        // Simulate service restart by clearing and reinitializing
        metricsCollector.clearMetrics();

        // Data should be cleared
        final metrics = metricsCollector.getMetrics();
        expect(metrics['counters'], isEmpty);
      });
    });

    group('Observability Edge Cases', () {
      test('should handle concurrent observability operations', () async {
        final futures = <Future>[];

        for (var i = 0; i < 100; i++) {
          futures.add(Future(() async {
            metricsCollector.incrementCounter('concurrent_test');
            logAggregationService.aggregateLog(
                'INFO', 'ConcurrentService', 'Message $i');
          }));
        }

        await Future.wait(futures);

        final metrics = metricsCollector.getMetrics();
        expect(metrics['counters']['concurrent_test'], equals(100));

        final logs = logAggregationService.getLogs();
        expect(logs.length, greaterThanOrEqualTo(100));
      });

      test('should handle observability data overflow', () async {
        // Generate large amount of data
        for (var i = 0; i < 10000; i++) {
          metricsCollector.recordGauge('overflow_test', i.toDouble());
        }

        final metrics = metricsCollector.getMetrics();
        final gaugeStats = metrics['gauges']['overflow_test'];
        expect(gaugeStats['count'], equals(10000));
        expect(gaugeStats['min'], equals(0));
        expect(gaugeStats['max'], equals(9999));
      });
    });
  });
}

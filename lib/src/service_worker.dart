/// Squadron worker integration for running services in isolates.
library service_worker;

import 'dart:async';
// 'dart:isolate' is not used directly here; Squadron manages isolates.

import 'package:squadron/squadron.dart';

import 'base_service.dart';
import 'exceptions/service_exceptions.dart';
import 'service_logger.dart';
import 'types/service_types.dart';
import 'codegen/dispatcher_registry.dart';

/// A Squadron worker wrapper that runs a service in an isolate.
class ServiceWorker extends Worker {
  /// Creates a service worker.
  ServiceWorker({
    required String serviceName,
    required ServiceFactory serviceFactory,
    List args = const [],
    ExceptionManager? exceptionManager,
  })  : _serviceName = serviceName,
        super(_serviceWorkerEntryPoint,
            args: [serviceName, serviceFactory, ...args],
            exceptionManager: exceptionManager);

  final String _serviceName;

  /// Gets the service name.
  String get serviceName => _serviceName;

  /// Initializes the service in the worker isolate.
  Future<void> initializeService() async {
    await send(_ServiceWorkerCommands.initialize);
  }

  /// Destroys the service in the worker isolate.
  Future<void> destroyService() async {
    await send(_ServiceWorkerCommands.destroy);
  }

  /// Calls a method on the service.
  // Name-based worker calls removed; use ID-based calls via send(_ServiceWorkerCommands.callMethodById,...)

  /// Performs a health check on the service.
  Future<ServiceHealthCheck> performHealthCheck() async {
    final result = await send(_ServiceWorkerCommands.healthCheck);
    return ServiceHealthCheck(
      status: ServiceHealthStatus.values[result['status']],
      timestamp: DateTime.parse(result['timestamp']),
      message: result['message'],
      details: Map<String, dynamic>.from(result['details'] ?? {}),
      duration: result['duration'] != null
          ? Duration(microseconds: result['duration'])
          : null,
    );
  }

  /// Gets service information.
  Future<Map<String, dynamic>> getServiceInfo() async {
    return await send(_ServiceWorkerCommands.getInfo);
  }
}

/// Entry point for the service worker isolate.
Future<void> _serviceWorkerEntryPoint(WorkerRequest startRequest) async {
  final args = startRequest.args;
  final serviceName = args[0] as String;
  final serviceFactory = args[1] as ServiceFactory;
  final additionalArgs = args.skip(2).toList();

  final service = _ServiceWorkerService(
    serviceName: serviceName,
    serviceFactory: serviceFactory,
    args: additionalArgs,
  );

  await service.install();

  // Hand off to Squadron runtime to process requests using the operations map
  run((_) => service, startRequest);
}

/// Commands for service worker communication.
class _ServiceWorkerCommands {
  static const int initialize = 1;
  static const int destroy = 2;
  static const int healthCheck = 4;
  static const int getInfo = 5;
  static const int callMethodById = 6;
}

/// Service implementation that runs in the worker isolate.
class _ServiceWorkerService implements WorkerService {
  /// Creates a service worker service.
  _ServiceWorkerService({
    required String serviceName,
    required ServiceFactory serviceFactory,
    List<dynamic> args = const [],
  })  : _serviceName = serviceName,
        _serviceFactory = serviceFactory,
        _args = args;

  final String _serviceName;
  final ServiceFactory _serviceFactory;
  final List<dynamic> _args; // reserved for future use (constructor params)

  BaseService? _service;
  late ServiceLogger _logger;

  /// Initializes the worker service.
  Future<void> install() async {
    _logger = ServiceLogger(serviceName: 'ServiceWorker[$_serviceName]');
    _logger.info('Service worker isolate started');
    if (_args.isNotEmpty) {
      _logger.debug('Worker args received', metadata: {'count': _args.length});
    }
  }

  /// Cleans up the worker service.
  Future<void> uninstall() async {
    if (_service != null) {
      try {
        await _service!.internalDestroy();
      } catch (error, stackTrace) {
        _logger.error('Error during service cleanup',
            error: error, stackTrace: stackTrace);
      }
    }
    _logger.info('Service worker isolate stopped');
  }

  @override
  Map<int, CommandHandler> get operations => {
        _ServiceWorkerCommands.initialize: _handleInitialize,
        _ServiceWorkerCommands.destroy: _handleDestroy,
        _ServiceWorkerCommands.callMethodById: _handleCallMethodById,
        _ServiceWorkerCommands.healthCheck: _handleHealthCheck,
        _ServiceWorkerCommands.getInfo: _handleGetInfo,
      };

  Future<void> _handleInitialize(WorkerRequest request) async {
    if (_service != null) {
      throw ServiceStateException(
          _serviceName, 'initialized', 'not initialized');
    }

    try {
      _logger.info('Creating service instance');
      _service = _serviceFactory();

      if (_service == null) {
        throw ServiceFactoryException(_serviceName);
      }

      _logger.info('Initializing service');
      await _service!.internalInitialize();
      _logger.info('Service initialized successfully');
    } catch (error, stackTrace) {
      _logger.error('Service initialization failed',
          error: error, stackTrace: stackTrace);
      _service = null;
      rethrow;
    }
  }

  Future<void> _handleDestroy(WorkerRequest request) async {
    if (_service == null) {
      return; // Already destroyed or never initialized
    }

    try {
      _logger.info('Destroying service');
      await _service!.internalDestroy();
      _logger.info('Service destroyed successfully');
    } catch (error, stackTrace) {
      _logger.error('Service destruction failed',
          error: error, stackTrace: stackTrace);
    } finally {
      _service = null;
    }
  }

  // Name-based call handler removed; ID-based dispatch is required.

  Future<dynamic> _handleCallMethodById(WorkerRequest request) async {
    if (_service == null) {
      throw ServiceStateException(
          _serviceName, 'not initialized', 'initialized');
    }

    final methodId = request.args[0] as int;
    final args = request.args[1] as List<dynamic>;

    try {
      final dispatcher =
          GeneratedDispatcherRegistry.findDispatcherForObject(_service!);
      if (dispatcher == null) {
        throw ServiceException('No dispatcher registered for $_serviceName');
      }
      return await dispatcher(_service!, methodId, args);
    } catch (error, stackTrace) {
      _logger.error('Method call by id failed',
          error: error,
          stackTrace: stackTrace,
          metadata: {'methodId': methodId, 'args': args});
      throw ServiceCallException(_serviceName, '#$methodId', error);
    }
  }

  Future<Map<String, dynamic>> _handleHealthCheck(WorkerRequest request) async {
    if (_service == null) {
      return {
        'status': ServiceHealthStatus.unhealthy.index,
        'timestamp': DateTime.now().toIso8601String(),
        'message': 'Service not initialized',
      };
    }

    try {
      final healthCheck = await _service!.healthCheck();
      return {
        'status': healthCheck.status.index,
        'timestamp': healthCheck.timestamp.toIso8601String(),
        'message': healthCheck.message,
        'details': healthCheck.details,
        'duration': healthCheck.duration?.inMicroseconds,
      };
    } catch (error, stackTrace) {
      _logger.error('Health check failed',
          error: error, stackTrace: stackTrace);
      return {
        'status': ServiceHealthStatus.unhealthy.index,
        'timestamp': DateTime.now().toIso8601String(),
        'message': 'Health check failed: $error',
      };
    }
  }

  Map<String, dynamic> _handleGetInfo(WorkerRequest request) {
    if (_service == null) {
      return {
        'name': _serviceName,
        'state': ServiceState.registered.name,
        'initialized': false,
      };
    }

    final info = _service!.getServiceInfo();
    return {
      'name': info.name,
      'type': info.type.toString(),
      'state': info.state.name,
      'initialized': info.state == ServiceState.initialized,
      'dependencies': info.dependencies.map((t) => t.toString()).toList(),
      'registeredAt': info.registeredAt?.toIso8601String(),
      'initializedAt': info.initializedAt?.toIso8601String(),
      'destroyedAt': info.destroyedAt?.toIso8601String(),
      'error': info.error?.toString(),
    };
  }

  // Reflection path removed.
}

/// Factory for creating service workers.
class ServiceWorkerFactory {
  /// Creates a service worker factory.
  const ServiceWorkerFactory();

  /// Creates a service worker for the given service type.
  ServiceWorker createWorker<T extends BaseService>({
    required String serviceName,
    required ServiceFactory<T> serviceFactory,
    List<dynamic> args = const [],
    ExceptionManager? exceptionManager,
  }) {
    return ServiceWorker(
      serviceName: serviceName,
      serviceFactory: serviceFactory,
      args: args,
      exceptionManager: exceptionManager,
    );
  }
}

/// Pool of service workers for managing multiple worker instances.
class ServiceWorkerPool {
  /// Creates a service worker pool.
  ServiceWorkerPool({
    this.maxWorkers = 10,
    this.minWorkers = 1,
  });

  /// Maximum number of workers in the pool.
  final int maxWorkers;

  /// Minimum number of workers in the pool.
  final int minWorkers;

  final Map<String, List<ServiceWorker>> _workers = {};
  final Map<String, ServiceFactory> _factories = {};

  /// Registers a service type with the pool.
  void registerService<T extends BaseService>(
    String serviceName,
    ServiceFactory<T> factory,
  ) {
    _factories[serviceName] = factory;
    _workers[serviceName] = [];
  }

  /// Gets or creates a worker for the service.
  Future<ServiceWorker> getWorker(String serviceName) async {
    final workers = _workers[serviceName];
    if (workers == null) {
      throw ServiceNotFoundException(serviceName);
    }

    // Find an available worker
    for (final worker in workers) {
      if (!worker.isStopped && worker.workload == 0) {
        return worker;
      }
    }

    // Create a new worker if under the limit
    if (workers.length < maxWorkers) {
      final factory = _factories[serviceName]!;
      final worker = ServiceWorker(
        serviceName: serviceName,
        serviceFactory: factory,
      );

      await worker.start();
      await worker.initializeService();

      workers.add(worker);
      return worker;
    }

    // Return the worker with the least workload
    workers.sort((a, b) => a.workload.compareTo(b.workload));
    return workers.first;
  }

  /// Releases a worker back to the pool.
  void releaseWorker(ServiceWorker worker) {
    // Workers are automatically available when their workload drops to 0
    // No explicit action needed
  }

  /// Shuts down all workers in the pool.
  Future<void> shutdown() async {
    for (final workers in _workers.values) {
      for (final worker in workers) {
        try {
          await worker.destroyService();
          worker.stop();
        } catch (error) {
          // Log error but continue shutdown
        }
      }
    }
    _workers.clear();
    _factories.clear();
  }

  /// Gets statistics about the worker pool.
  Map<String, dynamic> getStatistics() {
    final stats = <String, dynamic>{};

    for (final entry in _workers.entries) {
      final serviceName = entry.key;
      final workers = entry.value;

      stats[serviceName] = {
        'totalWorkers': workers.length,
        'activeWorkers': workers.where((w) => !w.isStopped).length,
        'idleWorkers':
            workers.where((w) => !w.isStopped && w.workload == 0).length,
        'totalWorkload': workers.fold<int>(0, (sum, w) => sum + w.workload),
        'totalErrors': workers.fold<int>(0, (sum, w) => sum + w.totalErrors),
      };
    }

    return stats;
  }
}

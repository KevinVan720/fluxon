/// Squadron worker integration for running services in isolates.
library service_worker;

import 'dart:async';
import 'dart:isolate';

import 'package:squadron/squadron.dart';

import 'base_service.dart';
import 'exceptions/service_exceptions.dart';
import 'service_logger.dart';
import 'types/service_types.dart';
import 'codegen/dispatcher_registry.dart';
import 'service_proxy.dart';
import 'events/event_dispatcher.dart';
import 'events/event_bridge.dart';
import 'events/event_mixin.dart';
import 'events/service_event.dart';
import 'events/event_type_registry.dart';

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

  /// Send an event to this worker isolate
  Future<void> sendEventToWorker(ServiceEvent event) async {
    await send(_ServiceWorkerCommands.sendEvent, args: [event.toJson()]);
  }

  /// Request this worker to broadcast an event to all isolates
  Future<void> broadcastEventFromWorker(ServiceEvent event) async {
    await send(_ServiceWorkerCommands.broadcastEvent, args: [event.toJson()]);
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
  static const int outboundCallById = 7; // worker->host bridge
  static const int sendEvent = 8; // send event from host to worker
  static const int broadcastEvent = 9; // send event from worker to all isolates
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
  SendPort? _hostBridgePort;

  BaseService? _service;
  late ServiceLogger _logger;

  // Event infrastructure for worker isolate
  EventDispatcher? _eventDispatcher;
  EventBridge? _eventBridge;

  /// Initializes the worker service.
  Future<void> install() async {
    _logger = ServiceLogger(serviceName: 'ServiceWorker[$_serviceName]');
    _logger.info('Service worker isolate started');
    if (_args.isNotEmpty) {
      _logger.debug('Worker args received', metadata: {'count': _args.length});
      final possiblePort = _args.last;
      if (possiblePort is SendPort) {
        _hostBridgePort = possiblePort;
      }
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
        _ServiceWorkerCommands.outboundCallById: _handleOutboundCallById,
        _ServiceWorkerCommands.healthCheck: _handleHealthCheck,
        _ServiceWorkerCommands.getInfo: _handleGetInfo,
        _ServiceWorkerCommands.sendEvent: _handleSendEvent,
        _ServiceWorkerCommands.broadcastEvent: _handleBroadcastEvent,
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

      // 🚀 SET UP EVENT INFRASTRUCTURE IN WORKER ISOLATE
      _eventDispatcher = EventDispatcher(logger: _logger);
      _eventBridge = EventBridge(
        isolateName: _serviceName,
        logger: _logger,
      );
      _eventBridge!.initialize(_eventDispatcher!, hostPort: _hostBridgePort);

      // Register event types in this worker isolate
      _registerEventTypes();

      // Set up event infrastructure for the service
      if (_service is ServiceEventMixin) {
        (_service as ServiceEventMixin).setEventDispatcher(_eventDispatcher!);
        (_service as ServiceEventMixin).setEventBridge(_eventBridge!);
        _logger.info('Event infrastructure set up in worker isolate');
      }

      // Inject bridge registry for cross-service calls from within worker
      if (_hostBridgePort != null && _service is ServiceClientMixin) {
        final registry = WorkerBridgeRegistry(
          hostPort: _hostBridgePort!,
          logger: _logger,
        );
        (_service as ServiceClientMixin).setProxyRegistry(registry);
      }

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
    final positionalArgs = request.args[1] as List<dynamic>;
    final namedArgs = request.args.length > 2
        ? Map<String, dynamic>.from(request.args[2] as Map)
        : <String, dynamic>{};

    try {
      final dispatcher =
          GeneratedDispatcherRegistry.findDispatcherForObject(_service!);
      if (dispatcher == null) {
        throw ServiceException('No dispatcher registered for $_serviceName');
      }
      return await dispatcher(_service!, methodId, positionalArgs, namedArgs);
    } catch (error, stackTrace) {
      _logger.error('Method call by id failed',
          error: error,
          stackTrace: stackTrace,
          metadata: {
            'methodId': methodId,
            'positional': positionalArgs,
            'named': namedArgs
          });
      throw ServiceCallException(_serviceName, '#$methodId', error);
    }
  }

  // Forward a call from worker to host to call another service via host proxies
  Future<dynamic> _handleOutboundCallById(WorkerRequest request) async {
    // No-op: outbound calls are initiated by the worker using _hostBridgePort directly
    throw ServiceException('Outbound bridge should not be invoked by host');
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

  /// Handle incoming event from host isolate
  Future<void> _handleSendEvent(WorkerRequest request) async {
    try {
      final eventData = request.args[0] as Map<String, dynamic>;

      if (_eventDispatcher == null) {
        _logger.warning('Event received but no event dispatcher available');
        return;
      }

      // Reconstruct event from JSON
      final event = _reconstructEventFromJson(eventData);

      // Send to local event dispatcher in this isolate
      await _eventDispatcher!.sendEvent(
        event,
        EventDistribution.broadcast(),
      );

      _logger.debug('Event processed in worker isolate', metadata: {
        'eventId': event.eventId,
        'eventType': event.eventType,
      });
    } catch (error, stackTrace) {
      _logger.error('Error handling incoming event',
          error: error, stackTrace: stackTrace);
    }
  }

  /// Handle broadcast event request from worker to all isolates
  Future<void> _handleBroadcastEvent(WorkerRequest request) async {
    try {
      final eventData = request.args[0] as Map<String, dynamic>;

      if (_hostBridgePort == null) {
        _logger.warning('Cannot broadcast event - no host bridge port');
        return;
      }

      // Send event to host for distribution to other isolates
      _hostBridgePort!.send({
        'cmd': 'broadcastEvent',
        'eventData': eventData,
        'sourceIsolate': _serviceName,
      });

      _logger.debug('Event broadcast request sent to host', metadata: {
        'eventId': eventData['eventId'],
        'eventType': eventData['eventType'],
      });
    } catch (error, stackTrace) {
      _logger.error('Error handling broadcast event request',
          error: error, stackTrace: stackTrace);
    }
  }

  /// Register event types in worker isolate
  void _registerEventTypes() {
    // Register common event types that can be reconstructed from JSON
    // In a real implementation, this would be generated code
    try {
      // Register GenericServiceEvent as fallback
      EventTypeRegistry.register<GenericServiceEvent>(
          (json) => GenericServiceEvent.fromJson(json));

      _logger.debug('Event types registered in worker isolate');
    } catch (error) {
      _logger.warning('Failed to register event types',
          metadata: {'error': error.toString()});
    }
  }

  /// Reconstruct event from JSON data
  ServiceEvent _reconstructEventFromJson(Map<String, dynamic> json) {
    // Try to create the correct event type using the registry
    final event = EventTypeRegistry.createFromJson(json);
    return event ?? GenericServiceEvent.fromJson(json);
  }

  // Reflection path removed.
}

/// A proxy used inside a worker isolate to call other services through the host isolate.
class BridgeServiceProxy<T extends BaseService> implements ServiceProxy<T> {
  BridgeServiceProxy({required SendPort hostPort, ServiceLogger? logger})
      : _hostPort = hostPort,
        _logger =
            logger ?? ServiceLogger(serviceName: 'BridgeServiceProxy<$T>');

  final SendPort _hostPort;
  final ServiceLogger _logger;

  @override
  Type get targetType => T;

  @override
  bool get isConnected => true;

  @override
  Future<void> connect(target) async {}

  @override
  Future<void> disconnect() async {}

  @override
  Future<R> callMethod<R>(
    String methodName,
    List<dynamic> positionalArgs, {
    Map<String, dynamic>? namedArgs,
    ServiceCallOptions? options,
  }) async {
    final reply = ReceivePort();
    try {
      _logger.debug('Outbound bridge call', metadata: {
        'service': T.toString(),
        'method': methodName,
        'positionalCount': positionalArgs.length,
      });
      final message = {
        'cmd': 'outboundCall',
        'serviceType': T.toString(),
        'method': methodName,
        'positional': positionalArgs,
        'named': namedArgs ?? const <String, dynamic>{},
        'replyTo': reply.sendPort,
      };
      _hostPort.send(message);
      final response = await reply.first;
      if (response is Map && response['ok'] == true) {
        return response['result'] as R;
      }
      final error = (response is Map) ? response['error'] : 'Unknown error';
      throw ServiceCallException(T.toString(), methodName, error);
    } finally {
      reply.close();
    }
  }
}

/// Registry used inside worker isolate to provide proxies that route through host.
class WorkerBridgeRegistry extends ServiceProxyRegistry {
  WorkerBridgeRegistry({required SendPort hostPort, ServiceLogger? logger})
      : _hostPort = hostPort,
        _bridgeLogger =
            logger ?? ServiceLogger(serviceName: 'WorkerBridgeRegistry'),
        super(logger: logger);

  final SendPort _hostPort;
  final ServiceLogger _bridgeLogger;
  final Map<Type, ServiceProxy> _map = {};

  @override
  void registerProxyForType(Type type, ServiceProxy proxy) {
    _map[type] = proxy;
  }

  @override
  ServiceProxy<T> getProxy<T extends BaseService>() {
    final existing = _map[T];
    if (existing != null) return existing as ServiceProxy<T>;
    final proxy =
        BridgeServiceProxy<T>(hostPort: _hostPort, logger: _bridgeLogger);
    _map[T] = proxy;
    return proxy;
  }

  @override
  bool hasProxy<T extends BaseService>() {
    return _map.containsKey(T);
  }

  @override
  Future<void> disconnectAll() async {
    _map.clear();
  }
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

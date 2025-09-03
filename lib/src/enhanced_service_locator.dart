/// Enhanced service locator with automatic dependency injection and cross-isolate communication
library enhanced_service_locator;

import 'dart:async';
import 'dart:isolate';
import 'package:meta/meta.dart';

import 'base_service.dart';
import 'service_locator.dart';
import 'service_registry.dart';
import 'service_logger.dart';
import 'exceptions/service_exceptions.dart';
import 'service_proxy.dart';
import 'service_worker.dart';
import 'package:squadron/squadron.dart';
import 'types/service_types.dart';

/// Enhanced service locator that provides automatic dependency injection
/// and transparent cross-isolate service communication
class EnhancedServiceLocator extends ServiceLocator {
  EnhancedServiceLocator({ServiceLogger? logger})
      : _logger =
            logger ?? ServiceLogger(serviceName: 'EnhancedServiceLocator'),
        super(logger: logger) {
    _registry = ServiceRegistry(logger: _logger);
    _proxyRegistry = ServiceProxyRegistry(logger: _logger);
  }

  final ServiceLogger _logger;
  late final ServiceRegistry _registry;
  late final ServiceProxyRegistry _proxyRegistry;
  final Map<Type, Isolate> _serviceIsolates = {};
  final Map<Type, SendPort> _isolatePorts = {};

  /// Initialize the enhanced service locator
  @override
  Future<void> initializeAll() async {
    // Initialize the service registry first
    await _registry.initialize();

    // Initialize services normally
    await super.initializeAll();

    // Perform automatic dependency injection
    await _performDependencyInjection();

    // Register local proxies for all initialized services and inject registry
    _setupProxyRegistry();
  }

  /// Register a service to run in its own isolate
  Future<void> registerIsolateService<T extends BaseService>(
    T Function() factory, {
    String? isolateName,
  }) async {
    final name = isolateName ?? T.toString();

    // Create receive port for communication
    final receivePort = ReceivePort();

    // Spawn isolate
    final isolate = await Isolate.spawn(
      _isolateEntryPoint<T>,
      _IsolateStartupData(
        factory: factory,
        sendPort: receivePort.sendPort,
        serviceType: T,
        registryLogger: _logger,
      ),
      debugName: name,
    );

    _serviceIsolates[T] = isolate;

    // Wait for isolate to send its SendPort
    final completer = Completer<SendPort>();
    late StreamSubscription subscription;

    subscription = receivePort.listen((message) {
      if (message is SendPort) {
        _isolatePorts[T] = message;
        _registry.registerRemoteService<T>(message);
        completer.complete(message);
        subscription.cancel();
      }
    });

    await completer.future;
    receivePort.close();

    _logger.info('Isolate service registered: $T');
  }

  /// Perform automatic dependency injection for all services
  Future<void> _performDependencyInjection() async {
    _logger.info('Performing automatic dependency injection');

    final allServiceInfo = getAllServiceInfo();
    for (final serviceInfo in allServiceInfo) {
      if (serviceInfo.instance != null) {
        await _injectDependencies(
            serviceInfo.type, serviceInfo.instance! as BaseService);
      }
    }

    _logger.info('Dependency injection completed');
  }

  /// Inject dependencies for a specific service
  Future<void> _injectDependencies(
      Type serviceType, BaseService service) async {
    final allDependencies = [
      ...service.dependencies,
      ...service.optionalDependencies
    ];

    for (final depType in allDependencies) {
      // For now, we'll use a simplified approach
      // In a real implementation, this would need proper type-safe dependency resolution
      _logger.debug('Processing dependency', metadata: {
        'service': serviceType.toString(),
        'dependency': depType.toString(),
      });

      // TODO: Implement proper dependency injection with type safety
      // This requires either reflection or code generation to properly
      // resolve dependencies by their actual types
    }
  }

  /// Get a service (local or remote)
  @override
  T get<T extends BaseService>() {
    // Try local first
    if (isRegistered<T>()) {
      return super.get<T>();
    }

    // Try registry (remote services)
    final remoteService = _registry.getService<T>();
    if (remoteService != null) {
      return remoteService;
    }

    throw ServiceException('Service $T is not available');
  }

  /// Check if service is available (local or remote)
  bool isServiceAvailable<T extends BaseService>() {
    return isRegistered<T>() || _registry.hasService<T>();
  }

  /// Destroy all services and isolates
  @override
  Future<void> destroyAll() async {
    // Destroy local services first
    await super.destroyAll();

    // Request graceful shutdown of worker isolates
    for (final port in _isolatePorts.values) {
      try {
        port.send('shutdown');
      } catch (_) {}
    }
    // Allow some time for workers to cleanup
    await Future.delayed(const Duration(milliseconds: 100));
    // Ensure isolates are terminated
    for (final isolate in _serviceIsolates.values) {
      try {
        isolate.kill(priority: Isolate.immediate);
      } catch (_) {}
    }

    _serviceIsolates.clear();
    _isolatePorts.clear();

    // Dispose registry
    _registry.dispose();

    // Disconnect all proxies
    await _proxyRegistry.disconnectAll();

    _logger.info('All services and isolates destroyed');
  }

  /// Get the service registry
  ServiceRegistry get registry => _registry;

  /// Get the proxy registry
  ServiceProxyRegistry get proxyRegistry => _proxyRegistry;

  void _setupProxyRegistry() {
    // Register local proxies for each initialized service
    for (final type in initializedServiceTypes) {
      _registerLocalProxy(type);
    }

    // Inject registry into services that support client calls
    for (final type in initializedServiceTypes) {
      final service = _tryGetServiceInstance(type);
      if (service is ServiceClientMixin) {
        service.setProxyRegistry(_proxyRegistry);
      }
    }
  }

  void _registerLocalProxy(Type serviceType) {
    try {
      // Use generic helper via switch on string; limited but avoids mirrors in core
      // Fallback: use dynamic proxy creation
      final service = _tryGetServiceInstance(serviceType);
      if (service == null) return;

      final localProxy = LocalServiceProxy<BaseService>(logger: _logger);
      localProxy.connect(service);
      _proxyRegistry.registerProxyForType(serviceType, localProxy);
    } catch (e, st) {
      _logger.error('Failed to register local proxy', error: e, stackTrace: st);
    }
  }

  BaseService? _tryGetServiceInstance(Type t) {
    try {
      // Use the public API: get via type-safe generics cannot be done dynamically,
      // so expose instances via service info
      final info = getAllServiceInfo().firstWhere(
        (i) => i.type == t,
        orElse: () => throw StateError('Service not found for type $t'),
      );
      final instance = info.instance;
      if (instance is BaseService) return instance;
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Register a worker-backed service proxy for type [T].
  ///
  /// This starts a [ServiceWorker], initializes the service in the isolate,
  /// and registers a [WorkerServiceProxy] in the proxy registry so that
  /// services using [ServiceClientMixin] can call it.
  Future<void> registerWorkerServiceProxy<T extends BaseService>({
    required String serviceName,
    required ServiceFactory<T> serviceFactory,
    List<dynamic> args = const [],
    ExceptionManager? exceptionManager,
  }) async {
    final worker = ServiceWorkerFactory().createWorker<T>(
      serviceName: serviceName,
      serviceFactory: serviceFactory,
      args: args,
      exceptionManager: exceptionManager,
    );

    await worker.start();
    await worker.initializeService();

    final workerProxy = WorkerServiceProxy<T>(logger: _logger);
    await workerProxy.connect(worker);
    _proxyRegistry.registerProxyForType(T, workerProxy);

    _logger.info('Worker service proxy registered: $T');
  }
}

/// Data passed to isolate on startup
class _IsolateStartupData<T extends BaseService> {
  const _IsolateStartupData({
    required this.factory,
    required this.sendPort,
    required this.serviceType,
    required this.registryLogger,
  });

  final T Function() factory;
  final SendPort sendPort;
  final Type serviceType;
  final ServiceLogger registryLogger;
}

/// Entry point for service isolates
Future<void> _isolateEntryPoint<T extends BaseService>(
    _IsolateStartupData<T> data) async {
  try {
    // Create receive port for this isolate
    final receivePort = ReceivePort();

    // Send our SendPort back to main isolate
    data.sendPort.send(receivePort.sendPort);

    // Create service registry for this isolate
    final registry = ServiceRegistry(logger: data.registryLogger);
    await registry.initialize(mainSendPort: data.sendPort);

    // Create and initialize the service
    final service = data.factory();

    // Add communication mixin if supported
    if (service is ServiceCommunicationMixin) {
      (service as ServiceCommunicationMixin).setServiceRegistry(registry);
    }

    await service.internalInitialize();

    // Register with registry
    registry.registerLocalService(service);

    // Listen for messages
    await for (final message in receivePort) {
      if (message == 'shutdown') {
        break;
      }
      // Registry handles all other messages
    }

    // Cleanup
    await service.internalDestroy();
    registry.dispose();
    receivePort.close();
  } catch (error, stackTrace) {
    print('Isolate error: $error');
    print('Stack trace: $stackTrace');
  }
}

/// Mixin for services that want automatic dependency injection
mixin AutoDependencyMixin on BaseService {
  /// Override to automatically call dependency methods when they become available
  @override
  void onDependencyAvailable(Type serviceType, BaseService service) {
    super.onDependencyAvailable(serviceType, service);

    // Call service-specific dependency handlers
    _callDependencyHandler(serviceType, service);
  }

  /// Call service-specific dependency handler methods
  void _callDependencyHandler(Type serviceType, BaseService service) {
    // This would use reflection in a real implementation
    // For now, services can override onDependencyAvailable to handle specific dependencies
  }
}

/// Enhanced base service with automatic dependency management
abstract class EnhancedBaseService extends BaseService
    with AutoDependencyMixin, ServiceCommunicationMixin {
  EnhancedBaseService({super.config, super.logger});

  /// Template method for handling specific dependency types
  /// Override this to handle when specific dependencies become available
  @protected
  void onSpecificDependencyAvailable<T extends BaseService>(T service) {
    // Override in subclasses to handle specific dependency types
  }

  @override
  void onDependencyAvailable(Type serviceType, BaseService service) {
    super.onDependencyAvailable(serviceType, service);

    // Call type-specific handler
    _dispatchDependencyHandler(serviceType, service);
  }

  void _dispatchDependencyHandler(Type serviceType, BaseService service) {
    // In a real implementation, this would use reflection or code generation
    // to call the appropriate onSpecificDependencyAvailable<T> method

    // For now, subclasses can override onDependencyAvailable directly
  }
}

/// Service locator for registering and managing services.
library service_locator;

import 'dart:async';
import 'dart:isolate';

import 'package:squadron/squadron.dart';

import 'base_service.dart';
import 'codegen/dispatcher_registry.dart';
import 'dependency_resolver.dart';
import 'events/event_bridge.dart';
import 'events/event_dispatcher.dart';
import 'events/event_mixin.dart';
import 'events/service_event.dart';
import 'exceptions/service_exceptions.dart';
import 'flux_service.dart';
import 'service_logger.dart';
import 'service_proxy.dart';
import 'service_registry.dart';
import 'service_worker.dart';
import 'types/service_types.dart';

/// Central registry and manager for all services in the application.
///
/// The ServiceLocator provides a single point for:
/// - Registering services with their factories
/// - Managing service dependencies
/// - Initializing services in the correct order
/// - Retrieving service instances
/// - Managing service lifecycle
class ServiceLocator {
  /// Creates a service locator.
  ServiceLocator({
    ServiceLogger? logger,
  }) : _logger = logger ?? ServiceLogger(serviceName: 'ServiceLocator') {
    _dependencyResolver = DependencyResolver();
    _registry = ServiceRegistry(logger: _logger);
    _proxyRegistry = ServiceProxyRegistry(logger: _logger);

    // Initialize automatic event infrastructure
    _eventDispatcher = EventDispatcher(logger: _logger);
    _eventBridge = EventBridge(isolateName: 'MainIsolate', logger: _logger);
    _eventBridge.initialize(_eventDispatcher,
        workerBroadcastCallback: _broadcastEventToAllWorkers);

    _logger.info('ServiceLocator created with automatic event infrastructure');
  }

  final ServiceLogger _logger;
  late final DependencyResolver _dependencyResolver;
  late final ServiceRegistry _registry;
  late final ServiceProxyRegistry _proxyRegistry;

  // Automatic event infrastructure
  late final EventDispatcher _eventDispatcher;
  late final EventBridge _eventBridge;

  final Map<Type, ServiceFactory> _factories = {};
  final Map<Type, BaseService> _instances = {};
  final Map<Type, ServiceInfo> _serviceInfos = {};
  final List<Future<void>> _pendingRemoteRegistrations = [];

  bool _isInitialized = false;
  bool _isInitializing = false;
  bool _isDestroying = false;

  final List<ServiceLifecycleCallback> _initializationCallbacks = [];
  final List<ServiceLifecycleCallback> _destructionCallbacks = [];

  // Enhanced features
  final List<ReceivePort> _bridgePorts = [];
  final List<StreamSubscription> _bridgeSubscriptions = [];

  // Event bridging for cross-isolate communication
  final Map<String, ServiceWorker> _workerRegistry = {};

  /// Gets whether the service locator has been initialized.
  bool get isInitialized => _isInitialized;

  /// Gets whether the service locator is currently initializing.
  bool get isInitializing => _isInitializing;

  /// Gets whether the service locator is currently being destroyed.
  bool get isDestroying => _isDestroying;

  /// Gets the number of registered services.
  int get serviceCount => _factories.length;

  /// Gets the number of initialized services.
  int get initializedServiceCount => _instances.length;

  /// Gets all registered service types.
  Set<Type> get registeredServiceTypes => Set.from(_factories.keys);

  /// Gets all initialized service types.
  Set<Type> get initializedServiceTypes => Set.from(_instances.keys);

  /// Gets the dependency resolver.
  DependencyResolver get dependencyResolver => _dependencyResolver;

  /// Registers a service with the locator.
  ///
  /// [T] must extend [BaseService].
  /// [factory] is called to create the service instance when needed.
  ///
  /// Throws [ServiceAlreadyRegisteredException] if the service is already registered.
  void register<T extends BaseService>(ServiceFactory<T> factory) {
    final serviceType = T;
    final serviceName = serviceType.toString();

    if (_factories.containsKey(serviceType)) {
      throw ServiceAlreadyRegisteredException(serviceName);
    }

    if (_isInitialized) {
      throw const ServiceStateException(
        'ServiceLocator',
        'initialized',
        'not initialized',
      );
    }

    // Create a temporary instance to get dependency information
    final tempInstance = factory();

    // If this is a generated Worker class, route to remote registration
    if (tempInstance is FluxService) {
      final isWorker = tempInstance.runtimeType.toString().endsWith('Worker') ||
          tempInstance.clientBaseType != tempInstance.runtimeType;
      if (isWorker) {
        final baseTypeName = tempInstance.clientBaseType.toString();
        // Schedule remote proxy registration and await it in initializeAll
        final f = registerWorkerServiceProxy<T>(
          serviceName: baseTypeName,
          serviceFactory: factory,
        );
        _pendingRemoteRegistrations.add(f);
        _logger.info('Scheduled remote worker registration', metadata: {
          'service': baseTypeName,
          'workerType': tempInstance.runtimeType.toString(),
        });
        return;
      }
    }

    _factories[serviceType] = factory;
    final dependencies = tempInstance.dependencies;
    final optionalDependencies = tempInstance.optionalDependencies;

    // Register with dependency resolver
    _dependencyResolver.registerService(
      serviceType,
      serviceName,
      dependencies,
      optionalDependencies,
    );

    // Create service info
    _serviceInfos[serviceType] = ServiceInfo(
      name: serviceName,
      type: serviceType,
      dependencies: dependencies,
      state: ServiceState.registered,
      config: tempInstance.config,
      registeredAt: DateTime.now(),
    );

    _logger.info('Registered service: $serviceName');
    _logger.debug('Service dependencies', metadata: {
      'service': serviceName,
      'dependencies': dependencies.map((t) => t.toString()).toList(),
      'optionalDependencies':
          optionalDependencies.map((t) => t.toString()).toList(),
    });
  }

  /// Unregisters a service from the locator.
  ///
  /// The service must not be initialized and no other services should depend on it.
  void unregister<T extends BaseService>() {
    final serviceType = T;
    final serviceName = serviceType.toString();

    if (!_factories.containsKey(serviceType)) {
      throw ServiceNotFoundException(serviceName);
    }

    if (_instances.containsKey(serviceType)) {
      throw ServiceStateException(
        serviceName,
        'initialized',
        'not initialized',
      );
    }

    // Check if any other services depend on this one
    final dependents = _dependencyResolver.getDependents(serviceType);
    if (dependents.isNotEmpty) {
      final dependentNames = dependents.map((t) => t.toString()).join(', ');
      throw ServiceException(
          'Cannot unregister service "$serviceName" because it has dependents: $dependentNames');
    }

    _factories.remove(serviceType);
    _serviceInfos.remove(serviceType);
    _dependencyResolver.unregisterService(serviceType);

    _logger.info('Unregistered service: $serviceName');
  }

  /// Gets a service instance.
  ///
  /// The service must be registered and initialized.
  ///
  /// Throws [ServiceNotFoundException] if the service is not registered.
  /// Throws [ServiceLocatorNotInitializedException] if the locator is not initialized.
  T get<T extends BaseService>() {
    final serviceType = T;
    final serviceName = serviceType.toString();

    if (!_isInitialized) {
      throw const ServiceLocatorNotInitializedException();
    }

    // Try local services first
    final instance = _instances[serviceType];
    if (instance != null) {
      if (instance is! T) {
        throw InvalidServiceTypeException(
            'Service "$serviceName" is not of type $T');
      }
      instance.ensureNotDestroyed();
      return instance;
    }

    // 🚀 OPTIMIZATION: Try remote services via proxy registry
    if (_proxyRegistry.hasProxy<T>()) {
      final proxy = _proxyRegistry.getProxy<T>();

      // For local proxies, return the actual instance
      if (proxy is LocalServiceProxy) {
        final localInstance = proxy.peekInstance();
        if (localInstance != null && localInstance is T) {
          return localInstance;
        }
      }

      // For remote proxies, return the generated client
      final generated =
          GeneratedClientRegistry.create<T>(proxy as ServiceProxy<T>);
      if (generated != null) return generated;
    }

    // Try service registry as fallback
    final remote = _registry.getService<T>();
    if (remote != null) return remote;

    throw ServiceNotFoundException(serviceName);
  }

  /// Tries to get a service instance.
  ///
  /// Returns null if the service is not registered or not initialized.
  T? tryGet<T extends BaseService>() {
    try {
      return get<T>();
    } on ServiceException {
      return null;
    }
  }

  /// Checks if a service is registered.
  bool isRegistered<T extends BaseService>() => _factories.containsKey(T);

  /// Checks if a service is initialized.
  bool isServiceInitialized<T extends BaseService>() => _instances.containsKey(T);

  /// Gets information about a service.
  ServiceInfo getServiceInfo<T extends BaseService>() {
    final serviceType = T;
    final info = _serviceInfos[serviceType];

    if (info == null) {
      throw ServiceNotFoundException(serviceType.toString());
    }

    return info;
  }

  /// Gets information about all services.
  List<ServiceInfo> getAllServiceInfo() => List.from(_serviceInfos.values);

  // Enhanced helpers
  bool isServiceAvailable<T extends BaseService>() => isRegistered<T>() || _registry.hasService<T>();

  // Expose registries for advanced scenarios (e.g., direct proxy usage in demos)
  ServiceRegistry get registry => _registry;
  ServiceProxyRegistry get proxyRegistry => _proxyRegistry;

  void _setupProxyRegistry() {
    // Set up for initialized services
    for (final type in initializedServiceTypes) {
      _registerLocalProxy(type);
    }
    for (final type in initializedServiceTypes) {
      final service = _tryGetServiceInstance(type);
      if (service is ServiceClientMixin) {
        service.setProxyRegistry(_proxyRegistry);
      }

      // 🚀 AUTOMATIC EVENT INFRASTRUCTURE SETUP
      if (service is ServiceEventMixin) {
        service.setEventDispatcher(_eventDispatcher);
        service.setEventBridge(_eventBridge);

        // Auto-register this isolate in the event bridge
        _eventBridge.registerIsolate(type.toString());

        _logger.debug('Automatic event infrastructure configured', metadata: {
          'serviceType': type.toString(),
        });
      }

      // Note: local-side registration is performed by generated code when needed.
    }

    // Also set up for registered but not yet initialized services
    _setupEventInfrastructureForRegisteredServices();

    // Auto-discover remote services for event routing
    _autoDiscoverRemoteServices();
  }

  /// Set up event infrastructure for registered services before initialization
  void _setupEventInfrastructureForRegisteredServices() {
    for (final type in registeredServiceTypes) {
      if (!_instances.containsKey(type)) {
        // Create service instance to set up infrastructure
        final factory = _factories[type]!;
        final service = factory();

        // Set up complete infrastructure
        if (service is ServiceEventMixin) {
          service.setEventDispatcher(_eventDispatcher);
          service.setEventBridge(_eventBridge);
        }

        if (service is ServiceClientMixin) {
          service.setProxyRegistry(_proxyRegistry);
        }

        // Note: local-side registration is performed by generated code when needed.

        _logger.debug('Pre-initialized service infrastructure', metadata: {
          'serviceType': type.toString(),
        });

        // Replace the factory to return this configured instance
        _factories[type] = () => service;
      }
    }
  }

  /// Automatically discover and register remote services for event routing
  void _autoDiscoverRemoteServices() {
    final remoteTypes = _proxyRegistry.registeredTypes.where((type) {
      final proxy = _proxyRegistry.tryGetProxyByType(type);
      return proxy is WorkerServiceProxy;
    });

    for (final type in remoteTypes) {
      _eventBridge.registerIsolate(type.toString());
      _logger.debug('Auto-registered remote service for events', metadata: {
        'serviceType': type.toString(),
      });
    }
  }

  void _registerLocalProxy(Type serviceType) {
    try {
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

  Future<void> _performDependencyInjection() async {
    _logger.info('Performing automatic dependency injection');
    final allServiceInfo = getAllServiceInfo();
    for (final serviceInfo in allServiceInfo) {
      if (serviceInfo.instance != null) {
        _logger.debug('Processing dependency', metadata: {
          'service': serviceInfo.type.toString(),
          'dependencyCount': serviceInfo.dependencies.length,
        });
      }
    }
    _logger.info('Dependency injection completed');
  }

  // Cross-isolate registration
  Future<void> registerWorkerServiceProxy<T extends BaseService>({
    required String serviceName,
    required ServiceFactory<T> serviceFactory,
    List<dynamic> args = const [],
    ExceptionManager? exceptionManager,
  }) async {
    try {
      // Call host-side registration hook if available (FluxService override in worker)
      final temp = serviceFactory();
      if (temp is FluxService) {
        await temp.registerHostSide();
      }
    } catch (e, st) {
      _logger.error('Error during generated registration',
          error: e, stackTrace: st);
    }
    final bridge = ReceivePort();
    final worker = const ServiceWorkerFactory().createWorker<T>(
      serviceName: serviceName,
      serviceFactory: serviceFactory,
      args: [...args, bridge.sendPort],
      exceptionManager: exceptionManager,
    );
    await worker.start();
    await worker.initializeService();
    final workerProxy = WorkerServiceProxy<T>(logger: _logger);
    await workerProxy.connect(worker);
    // Register proxy under the base client type for transparency
    try {
      final temp = serviceFactory();
      final clientType = temp.clientBaseType;
      _proxyRegistry.registerProxyForType(clientType, workerProxy);
    } catch (_) {
      _proxyRegistry.registerProxyForType(T, workerProxy);
    }

    // 🚀 REGISTER WORKER FOR EVENT BRIDGING
    _workerRegistry[serviceName] = worker;

    final sub = bridge.listen((message) async {
      if (message is Map && message['cmd'] == 'broadcastEvent') {
        // 🚀 HANDLE EVENT BROADCAST FROM WORKER
        await _handleEventBroadcastFromWorker(
            Map<String, dynamic>.from(message));
      } else if (message is Map && message['cmd'] == 'outboundCall') {
        final replyTo = message['replyTo'] as SendPort?;
        try {
          final serviceTypeStr = message['serviceType'] as String;
          final method = message['method'] as String;
          final positional = (message['positional'] as List).cast<dynamic>();
          final named = Map<String, dynamic>.from(message['named'] as Map);

          // 🚀 WORKER-TO-MAIN: Check both proxy registry AND local services
          Type? targetType;
          ServiceProxy? proxy;
          BaseService? localService;

          // First try proxy registry (for remote services)
          try {
            targetType = _proxyRegistry.registeredTypes.firstWhere(
              (t) => t.toString() == serviceTypeStr,
            );
            proxy = _proxyRegistry.tryGetProxyByType(targetType);
          } catch (e) {
            // Not found in proxy registry, try local services
          }

          // If not found in proxy registry, check local services
          if (proxy == null) {
            // Look for local service by type name
            for (final entry in _instances.entries) {
              if (entry.key.toString() == serviceTypeStr) {
                targetType = entry.key;
                localService = entry.value;
                // Create a temporary local proxy for the call
                proxy = LocalServiceProxy<BaseService>();
                await proxy.connect(localService);
                break;
              }
            }
          }

          if (proxy == null || targetType == null) {
            throw ServiceNotFoundException(serviceTypeStr);
          }
          dynamic result;
          if (proxy is WorkerServiceProxy) {
            result = await proxy.callMethod<dynamic>(method, positional,
                namedArgs: named);
          } else if (proxy is LocalServiceProxy) {
            final instance = proxy.peekInstance();
            if (instance == null) {
              throw const ServiceException('Local proxy has no instance');
            }
            final methodId =
                ServiceMethodIdRegistry.tryGetIdByType(targetType, method);
            if (methodId == null) {
              throw ServiceException(
                  'No method id for $serviceTypeStr.$method');
            }
            final dispatcher =
                GeneratedDispatcherRegistry.findDispatcherForObject(instance);
            if (dispatcher == null) {
              throw ServiceException(
                  'No dispatcher registered for $serviceTypeStr');
            }
            result = await dispatcher(instance, methodId, positional, named);
          } else {
            throw ServiceException(
                'Unsupported proxy type: ${proxy.runtimeType}');
          }
          replyTo?.send({'ok': true, 'result': result});
        } catch (e, st) {
          _logger.error('Outbound call failed', error: e, stackTrace: st);
          final replyTo = message['replyTo'] as SendPort?;
          replyTo?.send({'ok': false, 'error': e.toString()});
        }
      }
    });
    _bridgePorts.add(bridge);
    _bridgeSubscriptions.add(sub);
    _logger.info('Worker service proxy registered: $T');
  }

  /// Broadcast event to all worker isolates (called from main isolate)
  Future<void> _broadcastEventToAllWorkers(ServiceEvent event) async {
    _logger.debug('Broadcasting event to all workers', metadata: {
      'eventId': event.eventId,
      'eventType': event.eventType,
      'targetWorkers': _workerRegistry.keys.toList(),
    });

    // Send to all worker isolates
    for (final entry in _workerRegistry.entries) {
      final workerName = entry.key;
      final worker = entry.value;

      try {
        await worker.sendEventToWorker(event);
        _logger.debug('Event sent to worker', metadata: {
          'eventId': event.eventId,
          'targetWorker': workerName,
        });
      } catch (error) {
        _logger.debug('Failed to send event to worker', metadata: {
          'eventId': event.eventId,
          'targetWorker': workerName,
          'error': error.toString(),
        });
      }
    }
  }

  /// Handle event broadcast request from worker isolate
  Future<void> _handleEventBroadcastFromWorker(
      Map<String, dynamic> message) async {
    try {
      final eventData = message['eventData'] as Map<String, dynamic>;
      final sourceIsolate = message['sourceIsolate'] as String;

      _logger
          .debug('Broadcasting event from worker to all isolates', metadata: {
        'eventId': eventData['eventId'],
        'eventType': eventData['eventType'],
        'sourceIsolate': sourceIsolate,
        'targetWorkers': _workerRegistry.keys.toList(),
      });

      // Send to local services in main isolate
      final event = GenericServiceEvent.fromJson(eventData);
      await _eventDispatcher.sendEvent(event, EventDistribution.broadcast());

      // Send to all other worker isolates
      for (final entry in _workerRegistry.entries) {
        final workerName = entry.key;
        final worker = entry.value;

        if (workerName != sourceIsolate) {
          try {
            await worker.sendEventToWorker(event);
            _logger.debug('Event sent to worker', metadata: {
              'eventId': event.eventId,
              'targetWorker': workerName,
            });
          } catch (error) {
            _logger.debug('Failed to send event to worker', metadata: {
              'eventId': event.eventId,
              'targetWorker': workerName,
              'error': error.toString(),
            });
          }
        }
      }
    } catch (error, stackTrace) {
      _logger.error('Error handling event broadcast from worker',
          error: error, stackTrace: stackTrace);
    }
  }

  /// Initializes all registered services in dependency order.
  ///
  /// This must be called before using any services.
  Future<void> initializeAll() async {
    if (_isInitialized) {
      _logger.warning('Service locator is already initialized');
      return;
    }

    if (_isInitializing) {
      throw const ServiceStateException(
        'ServiceLocator',
        'initializing',
        'not initializing',
      );
    }

    _isInitializing = true;
    _logger.info('Starting service initialization');

    try {
      // Ensure any scheduled remote worker registrations are completed
      if (_pendingRemoteRegistrations.isNotEmpty) {
        await Future.wait(_pendingRemoteRegistrations);
        _pendingRemoteRegistrations.clear();
      }
      // Initialize registry
      await _registry.initialize();
      // Validate dependencies
      _dependencyResolver.validateDependencies();

      // Get initialization order
      final initOrder = _dependencyResolver.resolveInitializationOrder();
      _logger.info('Service initialization order determined', metadata: {
        'order': initOrder.map((t) => t.toString()).toList(),
      });

      // 🚀 OPTIMIZATION: Set up proxy registry and event infrastructure FIRST
      _setupProxyRegistry();

      // Initialize services in order
      for (final serviceType in initOrder) {
        await _initializeService(serviceType);
      }

      _isInitialized = true;
      _logger.info('All services initialized successfully');

      // Enhanced hooks
      await _performDependencyInjection();

      // Call initialization callbacks
      for (final callback in _initializationCallbacks) {
        try {
          await callback('ServiceLocator');
        } catch (error, stackTrace) {
          _logger.error('Initialization callback failed',
              error: error, stackTrace: stackTrace);
        }
      }
    } catch (error, stackTrace) {
      _logger.error('Service initialization failed',
          error: error, stackTrace: stackTrace);

      // Clean up any partially initialized services
      await _cleanupPartialInitialization();
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  /// Destroys all services in reverse dependency order.
  Future<void> destroyAll() async {
    if (!_isInitialized) {
      _logger.warning('Service locator is not initialized');
      return;
    }

    if (_isDestroying) {
      _logger.warning('Service locator is already being destroyed');
      return;
    }

    _isDestroying = true;
    _logger.info('Starting service destruction');

    try {
      // Call destruction callbacks
      for (final callback in _destructionCallbacks) {
        try {
          await callback('ServiceLocator');
        } catch (error, stackTrace) {
          _logger.error('Destruction callback failed',
              error: error, stackTrace: stackTrace);
        }
      }

      // Get destruction order (reverse of initialization order)
      final destructionOrder = _dependencyResolver.resolveDestructionOrder();
      _logger.info('Service destruction order determined', metadata: {
        'order': destructionOrder.map((t) => t.toString()).toList(),
      });

      // Destroy services in order
      for (final serviceType in destructionOrder) {
        await _destroyService(serviceType);
      }

      _isInitialized = false;
      _logger.info('All services destroyed successfully');

      // Enhanced cleanup
      _registry.dispose();
      await _proxyRegistry.disconnectAll();
      for (final sub in _bridgeSubscriptions) {
        try {
          await sub.cancel();
        } catch (_) {}
      }
      _bridgeSubscriptions.clear();
      for (final port in _bridgePorts) {
        try {
          port.close();
        } catch (_) {}
      }
      _bridgePorts.clear();
    } catch (error, stackTrace) {
      _logger.error('Service destruction failed',
          error: error, stackTrace: stackTrace);
      // Continue with cleanup even if some services failed to destroy
    } finally {
      _isDestroying = false;
    }
  }

  /// Adds a callback to be called after all services are initialized.
  void addInitializationCallback(ServiceLifecycleCallback callback) {
    _initializationCallbacks.add(callback);
  }

  /// Adds a callback to be called before services are destroyed.
  void addDestructionCallback(ServiceLifecycleCallback callback) {
    _destructionCallbacks.add(callback);
  }

  /// Removes an initialization callback.
  void removeInitializationCallback(ServiceLifecycleCallback callback) {
    _initializationCallbacks.remove(callback);
  }

  /// Removes a destruction callback.
  void removeDestructionCallback(ServiceLifecycleCallback callback) {
    _destructionCallbacks.remove(callback);
  }

  /// Performs health checks on all initialized services.
  Future<Map<String, ServiceHealthCheck>> performHealthChecks() async {
    final results = <String, ServiceHealthCheck>{};

    for (final entry in _instances.entries) {
      final serviceType = entry.key;
      final service = entry.value;
      final serviceName = serviceType.toString();

      try {
        final healthCheck = await service.healthCheck();
        results[serviceName] = healthCheck;
      } catch (error, stackTrace) {
        _logger.error('Health check failed for service: $serviceName',
            error: error, stackTrace: stackTrace);

        results[serviceName] = ServiceHealthCheck(
          status: ServiceHealthStatus.unhealthy,
          timestamp: DateTime.now(),
          message: 'Health check failed: $error',
        );
      }
    }

    return results;
  }

  /// Gets dependency statistics.
  DependencyStatistics getDependencyStatistics() {
    final analyzer = DependencyAnalyzer(_dependencyResolver);
    return analyzer.getStatistics();
  }

  /// Visualizes the dependency graph.
  String visualizeDependencyGraph() => _dependencyResolver.visualizeDependencyGraph();

  /// Clears all services and resets the locator.
  ///
  /// This will destroy all services if they are initialized.
  Future<void> clear() async {
    if (_isInitialized) {
      await destroyAll();
    }

    _factories.clear();
    _instances.clear();
    _serviceInfos.clear();
    _dependencyResolver.clear();
    _initializationCallbacks.clear();
    _destructionCallbacks.clear();

    _logger.info('Service locator cleared');
  }

  Future<void> _initializeService(Type serviceType) async {
    final serviceName = serviceType.toString();
    final factory = _factories[serviceType];

    if (factory == null) {
      throw ServiceNotFoundException(serviceName);
    }

    _logger.info('Initializing service: $serviceName');

    try {
      // Create service instance
      final service = factory();
      if (service == null) {
        throw ServiceFactoryException(serviceName);
      }

      // Update service info
      _serviceInfos[serviceType] = _serviceInfos[serviceType]!.copyWith(
        state: ServiceState.initializing,
        instance: service,
      );

      // Inject dependencies before initialization
      await _injectDependencies(service);

      // Initialize the service
      await service.internalInitialize();

      // Store the initialized instance
      _instances[serviceType] = service;

      // Update service info
      _serviceInfos[serviceType] = _serviceInfos[serviceType]!.copyWith(
        state: ServiceState.initialized,
        initializedAt: DateTime.now(),
      );

      _logger.info('Service initialized successfully: $serviceName');
    } catch (error, stackTrace) {
      _logger.error('Failed to initialize service: $serviceName',
          error: error, stackTrace: stackTrace);

      // Update service info with error
      _serviceInfos[serviceType] = _serviceInfos[serviceType]!.copyWith(
        state: ServiceState.failed,
        error: error,
      );

      rethrow;
    }
  }

  Future<void> _destroyService(Type serviceType) async {
    final serviceName = serviceType.toString();
    final service = _instances[serviceType];

    if (service == null) {
      // Service was never initialized or already destroyed
      return;
    }

    _logger.info('Destroying service: $serviceName');

    try {
      // Update service info
      _serviceInfos[serviceType] = _serviceInfos[serviceType]!.copyWith(
        state: ServiceState.destroying,
      );

      // Destroy the service
      await service.internalDestroy();

      // Remove from instances
      _instances.remove(serviceType);

      // Update service info
      _serviceInfos[serviceType] = _serviceInfos[serviceType]!.copyWith(
        state: ServiceState.destroyed,
        destroyedAt: DateTime.now(),
      );

      _logger.info('Service destroyed successfully: $serviceName');
    } catch (error, stackTrace) {
      _logger.error('Failed to destroy service: $serviceName',
          error: error, stackTrace: stackTrace);

      // Update service info with error
      _serviceInfos[serviceType] = _serviceInfos[serviceType]!.copyWith(
        state: ServiceState.failed,
        error: error,
      );

      // Don't rethrow destruction errors to avoid cascading failures
    }
  }

  /// Inject dependencies into a service
  Future<void> _injectDependencies(BaseService service) async {
    final dependencies = service.dependencies;
    final optionalDependencies = service.optionalDependencies;

    // Inject required dependencies
    for (final depType in dependencies) {
      final dependency = _instances[depType];
      if (dependency != null) {
        service.onDependencyAvailable(depType, dependency);
      }
    }

    // Inject optional dependencies
    for (final depType in optionalDependencies) {
      final dependency = _instances[depType];
      if (dependency != null) {
        service.onDependencyAvailable(depType, dependency);
      }
    }
  }

  Future<void> _cleanupPartialInitialization() async {
    _logger.info('Cleaning up partially initialized services');

    // Destroy any services that were successfully initialized
    final initializedServices = List.from(_instances.keys);
    for (final serviceType in initializedServices.reversed) {
      await _destroyService(serviceType);
    }

    _instances.clear();
  }
}

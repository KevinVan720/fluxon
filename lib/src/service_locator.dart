/// Service locator for registering and managing services.
library service_locator;

import 'dart:async';

import 'base_service.dart';
import 'dependency_resolver.dart';
import 'exceptions/service_exceptions.dart';
import 'service_logger.dart';
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
  }

  final ServiceLogger _logger;
  late final DependencyResolver _dependencyResolver;

  final Map<Type, ServiceFactory> _factories = {};
  final Map<Type, BaseService> _instances = {};
  final Map<Type, ServiceInfo> _serviceInfos = {};

  bool _isInitialized = false;
  bool _isInitializing = false;
  bool _isDestroying = false;

  final List<ServiceLifecycleCallback> _initializationCallbacks = [];
  final List<ServiceLifecycleCallback> _destructionCallbacks = [];

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
      throw ServiceStateException(
        'ServiceLocator',
        'initialized',
        'not initialized',
      );
    }

    _factories[serviceType] = factory;

    // Create a temporary instance to get dependency information
    final tempInstance = factory();
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
      throw ServiceLocatorNotInitializedException();
    }

    final instance = _instances[serviceType];
    if (instance == null) {
      throw ServiceNotFoundException(serviceName);
    }

    if (instance is! T) {
      throw InvalidServiceTypeException(
          'Service "$serviceName" is not of type $T');
    }

    instance.ensureNotDestroyed();
    return instance;
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
  bool isRegistered<T extends BaseService>() {
    return _factories.containsKey(T);
  }

  /// Checks if a service is initialized.
  bool isServiceInitialized<T extends BaseService>() {
    return _instances.containsKey(T);
  }

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
  List<ServiceInfo> getAllServiceInfo() {
    return List.from(_serviceInfos.values);
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
      throw ServiceStateException(
        'ServiceLocator',
        'initializing',
        'not initializing',
      );
    }

    _isInitializing = true;
    _logger.info('Starting service initialization');

    try {
      // Validate dependencies
      _dependencyResolver.validateDependencies();

      // Get initialization order
      final initOrder = _dependencyResolver.resolveInitializationOrder();
      _logger.info('Service initialization order determined', metadata: {
        'order': initOrder.map((t) => t.toString()).toList(),
      });

      // Initialize services in order
      for (final serviceType in initOrder) {
        await _initializeService(serviceType);
      }

      _isInitialized = true;
      _logger.info('All services initialized successfully');

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
  String visualizeDependencyGraph() {
    return _dependencyResolver.visualizeDependencyGraph();
  }

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

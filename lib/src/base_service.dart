/// Base service class that all services must extend.
library base_service;

import 'dart:async';
import 'package:meta/meta.dart';

import 'exceptions/service_exceptions.dart';
import 'service_logger.dart';
import 'types/service_types.dart';

/// Abstract base class for all services in the framework.
///
/// Services must extend this class and implement the required methods.
/// The base class provides common functionality like logging, lifecycle
/// management, and dependency declaration.
abstract class BaseService {
  /// Creates a base service.
  BaseService({
    ServiceConfig? config,
    ServiceLogger? logger,
  })  : _config = config ?? const ServiceConfig(),
        _logger = logger ?? ServiceLogger(serviceName: _getServiceName()) {
    _state = ServiceState.registered;
    _registeredAt = DateTime.now();
    // Replace fallback logger name with the concrete type once constructed
    if (logger == null) {
      _logger = ServiceLogger(serviceName: serviceName);
    }
  }

  final ServiceConfig _config;
  late ServiceLogger _logger;
  late ServiceState _state;
  DateTime? _registeredAt;
  DateTime? _initializedAt;
  DateTime? _destroyedAt;
  Object? _error;

  /// Gets the service configuration.
  ServiceConfig get config => _config;

  /// Gets the service logger.
  ServiceLogger get logger => _logger;

  /// Gets the current service state.
  ServiceState get state => _state;

  /// Gets when the service was registered.
  DateTime? get registeredAt => _registeredAt;

  /// Gets when the service was initialized.
  DateTime? get initializedAt => _initializedAt;

  /// Gets when the service was destroyed.
  DateTime? get destroyedAt => _destroyedAt;

  /// Gets the last error that occurred.
  Object? get error => _error;

  /// Gets the service name (typically the class name).
  String get serviceName => runtimeType.toString();

  /// Gets whether the service is initialized.
  bool get isInitialized => _state == ServiceState.initialized;

  /// Gets whether the service is destroyed.
  bool get isDestroyed => _state == ServiceState.destroyed;

  /// Gets whether the service has failed.
  bool get hasFailed => _state == ServiceState.failed;

  /// Declares the dependencies for this service.
  ///
  /// Services listed here will be initialized before this service.
  /// Override this method to declare dependencies.
  List<Type> get dependencies => const [];

  /// Declares optional dependencies for this service.
  ///
  /// These services will be initialized before this service if they are
  /// registered, but are not required for this service to function.
  List<Type> get optionalDependencies => const [];

  // Dependency management
  final Map<Type, BaseService> _dependencies = {};

  /// Get a dependency service
  @protected
  T? getDependency<T extends BaseService>() => _dependencies[T] as T?;

  /// Get a required dependency service (throws if not available)
  @protected
  T getRequiredDependency<T extends BaseService>() {
    final dependency = getDependency<T>();
    if (dependency == null) {
      throw ServiceException(
          'Required dependency $T is not available for service $serviceName');
    }
    return dependency;
  }

  /// Called when a dependent service becomes available
  @mustCallSuper
  void onDependencyAvailable(Type serviceType, BaseService service) {
    _dependencies[serviceType] = service;
    _logger.debug('Dependency $serviceType is now available');
  }

  /// Called when a dependent service becomes unavailable
  @mustCallSuper
  void onDependencyUnavailable(Type serviceType) {
    _dependencies.remove(serviceType);
    _logger.debug('Dependency $serviceType is no longer available');
  }

  /// Check if all required dependencies are available
  bool get hasAllDependencies {
    for (final depType in dependencies) {
      if (!_dependencies.containsKey(depType)) {
        return false;
      }
    }
    return true;
  }

  /// Initializes the service.
  ///
  /// This method is called automatically by the service locator when
  /// all dependencies are satisfied. Override this method to perform
  /// service-specific initialization.
  Future<void> initialize() async {
    // Default implementation does nothing
  }

  /// Destroys the service and cleans up resources.
  ///
  /// This method is called automatically by the service locator during
  /// shutdown. Override this method to perform service-specific cleanup.
  Future<void> destroy() async {
    // Default implementation does nothing
  }

  /// Performs a health check on the service.
  ///
  /// Override this method to implement service-specific health checks.
  Future<ServiceHealthCheck> healthCheck() async {
    if (_state == ServiceState.initialized) {
      return ServiceHealthCheck(
        status: ServiceHealthStatus.healthy,
        timestamp: DateTime.now(),
        message: 'Service is running normally',
      );
    } else if (_state == ServiceState.failed) {
      return ServiceHealthCheck(
        status: ServiceHealthStatus.unhealthy,
        timestamp: DateTime.now(),
        message: 'Service has failed',
        details: {'error': _error?.toString()},
      );
    } else {
      return ServiceHealthCheck(
        status: ServiceHealthStatus.unknown,
        timestamp: DateTime.now(),
        message: 'Service state: $_state',
      );
    }
  }

  /// Called internally by the framework to initialize the service.
  Future<void> internalInitialize() async {
    if (_state != ServiceState.registered) {
      throw ServiceStateException(
          serviceName, _state.toString(), ServiceState.registered.toString());
    }

    _setState(ServiceState.initializing);
    _logger.info('Initializing service');

    try {
      await _withTimeout(
        initialize(),
        _config.timeout,
        'Service initialization',
      );

      _setState(ServiceState.initialized);
      _initializedAt = DateTime.now();
      _logger.info('Service initialized successfully');
    } catch (error, stackTrace) {
      _error = error;
      _setState(ServiceState.failed);
      _logger.error('Service initialization failed',
          error: error, stackTrace: stackTrace);
      throw ServiceInitializationException(serviceName, error);
    }
  }

  /// Called internally by the framework to destroy the service.
  Future<void> internalDestroy() async {
    if (_state == ServiceState.destroyed) {
      return; // Already destroyed
    }

    if (_state == ServiceState.destroying) {
      return; // Already being destroyed
    }

    _setState(ServiceState.destroying);
    _logger.info('Destroying service');

    try {
      await _withTimeout(
        destroy(),
        _config.timeout,
        'Service destruction',
      );

      _setState(ServiceState.destroyed);
      _destroyedAt = DateTime.now();
      _logger.info('Service destroyed successfully');
    } catch (error, stackTrace) {
      _error = error;
      _setState(ServiceState.failed);
      _logger.error('Service destruction failed',
          error: error, stackTrace: stackTrace);
      // Don't rethrow destruction errors to avoid cascading failures
    }
  }

  /// Ensures the service is in the initialized state.
  void ensureInitialized() {
    if (_state != ServiceState.initialized) {
      throw ServiceStateException(
        serviceName,
        _state.toString(),
        ServiceState.initialized.toString(),
      );
    }
  }

  /// Ensures the service is not destroyed.
  void ensureNotDestroyed() {
    if (_state == ServiceState.destroyed) {
      throw ServiceDestroyedException(serviceName);
    }
  }

  /// Sets metadata on the service logger.
  void setLoggerMetadata(Map<String, dynamic> metadata) {
    _logger.setMetadata(metadata);
  }

  /// Adds metadata to the service logger.
  void addLoggerMetadata(String key, dynamic value) {
    _logger.addMetadata(key, value);
  }

  /// Creates a child logger with additional metadata.
  ServiceLogger createChildLogger(Map<String, dynamic> metadata) {
    return _logger.child(metadata);
  }

  /// Executes an operation with retry logic.
  Future<T> withRetry<T>(
    String operationName,
    Future<T> Function() operation, {
    int? maxAttempts,
    Duration? retryDelay,
  }) async {
    final attempts = maxAttempts ?? _config.retryAttempts;
    final delay = retryDelay ?? _config.retryDelay;

    for (int attempt = 1; attempt <= attempts; attempt++) {
      try {
        return await operation();
      } catch (error, stackTrace) {
        if (attempt == attempts) {
          _logger.error(
              'Operation "$operationName" failed after $attempts attempts',
              error: error,
              stackTrace: stackTrace);
          throw ServiceRetryExceededException(operationName, attempts);
        }

        _logger.warning(
            'Operation "$operationName" failed (attempt $attempt/$attempts), retrying...',
            metadata: {'error': error.toString()});

        if (delay > Duration.zero) {
          await Future.delayed(delay);
        }
      }
    }

    // This should never be reached
    throw ServiceRetryExceededException(operationName, attempts);
  }

  /// Gets information about this service.
  ServiceInfo getServiceInfo() {
    return ServiceInfo(
      name: serviceName,
      type: runtimeType,
      dependencies: dependencies,
      state: _state,
      config: _config,
      instance: this,
      error: _error,
      registeredAt: _registeredAt,
      initializedAt: _initializedAt,
      destroyedAt: _destroyedAt,
    );
  }

  void _setState(ServiceState newState) {
    final oldState = _state;
    _state = newState;
    _logger.debug('Service state changed: $oldState -> $newState');
  }

  Future<T> _withTimeout<T>(
    Future<T> future,
    Duration timeout,
    String operationName,
  ) async {
    try {
      return await future.timeout(timeout);
    } on TimeoutException {
      throw ServiceTimeoutException(operationName, timeout);
    }
  }

  static String _getServiceName() {
    // This is a fallback for when the service name is needed before
    // the instance is fully constructed
    return 'UnknownService';
  }

  @override
  String toString() {
    return '$serviceName(state: $_state)';
  }
}

/// Mixin for services that need periodic tasks.
mixin PeriodicServiceMixin on BaseService {
  Timer? _periodicTimer;

  /// The interval for periodic tasks.
  Duration get periodicInterval => const Duration(minutes: 1);

  /// Whether periodic tasks are enabled.
  bool get periodicTasksEnabled => true;

  /// Performs periodic tasks.
  Future<void> performPeriodicTask() async {
    // Override in subclasses
  }

  @override
  Future<void> initialize() async {
    await super.initialize();

    if (periodicTasksEnabled) {
      _startPeriodicTasks();
    }
  }

  @override
  Future<void> destroy() async {
    _stopPeriodicTasks();
    await super.destroy();
  }

  void _startPeriodicTasks() {
    _periodicTimer = Timer.periodic(periodicInterval, (_) async {
      try {
        await performPeriodicTask();
      } catch (error, stackTrace) {
        logger.error('Periodic task failed',
            error: error, stackTrace: stackTrace);
      }
    });

    logger.debug('Started periodic tasks with interval: $periodicInterval');
  }

  void _stopPeriodicTasks() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
    logger.debug('Stopped periodic tasks');
  }
}

/// Mixin for services that need configuration validation.
mixin ConfigurableServiceMixin on BaseService {
  /// Validates the service configuration.
  ///
  /// Override this method to implement configuration validation.
  /// Throw a [ServiceConfigurationException] if the configuration is invalid.
  void validateConfiguration() {
    // Override in subclasses
  }

  @override
  Future<void> initialize() async {
    try {
      validateConfiguration();
    } catch (error) {
      throw ServiceConfigurationException(
        'Configuration validation failed for $serviceName: $error',
        error,
      );
    }

    await super.initialize();
  }
}

/// Mixin for services that need resource management.
mixin ResourceManagedServiceMixin on BaseService {
  final List<StreamSubscription> _subscriptions = [];
  final List<Timer> _timers = [];

  /// Registers a stream subscription for automatic cleanup.
  void registerSubscription(StreamSubscription subscription) {
    _subscriptions.add(subscription);
  }

  /// Registers a timer for automatic cleanup.
  void registerTimer(Timer timer) {
    _timers.add(timer);
  }

  @override
  Future<void> destroy() async {
    // Cancel all subscriptions
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();

    // Cancel all timers
    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();

    await super.destroy();
  }
}

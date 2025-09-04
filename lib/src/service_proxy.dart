/// Service proxy system for transparent inter-service communication.
library service_proxy;

import 'dart:async';

import 'base_service.dart';
import 'events/event_mixin.dart';
import 'exceptions/service_exceptions.dart';
import 'service_logger.dart';
import 'service_worker.dart';
import 'types/service_types.dart';

/// Interface for service proxy implementations.
abstract class ServiceProxy<T extends BaseService> {
  /// The target service type.
  Type get targetType;

  /// Whether the proxy is connected to a service.
  bool get isConnected;

  /// Calls a method on the target service.
  Future<R> callMethod<R>(
    String methodName,
    List<dynamic> positionalArgs, {
    Map<String, dynamic>? namedArgs,
    ServiceCallOptions? options,
  });

  /// Connects the proxy to a service instance or worker.
  Future<void> connect(target);

  /// Disconnects the proxy.
  Future<void> disconnect();
}

typedef ServiceClientFactory<T extends BaseService> = T Function(
  ServiceProxy<T> proxy,
);

class GeneratedClientRegistry {
  static final Map<Type, dynamic> _factories = {};

  static void register<T extends BaseService>(ServiceClientFactory<T> factory) {
    _factories[T] = factory;
  }

  static T? create<T extends BaseService>(ServiceProxy<T> proxy) {
    final dynamic factory = _factories[T];
    if (factory == null) return null;
    final typedFactory =
        factory as ServiceClientFactory<T>;
    return typedFactory(proxy);
  }
}

/// Proxy for services running in the same isolate.
class LocalServiceProxy<T extends BaseService> implements ServiceProxy<T> {
  /// Creates a local service proxy.
  LocalServiceProxy({
    ServiceLogger? logger,
  }) : _logger = logger ?? ServiceLogger(serviceName: 'LocalServiceProxy<$T>');

  final ServiceLogger _logger;
  T? _service;

  /// Exposes the underlying local instance if connected.
  T? peekInstance() => _service;

  @override
  Type get targetType => T;

  @override
  bool get isConnected => _service != null;

  @override
  Future<void> connect(target) async {
    if (target is! T) {
      throw InvalidServiceTypeException(
          'Expected service of type $T, got ${target.runtimeType}');
    }

    _service = target;
    _logger.debug('Connected to local service: ${target.serviceName}');
  }

  @override
  Future<void> disconnect() async {
    if (_service != null) {
      _logger
          .debug('Disconnected from local service: ${_service!.serviceName}');
      _service = null;
    }
  }

  @override
  Future<R> callMethod<R>(
    String methodName,
    List<dynamic> positionalArgs, {
    Map<String, dynamic>? namedArgs,
    ServiceCallOptions? options,
  }) async {
    // Name-based invocation on local proxies is disabled to remove reflection paths.
    // Services should obtain local instances via ServiceClientMixin.getService<T>(),
    // which returns the actual instance for LocalServiceProxy.
    throw const ServiceException(
        'LocalServiceProxy does not support name-based calls. Use direct instance returned by getService<T>()');
  }
}

/// Proxy for services running in worker isolates.
class WorkerServiceProxy<T extends BaseService> implements ServiceProxy<T> {
  /// Creates a worker service proxy.
  WorkerServiceProxy({
    ServiceLogger? logger,
  }) : _logger = logger ?? ServiceLogger(serviceName: 'WorkerServiceProxy<$T>');

  final ServiceLogger _logger;
  ServiceWorker? _worker;

  @override
  Type get targetType => T;

  @override
  bool get isConnected => _worker != null && !_worker!.isStopped;

  @override
  Future<void> connect(target) async {
    if (target is! ServiceWorker) {
      throw InvalidServiceTypeException(
          'Expected ServiceWorker, got ${target.runtimeType}');
    }

    _worker = target;
    _logger.debug('Connected to worker service: ${target.serviceName}');
  }

  @override
  Future<void> disconnect() async {
    final worker = _worker;
    if (worker != null) {
      try {
        // Attempt graceful shutdown of the service in the isolate
        await worker.destroyService();
      } catch (e) {
        // Ignore errors during teardown
      }
      try {
        worker.stop();
      } catch (e) {
        // Ignore errors during stop
      }
      _logger.debug('Disconnected from worker service: ${worker.serviceName}');
      _worker = null;
    }
  }

  @override
  Future<R> callMethod<R>(
    String methodName,
    List<dynamic> positionalArgs, {
    Map<String, dynamic>? namedArgs,
    ServiceCallOptions? options,
  }) async {
    final worker = _worker;
    if (worker == null || worker.isStopped) {
      throw ServiceStateException(
        T.toString(),
        'disconnected',
        'connected',
      );
    }

    final callOptions = options ?? const ServiceCallOptions();

    try {
      final methodId = ServiceMethodIdRegistry.tryGetId<T>(methodName);
      if (methodId == null) {
        throw ServiceException(
            'No generated method id for $T.$methodName. Ensure codegen ran and method IDs are registered.');
      }
      return await _callMethodByIdWithRetry<R>(
        worker,
        methodId,
        positionalArgs,
        namedArgs ?? const {},
        callOptions,
      );
    } catch (error) {
      List<String> _stringifyList(List<dynamic> list) =>
          list.map((e) => e?.toString() ?? 'null').toList();
      Map<String, String>? _stringifyMap(Map<String, dynamic>? map) =>
          map?.map((k, v) => MapEntry(k, v?.toString() ?? 'null'));
      _logger.error('Worker method call failed', error: error, metadata: {
        'service': worker.serviceName,
        'method': methodName,
        'positional': _stringifyList(positionalArgs),
        'named': _stringifyMap(namedArgs ?? const {}),
      });
      rethrow;
    }
  }

  Future<R> _callMethodByIdWithRetry<R>(
    ServiceWorker worker,
    int methodId,
    List<dynamic> positionalArgs,
    Map<String, dynamic> namedArgs,
    ServiceCallOptions options,
  ) async {
    var attempt = 0;
    final maxAttempts = options.retryAttempts + 1;

    while (attempt < maxAttempts) {
      try {
        final result = await worker.send(6, args: [
          methodId,
          positionalArgs,
          namedArgs
        ]).timeout(options.timeout);
        return result as R;
      } on TimeoutException {
        attempt++;
        if (attempt >= maxAttempts) {
          throw ServiceTimeoutException(
              'Method call by id: $methodId', options.timeout);
        }
        _logger.warning('Call timed out, retrying...', metadata: {
          'methodId': methodId,
          'timeout_ms': options.timeout.inMilliseconds,
          'attempt': attempt,
          'maxAttempts': maxAttempts,
        });
        if (options.retryDelay > Duration.zero) {
          await Future.delayed(options.retryDelay);
        }
      } catch (error) {
        attempt++;
        if (attempt >= maxAttempts) {
          throw ServiceRetryExceededException(
            'Method call by id: $methodId',
            options.retryAttempts,
          );
        }
        _logger.warning(
          'Method call by id failed (attempt $attempt/$maxAttempts), retrying...',
          metadata: {
            'methodId': methodId,
            'error': error.toString(),
          },
        );
        if (options.retryDelay > Duration.zero) {
          await Future.delayed(options.retryDelay);
        }
      }
    }
    throw ServiceRetryExceededException(
        'Method call by id: $methodId', maxAttempts);
  }
}

/// Factory for creating service proxies.
class ServiceProxyFactory {
  /// Creates a service proxy factory.
  const ServiceProxyFactory();

  /// Creates a local service proxy.
  LocalServiceProxy<T> createLocalProxy<T extends BaseService>({
    ServiceLogger? logger,
  }) => LocalServiceProxy<T>(logger: logger);

  /// Creates a worker service proxy.
  WorkerServiceProxy<T> createWorkerProxy<T extends BaseService>({
    ServiceLogger? logger,
  }) => WorkerServiceProxy<T>(logger: logger);

  /// Creates the appropriate proxy based on the target.
  ServiceProxy<T> createProxy<T extends BaseService>(
    target, {
    ServiceLogger? logger,
  }) {
    if (target is BaseService) {
      final proxy = createLocalProxy<T>(logger: logger);
      proxy.connect(target);
      return proxy;
    } else if (target is ServiceWorker) {
      final proxy = createWorkerProxy<T>(logger: logger);
      proxy.connect(target);
      return proxy;
    } else {
      throw InvalidServiceTypeException(
          'Cannot create proxy for target of type ${target.runtimeType}');
    }
  }
}

/// Registry for managing service proxies.
class ServiceProxyRegistry {
  /// Creates a service proxy registry.
  ServiceProxyRegistry({
    ServiceLogger? logger,
  }) : _logger = logger ?? ServiceLogger(serviceName: 'ServiceProxyRegistry');

  final ServiceLogger _logger;
  final ServiceProxyFactory _factory = const ServiceProxyFactory();
  final Map<Type, ServiceProxy> _proxies = {};

  /// Registers a proxy for a service type.
  void registerProxy<T extends BaseService>(ServiceProxy<T> proxy) {
    _proxies[T] = proxy;
    _logger.debug('Registered proxy for service type: $T');
  }

  /// Registers a proxy for a specific [type] at runtime.
  void registerProxyForType(Type type, ServiceProxy proxy) {
    _proxies[type] = proxy;
    _logger.debug('Registered proxy for service type: $type');
  }

  /// Gets a proxy for a service type.
  ServiceProxy getProxy<T extends BaseService>() {
    final proxy = _proxies[T];
    if (proxy == null) {
      throw ServiceNotFoundException(T.toString());
    }
    return proxy;
  }

  /// Creates and registers a proxy for a service.
  ServiceProxy<T> createAndRegisterProxy<T extends BaseService>(
    target, {
    ServiceLogger? logger,
  }) {
    final proxy = _factory.createProxy<T>(target, logger: logger);
    registerProxy<T>(proxy);
    return proxy;
  }

  /// Removes a proxy for a service type.
  Future<void> removeProxy<T extends BaseService>() async {
    final proxy = _proxies.remove(T);
    if (proxy != null) {
      await proxy.disconnect();
      _logger.debug('Removed proxy for service type: $T');
    }
  }

  /// Checks if a proxy is registered for a service type.
  bool hasProxy<T extends BaseService>() => _proxies.containsKey(T);

  /// Gets all registered proxy types.
  Set<Type> get registeredTypes => Set.from(_proxies.keys);

  /// Gets a proxy by runtime type, or null if not registered.
  ServiceProxy? tryGetProxyByType(Type type) => _proxies[type];

  /// Disconnects all proxies.
  Future<void> disconnectAll() async {
    for (final proxy in _proxies.values) {
      try {
        await proxy.disconnect();
      } catch (error) {
        _logger.error('Error disconnecting proxy', error: error);
      }
    }
    _proxies.clear();
    _logger.info('Disconnected all proxies');
  }

  /// Gets statistics about registered proxies.
  Map<String, dynamic> getStatistics() {
    final stats = <String, dynamic>{};

    for (final entry in _proxies.entries) {
      final type = entry.key;
      final proxy = entry.value;

      stats[type.toString()] = {
        'connected': proxy.isConnected,
        'proxyType': proxy.runtimeType.toString(),
      };
    }

    return stats;
  }
}

/// Mixin for services that need to call other services.
mixin ServiceClientMixin on BaseService {
  ServiceProxyRegistry? _proxyRegistry;

  /// Sets the proxy registry for this service.
  void setProxyRegistry(ServiceProxyRegistry registry) {
    _proxyRegistry = registry;

    // Automatically set up event infrastructure if this service uses events
    if (this is ServiceEventMixin) {
      _setupEventInfrastructure(registry);
    }
  }

  /// Automatically set up event infrastructure
  void _setupEventInfrastructure(ServiceProxyRegistry registry) {
    // This will be called automatically when the service is registered
    // The ServiceLocator will handle the actual setup
  }

  /// Gets a service client for calling another service.
  T getService<T extends BaseService>() {
    final registry = _proxyRegistry;
    if (registry == null) {
      throw ServiceException(
          'Proxy registry not set for service $serviceName');
    }

    final proxy = registry.getProxy<T>();
    // Prefer returning the real local instance when available
    if (proxy is LocalServiceProxy) {
      final instance = proxy.peekInstance();
      if (instance != null && instance is T) return instance;
    }
    final generated =
        GeneratedClientRegistry.create<T>(proxy as ServiceProxy<T>);
    if (generated != null) return generated;
    throw ServiceException(
        'No generated client for $T. Ensure codegen ran and client factory is registered.');
  }

  /// Checks if a service is available.
  bool hasService<T extends BaseService>() {
    final registry = _proxyRegistry;
    if (registry == null) {
      return false;
    }

    return registry.hasProxy<T>() && registry.getProxy<T>().isConnected;
  }
}

// Dynamic client removed: reflection path is no longer supported.

/// Lookup table for generated method IDs (populated by generated code via mixin)
class ServiceMethodIdRegistry {
  static final Map<Type, Map<String, int>> _ids = {};
  static void register<T extends BaseService>(Map<String, int> methodIds) {
    _ids[T] = methodIds;
  }

  static int? tryGetId<T extends BaseService>(String methodName) {
    final map = _ids[T];
    return map?[methodName];
  }

  /// Lookup by runtime [type]. Returns null if none or method not found.
  static int? tryGetIdByType(Type type, String methodName) {
    final map = _ids[type];
    return map?[methodName];
  }
}

/// Interceptor for method calls on service proxies.
class ServiceCallInterceptor {
  /// Creates a service call interceptor.
  const ServiceCallInterceptor();

  /// Intercepts a method call before it's executed.
  Future<void> beforeCall(
    String serviceName,
    String methodName,
    List<dynamic> args,
  ) async {
    // Override in subclasses for custom behavior
  }

  /// Intercepts a method call after it's executed.
  Future<void> afterCall(
    String serviceName,
    String methodName,
    List<dynamic> args,
    result,
    Duration duration,
  ) async {
    // Override in subclasses for custom behavior
  }

  /// Intercepts a method call when an error occurs.
  Future<void> onError(
    String serviceName,
    String methodName,
    List<dynamic> args,
    Object error,
    StackTrace stackTrace,
  ) async {
    // Override in subclasses for custom behavior
  }
}

/// Logging interceptor that logs all service method calls.
class LoggingServiceInterceptor extends ServiceCallInterceptor {
  /// Creates a logging service interceptor.
  LoggingServiceInterceptor({
    ServiceLogger? logger,
  }) : _logger = logger ?? ServiceLogger(serviceName: 'ServiceInterceptor');

  final ServiceLogger _logger;

  @override
  Future<void> beforeCall(
    String serviceName,
    String methodName,
    List<dynamic> args,
  ) async {
    _logger.debug('Calling service method', metadata: {
      'service': serviceName,
      'method': methodName,
      'args': args,
    });
  }

  @override
  Future<void> afterCall(
    String serviceName,
    String methodName,
    List<dynamic> args,
    result,
    Duration duration,
  ) async {
    _logger.debug('Service method completed', metadata: {
      'service': serviceName,
      'method': methodName,
      'duration_ms': duration.inMilliseconds,
    });
  }

  @override
  Future<void> onError(
    String serviceName,
    String methodName,
    List<dynamic> args,
    Object error,
    StackTrace stackTrace,
  ) async {
    _logger.error('Service method failed',
        error: error,
        stackTrace: stackTrace,
        metadata: {
          'service': serviceName,
          'method': methodName,
          'args': args,
        });
  }
}

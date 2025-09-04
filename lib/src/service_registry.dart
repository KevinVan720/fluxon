/// Service registry for managing cross-isolate service communication
library service_registry;

import 'dart:async';
import 'dart:isolate';

import 'package:meta/meta.dart';

import 'base_service.dart';
import 'service_logger.dart';
import 'exceptions/service_exceptions.dart';

/// Message types for cross-isolate communication
enum ServiceMessageType {
  methodCall,
  methodResponse,
  methodError,
  serviceAvailable,
  serviceUnavailable,
  healthCheck,
}

/// Message for cross-isolate service communication
class ServiceMessage {
  const ServiceMessage({
    required this.type,
    required this.serviceType,
    required this.requestId,
    this.methodName,
    this.arguments,
    this.result,
    this.error,
    this.stackTrace,
  });

  final ServiceMessageType type;
  final String serviceType;
  final String requestId;
  final String? methodName;
  final Map<String, dynamic>? arguments;
  final dynamic result;
  final String? error;
  final String? stackTrace;

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'serviceType': serviceType,
      'requestId': requestId,
      'methodName': methodName,
      'arguments': arguments,
      'result': result,
      'error': error,
      'stackTrace': stackTrace,
    };
  }

  factory ServiceMessage.fromJson(Map<String, dynamic> json) {
    return ServiceMessage(
      type: ServiceMessageType.values.byName(json['type'] as String),
      serviceType: json['serviceType'] as String,
      requestId: json['requestId'] as String,
      methodName: json['methodName'] as String?,
      arguments: json['arguments'] as Map<String, dynamic>?,
      result: json['result'],
      error: json['error'] as String?,
      stackTrace: json['stackTrace'] as String?,
    );
  }
}

/// Service proxy for transparent cross-isolate method calls
class ServiceRegistryProxy<T extends BaseService> {
  ServiceRegistryProxy({
    required this.serviceType,
    required this.sendPort,
    required this.logger,
  }) : _requestId = 0;

  final Type serviceType;
  final SendPort sendPort;
  final ServiceLogger logger;
  int _requestId;
  final Map<String, Completer<dynamic>> _pendingRequests = {};

  /// Handle incoming messages from the service isolate
  void handleMessage(ServiceMessage message) {
    switch (message.type) {
      case ServiceMessageType.methodResponse:
        _handleMethodResponse(message);
        break;
      case ServiceMessageType.methodError:
        _handleMethodError(message);
        break;
      default:
        logger.warning('Unexpected message type: ${message.type}');
    }
  }

  /// Call a method on the remote service
  Future<R> callMethod<R>(String methodName,
      [Map<String, dynamic>? arguments]) async {
    final requestId =
        'req_${++_requestId}_${DateTime.now().millisecondsSinceEpoch}';
    final completer = Completer<R>();

    _pendingRequests[requestId] = completer;

    final message = ServiceMessage(
      type: ServiceMessageType.methodCall,
      serviceType: serviceType.toString(),
      requestId: requestId,
      methodName: methodName,
      arguments: arguments ?? {},
    );

    logger.debug('Calling remote method', metadata: {
      'service': serviceType.toString(),
      'method': methodName,
      'requestId': requestId,
    });

    sendPort.send(message.toJson());

    // Set up timeout
    Timer(const Duration(seconds: 30), () {
      if (_pendingRequests.containsKey(requestId)) {
        _pendingRequests.remove(requestId);
        if (!completer.isCompleted) {
          completer.completeError(ServiceTimeoutException(
              'Method call', const Duration(seconds: 30)));
        }
      }
    });

    return completer.future;
  }

  void _handleMethodResponse(ServiceMessage message) {
    final completer = _pendingRequests.remove(message.requestId);
    if (completer != null && !completer.isCompleted) {
      logger.debug('Received method response', metadata: {
        'requestId': message.requestId,
      });
      completer.complete(message.result);
    }
  }

  void _handleMethodError(ServiceMessage message) {
    final completer = _pendingRequests.remove(message.requestId);
    if (completer != null && !completer.isCompleted) {
      logger.warning('Received method error', metadata: {
        'requestId': message.requestId,
        'error': message.error,
      });

      final error = ServiceException(
        message.error ?? 'Unknown remote service error',
        message.stackTrace,
      );
      completer.completeError(error);
    }
  }

  /// Clean up pending requests
  void dispose() {
    for (final completer in _pendingRequests.values) {
      if (!completer.isCompleted) {
        completer.completeError(ServiceException('Service proxy disposed'));
      }
    }
    _pendingRequests.clear();
  }
}

/// Service registry for managing service instances and communication
class ServiceRegistry {
  ServiceRegistry({ServiceLogger? logger})
      : _logger = logger ?? ServiceLogger(serviceName: 'ServiceRegistry');

  final ServiceLogger _logger;
  final Map<Type, BaseService> _localServices = {};
  final Map<Type, ServiceRegistryProxy> _remoteServices = {};
  final Map<Type, SendPort> _servicePorts = {};
  ReceivePort? _receivePort;
  SendPort? _mainSendPort;

  /// Initialize the service registry
  Future<void> initialize({SendPort? mainSendPort}) async {
    _mainSendPort = mainSendPort;
    _receivePort = ReceivePort();

    // Listen for incoming messages
    _receivePort!.listen((message) {
      try {
        if (message is Map<String, dynamic>) {
          final serviceMessage = ServiceMessage.fromJson(message);
          _handleMessage(serviceMessage);
        }
      } catch (e, stackTrace) {
        _logger.error('Error handling registry message',
            error: e, stackTrace: stackTrace);
      }
    });

    _logger.info('Service registry initialized');
  }

  /// Register a local service
  void registerLocalService<T extends BaseService>(T service) {
    _localServices[T] = service;
    _logger.info('Local service registered: $T');

    // Notify other isolates that this service is available
    _notifyServiceAvailable(T, service);
  }

  /// Register a remote service with its communication port
  void registerRemoteService<T extends BaseService>(SendPort sendPort) {
    _servicePorts[T] = sendPort;

    final proxy = ServiceRegistryProxy<T>(
      serviceType: T,
      sendPort: sendPort,
      logger: _logger,
    );

    _remoteServices[T] = proxy;
    _logger.info('Remote service registered: $T');
  }

  /// Get a service (local or remote)
  T? getService<T extends BaseService>() {
    // Try local first
    final localService = _localServices[T];
    if (localService != null) {
      return localService as T;
    }

    // Try remote proxy
    final remoteProxy = _remoteServices[T];
    if (remoteProxy != null) {
      return remoteProxy as T;
    }

    return null;
  }

  /// Check if a service is available
  bool hasService<T extends BaseService>() {
    return _localServices.containsKey(T) || _remoteServices.containsKey(T);
  }

  /// Get all available service types
  Set<Type> get availableServices {
    return {..._localServices.keys, ..._remoteServices.keys};
  }

  /// Handle incoming messages
  void _handleMessage(ServiceMessage message) {
    switch (message.type) {
      case ServiceMessageType.methodCall:
        _handleMethodCall(message);
        break;
      case ServiceMessageType.serviceAvailable:
        _handleServiceAvailable(message);
        break;
      case ServiceMessageType.serviceUnavailable:
        _handleServiceUnavailable(message);
        break;
      case ServiceMessageType.methodResponse:
      case ServiceMessageType.methodError:
        // Forward to the appropriate proxy
        final serviceType = _getTypeFromString(message.serviceType);
        if (serviceType != null) {
          final proxy = _remoteServices[serviceType];
          proxy?.handleMessage(message);
        }
        break;
      default:
        _logger.warning('Unhandled message type: ${message.type}');
    }
  }

  /// Handle method call on local service
  Future<void> _handleMethodCall(ServiceMessage message) async {
    final serviceType = _getTypeFromString(message.serviceType);
    if (serviceType == null) {
      _sendError(message, 'Unknown service type: ${message.serviceType}');
      return;
    }

    final service = _localServices[serviceType];
    if (service == null) {
      _sendError(message, 'Service not available: ${message.serviceType}');
      return;
    }

    try {
      _logger.debug('Handling method call', metadata: {
        'service': message.serviceType,
        'method': message.methodName,
        'requestId': message.requestId,
      });

      // Use reflection or a method dispatcher to call the actual method
      final result = await _dispatchMethod(
          service, message.methodName!, message.arguments ?? {});

      _sendResponse(message, result);
    } catch (error, stackTrace) {
      _logger.error('Method call failed',
          metadata: {
            'service': message.serviceType,
            'method': message.methodName,
            'requestId': message.requestId,
          },
          error: error,
          stackTrace: stackTrace);

      _sendError(message, error.toString(), stackTrace.toString());
    }
  }

  /// Dispatch method call to service (simplified - in real implementation would use reflection)
  Future<dynamic> _dispatchMethod(BaseService service, String methodName,
      Map<String, dynamic> arguments) async {
    // This is a simplified dispatcher. In a real implementation, you would use
    // reflection or code generation to dispatch method calls dynamically.

    switch (methodName) {
      case 'healthCheck':
        return (await service.healthCheck()).toJson();
      default:
        throw ServiceException('Method not supported: $methodName');
    }
  }

  /// Send method response
  void _sendResponse(ServiceMessage originalMessage, dynamic result) {
    final response = ServiceMessage(
      type: ServiceMessageType.methodResponse,
      serviceType: originalMessage.serviceType,
      requestId: originalMessage.requestId,
      result: result,
    );

    _sendToMain(response);
  }

  /// Send method error
  void _sendError(ServiceMessage originalMessage, String error,
      [String? stackTrace]) {
    final response = ServiceMessage(
      type: ServiceMessageType.methodError,
      serviceType: originalMessage.serviceType,
      requestId: originalMessage.requestId,
      error: error,
      stackTrace: stackTrace,
    );

    _sendToMain(response);
  }

  /// Send message to main isolate
  void _sendToMain(ServiceMessage message) {
    _mainSendPort?.send(message.toJson());
  }

  /// Notify that a service is available
  void _notifyServiceAvailable(Type serviceType, BaseService service) {
    final message = ServiceMessage(
      type: ServiceMessageType.serviceAvailable,
      serviceType: serviceType.toString(),
      requestId: 'notify_${DateTime.now().millisecondsSinceEpoch}',
    );

    _sendToMain(message);
  }

  /// Handle service available notification
  void _handleServiceAvailable(ServiceMessage message) {
    _logger.info('Service became available: ${message.serviceType}');

    // Notify local services about the new dependency
    final serviceType = _getTypeFromString(message.serviceType);
    if (serviceType != null) {
      _notifyDependents(serviceType);
    }
  }

  /// Handle service unavailable notification
  void _handleServiceUnavailable(ServiceMessage message) {
    _logger.info('Service became unavailable: ${message.serviceType}');

    final serviceType = _getTypeFromString(message.serviceType);
    if (serviceType != null) {
      _remoteServices.remove(serviceType);
      _servicePorts.remove(serviceType);

      // Notify dependents
      for (final service in _localServices.values) {
        service.onDependencyUnavailable(serviceType);
      }
    }
  }

  /// Notify services that depend on the given service type
  void _notifyDependents(Type serviceType) {
    for (final service in _localServices.values) {
      if (service.dependencies.contains(serviceType) ||
          service.optionalDependencies.contains(serviceType)) {
        final dependency = getService();
        if (dependency != null) {
          service.onDependencyAvailable(serviceType, dependency);
        }
      }
    }
  }

  /// Convert string to Type (simplified - would need proper type registry in real implementation)
  Type? _getTypeFromString(String typeName) {
    // This is simplified. In a real implementation, you would maintain
    // a registry of type names to Type objects
    return null; // Placeholder
  }

  /// Dispose the registry
  void dispose() {
    _receivePort?.close();

    for (final proxy in _remoteServices.values) {
      proxy.dispose();
    }

    _remoteServices.clear();
    _servicePorts.clear();
    _localServices.clear();

    _logger.info('Service registry disposed');
  }
}

/// Mixin for services that need cross-isolate communication
mixin ServiceCommunicationMixin on BaseService {
  ServiceRegistry? _registry;

  /// Set the service registry for this service
  void setServiceRegistry(ServiceRegistry registry) {
    _registry = registry;
    registry.registerLocalService(this);
  }

  /// Get a service through the registry (local or remote)
  @protected
  T? getRegistryService<T extends BaseService>() {
    return _registry?.getService<T>();
  }

  /// Override dependency getter to use registry
  @override
  T? getDependency<T extends BaseService>() {
    // Try local dependencies first
    final localDep = super.getDependency<T>();
    if (localDep != null) return localDep;

    // Try registry (which includes remote services)
    return getRegistryService<T>();
  }
}

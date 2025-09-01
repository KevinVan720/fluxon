/// Type definitions for the service framework.
library service_types;

/// Represents the current state of a service.
enum ServiceState {
  /// Service has not been initialized yet (Squadron services).
  uninitialized,

  /// Service has been registered but not yet initialized.
  registered,

  /// Service is currently being initialized.
  initializing,

  /// Service has been successfully initialized and is ready for use.
  initialized,

  /// Service is running and ready to handle requests (Squadron services).
  running,

  /// Service is currently being stopped (Squadron services).
  stopping,

  /// Service is currently being destroyed.
  destroying,

  /// Service has been stopped but not destroyed (Squadron services).
  stopped,

  /// Service has been destroyed and is no longer available.
  destroyed,

  /// Service initialization or operation failed.
  failed,
}

/// Factory function type for creating service instances.
typedef ServiceFactory<T> = T Function();

/// Callback function type for service lifecycle events.
typedef ServiceLifecycleCallback = Future<void> Function(String serviceName);

/// Configuration for service initialization.
class ServiceConfig {
  /// Creates a new service configuration.
  const ServiceConfig({
    this.timeout = const Duration(seconds: 30),
    this.retryAttempts = 3,
    this.retryDelay = const Duration(seconds: 1),
    this.enableLogging = true,
    this.logLevel = ServiceLogLevel.info,
    this.metadata = const <String, dynamic>{},
  });

  /// Maximum time to wait for service initialization.
  final Duration timeout;

  /// Number of retry attempts for failed operations.
  final int retryAttempts;

  /// Delay between retry attempts.
  final Duration retryDelay;

  /// Whether to enable logging for this service.
  final bool enableLogging;

  /// Default log level for the service.
  final ServiceLogLevel logLevel;

  /// Additional metadata for the service.
  final Map<String, dynamic> metadata;
}

/// Log levels for service logging.
enum ServiceLogLevel {
  /// Detailed debug information.
  debug,

  /// General information.
  info,

  /// Warning messages.
  warning,

  /// Error messages.
  error,

  /// Critical errors.
  critical,
}

/// Information about a registered service.
class ServiceInfo {
  /// Creates service information.
  const ServiceInfo({
    required this.name,
    required this.type,
    required this.dependencies,
    required this.state,
    required this.config,
    this.instance,
    this.error,
    this.registeredAt,
    this.initializedAt,
    this.destroyedAt,
  });

  /// The service name (typically the class name).
  final String name;

  /// The service type.
  final Type type;

  /// List of service types this service depends on.
  final List<Type> dependencies;

  /// Current state of the service.
  final ServiceState state;

  /// Service configuration.
  final ServiceConfig config;

  /// The service instance (null if not initialized).
  final Object? instance;

  /// Error information if the service failed.
  final Object? error;

  /// When the service was registered.
  final DateTime? registeredAt;

  /// When the service was initialized.
  final DateTime? initializedAt;

  /// When the service was destroyed.
  final DateTime? destroyedAt;

  /// Creates a copy of this service info with updated fields.
  ServiceInfo copyWith({
    String? name,
    Type? type,
    List<Type>? dependencies,
    ServiceState? state,
    ServiceConfig? config,
    Object? instance,
    Object? error,
    DateTime? registeredAt,
    DateTime? initializedAt,
    DateTime? destroyedAt,
  }) {
    return ServiceInfo(
      name: name ?? this.name,
      type: type ?? this.type,
      dependencies: dependencies ?? this.dependencies,
      state: state ?? this.state,
      config: config ?? this.config,
      instance: instance ?? this.instance,
      error: error ?? this.error,
      registeredAt: registeredAt ?? this.registeredAt,
      initializedAt: initializedAt ?? this.initializedAt,
      destroyedAt: destroyedAt ?? this.destroyedAt,
    );
  }

  @override
  String toString() {
    return 'ServiceInfo(name: $name, type: $type, state: $state, '
        'dependencies: ${dependencies.length})';
  }
}

/// Dependency relationship between services.
class ServiceDependency {
  /// Creates a service dependency.
  const ServiceDependency({
    required this.dependent,
    required this.dependency,
    required this.isRequired,
  });

  /// The service that has the dependency.
  final Type dependent;

  /// The service that is depended upon.
  final Type dependency;

  /// Whether this dependency is required for initialization.
  final bool isRequired;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ServiceDependency &&
        other.dependent == dependent &&
        other.dependency == dependency &&
        other.isRequired == isRequired;
  }

  @override
  int get hashCode {
    return dependent.hashCode ^ dependency.hashCode ^ isRequired.hashCode;
  }

  @override
  String toString() {
    return 'ServiceDependency($dependent -> $dependency, required: $isRequired)';
  }
}

/// Result of a service operation.
class ServiceResult<T> {
  /// Creates a successful result.
  const ServiceResult.success(this.data)
      : error = null,
        isSuccess = true;

  /// Creates a failed result.
  const ServiceResult.failure(this.error)
      : data = null,
        isSuccess = false;

  /// The result data (null if failed).
  final T? data;

  /// The error (null if successful).
  final Object? error;

  /// Whether the operation was successful.
  final bool isSuccess;

  /// Whether the operation failed.
  bool get isFailure => !isSuccess;

  @override
  String toString() {
    if (isSuccess) {
      return 'ServiceResult.success($data)';
    } else {
      return 'ServiceResult.failure($error)';
    }
  }
}

/// Options for service method calls.
class ServiceCallOptions {
  /// Creates service call options.
  const ServiceCallOptions({
    this.timeout = const Duration(seconds: 10),
    this.retryAttempts = 0,
    this.retryDelay = const Duration(milliseconds: 500),
    this.metadata = const <String, dynamic>{},
  });

  /// Maximum time to wait for the method call.
  final Duration timeout;

  /// Number of retry attempts for failed calls.
  final int retryAttempts;

  /// Delay between retry attempts.
  final Duration retryDelay;

  /// Additional metadata for the call.
  final Map<String, dynamic> metadata;
}

/// Health status of a service.
enum ServiceHealthStatus {
  /// Service is healthy and functioning normally.
  healthy,

  /// Service is degraded but still functional.
  degraded,

  /// Service is unhealthy and may not function properly.
  unhealthy,

  /// Service health status is unknown.
  unknown,
}

/// Health check result for a service.
class ServiceHealthCheck {
  /// Creates a health check result.
  const ServiceHealthCheck({
    required this.status,
    required this.timestamp,
    this.message,
    this.details = const <String, dynamic>{},
    this.duration,
  });

  /// The health status.
  final ServiceHealthStatus status;

  /// When the health check was performed.
  final DateTime timestamp;

  /// Optional message describing the health status.
  final String? message;

  /// Additional details about the health check.
  final Map<String, dynamic> details;

  /// How long the health check took.
  final Duration? duration;

  /// Whether the service is healthy.
  bool get isHealthy => status == ServiceHealthStatus.healthy;

  /// Converts the health check to JSON
  Map<String, dynamic> toJson() {
    return {
      'status': status.name,
      'timestamp': timestamp.toIso8601String(),
      'message': message,
      'details': details,
      'duration': duration?.inMicroseconds,
    };
  }

  @override
  String toString() {
    return 'ServiceHealthCheck(status: $status, message: $message, '
        'timestamp: $timestamp)';
  }
}

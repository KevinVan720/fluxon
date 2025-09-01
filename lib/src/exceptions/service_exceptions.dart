/// Exception classes for the service framework.
library service_exceptions;

/// Base class for all service framework exceptions.
class ServiceException implements Exception {
  /// Creates a service exception.
  const ServiceException(this.message, [this.cause]);

  /// The error message.
  final String message;
  
  /// The underlying cause of the exception (if any).
  final Object? cause;

  @override
  String toString() {
    if (cause != null) {
      return '$runtimeType: $message\nCaused by: $cause';
    }
    return '$runtimeType: $message';
  }
}

/// Exception thrown when a service registration fails.
class ServiceRegistrationException extends ServiceException {
  /// Creates a service registration exception.
  const ServiceRegistrationException(super.message, [super.cause]);
}

/// Exception thrown when a service is already registered.
class ServiceAlreadyRegisteredException extends ServiceRegistrationException {
  /// Creates a service already registered exception.
  const ServiceAlreadyRegisteredException(String serviceName)
      : super('Service "$serviceName" is already registered');
}

/// Exception thrown when a service is not found.
class ServiceNotFoundException extends ServiceException {
  /// Creates a service not found exception.
  const ServiceNotFoundException(String serviceName)
      : super('Service "$serviceName" is not registered');
}

/// Exception thrown when a service initialization fails.
class ServiceInitializationException extends ServiceException {
  /// Creates a service initialization exception.
  const ServiceInitializationException(String serviceName, [Object? cause])
      : super('Failed to initialize service "$serviceName"', cause);
}

/// Exception thrown when a circular dependency is detected.
class CircularDependencyException extends ServiceException {
  /// Creates a circular dependency exception.
  CircularDependencyException(List<String> cycle)
      : cycle = cycle,
        super('Circular dependency detected: ${cycle.join(' -> ')}');

  /// The services involved in the circular dependency.
  final List<String> cycle;
}

/// Exception thrown when a dependency is not satisfied.
class DependencyNotSatisfiedException extends ServiceException {
  /// Creates a dependency not satisfied exception.
  const DependencyNotSatisfiedException(String serviceName, String dependency)
      : super('Service "$serviceName" depends on "$dependency" which is not '
            'registered or initialized');
}

/// Exception thrown when a service operation times out.
class ServiceTimeoutException extends ServiceException {
  /// Creates a service timeout exception.
  ServiceTimeoutException(String operation, Duration timeout)
      : super('Operation "$operation" timed out after ${timeout.inMilliseconds}ms');
}

/// Exception thrown when a service is in an invalid state for an operation.
class ServiceStateException extends ServiceException {
  /// Creates a service state exception.
  const ServiceStateException(String serviceName, String currentState, 
      String expectedState)
      : super('Service "$serviceName" is in state "$currentState" but '
            'expected "$expectedState"');
}

/// Exception thrown when a service method call fails.
class ServiceCallException extends ServiceException {
  /// Creates a service call exception.
  const ServiceCallException(String serviceName, String methodName, 
      [Object? cause])
      : super('Failed to call method "$methodName" on service "$serviceName"', 
            cause);
}

/// Exception thrown when service configuration is invalid.
class ServiceConfigurationException extends ServiceException {
  /// Creates a service configuration exception.
  const ServiceConfigurationException(super.message, [super.cause]);
}

/// Exception thrown when a service worker isolate fails.
class ServiceWorkerException extends ServiceException {
  /// Creates a service worker exception.
  const ServiceWorkerException(String serviceName, [Object? cause])
      : super('Service worker for "$serviceName" failed', cause);
}

/// Exception thrown when service communication fails.
class ServiceCommunicationException extends ServiceException {
  /// Creates a service communication exception.
  const ServiceCommunicationException(String message, [Object? cause])
      : super('Service communication failed: $message', cause);
}

/// Exception thrown when service serialization/deserialization fails.
class ServiceSerializationException extends ServiceException {
  /// Creates a service serialization exception.
  const ServiceSerializationException(String message, [Object? cause])
      : super('Service serialization failed: $message', cause);
}

/// Exception thrown when a service health check fails.
class ServiceHealthException extends ServiceException {
  /// Creates a service health exception.
  const ServiceHealthException(String serviceName, [Object? cause])
      : super('Health check failed for service "$serviceName"', cause);
}

/// Exception thrown when the service locator is not initialized.
class ServiceLocatorNotInitializedException extends ServiceException {
  /// Creates a service locator not initialized exception.
  const ServiceLocatorNotInitializedException()
      : super('ServiceLocator has not been initialized. Call initializeAll() first.');
}

/// Exception thrown when trying to use a destroyed service.
class ServiceDestroyedException extends ServiceException {
  /// Creates a service destroyed exception.
  const ServiceDestroyedException(String serviceName)
      : super('Service "$serviceName" has been destroyed and cannot be used');
}

/// Exception thrown when a service factory returns null.
class ServiceFactoryException extends ServiceException {
  /// Creates a service factory exception.
  const ServiceFactoryException(String serviceName)
      : super('Service factory for "$serviceName" returned null');
}

/// Exception thrown when a service type is invalid.
class InvalidServiceTypeException extends ServiceException {
  /// Creates an invalid service type exception.
  const InvalidServiceTypeException(String message)
      : super('Invalid service type: $message');
}

/// Exception thrown when maximum retry attempts are exceeded.
class ServiceRetryExceededException extends ServiceException {
  /// Creates a service retry exceeded exception.
  const ServiceRetryExceededException(String operation, int attempts)
      : super('Operation "$operation" failed after $attempts retry attempts');
}

/// Exception thrown when a service method is not found.
class ServiceMethodNotFoundException extends ServiceException {
  /// Creates a service method not found exception.
  const ServiceMethodNotFoundException(String serviceName, String methodName)
      : super('Method "$methodName" not found on service "$serviceName"');
}

/// Exception thrown when service parameters are invalid.
class ServiceParameterException extends ServiceException {
  /// Creates a service parameter exception.
  const ServiceParameterException(String message)
      : super('Invalid service parameter: $message');
}
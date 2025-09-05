part of 'service_exceptions.dart';

class ServiceTimeoutException extends ServiceException {
  ServiceTimeoutException(String operation, Duration timeout)
      : super(
            'Operation "$operation" timed out after ${timeout.inMilliseconds}ms');
}

class ServiceStateException extends ServiceException {
  const ServiceStateException(
      String serviceName, String currentState, String expectedState)
      : super(
            'Service "$serviceName" is in state "$currentState" but expected "$expectedState"');
}

class ServiceCallException extends ServiceException {
  const ServiceCallException(String serviceName, String methodName,
      [Object? cause])
      : super('Failed to call method "$methodName" on service "$serviceName"',
            cause);
}

class ServiceConfigurationException extends ServiceException {
  const ServiceConfigurationException(super.message, [super.cause]);
}

class ServiceWorkerException extends ServiceException {
  const ServiceWorkerException(String serviceName, [Object? cause])
      : super('Service worker for "$serviceName" failed', cause);
}

class ServiceLocatorNotInitializedException extends ServiceException {
  const ServiceLocatorNotInitializedException()
      : super(
            'ServiceLocator has not been initialized. Call initializeAll() first.');
}

class ServiceDestroyedException extends ServiceException {
  const ServiceDestroyedException(String serviceName)
      : super('Service "$serviceName" has been destroyed and cannot be used');
}

class ServiceFactoryException extends ServiceException {
  const ServiceFactoryException(String serviceName)
      : super('Service factory for "$serviceName" returned null');
}

class InvalidServiceTypeException extends ServiceException {
  const InvalidServiceTypeException(String message)
      : super('Invalid service type: $message');
}

class ServiceRetryExceededException extends ServiceException {
  const ServiceRetryExceededException(String operation, int attempts)
      : super('Operation "$operation" failed after $attempts retry attempts');
}

class ServiceMethodNotFoundException extends ServiceException {
  const ServiceMethodNotFoundException(String serviceName, String methodName)
      : super('Method "$methodName" not found on service "$serviceName"');
}

class ServiceParameterException extends ServiceException {
  const ServiceParameterException(String message)
      : super('Invalid service parameter: $message');
}

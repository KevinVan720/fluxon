part of 'service_exceptions.dart';

class ServiceRegistrationException extends ServiceException {
  const ServiceRegistrationException(super.message, [super.cause]);
}

class ServiceAlreadyRegisteredException extends ServiceRegistrationException {
  const ServiceAlreadyRegisteredException(String serviceName)
      : super('Service "$serviceName" is already registered');
}

class ServiceNotFoundException extends ServiceException {
  const ServiceNotFoundException(String serviceName)
      : super('Service "$serviceName" is not registered');
}

class ServiceInitializationException extends ServiceException {
  const ServiceInitializationException(String serviceName, [Object? cause])
      : super('Failed to initialize service "$serviceName"', cause);
}

class CircularDependencyException extends ServiceException {
  CircularDependencyException(List<String> cycle)
      : cycle = cycle,
        super('Circular dependency detected: ${cycle.join(' -> ')}');
  final List<String> cycle;
}

class DependencyNotSatisfiedException extends ServiceException {
  const DependencyNotSatisfiedException(String serviceName, String dependency)
      : super('Service "$serviceName" depends on "$dependency" which is not '
            'registered or initialized');
}

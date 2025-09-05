part of 'service_exceptions.dart';

class ServiceHealthException extends ServiceException {
  const ServiceHealthException(String serviceName, [Object? cause])
      : super('Health check failed for service "$serviceName"', cause);
}

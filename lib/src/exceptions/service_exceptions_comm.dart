part of 'service_exceptions.dart';

class ServiceCommunicationException extends ServiceException {
  const ServiceCommunicationException(String message, [Object? cause])
      : super('Service communication failed: $message', cause);
}

class ServiceSerializationException extends ServiceException {
  const ServiceSerializationException(String message, [Object? cause])
      : super('Service serialization failed: $message', cause);
}

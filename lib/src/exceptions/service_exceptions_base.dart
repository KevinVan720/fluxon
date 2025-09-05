part of 'service_exceptions.dart';

/// Base class for all service framework exceptions.
class ServiceException implements Exception {
  const ServiceException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => cause != null
      ? '$runtimeType: $message\nCaused by: $cause'
      : '$runtimeType: $message';
}

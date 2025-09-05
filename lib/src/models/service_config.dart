part of 'service_models.dart';

enum ServiceLogLevel {
  debug,
  info,
  warning,
  error,
  critical,
}

class ServiceConfig {
  const ServiceConfig({
    this.timeout = const Duration(seconds: 30),
    this.retryAttempts = 3,
    this.retryDelay = const Duration(seconds: 1),
    this.enableLogging = true,
    this.logLevel = ServiceLogLevel.info,
    this.metadata = const <String, dynamic>{},
  });

  final Duration timeout;
  final int retryAttempts;
  final Duration retryDelay;
  final bool enableLogging;
  final ServiceLogLevel logLevel;
  final Map<String, dynamic> metadata;
}

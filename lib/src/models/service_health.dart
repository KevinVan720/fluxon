part of 'service_models.dart';

enum ServiceHealthStatus {
  healthy,
  degraded,
  unhealthy,
  unknown,
}

class ServiceHealthCheck {
  const ServiceHealthCheck({
    required this.status,
    required this.timestamp,
    this.message,
    this.details = const <String, dynamic>{},
    this.duration,
  });

  final ServiceHealthStatus status;
  final DateTime timestamp;
  final String? message;
  final Map<String, dynamic> details;
  final Duration? duration;

  bool get isHealthy => status == ServiceHealthStatus.healthy;

  Map<String, dynamic> toJson() => {
        'status': status.name,
        'timestamp': timestamp.toIso8601String(),
        'message': message,
        'details': details,
        'duration': duration?.inMicroseconds,
      };

  @override
  String toString() =>
      'ServiceHealthCheck(status: $status, message: $message, timestamp: $timestamp)';
}

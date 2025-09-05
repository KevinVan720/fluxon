import 'service_event_base.dart';

/// Target for event distribution
class EventTarget {
  const EventTarget({
    required this.serviceType,
    this.waitUntilProcessed = false,
    this.timeout,
    this.retryCount = 0,
    this.condition,
  });

  /// The type of service to send the event to
  final Type serviceType;

  /// Whether to wait for processing confirmation before continuing
  final bool waitUntilProcessed;

  /// Timeout for waiting for processing (if waitUntilProcessed is true)
  final Duration? timeout;

  /// Number of retry attempts if processing fails
  final int retryCount;

  /// Optional condition function to determine if event should be sent
  final bool Function(ServiceEvent event)? condition;

  /// Check if this target should receive the event
  bool shouldReceive(ServiceEvent event) => condition?.call(event) ?? true;

  @override
  String toString() =>
      'EventTarget(service: $serviceType, wait: $waitUntilProcessed, retries: $retryCount)';
}

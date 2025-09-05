part of 'service_types.dart';

/// Represents the current state of a service.
enum ServiceState {
  uninitialized,
  registered,
  initializing,
  initialized,
  running,
  stopping,
  destroying,
  stopped,
  destroyed,
  failed,
}

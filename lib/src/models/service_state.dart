part of 'service_models.dart';

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

/// Type definitions for the service framework.
library service_types;

part 'types_state.dart';
part 'types_config.dart';
part 'types_info.dart';
part 'types_results.dart';
part 'types_health.dart';

/// Factory function type for creating service instances.
typedef ServiceFactory<T> = T Function();

/// Callback function type for service lifecycle events.
typedef ServiceLifecycleCallback = Future<void> Function(String serviceName);

/// All enums/classes moved to part files. Keep typedefs here for convenience.

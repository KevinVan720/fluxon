/// Type definitions and model classes for the service framework.
library service_models;

part 'service_state.dart';
part 'service_config.dart';
part 'service_info.dart';
part 'service_results.dart';
part 'service_health.dart';

typedef ServiceFactory<T> = T Function();
typedef ServiceLifecycleCallback = Future<void> Function(String serviceName);

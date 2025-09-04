/// A comprehensive service locator and services framework for Dart applications
/// using Squadron worker isolates.
///
/// This library provides:
/// - Service registration and dependency management
/// - Automatic service initialization in dependency order
/// - Squadron worker isolate integration for true parallelism
/// - Transparent inter-service communication
/// - Structured logging with service-specific prefixes
/// - Complete service lifecycle management
library dart_service_framework;

// Core framework exports
export 'src/base_service.dart';
export 'src/flux_service.dart'; // 🚀 FLUX: Simplified public API
export 'src/service_locator.dart';
export 'src/service_registry.dart';
export 'src/dependency_resolver.dart';
export 'src/service_logger.dart';
export 'src/service_proxy.dart';
export 'src/service_worker.dart';
export 'src/annotations/service_annotations.dart';
export 'src/codegen/dispatcher_registry.dart';

// Squadron-first framework exports (temporarily disabled due to integration issues)
// export 'src/squadron_service.dart';
// export 'src/squadron_service_locator.dart';
// export 'src/squadron_proxy_generator.dart' show ServiceProxyFactory;
// export 'src/squadron_worker.dart';

// Event system exports
export 'src/events/service_event.dart';
export 'src/events/event_dispatcher.dart';
export 'src/events/event_mixin.dart';
export 'src/events/event_bridge.dart';
export 'src/events/event_type_registry.dart';

// Exception exports
export 'src/exceptions/service_exceptions.dart';

// Type exports
export 'src/types/service_types.dart';

/// Flux - A comprehensive service framework for Dart applications
/// with complete isolate transparency and automatic event communication.
///
/// This library provides:
/// - FluxRuntime for unified service management
/// - FluxService for zero-boilerplate service creation
/// - Complete isolate transparency (local/remote services identical)
/// - Automatic event-driven communication across isolates
/// - Zero-configuration dependency injection
/// - Automatic infrastructure setup
library flux;

export 'src/annotations/service_annotations.dart';
// 🔧 Service framework core
export 'src/base_service.dart';
// 🛠️ Advanced features (for framework extension)
export 'src/codegen/dispatcher_registry.dart';
export 'src/dependency_resolver/dependency_resolver.dart';
export 'src/events/event_bridge.dart';
export 'src/events/event_dispatcher.dart';
export 'src/events/event_mixin.dart';
export 'src/events/event_type_registry.dart';
// 📡 Event system
export 'src/events/service_event.dart';
export 'src/exceptions/service_exceptions.dart';
// 🚀 Core Flux API
export 'src/flux_runtime.dart' show FluxRuntime;
export 'src/flux_service.dart';
export 'src/models/service_models.dart';
export 'src/service_logger.dart';
export 'src/service_proxy.dart';
export 'src/service_worker.dart';

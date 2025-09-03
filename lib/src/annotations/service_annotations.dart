/// Annotations for service code generation.
library service_annotations;

import 'package:meta/meta.dart';

/// Marks a service API for code generation.
///
/// Apply this to an abstract class that extends `BaseService`.
/// When `remote` is true, the build will generate a client proxy and
/// worker-side dispatcher to enable cross-isolate invocation.
@immutable
class ServiceContract {
  /// Creates a [ServiceContract] annotation.
  const ServiceContract({this.remote = false, this.name});

  /// Whether to generate worker/client artifacts for remote execution.
  final bool remote;

  /// Optional explicit service name (defaults to the class name).
  final String? name;
}

/// Configures per-method options for service calls.
@immutable
class ServiceMethod {
  /// Creates a [ServiceMethod] annotation.
  const ServiceMethod({this.timeoutMs, this.retryAttempts, this.retryDelayMs});

  /// Override call timeout in milliseconds.
  final int? timeoutMs;

  /// Override retry attempts (default comes from framework).
  final int? retryAttempts;

  /// Override retry delay in milliseconds.
  final int? retryDelayMs;
}

/// Specifies a custom codec for (de)serializing a parameter or return type.
@immutable
class SerializeWith {
  /// Creates a [SerializeWith] annotation.
  const SerializeWith(this.codecType);

  /// A type that exposes `toJson`/`fromJson` or `encode`/`decode` statics.
  final Type codecType;
}

part of 'service_models.dart';

class ServiceInfo {
  const ServiceInfo({
    required this.name,
    required this.type,
    required this.dependencies,
    required this.state,
    required this.config,
    this.instance,
    this.error,
    this.registeredAt,
    this.initializedAt,
    this.destroyedAt,
  });

  final String name;
  final Type type;
  final List<Type> dependencies;
  final ServiceState state;
  final ServiceConfig config;
  final Object? instance;
  final Object? error;
  final DateTime? registeredAt;
  final DateTime? initializedAt;
  final DateTime? destroyedAt;

  ServiceInfo copyWith({
    String? name,
    Type? type,
    List<Type>? dependencies,
    ServiceState? state,
    ServiceConfig? config,
    Object? instance,
    Object? error,
    DateTime? registeredAt,
    DateTime? initializedAt,
    DateTime? destroyedAt,
  }) =>
      ServiceInfo(
        name: name ?? this.name,
        type: type ?? this.type,
        dependencies: dependencies ?? this.dependencies,
        state: state ?? this.state,
        config: config ?? this.config,
        instance: instance ?? this.instance,
        error: error ?? this.error,
        registeredAt: registeredAt ?? this.registeredAt,
        initializedAt: initializedAt ?? this.initializedAt,
        destroyedAt: destroyedAt ?? this.destroyedAt,
      );

  @override
  String toString() => 'ServiceInfo(name: $name, type: $type, state: $state, '
      'dependencies: ${dependencies.length})';
}

class ServiceDependency {
  const ServiceDependency({
    required this.dependent,
    required this.dependency,
    required this.isRequired,
  });

  final Type dependent;
  final Type dependency;
  final bool isRequired;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ServiceDependency &&
          other.dependent == dependent &&
          other.dependency == dependency &&
          other.isRequired == isRequired);

  @override
  int get hashCode =>
      dependent.hashCode ^ dependency.hashCode ^ isRequired.hashCode;

  @override
  String toString() =>
      'ServiceDependency($dependent -> $dependency, required: $isRequired)';
}

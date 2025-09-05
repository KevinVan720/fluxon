part of 'dependency_resolver.dart';

/// Detailed dependency information for a service.
class ServiceDependencyInfo {
  /// Creates service dependency information.
  const ServiceDependencyInfo({
    required this.serviceType,
    required this.serviceName,
    required this.requiredDependencies,
    required this.optionalDependencies,
    required this.dependents,
    required this.totalDependencies,
    required this.totalDependents,
  });

  final Type serviceType;
  final String serviceName;
  final List<Type> requiredDependencies;
  final List<Type> optionalDependencies;
  final List<Type> dependents;
  final int totalDependencies;
  final int totalDependents;

  List<Type> get allDependencies => [
        ...requiredDependencies,
        ...optionalDependencies,
      ];

  bool get hasDependencies => totalDependencies > 0;
  bool get hasDependents => totalDependents > 0;
  bool get isLeaf => !hasDependents;
  bool get isRoot => !hasDependencies;

  @override
  String toString() => 'ServiceDependencyInfo($serviceName: '
      '$totalDependencies deps, $totalDependents dependents)';
}

/// Statistics about a dependency graph.
class DependencyStatistics {
  const DependencyStatistics({
    required this.totalServices,
    required this.rootServices,
    required this.leafServices,
    required this.averageDependencies,
    required this.maxDependencies,
    required this.averageDependents,
    required this.maxDependents,
    required this.longestChainLength,
  });

  final int totalServices;
  final int rootServices;
  final int leafServices;
  final double averageDependencies;
  final int maxDependencies;
  final double averageDependents;
  final int maxDependents;
  final int longestChainLength;

  @override
  String toString() => 'DependencyStatistics(\n'
      '  Total Services: $totalServices\n'
      '  Root Services: $rootServices\n'
      '  Leaf Services: $leafServices\n'
      '  Avg Dependencies: ${averageDependencies.toStringAsFixed(2)}\n'
      '  Max Dependencies: $maxDependencies\n'
      '  Avg Dependents: ${averageDependents.toStringAsFixed(2)}\n'
      '  Max Dependents: $maxDependents\n'
      '  Longest Chain: $longestChainLength\n'
      ')';
}

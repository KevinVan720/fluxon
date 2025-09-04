/// Dependency resolution system for service initialization ordering.
library dependency_resolver;

import 'exceptions/service_exceptions.dart';

/// Resolves service dependencies and determines initialization order.
class DependencyResolver {
  /// Creates a dependency resolver.
  DependencyResolver();

  final Map<Type, Set<Type>> _dependencies = {};
  final Map<Type, Set<Type>> _optionalDependencies = {};
  final Map<Type, String> _serviceNames = {};

  /// Registers a service and its dependencies.
  void registerService(
    Type serviceType,
    String serviceName,
    List<Type> dependencies,
    List<Type> optionalDependencies,
  ) {
    _serviceNames[serviceType] = serviceName;
    _dependencies[serviceType] = Set.from(dependencies);
    _optionalDependencies[serviceType] = Set.from(optionalDependencies);
  }

  /// Unregisters a service.
  void unregisterService(Type serviceType) {
    _dependencies.remove(serviceType);
    _optionalDependencies.remove(serviceType);
    _serviceNames.remove(serviceType);
  }

  /// Gets all registered service types.
  Set<Type> get registeredServices => Set.from(_dependencies.keys);

  /// Gets the dependencies for a service.
  Set<Type> getDependencies(Type serviceType) {
    return Set.from(_dependencies[serviceType] ?? {});
  }

  /// Gets the optional dependencies for a service.
  Set<Type> getOptionalDependencies(Type serviceType) {
    return Set.from(_optionalDependencies[serviceType] ?? {});
  }

  /// Gets all dependencies (required and optional) for a service.
  Set<Type> getAllDependencies(Type serviceType) {
    return {
      ...getDependencies(serviceType),
      ...getOptionalDependencies(serviceType),
    };
  }

  /// Gets services that depend on the given service.
  Set<Type> getDependents(Type serviceType) {
    final dependents = <Type>{};

    for (final entry in _dependencies.entries) {
      if (entry.value.contains(serviceType)) {
        dependents.add(entry.key);
      }
    }

    for (final entry in _optionalDependencies.entries) {
      if (entry.value.contains(serviceType)) {
        dependents.add(entry.key);
      }
    }

    return dependents;
  }

  /// Validates all service dependencies.
  ///
  /// Throws [DependencyNotSatisfiedException] if required dependencies are missing.
  /// Throws [CircularDependencyException] if circular dependencies are detected.
  void validateDependencies() {
    // Check for missing required dependencies
    for (final entry in _dependencies.entries) {
      final serviceType = entry.key;
      final dependencies = entry.value;

      for (final dependency in dependencies) {
        if (!_dependencies.containsKey(dependency)) {
          throw DependencyNotSatisfiedException(
            _serviceNames[serviceType] ?? serviceType.toString(),
            _serviceNames[dependency] ?? dependency.toString(),
          );
        }
      }
    }

    // Check for circular dependencies
    _detectCircularDependencies();
  }

  /// Resolves the initialization order for all services.
  ///
  /// Returns a list of service types in the order they should be initialized.
  /// Services with no dependencies come first, followed by services whose
  /// dependencies have already been resolved.
  List<Type> resolveInitializationOrder() {
    validateDependencies();
    return _topologicalSort();
  }

  /// Resolves the destruction order for all services.
  ///
  /// Returns a list of service types in the order they should be destroyed.
  /// This is the reverse of the initialization order.
  List<Type> resolveDestructionOrder() {
    return resolveInitializationOrder().reversed.toList();
  }

  /// Gets the dependency graph as a map.
  Map<Type, Set<Type>> getDependencyGraph() {
    final graph = <Type, Set<Type>>{};

    for (final serviceType in _dependencies.keys) {
      graph[serviceType] = {
        ..._dependencies[serviceType] ?? {},
        // Only include optional dependencies that are actually registered
        ..._optionalDependencies[serviceType]
                ?.where((dep) => _dependencies.containsKey(dep)) ??
            {},
      };
    }

    return graph;
  }

  /// Creates a visual representation of the dependency graph.
  String visualizeDependencyGraph() {
    final buffer = StringBuffer();
    buffer.writeln('Service Dependency Graph:');
    buffer.writeln('========================');

    final graph = getDependencyGraph();
    final sortedServices = graph.keys.toList()
      ..sort((a, b) => _getServiceName(a).compareTo(_getServiceName(b)));

    for (final serviceType in sortedServices) {
      final serviceName = _getServiceName(serviceType);
      final dependencies = graph[serviceType] ?? {};

      buffer.writeln('$serviceName:');

      if (dependencies.isEmpty) {
        buffer.writeln('  (no dependencies)');
      } else {
        for (final dependency in dependencies) {
          final depName = _getServiceName(dependency);
          final isOptional =
              _optionalDependencies[serviceType]?.contains(dependency) ?? false;
          final marker = isOptional ? '  ├─ (optional)' : '  ├─';
          buffer.writeln('$marker $depName');
        }
      }
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Gets detailed dependency information for a service.
  ServiceDependencyInfo getDependencyInfo(Type serviceType) {
    if (!_dependencies.containsKey(serviceType)) {
      throw ServiceNotFoundException(_getServiceName(serviceType));
    }

    final requiredDeps = _dependencies[serviceType] ?? {};
    final optionalDeps = _optionalDependencies[serviceType] ?? {};
    final dependents = getDependents(serviceType);

    return ServiceDependencyInfo(
      serviceType: serviceType,
      serviceName: _getServiceName(serviceType),
      requiredDependencies: requiredDeps.toList(),
      optionalDependencies: optionalDeps.toList(),
      dependents: dependents.toList(),
      totalDependencies: requiredDeps.length + optionalDeps.length,
      totalDependents: dependents.length,
    );
  }

  /// Gets dependency information for all services.
  List<ServiceDependencyInfo> getAllDependencyInfo() {
    return _dependencies.keys
        .map((serviceType) => getDependencyInfo(serviceType))
        .toList();
  }

  /// Clears all registered services and dependencies.
  void clear() {
    _dependencies.clear();
    _optionalDependencies.clear();
    _serviceNames.clear();
  }

  void _detectCircularDependencies() {
    final visited = <Type>{};
    final recursionStack = <Type>{};
    final path = <Type>[];

    for (final serviceType in _dependencies.keys) {
      if (!visited.contains(serviceType)) {
        _dfsCircularCheck(serviceType, visited, recursionStack, path);
      }
    }
  }

  void _dfsCircularCheck(
    Type serviceType,
    Set<Type> visited,
    Set<Type> recursionStack,
    List<Type> path,
  ) {
    visited.add(serviceType);
    recursionStack.add(serviceType);
    path.add(serviceType);

    final dependencies = {
      ..._dependencies[serviceType] ?? {},
      // Include optional dependencies that are registered
      ..._optionalDependencies[serviceType]
              ?.where((dep) => _dependencies.containsKey(dep)) ??
          {},
    };

    for (final dependency in dependencies) {
      if (!visited.contains(dependency)) {
        _dfsCircularCheck(dependency, visited, recursionStack, path);
      } else if (recursionStack.contains(dependency)) {
        // Found a cycle
        final cycleStart = path.indexOf(dependency);
        final cycle = path.sublist(cycleStart)
          ..add(dependency); // Complete the cycle

        final cycleNames = cycle.map(_getServiceName).toList();
        throw CircularDependencyException(cycleNames);
      }
    }

    recursionStack.remove(serviceType);
    path.removeLast();
  }

  List<Type> _topologicalSort() {
    final result = <Type>[];
    final visited = <Type>{};
    final temp = <Type>{};

    void visit(Type serviceType) {
      if (temp.contains(serviceType)) {
        // This should not happen if circular dependency check passed
        throw CircularDependencyException([_getServiceName(serviceType)]);
      }

      if (visited.contains(serviceType)) {
        return;
      }

      temp.add(serviceType);

      final dependencies = {
        ..._dependencies[serviceType] ?? {},
        // Include optional dependencies that are registered
        ..._optionalDependencies[serviceType]
                ?.where((dep) => _dependencies.containsKey(dep)) ??
            {},
      };

      for (final dependency in dependencies) {
        visit(dependency);
      }

      temp.remove(serviceType);
      visited.add(serviceType);
      result.add(serviceType);
    }

    for (final serviceType in _dependencies.keys) {
      if (!visited.contains(serviceType)) {
        visit(serviceType);
      }
    }

    return result;
  }

  String _getServiceName(Type serviceType) {
    return _serviceNames[serviceType] ?? serviceType.toString();
  }
}

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

  /// The service type.
  final Type serviceType;

  /// The service name.
  final String serviceName;

  /// Required dependencies.
  final List<Type> requiredDependencies;

  /// Optional dependencies.
  final List<Type> optionalDependencies;

  /// Services that depend on this service.
  final List<Type> dependents;

  /// Total number of dependencies.
  final int totalDependencies;

  /// Total number of dependents.
  final int totalDependents;

  /// Gets all dependencies (required and optional).
  List<Type> get allDependencies => [
        ...requiredDependencies,
        ...optionalDependencies,
      ];

  /// Whether this service has any dependencies.
  bool get hasDependencies => totalDependencies > 0;

  /// Whether this service has any dependents.
  bool get hasDependents => totalDependents > 0;

  /// Whether this service is a leaf node (no dependents).
  bool get isLeaf => !hasDependents;

  /// Whether this service is a root node (no dependencies).
  bool get isRoot => !hasDependencies;

  @override
  String toString() {
    return 'ServiceDependencyInfo($serviceName: '
        '$totalDependencies deps, $totalDependents dependents)';
  }
}

/// Utility class for analyzing dependency graphs.
class DependencyAnalyzer {
  /// Creates a dependency analyzer.
  const DependencyAnalyzer(this.resolver);

  /// The dependency resolver to analyze.
  final DependencyResolver resolver;

  /// Finds services with no dependencies (root services).
  List<Type> findRootServices() {
    return resolver.registeredServices
        .where((service) => resolver.getDependencies(service).isEmpty)
        .toList();
  }

  /// Finds services with no dependents (leaf services).
  List<Type> findLeafServices() {
    return resolver.registeredServices
        .where((service) => resolver.getDependents(service).isEmpty)
        .toList();
  }

  /// Finds the longest dependency chain.
  List<Type> findLongestDependencyChain() {
    final chains = <List<Type>>[];

    for (final root in findRootServices()) {
      chains.add(_findLongestChainFrom(root));
    }

    return chains.reduce((a, b) => a.length > b.length ? a : b);
  }

  /// Gets dependency statistics.
  DependencyStatistics getStatistics() {
    final services = resolver.registeredServices;
    final totalServices = services.length;

    if (totalServices == 0) {
      return const DependencyStatistics(
        totalServices: 0,
        rootServices: 0,
        leafServices: 0,
        averageDependencies: 0.0,
        maxDependencies: 0,
        averageDependents: 0.0,
        maxDependents: 0,
        longestChainLength: 0,
      );
    }

    final rootServices = findRootServices().length;
    final leafServices = findLeafServices().length;

    final dependencyCounts =
        services.map((s) => resolver.getDependencies(s).length).toList();

    final dependentCounts =
        services.map((s) => resolver.getDependents(s).length).toList();

    final averageDependencies = dependencyCounts.isEmpty
        ? 0.0
        : dependencyCounts.reduce((a, b) => a + b) / dependencyCounts.length;

    final averageDependents = dependentCounts.isEmpty
        ? 0.0
        : dependentCounts.reduce((a, b) => a + b) / dependentCounts.length;

    final maxDependencies = dependencyCounts.isEmpty
        ? 0
        : dependencyCounts.reduce((a, b) => a > b ? a : b);

    final maxDependents = dependentCounts.isEmpty
        ? 0
        : dependentCounts.reduce((a, b) => a > b ? a : b);

    final longestChain = findLongestDependencyChain();

    return DependencyStatistics(
      totalServices: totalServices,
      rootServices: rootServices,
      leafServices: leafServices,
      averageDependencies: averageDependencies,
      maxDependencies: maxDependencies,
      averageDependents: averageDependents,
      maxDependents: maxDependents,
      longestChainLength: longestChain.length,
    );
  }

  List<Type> _findLongestChainFrom(Type service) {
    final dependents = resolver.getDependents(service);

    if (dependents.isEmpty) {
      return [service];
    }

    final chains = dependents
        .map((dependent) => _findLongestChainFrom(dependent))
        .toList();

    final longestChain = chains.reduce((a, b) => a.length > b.length ? a : b);
    return [service, ...longestChain];
  }
}

/// Statistics about a dependency graph.
class DependencyStatistics {
  /// Creates dependency statistics.
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

  /// Total number of services.
  final int totalServices;

  /// Number of root services (no dependencies).
  final int rootServices;

  /// Number of leaf services (no dependents).
  final int leafServices;

  /// Average number of dependencies per service.
  final double averageDependencies;

  /// Maximum number of dependencies for any service.
  final int maxDependencies;

  /// Average number of dependents per service.
  final double averageDependents;

  /// Maximum number of dependents for any service.
  final int maxDependents;

  /// Length of the longest dependency chain.
  final int longestChainLength;

  @override
  String toString() {
    return 'DependencyStatistics(\n'
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
}

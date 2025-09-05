part of 'dependency_resolver.dart';

/// Utility class for analyzing dependency graphs.
class DependencyAnalyzer {
  const DependencyAnalyzer(this.resolver);

  final DependencyResolver resolver;

  List<Type> findRootServices() => resolver.registeredServices
      .where((service) => resolver.getDependencies(service).isEmpty)
      .toList();

  List<Type> findLeafServices() => resolver.registeredServices
      .where((service) => resolver.getDependents(service).isEmpty)
      .toList();

  List<Type> findLongestDependencyChain() {
    final chains = <List<Type>>[];
    for (final root in findRootServices()) {
      chains.add(_findLongestChainFrom(root));
    }
    return chains.reduce((a, b) => a.length > b.length ? a : b);
  }

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
    final chains = dependents.map(_findLongestChainFrom).toList();
    final longestChain = chains.reduce((a, b) => a.length > b.length ? a : b);
    return [service, ...longestChain];
  }
}

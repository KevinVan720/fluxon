import 'package:fluxon/src/dependency_resolver/dependency_resolver.dart';
import 'package:fluxon/src/exceptions/service_exceptions.dart';
import 'package:test/test.dart';

// Mock service types for testing
class ServiceA {}

class ServiceB {}

class ServiceC {}

class ServiceD {}

class ServiceE {}

void main() {
  group('DependencyResolver', () {
    late DependencyResolver resolver;

    setUp(() {
      resolver = DependencyResolver();
    });

    test('should register services with dependencies', () {
      resolver.registerService(ServiceA, 'ServiceA', [], []);
      resolver.registerService(ServiceB, 'ServiceB', [ServiceA], []);

      expect(resolver.registeredServices, contains(ServiceA));
      expect(resolver.registeredServices, contains(ServiceB));
      expect(resolver.getDependencies(ServiceB), contains(ServiceA));
    });

    test('should resolve simple dependency chain', () {
      // A -> B -> C (A depends on B, B depends on C)
      resolver.registerService(ServiceC, 'ServiceC', [], []);
      resolver.registerService(ServiceB, 'ServiceB', [ServiceC], []);
      resolver.registerService(ServiceA, 'ServiceA', [ServiceB], []);

      final order = resolver.resolveInitializationOrder();

      expect(order.indexOf(ServiceC), lessThan(order.indexOf(ServiceB)));
      expect(order.indexOf(ServiceB), lessThan(order.indexOf(ServiceA)));
    });

    test('should resolve complex dependency graph', () {
      // Complex dependency graph:
      // A -> [B, C]
      // B -> [D]
      // C -> [D, E]
      // D -> []
      // E -> []
      resolver.registerService(ServiceD, 'ServiceD', [], []);
      resolver.registerService(ServiceE, 'ServiceE', [], []);
      resolver.registerService(ServiceC, 'ServiceC', [ServiceD, ServiceE], []);
      resolver.registerService(ServiceB, 'ServiceB', [ServiceD], []);
      resolver.registerService(ServiceA, 'ServiceA', [ServiceB, ServiceC], []);

      final order = resolver.resolveInitializationOrder();

      // D and E should come first (no dependencies)
      expect(order.indexOf(ServiceD), lessThan(order.indexOf(ServiceB)));
      expect(order.indexOf(ServiceD), lessThan(order.indexOf(ServiceC)));
      expect(order.indexOf(ServiceE), lessThan(order.indexOf(ServiceC)));

      // B and C should come before A
      expect(order.indexOf(ServiceB), lessThan(order.indexOf(ServiceA)));
      expect(order.indexOf(ServiceC), lessThan(order.indexOf(ServiceA)));
    });

    test('should detect circular dependencies', () {
      // A -> B -> C -> A (circular)
      resolver.registerService(ServiceA, 'ServiceA', [ServiceB], []);
      resolver.registerService(ServiceB, 'ServiceB', [ServiceC], []);
      resolver.registerService(ServiceC, 'ServiceC', [ServiceA], []);

      expect(
        () => resolver.validateDependencies(),
        throwsA(isA<CircularDependencyException>()),
      );
    });

    test('should detect missing dependencies', () {
      resolver.registerService(ServiceA, 'ServiceA', [ServiceB], []);
      // ServiceB is not registered

      expect(
        () => resolver.validateDependencies(),
        throwsA(isA<DependencyNotSatisfiedException>()),
      );
    });

    test('should handle optional dependencies', () {
      resolver.registerService(ServiceA, 'ServiceA', [], [ServiceB]);
      // ServiceB is not registered but it's optional

      expect(() => resolver.validateDependencies(), returnsNormally);

      final order = resolver.resolveInitializationOrder();
      expect(order, contains(ServiceA));
    });

    test('should include registered optional dependencies in order', () {
      resolver.registerService(ServiceB, 'ServiceB', [], []);
      resolver.registerService(ServiceA, 'ServiceA', [], [ServiceB]);

      final order = resolver.resolveInitializationOrder();

      expect(order.indexOf(ServiceB), lessThan(order.indexOf(ServiceA)));
    });

    test('should return destruction order as reverse of initialization', () {
      resolver.registerService(ServiceC, 'ServiceC', [], []);
      resolver.registerService(ServiceB, 'ServiceB', [ServiceC], []);
      resolver.registerService(ServiceA, 'ServiceA', [ServiceB], []);

      final initOrder = resolver.resolveInitializationOrder();
      final destructOrder = resolver.resolveDestructionOrder();

      expect(destructOrder, equals(initOrder.reversed.toList()));
    });

    test('should find dependents correctly', () {
      resolver.registerService(ServiceA, 'ServiceA', [ServiceB], []);
      resolver.registerService(ServiceC, 'ServiceC', [ServiceB], []);
      resolver.registerService(ServiceB, 'ServiceB', [], []);

      final dependents = resolver.getDependents(ServiceB);

      expect(dependents, contains(ServiceA));
      expect(dependents, contains(ServiceC));
      expect(dependents, hasLength(2));
    });

    test('should provide dependency information', () {
      resolver.registerService(ServiceA, 'ServiceA', [ServiceB], [ServiceC]);
      resolver.registerService(ServiceB, 'ServiceB', [], []);
      resolver.registerService(ServiceC, 'ServiceC', [], []);

      final info = resolver.getDependencyInfo(ServiceA);

      expect(info.serviceName, equals('ServiceA'));
      expect(info.requiredDependencies, contains(ServiceB));
      expect(info.optionalDependencies, contains(ServiceC));
      expect(info.totalDependencies, equals(2));
    });

    test('should visualize dependency graph', () {
      resolver.registerService(ServiceA, 'ServiceA', [ServiceB], []);
      resolver.registerService(ServiceB, 'ServiceB', [], []);

      final visualization = resolver.visualizeDependencyGraph();

      expect(visualization, contains('ServiceA'));
      expect(visualization, contains('ServiceB'));
      expect(visualization, contains('├─'));
    });

    test('should clear all registrations', () {
      resolver.registerService(ServiceA, 'ServiceA', [], []);
      resolver.registerService(ServiceB, 'ServiceB', [], []);

      expect(resolver.registeredServices, hasLength(2));

      resolver.clear();

      expect(resolver.registeredServices, isEmpty);
    });
  });

  group('DependencyAnalyzer', () {
    late DependencyResolver resolver;
    late DependencyAnalyzer analyzer;

    setUp(() {
      resolver = DependencyResolver();
      analyzer = DependencyAnalyzer(resolver);
    });

    test('should find root services', () {
      resolver.registerService(ServiceA, 'ServiceA', [ServiceB], []);
      resolver.registerService(ServiceB, 'ServiceB', [], []); // Root
      resolver.registerService(ServiceC, 'ServiceC', [], []); // Root

      final roots = analyzer.findRootServices();

      expect(roots, contains(ServiceB));
      expect(roots, contains(ServiceC));
      expect(roots, hasLength(2));
    });

    test('should find leaf services', () {
      resolver.registerService(ServiceA, 'ServiceA', [], []); // Leaf
      resolver.registerService(ServiceB, 'ServiceB', [ServiceA], []);
      resolver.registerService(ServiceC, 'ServiceC', [ServiceA], []);

      final leaves = analyzer.findLeafServices();

      expect(leaves, contains(ServiceB));
      expect(leaves, contains(ServiceC));
      expect(leaves, hasLength(2));
    });

    test('should calculate dependency statistics', () {
      resolver.registerService(ServiceA, 'ServiceA', [ServiceB, ServiceC], []);
      resolver.registerService(ServiceB, 'ServiceB', [ServiceD], []);
      resolver.registerService(ServiceC, 'ServiceC', [], []);
      resolver.registerService(ServiceD, 'ServiceD', [], []);

      final stats = analyzer.getStatistics();

      expect(stats.totalServices, equals(4));
      expect(stats.rootServices, equals(2)); // C and D
      expect(stats.leafServices, equals(1)); // A
      expect(stats.maxDependencies, equals(2)); // A has 2 dependencies
    });

    test('should find longest dependency chain', () {
      // Chain: D -> C -> B -> A
      resolver.registerService(ServiceD, 'ServiceD', [], []);
      resolver.registerService(ServiceC, 'ServiceC', [ServiceD], []);
      resolver.registerService(ServiceB, 'ServiceB', [ServiceC], []);
      resolver.registerService(ServiceA, 'ServiceA', [ServiceB], []);

      final longestChain = analyzer.findLongestDependencyChain();

      expect(longestChain, hasLength(4));
      expect(longestChain.first, equals(ServiceD));
      expect(longestChain.last, equals(ServiceA));
    });
  });
}

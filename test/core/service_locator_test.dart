import 'package:fluxon/src/base_service.dart';
import 'package:fluxon/src/exceptions/service_exceptions.dart';
import 'package:fluxon/src/flux_runtime.dart';
import 'package:fluxon/src/models/service_models.dart';
import 'package:fluxon/src/service_logger.dart';
import 'package:test/test.dart';

// Test service implementations
class ServiceA extends BaseService {
  bool initialized = false;
  bool destroyed = false;

  @override
  List<Type> get dependencies => const [];

  @override
  Future<void> initialize() async {
    initialized = true;
  }

  @override
  Future<void> destroy() async {
    destroyed = true;
  }
}

class ServiceB extends BaseService {
  bool initialized = false;
  bool destroyed = false;

  @override
  List<Type> get dependencies => [ServiceA];

  @override
  Future<void> initialize() async {
    initialized = true;
  }

  @override
  Future<void> destroy() async {
    destroyed = true;
  }
}

class ServiceC extends BaseService {
  bool initialized = false;
  bool destroyed = false;

  @override
  List<Type> get dependencies => [ServiceA, ServiceB];

  @override
  Future<void> initialize() async {
    initialized = true;
  }

  @override
  Future<void> destroy() async {
    destroyed = true;
  }
}

class FailingService extends BaseService {
  @override
  List<Type> get dependencies => const [];

  @override
  Future<void> initialize() async {
    throw Exception('Initialization failed');
  }
}

class OptionalDependencyService extends BaseService {
  @override
  List<Type> get dependencies => const [];

  @override
  List<Type> get optionalDependencies => [ServiceA];

  @override
  Future<void> initialize() async {
    // Initialization logic
  }
}

void main() {
  group('FluxRuntime', () {
    late FluxRuntime locator;
    late MemoryLogWriter logWriter;

    setUp(() {
      logWriter = MemoryLogWriter();
      locator = FluxRuntime(
        logger: ServiceLogger(serviceName: 'TestLocator', writer: logWriter),
      );
    });

    tearDown(() async {
      if (locator.isInitialized) {
        await locator.destroyAll();
      }
      await locator.clear();
    });

    test('should register services', () {
      locator.register<ServiceA>(ServiceA.new);

      expect(locator.isRegistered<ServiceA>(), isTrue);
      expect(locator.serviceCount, equals(1));
      expect(locator.registeredServiceTypes, contains(ServiceA));
    });

    test('should prevent duplicate registration', () {
      locator.register<ServiceA>(ServiceA.new);

      expect(
        () => locator.register<ServiceA>(ServiceA.new),
        throwsA(isA<ServiceAlreadyRegisteredException>()),
      );
    });

    test('should unregister services', () {
      locator.register<ServiceA>(ServiceA.new);

      expect(locator.isRegistered<ServiceA>(), isTrue);

      locator.unregister<ServiceA>();

      expect(locator.isRegistered<ServiceA>(), isFalse);
      expect(locator.serviceCount, equals(0));
    });

    test('should prevent unregistering non-existent services', () {
      expect(
        () => locator.unregister<ServiceA>(),
        throwsA(isA<ServiceNotFoundException>()),
      );
    });

    test('should prevent unregistering initialized services', () async {
      locator.register<ServiceA>(ServiceA.new);
      await locator.initializeAll();

      expect(
        () => locator.unregister<ServiceA>(),
        throwsA(isA<ServiceStateException>()),
      );
    });

    test('should initialize services in dependency order', () async {
      locator.register<ServiceA>(ServiceA.new);
      locator.register<ServiceB>(ServiceB.new);
      locator.register<ServiceC>(ServiceC.new);

      await locator.initializeAll();

      expect(locator.isInitialized, isTrue);
      expect(locator.initializedServiceCount, equals(3));

      final serviceA = locator.get<ServiceA>();
      final serviceB = locator.get<ServiceB>();
      final serviceC = locator.get<ServiceC>();

      expect(serviceA.initialized, isTrue);
      expect(serviceB.initialized, isTrue);
      expect(serviceC.initialized, isTrue);
    });

    test('should get initialized services', () async {
      locator.register<ServiceA>(ServiceA.new);
      await locator.initializeAll();

      final service = locator.get<ServiceA>();

      expect(service, isA<ServiceA>());
      expect(service.initialized, isTrue);
    });

    test('should throw when getting unregistered service', () async {
      await locator.initializeAll();

      expect(
        () => locator.get<ServiceA>(),
        throwsA(isA<ServiceNotFoundException>()),
      );
    });

    test('should throw when getting service before initialization', () {
      locator.register<ServiceA>(ServiceA.new);

      expect(
        () => locator.get<ServiceA>(),
        throwsA(isA<ServiceLocatorNotInitializedException>()),
      );
    });

    test('should try get services safely', () async {
      locator.register<ServiceA>(ServiceA.new);
      await locator.initializeAll();

      final service = locator.tryGet<ServiceA>();
      expect(service, isA<ServiceA>());

      final nonExistent = locator.tryGet<ServiceB>();
      expect(nonExistent, isNull);
    });

    test('should check service initialization status', () async {
      locator.register<ServiceA>(ServiceA.new);

      expect(locator.isServiceInitialized<ServiceA>(), isFalse);

      await locator.initializeAll();

      expect(locator.isServiceInitialized<ServiceA>(), isTrue);
    });

    test('should handle initialization failure', () async {
      locator.register<ServiceA>(ServiceA.new);
      locator.register<FailingService>(FailingService.new);

      expect(
        () => locator.initializeAll(),
        throwsA(isA<ServiceInitializationException>()),
      );

      expect(locator.isInitialized, isFalse);
    });

    test('should clean up on initialization failure', () async {
      locator.register<ServiceA>(ServiceA.new);
      locator.register<FailingService>(FailingService.new);

      try {
        await locator.initializeAll();
      } catch (_) {
        // Expected to fail
      }

      expect(locator.initializedServiceCount, equals(0));
    });

    test('should destroy services in reverse order', () async {
      final serviceA = ServiceA();
      final serviceB = ServiceB();
      final serviceC = ServiceC();

      locator.register<ServiceA>(() => serviceA);
      locator.register<ServiceB>(() => serviceB);
      locator.register<ServiceC>(() => serviceC);

      await locator.initializeAll();
      await locator.destroyAll();

      expect(locator.isInitialized, isFalse);
      expect(serviceA.destroyed, isTrue);
      expect(serviceB.destroyed, isTrue);
      expect(serviceC.destroyed, isTrue);
    });

    test('should handle optional dependencies', () async {
      locator
          .register<OptionalDependencyService>(OptionalDependencyService.new);
      // ServiceA is not registered but it's optional

      await locator.initializeAll();

      expect(locator.isInitialized, isTrue);

      final service = locator.get<OptionalDependencyService>();
      expect(service, isNotNull);
    });

    test('should handle optional dependencies when available', () async {
      locator.register<ServiceA>(ServiceA.new);
      locator
          .register<OptionalDependencyService>(OptionalDependencyService.new);

      await locator.initializeAll();

      expect(locator.isInitialized, isTrue);

      final serviceA = locator.get<ServiceA>();
      final optionalService = locator.get<OptionalDependencyService>();

      expect(serviceA, isNotNull);
      expect(optionalService, isNotNull);
    });

    test('should get service information', () async {
      locator.register<ServiceA>(ServiceA.new);

      final info = locator.getServiceInfo<ServiceA>();

      expect(info.name, equals('ServiceA'));
      expect(info.type, equals(ServiceA));
      expect(info.state, equals(ServiceState.registered));
    });

    test('should get all service information', () async {
      locator.register<ServiceA>(ServiceA.new);
      locator.register<ServiceB>(ServiceB.new);

      final allInfo = locator.getAllServiceInfo();

      expect(allInfo, hasLength(2));
      expect(allInfo.map((i) => i.name), containsAll(['ServiceA', 'ServiceB']));
    });

    test('should perform health checks', () async {
      locator.register<ServiceA>(ServiceA.new);
      await locator.initializeAll();

      final healthChecks = await locator.performHealthChecks();

      expect(healthChecks, hasLength(1));
      expect(healthChecks['ServiceA'], isNotNull);
      expect(healthChecks['ServiceA']!.status,
          equals(ServiceHealthStatus.healthy));
    });

    test('should get dependency statistics', () {
      locator.register<ServiceA>(ServiceA.new);
      locator.register<ServiceB>(ServiceB.new);
      locator.register<ServiceC>(ServiceC.new);

      final stats = locator.getDependencyStatistics();

      expect(stats.totalServices, equals(3));
      expect(stats.rootServices, equals(1)); // ServiceA
      expect(stats.leafServices, equals(1)); // ServiceC
    });

    test('should visualize dependency graph', () {
      locator.register<ServiceA>(ServiceA.new);
      locator.register<ServiceB>(ServiceB.new);

      final visualization = locator.visualizeDependencyGraph();

      expect(visualization, contains('ServiceA'));
      expect(visualization, contains('ServiceB'));
      expect(visualization, contains('Dependency Graph'));
    });

    test('should support lifecycle callbacks', () async {
      var initCallbackCalled = false;
      var destroyCallbackCalled = false;

      locator.addInitializationCallback((_) async {
        initCallbackCalled = true;
      });

      locator.addDestructionCallback((_) async {
        destroyCallbackCalled = true;
      });

      locator.register<ServiceA>(ServiceA.new);

      await locator.initializeAll();
      expect(initCallbackCalled, isTrue);

      await locator.destroyAll();
      expect(destroyCallbackCalled, isTrue);
    });

    test('should clear all services', () async {
      locator.register<ServiceA>(ServiceA.new);
      locator.register<ServiceB>(ServiceB.new);

      await locator.initializeAll();

      expect(locator.serviceCount, equals(2));
      expect(locator.isInitialized, isTrue);

      await locator.clear();

      expect(locator.serviceCount, equals(0));
      expect(locator.isInitialized, isFalse);
    });

    test('should prevent registration after initialization', () async {
      await locator.initializeAll();

      expect(
        () => locator.register<ServiceA>(ServiceA.new),
        throwsA(isA<ServiceStateException>()),
      );
    });

    test('should handle multiple initialization calls', () async {
      locator.register<ServiceA>(ServiceA.new);

      await locator.initializeAll();

      // Second call should not throw but should log warning
      await locator.initializeAll();

      expect(locator.isInitialized, isTrue);
    });

    test('should handle multiple destruction calls', () async {
      locator.register<ServiceA>(ServiceA.new);
      await locator.initializeAll();

      await locator.destroyAll();

      // Second call should not throw but should log warning
      await locator.destroyAll();

      expect(locator.isInitialized, isFalse);
    });
  });
}

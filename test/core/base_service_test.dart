import 'dart:async';

import 'package:fluxon/src/base_service.dart';
import 'package:fluxon/src/exceptions/service_exceptions.dart';
import 'package:fluxon/src/models/service_models.dart';
import 'package:fluxon/src/service_logger.dart';
import 'package:test/test.dart';

// Test service implementations
class TestService extends BaseService {
  TestService({ServiceLogger? logger}) : super(logger: logger);

  bool initializeCalled = false;
  bool destroyCalled = false;
  Exception? initializeError;
  Exception? destroyError;

  @override
  List<Type> get dependencies => const [];

  @override
  Future<void> initialize() async {
    if (initializeError != null) {
      throw initializeError!;
    }
    initializeCalled = true;
  }

  @override
  Future<void> destroy() async {
    if (destroyError != null) {
      throw destroyError!;
    }
    destroyCalled = true;
  }
}

class DependentService extends BaseService {
  DependentService({ServiceLogger? logger}) : super(logger: logger);

  @override
  List<Type> get dependencies => [TestService];

  @override
  Future<void> initialize() async {
    // Initialization logic
  }
}

class OptionalDependentService extends BaseService {
  OptionalDependentService({ServiceLogger? logger}) : super(logger: logger);

  @override
  List<Type> get dependencies => const [];

  @override
  List<Type> get optionalDependencies => [TestService];

  @override
  Future<void> initialize() async {
    // Initialization logic
  }
}

class ConfigurableTestService extends BaseService
    with ConfigurableServiceMixin {
  ConfigurableTestService({ServiceLogger? logger}) : super(logger: logger);

  bool configValid = true;

  @override
  List<Type> get dependencies => const [];

  @override
  void validateConfiguration() {
    if (!configValid) {
      throw Exception('Invalid configuration');
    }
  }

  @override
  Future<void> initialize() async {
    await super.initialize();
    // Initialization logic
  }
}

class PeriodicTestService extends BaseService with PeriodicServiceMixin {
  PeriodicTestService({ServiceLogger? logger}) : super(logger: logger);

  int periodicTaskCount = 0;
  bool enablePeriodic = true;

  @override
  List<Type> get dependencies => const [];

  @override
  Duration get periodicInterval => const Duration(milliseconds: 10);

  @override
  bool get periodicTasksEnabled => enablePeriodic;

  @override
  Future<void> performPeriodicTask() async {
    periodicTaskCount++;
  }

  @override
  Future<void> initialize() async {
    await super.initialize();
    // Initialization logic
  }
}

class ResourceManagedTestService extends BaseService
    with ResourceManagedServiceMixin {
  ResourceManagedTestService({ServiceLogger? logger}) : super(logger: logger);

  @override
  List<Type> get dependencies => const [];

  @override
  Future<void> initialize() async {
    // Register some test resources
    registerTimer(Timer.periodic(const Duration(seconds: 1), (_) {}));
  }
}

void main() {
  group('BaseService', () {
    late TestService service;
    late MemoryLogWriter logWriter;

    setUp(() {
      logWriter = MemoryLogWriter();
      final logger = ServiceLogger(
        serviceName: 'TestService',
        writer: logWriter,
      );
      service = TestService(logger: logger);
    });

    test('should start in registered state', () {
      expect(service.state, equals(ServiceState.registered));
      expect(service.isInitialized, isFalse);
      expect(service.isDestroyed, isFalse);
      expect(service.hasFailed, isFalse);
    });

    test('should initialize successfully', () async {
      await service.internalInitialize();

      expect(service.state, equals(ServiceState.initialized));
      expect(service.isInitialized, isTrue);
      expect(service.initializeCalled, isTrue);
      expect(service.initializedAt, isNotNull);
    });

    test('should handle initialization failure', () async {
      service.initializeError = Exception('Init failed');

      try {
        await service.internalInitialize();
        fail('Expected ServiceInitializationException to be thrown');
      } catch (e) {
        expect(e, isA<ServiceInitializationException>());
      }

      expect(service.state, equals(ServiceState.failed));
      expect(service.hasFailed, isTrue);
      expect(service.error, isNotNull);
    });

    test('should destroy successfully', () async {
      await service.internalInitialize();
      await service.internalDestroy();

      expect(service.state, equals(ServiceState.destroyed));
      expect(service.isDestroyed, isTrue);
      expect(service.destroyCalled, isTrue);
      expect(service.destroyedAt, isNotNull);
    });

    test('should handle destruction failure gracefully', () async {
      await service.internalInitialize();
      service.destroyError = Exception('Destroy failed');

      // Should not throw
      await service.internalDestroy();

      expect(service.state, equals(ServiceState.failed));
      expect(service.error, isNotNull);
    });

    test('should prevent double initialization', () async {
      await service.internalInitialize();

      expect(
        () => service.internalInitialize(),
        throwsA(isA<ServiceStateException>()),
      );
    });

    test('should allow multiple destroy calls', () async {
      await service.internalInitialize();
      await service.internalDestroy();

      // Second destroy should not throw
      await service.internalDestroy();

      expect(service.state, equals(ServiceState.destroyed));
    });

    test('should ensure initialized state', () async {
      expect(
        () => service.ensureInitialized(),
        throwsA(isA<ServiceStateException>()),
      );

      await service.internalInitialize();

      // Should not throw
      service.ensureInitialized();
    });

    test('should ensure not destroyed state', () async {
      await service.internalInitialize();
      await service.internalDestroy();

      expect(
        () => service.ensureNotDestroyed(),
        throwsA(isA<ServiceDestroyedException>()),
      );
    });

    test('should perform health check', () async {
      await service.internalInitialize();

      final healthCheck = await service.healthCheck();

      expect(healthCheck.status, equals(ServiceHealthStatus.healthy));
      expect(healthCheck.message, contains('running normally'));
    });

    test('should report unhealthy when failed', () async {
      service.initializeError = Exception('Init failed');

      try {
        await service.internalInitialize();
      } catch (_) {
        // Expected to fail
      }

      final healthCheck = await service.healthCheck();

      expect(healthCheck.status, equals(ServiceHealthStatus.unhealthy));
      expect(healthCheck.message, contains('failed'));
    });

    test('should manage logger metadata', () {
      service.setLoggerMetadata({'key1': 'value1'});
      service.addLoggerMetadata('key2', 'value2');

      service.logger.info('Test message');

      final entry = logWriter.entries.first;
      expect(entry.metadata['key1'], equals('value1'));
      expect(entry.metadata['key2'], equals('value2'));
    });

    test('should create child logger', () {
      service.setLoggerMetadata({'service': 'test'});

      final childLogger = service.createChildLogger({'request': '123'});
      childLogger.info('Child message');

      final entry = logWriter.entries.first;
      expect(entry.metadata['service'], equals('test'));
      expect(entry.metadata['request'], equals('123'));
    });

    test('should retry operations', () async {
      var attempts = 0;

      final result = await service.withRetry('test operation', () async {
        attempts++;
        if (attempts < 3) {
          throw Exception('Temporary failure');
        }
        return 'success';
      }, maxAttempts: 3);

      expect(result, equals('success'));
      expect(attempts, equals(3));
    });

    test('should fail after max retry attempts', () async {
      expect(
        () => service.withRetry('failing operation', () async {
          throw Exception('Always fails');
        }, maxAttempts: 2),
        throwsA(isA<ServiceRetryExceededException>()),
      );
    });

    test('should provide service info', () {
      final info = service.getServiceInfo();

      expect(info.name, equals('TestService'));
      expect(info.type, equals(TestService));
      expect(info.state, equals(ServiceState.registered));
      expect(info.dependencies, isEmpty);
    });

    test('should declare dependencies correctly', () {
      final dependentService = DependentService();

      expect(dependentService.dependencies, contains(TestService));
      expect(dependentService.dependencies, hasLength(1));
    });

    test('should declare optional dependencies correctly', () {
      final optionalService = OptionalDependentService();

      expect(optionalService.optionalDependencies, contains(TestService));
      expect(optionalService.dependencies, isEmpty);
    });
  });

  group('ConfigurableServiceMixin', () {
    late ConfigurableTestService service;

    setUp(() {
      service = ConfigurableTestService();
    });

    test('should validate configuration during initialization', () async {
      service.configValid = true;

      await service.internalInitialize();

      expect(service.state, equals(ServiceState.initialized));
    });

    test('should fail initialization with invalid configuration', () async {
      service.configValid = false;

      try {
        await service.internalInitialize();
        fail('Expected ServiceInitializationException to be thrown');
      } catch (e) {
        expect(e, isA<ServiceInitializationException>());
        final initException = e as ServiceInitializationException;
        expect(initException.cause, isA<ServiceConfigurationException>());
      }
    });
  });

  group('PeriodicServiceMixin', () {
    late PeriodicTestService service;

    setUp(() {
      service = PeriodicTestService();
    });

    test('should start periodic tasks on initialization', () async {
      await service.internalInitialize();

      // Wait for a few periodic executions
      await Future.delayed(const Duration(milliseconds: 50));

      expect(service.periodicTaskCount, greaterThan(0));
    });

    test('should stop periodic tasks on destruction', () async {
      await service.internalInitialize();
      await Future.delayed(const Duration(milliseconds: 20));

      final countBeforeDestroy = service.periodicTaskCount;

      await service.internalDestroy();
      await Future.delayed(const Duration(milliseconds: 20));

      // Count should not increase after destruction
      expect(service.periodicTaskCount, equals(countBeforeDestroy));
    });

    test('should not start periodic tasks when disabled', () async {
      service.enablePeriodic = false;

      await service.internalInitialize();
      await Future.delayed(const Duration(milliseconds: 30));

      expect(service.periodicTaskCount, equals(0));
    });
  });

  group('ResourceManagedServiceMixin', () {
    late ResourceManagedTestService service;

    setUp(() {
      service = ResourceManagedTestService();
    });

    test('should clean up resources on destruction', () async {
      await service.internalInitialize();

      // Verify resources are registered (indirectly)
      expect(service.state, equals(ServiceState.initialized));

      // Destruction should clean up resources without throwing
      await service.internalDestroy();

      expect(service.state, equals(ServiceState.destroyed));
    });
  });
}

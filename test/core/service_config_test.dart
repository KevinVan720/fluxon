import 'package:fluxon/src/base_service.dart';
import 'package:fluxon/src/models/service_models.dart';
import 'package:fluxon/src/service_logger.dart';
import 'package:test/test.dart';

// Test service that accepts custom ServiceConfig
class TestServiceWithConfig extends BaseService {
  TestServiceWithConfig({
    ServiceConfig? config,
    ServiceLogger? logger,
  }) : super(config: config, logger: logger);

  bool initialized = false;

  @override
  List<Type> get dependencies => const [];

  @override
  Future<void> initialize() async {
    initialized = true;
  }
}

// Test service with default config
class DefaultConfigService extends BaseService {
  DefaultConfigService() : super();

  @override
  List<Type> get dependencies => const [];

  @override
  Future<void> initialize() async {}
}

void main() {
  group('ServiceConfig', () {
    test('should create service with custom ServiceConfig', () {
      final service = TestServiceWithConfig(
        config: const ServiceConfig(
          timeout: Duration(seconds: 45),
          retryAttempts: 5,
          retryDelay: Duration(milliseconds: 200),
          enableLogging: false,
          logLevel: ServiceLogLevel.error,
          metadata: {'environment': 'test', 'version': '1.2.3'},
        ),
      );

      expect(service.config.timeout, equals(const Duration(seconds: 45)));
      expect(service.config.retryAttempts, equals(5));
      expect(
          service.config.retryDelay, equals(const Duration(milliseconds: 200)));
      expect(service.config.enableLogging, isFalse);
      expect(service.config.logLevel, equals(ServiceLogLevel.error));
      expect(service.config.metadata['environment'], equals('test'));
      expect(service.config.metadata['version'], equals('1.2.3'));
    });

    test('should use default ServiceConfig when none provided', () {
      final service = DefaultConfigService();

      expect(service.config.timeout, equals(const Duration(seconds: 30)));
      expect(service.config.retryAttempts, equals(3));
      expect(service.config.retryDelay, equals(const Duration(seconds: 1)));
      expect(service.config.enableLogging, isTrue);
      expect(service.config.logLevel, equals(ServiceLogLevel.info));
      expect(service.config.metadata, isEmpty);
    });

    test('should create ServiceConfig with partial parameters', () {
      const config = ServiceConfig(
        timeout: Duration(seconds: 60),
        enableLogging: false,
        // Other parameters use defaults
      );

      expect(config.timeout, equals(const Duration(seconds: 60)));
      expect(config.retryAttempts, equals(3)); // default
      expect(config.retryDelay, equals(const Duration(seconds: 1))); // default
      expect(config.enableLogging, isFalse);
      expect(config.logLevel, equals(ServiceLogLevel.info)); // default
      expect(config.metadata, isEmpty); // default
    });

    test('should handle empty metadata', () {
      const config = ServiceConfig(metadata: <String, dynamic>{});

      expect(config.metadata, isEmpty);
    });

    test('should handle complex metadata', () {
      const config = ServiceConfig(
        metadata: {
          'string': 'value',
          'number': 42,
          'boolean': true,
          'list': [1, 2, 3],
          'nested': {'key': 'value'},
        },
      );

      expect(config.metadata['string'], equals('value'));
      expect(config.metadata['number'], equals(42));
      expect(config.metadata['boolean'], isTrue);
      expect(config.metadata['list'], equals([1, 2, 3]));
      expect(config.metadata['nested'], equals({'key': 'value'}));
    });

    test('should handle all ServiceLogLevel values', () {
      for (final level in ServiceLogLevel.values) {
        final config = ServiceConfig(logLevel: level);
        expect(config.logLevel, equals(level));
      }
    });

    test('should handle zero and negative durations', () {
      const config = ServiceConfig(
        timeout: Duration.zero,
        retryDelay: Duration(milliseconds: -100),
      );

      expect(config.timeout, equals(Duration.zero));
      expect(config.retryDelay, equals(const Duration(milliseconds: -100)));
    });

    test('should handle zero and negative retry attempts', () {
      const config = ServiceConfig(retryAttempts: 0);
      expect(config.retryAttempts, equals(0));

      const negativeConfig = ServiceConfig(retryAttempts: -5);
      expect(negativeConfig.retryAttempts, equals(-5));
    });

    test('should preserve service config after initialization', () async {
      final service = TestServiceWithConfig(
        config: const ServiceConfig(
          timeout: Duration(minutes: 2),
          retryAttempts: 10,
          metadata: {'persistent': true},
        ),
      );

      await service.internalInitialize();

      expect(service.initialized, isTrue);
      expect(service.config.timeout, equals(const Duration(minutes: 2)));
      expect(service.config.retryAttempts, equals(10));
      expect(service.config.metadata['persistent'], isTrue);
    });
  });
}

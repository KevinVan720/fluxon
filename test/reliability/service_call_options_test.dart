import 'dart:async';

import 'package:flux/flux.dart';
import 'package:test/test.dart';

part 'service_call_options_test.g.dart';

@ServiceContract(remote: true)
class TimeoutTestService extends FluxService {
  Future<String> fastMethod() async {
    return 'fast_result';
  }

  Future<String> slowMethod(int delayMs) async {
    await Future.delayed(Duration(milliseconds: delayMs));
    return 'slow_result';
  }

  Future<String> verySlowMethod() async {
    await Future.delayed(const Duration(seconds: 5));
    return 'very_slow_result';
  }
}

void main() {
  group('ServiceCallOptions Tests', () {
    late FluxRuntime runtime;

    setUp(() async {
      runtime = FluxRuntime();
      runtime.register<TimeoutTestService>(TimeoutTestServiceImpl.new);
      await runtime.initializeAll();
    });

    tearDown(() async {
      await runtime.destroyAll();
    });

    group('Timeout Configuration', () {
      test('should succeed with sufficient timeout', () async {
        final proxy = runtime.proxyRegistry.getProxy<TimeoutTestService>();

        final result = await proxy.callMethod<String>(
          'slowMethod',
          [100], // 100ms delay
          options:
              const ServiceCallOptions(timeout: Duration(milliseconds: 500)),
        );

        expect(result, equals('slow_result'));
      });

      test('should timeout with insufficient timeout', () async {
        final proxy = runtime.proxyRegistry.getProxy<TimeoutTestService>();

        expect(
          () => proxy.callMethod<String>(
            'slowMethod',
            [300], // 300ms delay
            options:
                const ServiceCallOptions(timeout: Duration(milliseconds: 100)),
          ),
          throwsA(isA<ServiceTimeoutException>()),
        );
      });

      test('should handle very short timeout', () async {
        final proxy = runtime.proxyRegistry.getProxy<TimeoutTestService>();

        expect(
          () => proxy.callMethod<String>(
            'slowMethod',
            [100],
            options:
                const ServiceCallOptions(timeout: Duration(microseconds: 1)),
          ),
          throwsA(isA<ServiceTimeoutException>()),
        );
      });

      test('should handle very long timeout', () async {
        final proxy = runtime.proxyRegistry.getProxy<TimeoutTestService>();

        final result = await proxy.callMethod<String>(
          'fastMethod',
          [],
          options: const ServiceCallOptions(timeout: Duration(hours: 1)),
        );

        expect(result, equals('fast_result'));
      });
    });

    group('Retry Configuration', () {
      test('should use default retry behavior with zero retries', () async {
        final proxy = runtime.proxyRegistry.getProxy<TimeoutTestService>();

        // This should succeed on first try (no retries needed)
        final result = await proxy.callMethod<String>(
          'fastMethod',
          [],
          options: const ServiceCallOptions(retryAttempts: 0),
        );

        expect(result, equals('fast_result'));
      });

      test('should handle large retry count gracefully', () async {
        final proxy = runtime.proxyRegistry.getProxy<TimeoutTestService>();

        // This should succeed on first try regardless of retry count
        final result = await proxy.callMethod<String>(
          'fastMethod',
          [],
          options: const ServiceCallOptions(retryAttempts: 1000),
        );

        expect(result, equals('fast_result'));
      });
    });

    group('Metadata Configuration', () {
      test('should handle empty metadata', () {
        const options = ServiceCallOptions(metadata: <String, dynamic>{});
        expect(options.metadata, isEmpty);
      });

      test('should handle null values in metadata', () {
        const options = ServiceCallOptions(metadata: {
          'nullValue': null,
          'stringValue': 'test',
        });

        expect(options.metadata['nullValue'], isNull);
        expect(options.metadata['stringValue'], equals('test'));
      });

      test('should handle complex metadata types', () {
        const options = ServiceCallOptions(metadata: {
          'string': 'value',
          'number': 42,
          'boolean': true,
          'list': [1, 2, 3],
          'map': {'nested': 'value'},
        });

        expect(options.metadata['string'], equals('value'));
        expect(options.metadata['number'], equals(42));
        expect(options.metadata['boolean'], isTrue);
        expect(options.metadata['list'], equals([1, 2, 3]));
        expect(options.metadata['map'], equals({'nested': 'value'}));
      });
    });

    group('Combined Options', () {
      test('should handle timeout and metadata together', () async {
        final proxy = runtime.proxyRegistry.getProxy<TimeoutTestService>();

        final result = await proxy.callMethod<String>(
          'fastMethod',
          [],
          options: const ServiceCallOptions(
            timeout: Duration(seconds: 10),
            metadata: {'test': 'combined_options'},
          ),
        );

        expect(result, equals('fast_result'));
      });

      test('should handle all options together', () async {
        final proxy = runtime.proxyRegistry.getProxy<TimeoutTestService>();

        final result = await proxy.callMethod<String>(
          'fastMethod',
          [],
          options: const ServiceCallOptions(
            timeout: Duration(seconds: 30),
            retryAttempts: 3,
            retryDelay: Duration(milliseconds: 100),
            metadata: {'comprehensive': true, 'testId': 123},
          ),
        );

        expect(result, equals('fast_result'));
      });
    });

    group('Default Values', () {
      test('should use correct default values', () {
        const options = ServiceCallOptions();

        expect(options.timeout, equals(const Duration(seconds: 10)));
        expect(options.retryAttempts, equals(0));
        expect(options.retryDelay, equals(const Duration(milliseconds: 500)));
        expect(options.metadata, isEmpty);
      });

      test('should allow overriding individual defaults', () {
        const options = ServiceCallOptions(timeout: Duration(seconds: 30));

        expect(options.timeout, equals(const Duration(seconds: 30)));
        expect(options.retryAttempts, equals(0)); // Still default
        expect(options.retryDelay,
            equals(const Duration(milliseconds: 500))); // Still default
        expect(options.metadata, isEmpty); // Still default
      });
    });

    group('Edge Cases', () {
      test('should handle zero timeout duration', () {
        const options = ServiceCallOptions(timeout: Duration.zero);
        expect(options.timeout, equals(Duration.zero));
      });

      test('should handle negative retry attempts', () {
        const options = ServiceCallOptions(retryAttempts: -5);
        expect(options.retryAttempts, equals(-5)); // Value preserved
      });

      test('should handle negative retry delay', () {
        const options =
            ServiceCallOptions(retryDelay: Duration(milliseconds: -100));
        expect(options.retryDelay,
            equals(const Duration(milliseconds: -100))); // Value preserved
      });

      test('should handle very large metadata', () {
        final largeMetadata = <String, dynamic>{};
        for (int i = 0; i < 100; i++) {
          largeMetadata['key_$i'] = 'value_$i';
        }

        final options = ServiceCallOptions(metadata: largeMetadata);
        expect(options.metadata, hasLength(100));
        expect(options.metadata['key_50'], equals('value_50'));
      });
    });

    group('Real-world Scenarios', () {
      test('should handle quick operations with long timeout', () async {
        final proxy = runtime.proxyRegistry.getProxy<TimeoutTestService>();

        final stopwatch = Stopwatch()..start();
        final result = await proxy.callMethod<String>(
          'fastMethod',
          [],
          options: const ServiceCallOptions(timeout: Duration(minutes: 5)),
        );
        stopwatch.stop();

        expect(result, equals('fast_result'));
        expect(stopwatch.elapsedMilliseconds,
            lessThan(1000)); // Should be very fast
      });

      test('should respect timeout boundaries accurately', () async {
        final proxy = runtime.proxyRegistry.getProxy<TimeoutTestService>();

        final stopwatch = Stopwatch()..start();

        expect(
          () => proxy.callMethod<String>(
            'slowMethod',
            [200], // 200ms delay
            options: const ServiceCallOptions(
                timeout: Duration(milliseconds: 100)), // 100ms timeout
          ),
          throwsA(isA<ServiceTimeoutException>()),
        );

        stopwatch.stop();
        // Should timeout around 100ms, not wait for the full 200ms
        expect(stopwatch.elapsedMilliseconds, lessThan(150));
      });

      test('should work with reasonable retry configuration', () async {
        final proxy = runtime.proxyRegistry.getProxy<TimeoutTestService>();

        // This should succeed immediately (no retries needed for fast method)
        final result = await proxy.callMethod<String>(
          'fastMethod',
          [],
          options: const ServiceCallOptions(
            retryAttempts: 3,
            retryDelay: Duration(milliseconds: 50),
          ),
        );

        expect(result, equals('fast_result'));
      });
    });
  });
}

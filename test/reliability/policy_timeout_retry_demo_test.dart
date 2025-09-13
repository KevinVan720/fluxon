import 'package:fluxon/fluxon.dart';
import 'package:test/test.dart';

part 'policy_timeout_retry_demo_test.g.dart';

@ServiceContract(remote: true)
class PolicyService extends FluxService {
  int _n = 0;

  @ServiceMethod(retryAttempts: 2, retryDelayMs: 50)
  Future<String> flaky() async {
    _n++;
    if (_n < 3) throw StateError('flaky');
    return 'ok-after-$_n';
  }

  @ServiceMethod(timeoutMs: 100)
  Future<String> slow() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return 'slow-finished';
  }

  @ServiceMethod(timeoutMs: 100, retryAttempts: 1, retryDelayMs: 50)
  Future<String> slowRetry() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return 'slow-retry-finished';
  }
}

Future<void> _runPolicytimeoutretrydemoDemo() async {
  final locator = FluxRuntime();
  try {
    locator.register<PolicyService>(PolicyServiceImpl.new);

    await locator.initializeAll();

    final proxy = locator.proxyRegistry.getProxy<PolicyService>()
        as ServiceProxy<PolicyService>;
    final client = GeneratedClientRegistry.create<PolicyService>(proxy)!;
    final flakyRes = await client.flaky();
    print('flaky() => $flakyRes');

    try {
      await client.slow();
    } on ServiceTimeoutException catch (e) {
      print('slow() timed out as per policy: ${e.message}');
    }
  } finally {
    await locator.destroyAll();
  }
}

void main() {
  group('Policy Timeout Retry Demo', () {
    test('runs policy timeout retry demo successfully', () async {
      await _runPolicytimeoutretrydemoDemo();
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('flaky respects retryAttempts and retryDelayMs', () async {
      final locator = FluxRuntime();
      try {
        locator.register<PolicyService>(PolicyServiceImpl.new);
        await locator.initializeAll();

        final proxy = locator.proxyRegistry.getProxy<PolicyService>()
            as ServiceProxy<PolicyService>;
        final client = GeneratedClientRegistry.create<PolicyService>(proxy)!;

        final sw = Stopwatch()..start();
        final res = await client.flaky();
        sw.stop();

        expect(res, equals('ok-after-3'));
        // Two retries with 50ms delay each => ~100ms minimum
        expect(sw.elapsedMilliseconds, greaterThanOrEqualTo(90));
      } finally {
        await locator.destroyAll();
      }
    });

    test('slow() times out per method policy', () async {
      final locator = FluxRuntime();
      try {
        locator.register<PolicyService>(PolicyServiceImpl.new);
        await locator.initializeAll();

        final proxy = locator.proxyRegistry.getProxy<PolicyService>()
            as ServiceProxy<PolicyService>;
        final client = GeneratedClientRegistry.create<PolicyService>(proxy)!;

        expect(() => client.slow(), throwsA(isA<ServiceTimeoutException>()));
      } finally {
        await locator.destroyAll();
      }
    });

    test('runtime override can relax timeout to succeed', () async {
      final locator = FluxRuntime();
      try {
        locator.register<PolicyService>(PolicyServiceImpl.new);
        await locator.initializeAll();

        final proxy = locator.proxyRegistry.getProxy<PolicyService>()
            as ServiceProxy<PolicyService>;
        final result = await proxy.callMethod<String>(
          'slow',
          const [],
          options:
              const ServiceCallOptions(timeout: Duration(milliseconds: 350)),
        );
        expect(result, equals('slow-finished'));
      } finally {
        await locator.destroyAll();
      }
    });

    test('slowRetry() times out after retryAttempts and delay', () async {
      final locator = FluxRuntime();
      try {
        locator.register<PolicyService>(PolicyServiceImpl.new);
        await locator.initializeAll();

        final proxy = locator.proxyRegistry.getProxy<PolicyService>()
            as ServiceProxy<PolicyService>;
        final client = GeneratedClientRegistry.create<PolicyService>(proxy)!;

        final sw = Stopwatch()..start();
        await expectLater(
            () => client.slowRetry(), throwsA(isA<ServiceTimeoutException>()));
        sw.stop();
        // One retry with 100ms timeout and 50ms delay => ~250ms minimum
        expect(sw.elapsedMilliseconds, greaterThanOrEqualTo(230));
      } finally {
        await locator.destroyAll();
      }
    });
  });
}

import 'package:dart_service_framework/dart_service_framework.dart';
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
}

Future<void> _runPolicytimeoutretrydemoDemo() async {
  final locator = ServiceLocator();
  try {
    locator.register<PolicyService>(PolicyServiceWorker.new);

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
  });
}

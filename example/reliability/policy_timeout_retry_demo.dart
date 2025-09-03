import 'package:dart_service_framework/dart_service_framework.dart';

part 'policy_timeout_retry_demo.g.dart';

@ServiceContract(remote: true)
abstract class PolicyService extends BaseService {
  @ServiceMethod(retryAttempts: 2, retryDelayMs: 50)
  Future<String> flaky();

  @ServiceMethod(timeoutMs: 100)
  Future<String> slow();
}

class PolicyServiceImpl extends PolicyService {
  int _n = 0;

  @override
  Future<void> initialize() async {
    _registerPolicyServiceDispatcher();
  }

  @override
  Future<String> flaky() async {
    _n++;
    if (_n < 3) throw StateError('flaky');
    return 'ok-after-$_n';
  }

  @override
  Future<String> slow() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return 'slow-finished';
  }
}

Future<void> main() async {
  final locator = EnhancedServiceLocator();
  try {
    await locator.registerWorkerServiceProxy<PolicyService>(
      serviceName: 'PolicyService',
      serviceFactory: () => PolicyServiceImpl(),
      registerGenerated: registerPolicyServiceGenerated,
    );

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

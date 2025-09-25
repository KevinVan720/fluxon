// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'policy_timeout_retry_demo_test.dart';

// **************************************************************************
// ServiceGenerator
// **************************************************************************

// Service client for PolicyService
class PolicyServiceClient extends PolicyService {
  PolicyServiceClient(this._proxy);
  final ServiceProxy<PolicyService> _proxy;

  @override
  Future<String> flaky() async {
    return await _proxy.callMethod<String>('flaky', [],
        namedArgs: {},
        options: const ServiceCallOptions(
            retryAttempts: 2, retryDelay: Duration(milliseconds: 50)));
  }

  @override
  Future<String> slow() async {
    return await _proxy.callMethod<String>('slow', [],
        namedArgs: {},
        options:
            const ServiceCallOptions(timeout: Duration(milliseconds: 100)));
  }

  @override
  Future<String> slowRetry() async {
    return await _proxy.callMethod<String>('slowRetry', [],
        namedArgs: {},
        options: const ServiceCallOptions(
            timeout: Duration(milliseconds: 100),
            retryAttempts: 1,
            retryDelay: Duration(milliseconds: 50)));
  }
}

void $registerPolicyServiceClientFactory() {
  GeneratedClientRegistry.register<PolicyService>(
    (proxy) => PolicyServiceClient(proxy),
  );
}

class _PolicyServiceMethods {
  static const int flakyId = 1;
  static const int slowId = 2;
  static const int slowRetryId = 3;
}

Future<dynamic> _PolicyServiceDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as PolicyService;
  switch (methodId) {
    case _PolicyServiceMethods.flakyId:
      return await s.flaky();
    case _PolicyServiceMethods.slowId:
      return await s.slow();
    case _PolicyServiceMethods.slowRetryId:
      return await s.slowRetry();
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void $registerPolicyServiceDispatcher() {
  GeneratedDispatcherRegistry.register<PolicyService>(
    _PolicyServiceDispatcher,
  );
}

void $registerPolicyServiceMethodIds() {
  ServiceMethodIdRegistry.register<PolicyService>({
    'flaky': _PolicyServiceMethods.flakyId,
    'slow': _PolicyServiceMethods.slowId,
    'slowRetry': _PolicyServiceMethods.slowRetryId,
  });
}

void registerPolicyServiceGenerated() {
  $registerPolicyServiceClientFactory();
  $registerPolicyServiceMethodIds();
}

// Remote service implementation that auto-registers the dispatcher
class PolicyServiceImpl extends PolicyService {
  @override
  bool get isRemote => true;
  @override
  Type get clientBaseType => PolicyService;
  @override
  Future<void> registerHostSide() async {
    $registerPolicyServiceClientFactory();
    $registerPolicyServiceMethodIds();
  }

  @override
  Future<void> initialize() async {
    $registerPolicyServiceDispatcher();
    await super.initialize();
  }
}

void $registerPolicyServiceLocalSide() {
  $registerPolicyServiceDispatcher();
  $registerPolicyServiceClientFactory();
  $registerPolicyServiceMethodIds();
}

void $autoRegisterPolicyServiceLocalSide() {
  LocalSideRegistry.register<PolicyService>($registerPolicyServiceLocalSide);
}

final $_PolicyServiceLocalSideRegistered = (() {
  $autoRegisterPolicyServiceLocalSide();
  return true;
})();

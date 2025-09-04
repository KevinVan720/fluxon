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
    return await _proxy.callMethod('flaky', [],
        namedArgs: {},
        options: const ServiceCallOptions(
            retryAttempts: 2, retryDelay: Duration(milliseconds: 50)));
  }

  @override
  Future<String> slow() async {
    return await _proxy.callMethod('slow', [],
        namedArgs: {},
        options:
            const ServiceCallOptions(timeout: Duration(milliseconds: 100)));
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
  });
}

void registerPolicyServiceGenerated() {
  $registerPolicyServiceClientFactory();
  $registerPolicyServiceMethodIds();
}

// Remote service implementation that auto-registers the dispatcher
class PolicyServiceImpl extends PolicyService {
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

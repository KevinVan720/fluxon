// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'policy_timeout_retry_demo.dart';

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

void _registerPolicyServiceClientFactory() {
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

void _registerPolicyServiceDispatcher() {
  GeneratedDispatcherRegistry.register<PolicyService>(
    _PolicyServiceDispatcher,
  );
}

void _registerPolicyServiceMethodIds() {
  ServiceMethodIdRegistry.register<PolicyService>({
    'flaky': _PolicyServiceMethods.flakyId,
    'slow': _PolicyServiceMethods.slowId,
  });
}

void registerPolicyServiceGenerated() {
  _registerPolicyServiceClientFactory();
  _registerPolicyServiceMethodIds();
}

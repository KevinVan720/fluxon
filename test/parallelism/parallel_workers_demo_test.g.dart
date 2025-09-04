// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'parallel_workers_demo_test.dart';

// **************************************************************************
// ServiceGenerator
// **************************************************************************

// Service client for CruncherService
class CruncherServiceClient extends CruncherService {
  CruncherServiceClient(this._proxy);
  final ServiceProxy<CruncherService> _proxy;

  @override
  Future<int> fibonacci(int n) async {
    return await _proxy.callMethod('fibonacci', [n], namedArgs: {});
  }
}

void _registerCruncherServiceClientFactory() {
  GeneratedClientRegistry.register<CruncherService>(
    (proxy) => CruncherServiceClient(proxy),
  );
}

class _CruncherServiceMethods {
  static const int fibonacciId = 1;
}

Future<dynamic> _CruncherServiceDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as CruncherService;
  switch (methodId) {
    case _CruncherServiceMethods.fibonacciId:
      return await s.fibonacci(positionalArgs[0]);
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void _registerCruncherServiceDispatcher() {
  GeneratedDispatcherRegistry.register<CruncherService>(
    _CruncherServiceDispatcher,
  );
}

void _registerCruncherServiceMethodIds() {
  ServiceMethodIdRegistry.register<CruncherService>({
    'fibonacci': _CruncherServiceMethods.fibonacciId,
  });
}

void registerCruncherServiceGenerated() {
  _registerCruncherServiceClientFactory();
  _registerCruncherServiceMethodIds();
}

// 🚀 FLUX: Single registration call mixin
mixin CruncherServiceRegistration {
  void registerService() {
    _registerCruncherServiceDispatcher();
  }
}

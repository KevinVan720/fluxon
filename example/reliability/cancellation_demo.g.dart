// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cancellation_demo.dart';

// **************************************************************************
// ServiceGenerator
// **************************************************************************

// Service client for SlowService
class SlowServiceClient extends SlowService {
  SlowServiceClient(this._proxy);
  final ServiceProxy<SlowService> _proxy;

  @override
  Future<String> sleepMs(int ms) async {
    return await _proxy.callMethod('sleepMs', [ms], namedArgs: {});
  }

  @override
  Future<String> quick() async {
    return await _proxy.callMethod('quick', [], namedArgs: {});
  }
}

void _registerSlowServiceClientFactory() {
  GeneratedClientRegistry.register<SlowService>(
    (proxy) => SlowServiceClient(proxy),
  );
}

class _SlowServiceMethods {
  static const int sleepMsId = 1;
  static const int quickId = 2;
}

Future<dynamic> _SlowServiceDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as SlowService;
  switch (methodId) {
    case _SlowServiceMethods.sleepMsId:
      return await s.sleepMs(positionalArgs[0]);
    case _SlowServiceMethods.quickId:
      return await s.quick();
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void _registerSlowServiceDispatcher() {
  GeneratedDispatcherRegistry.register<SlowService>(
    _SlowServiceDispatcher,
  );
}

void _registerSlowServiceMethodIds() {
  ServiceMethodIdRegistry.register<SlowService>({
    'sleepMs': _SlowServiceMethods.sleepMsId,
    'quick': _SlowServiceMethods.quickId,
  });
}

void registerSlowServiceGenerated() {
  _registerSlowServiceClientFactory();
  _registerSlowServiceMethodIds();
}

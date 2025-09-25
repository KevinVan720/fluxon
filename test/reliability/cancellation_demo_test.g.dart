// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cancellation_demo_test.dart';

// **************************************************************************
// ServiceGenerator
// **************************************************************************

// Service client for SlowService
class SlowServiceClient extends SlowService {
  SlowServiceClient(this._proxy);
  final ServiceProxy<SlowService> _proxy;

  @override
  Future<String> sleepMs(int ms) async {
    return await _proxy.callMethod<String>('sleepMs', [ms], namedArgs: {});
  }

  @override
  Future<String> quick() async {
    return await _proxy.callMethod<String>('quick', [], namedArgs: {});
  }
}

void $registerSlowServiceClientFactory() {
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

void $registerSlowServiceDispatcher() {
  GeneratedDispatcherRegistry.register<SlowService>(
    _SlowServiceDispatcher,
  );
}

void $registerSlowServiceMethodIds() {
  ServiceMethodIdRegistry.register<SlowService>({
    'sleepMs': _SlowServiceMethods.sleepMsId,
    'quick': _SlowServiceMethods.quickId,
  });
}

void registerSlowServiceGenerated() {
  $registerSlowServiceClientFactory();
  $registerSlowServiceMethodIds();
}

// Remote service implementation that auto-registers the dispatcher
class SlowServiceImpl extends SlowService {
  @override
  bool get isRemote => true;
  @override
  Type get clientBaseType => SlowService;
  @override
  Future<void> registerHostSide() async {
    $registerSlowServiceClientFactory();
    $registerSlowServiceMethodIds();
  }

  @override
  Future<void> initialize() async {
    $registerSlowServiceDispatcher();
    await super.initialize();
  }
}

void $registerSlowServiceLocalSide() {
  $registerSlowServiceDispatcher();
  $registerSlowServiceClientFactory();
  $registerSlowServiceMethodIds();
}

void $autoRegisterSlowServiceLocalSide() {
  LocalSideRegistry.register<SlowService>($registerSlowServiceLocalSide);
}

final $_SlowServiceLocalSideRegistered = (() {
  $autoRegisterSlowServiceLocalSide();
  return true;
})();

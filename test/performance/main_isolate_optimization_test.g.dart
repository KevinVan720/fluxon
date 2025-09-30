// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'main_isolate_optimization_test.dart';

// **************************************************************************
// ServiceGenerator
// **************************************************************************

// Service client for HighFrequencyEventService
class HighFrequencyEventServiceClient extends HighFrequencyEventService {
  HighFrequencyEventServiceClient(this._proxy);
  final ServiceProxy<HighFrequencyEventService> _proxy;

  @override
  Future<void> sendBurstEvents(int count) async {
    await _proxy.callMethod<void>('sendBurstEvents', [count], namedArgs: {});
  }
}

void $registerHighFrequencyEventServiceClientFactory() {
  GeneratedClientRegistry.register<HighFrequencyEventService>(
    (proxy) => HighFrequencyEventServiceClient(proxy),
  );
}

class _HighFrequencyEventServiceMethods {
  static const int sendBurstEventsId = 1;
}

Future<dynamic> _HighFrequencyEventServiceDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as HighFrequencyEventService;
  switch (methodId) {
    case _HighFrequencyEventServiceMethods.sendBurstEventsId:
      return await s.sendBurstEvents(positionalArgs[0]);
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void $registerHighFrequencyEventServiceDispatcher() {
  GeneratedDispatcherRegistry.register<HighFrequencyEventService>(
    _HighFrequencyEventServiceDispatcher,
  );
}

void $registerHighFrequencyEventServiceMethodIds() {
  ServiceMethodIdRegistry.register<HighFrequencyEventService>({
    'sendBurstEvents': _HighFrequencyEventServiceMethods.sendBurstEventsId,
  });
}

void registerHighFrequencyEventServiceGenerated() {
  $registerHighFrequencyEventServiceClientFactory();
  $registerHighFrequencyEventServiceMethodIds();
}

// Remote service implementation that auto-registers the dispatcher
class HighFrequencyEventServiceImpl extends HighFrequencyEventService {
  @override
  bool get isRemote => true;
  @override
  Type get clientBaseType => HighFrequencyEventService;
  @override
  Future<void> registerHostSide() async {
    $registerHighFrequencyEventServiceClientFactory();
    $registerHighFrequencyEventServiceMethodIds();
  }

  @override
  Future<void> initialize() async {
    $registerHighFrequencyEventServiceDispatcher();
    await super.initialize();
  }
}

void $registerHighFrequencyEventServiceLocalSide() {
  $registerHighFrequencyEventServiceDispatcher();
  $registerHighFrequencyEventServiceClientFactory();
  $registerHighFrequencyEventServiceMethodIds();
}

void $autoRegisterHighFrequencyEventServiceLocalSide() {
  LocalSideRegistry.register<HighFrequencyEventService>(
      $registerHighFrequencyEventServiceLocalSide);
}

final $_HighFrequencyEventServiceLocalSideRegistered = (() {
  $autoRegisterHighFrequencyEventServiceLocalSide();
  return true;
})();

// Service client for MainIsolateTestListener
class MainIsolateTestListenerClient extends MainIsolateTestListener {
  MainIsolateTestListenerClient(this._proxy);
  final ServiceProxy<MainIsolateTestListener> _proxy;

  @override
  Future<Map<String, dynamic>> getPerformanceStats() async {
    return await _proxy.callMethod<Map<String, dynamic>>(
        'getPerformanceStats', [],
        namedArgs: {});
  }
}

void $registerMainIsolateTestListenerClientFactory() {
  GeneratedClientRegistry.register<MainIsolateTestListener>(
    (proxy) => MainIsolateTestListenerClient(proxy),
  );
}

class _MainIsolateTestListenerMethods {
  static const int getPerformanceStatsId = 1;
}

Future<dynamic> _MainIsolateTestListenerDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as MainIsolateTestListener;
  switch (methodId) {
    case _MainIsolateTestListenerMethods.getPerformanceStatsId:
      return await s.getPerformanceStats();
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void $registerMainIsolateTestListenerDispatcher() {
  GeneratedDispatcherRegistry.register<MainIsolateTestListener>(
    _MainIsolateTestListenerDispatcher,
  );
}

void $registerMainIsolateTestListenerMethodIds() {
  ServiceMethodIdRegistry.register<MainIsolateTestListener>({
    'getPerformanceStats':
        _MainIsolateTestListenerMethods.getPerformanceStatsId,
  });
}

void registerMainIsolateTestListenerGenerated() {
  $registerMainIsolateTestListenerClientFactory();
  $registerMainIsolateTestListenerMethodIds();
}

// Local service implementation that auto-registers local side
class MainIsolateTestListenerImpl extends MainIsolateTestListener {
  MainIsolateTestListenerImpl() {
    // 🚀 AUTO-REGISTRATION: Register local side when instance is created
    $registerMainIsolateTestListenerLocalSide();
  }
}

void $registerMainIsolateTestListenerLocalSide() {
  $registerMainIsolateTestListenerDispatcher();
  $registerMainIsolateTestListenerClientFactory();
  $registerMainIsolateTestListenerMethodIds();
}

void $autoRegisterMainIsolateTestListenerLocalSide() {
  LocalSideRegistry.register<MainIsolateTestListener>(
      $registerMainIsolateTestListenerLocalSide);
}

final $_MainIsolateTestListenerLocalSideRegistered = (() {
  $autoRegisterMainIsolateTestListenerLocalSide();
  return true;
})();

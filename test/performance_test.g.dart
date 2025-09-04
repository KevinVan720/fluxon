// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'performance_test.dart';

// **************************************************************************
// ServiceGenerator
// **************************************************************************

// Service client for PerformanceService
class PerformanceServiceClient extends PerformanceService {
  PerformanceServiceClient(this._proxy);
  final ServiceProxy<PerformanceService> _proxy;

  @override
  Future<List<String>> generateLargeDataset(int count, int stringLength) async {
    return await _proxy.callMethod(
        'generateLargeDataset', [count, stringLength],
        namedArgs: {});
  }

  @override
  Future<Map<String, int>> processEvents(int eventCount) async {
    return await _proxy
        .callMethod('processEvents', [eventCount], namedArgs: {});
  }
}

void $registerPerformanceServiceClientFactory() {
  GeneratedClientRegistry.register<PerformanceService>(
    (proxy) => PerformanceServiceClient(proxy),
  );
}

class _PerformanceServiceMethods {
  static const int generateLargeDatasetId = 1;
  static const int processEventsId = 2;
}

Future<dynamic> _PerformanceServiceDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as PerformanceService;
  switch (methodId) {
    case _PerformanceServiceMethods.generateLargeDatasetId:
      return await s.generateLargeDataset(positionalArgs[0], positionalArgs[1]);
    case _PerformanceServiceMethods.processEventsId:
      return await s.processEvents(positionalArgs[0]);
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void $registerPerformanceServiceDispatcher() {
  GeneratedDispatcherRegistry.register<PerformanceService>(
    _PerformanceServiceDispatcher,
  );
}

void $registerPerformanceServiceMethodIds() {
  ServiceMethodIdRegistry.register<PerformanceService>({
    'generateLargeDataset': _PerformanceServiceMethods.generateLargeDatasetId,
    'processEvents': _PerformanceServiceMethods.processEventsId,
  });
}

void registerPerformanceServiceGenerated() {
  $registerPerformanceServiceClientFactory();
  $registerPerformanceServiceMethodIds();
}

// Remote service implementation that auto-registers the dispatcher
class PerformanceServiceImpl extends PerformanceService {
  @override
  Type get clientBaseType => PerformanceService;
  @override
  Future<void> registerHostSide() async {
    $registerPerformanceServiceClientFactory();
    $registerPerformanceServiceMethodIds();
  }

  @override
  Future<void> initialize() async {
    $registerPerformanceServiceDispatcher();
    await super.initialize();
  }
}

void $registerPerformanceServiceLocalSide() {
  $registerPerformanceServiceDispatcher();
  $registerPerformanceServiceClientFactory();
  $registerPerformanceServiceMethodIds();
}

void $autoRegisterPerformanceServiceLocalSide() {
  LocalSideRegistry.register<PerformanceService>(
      $registerPerformanceServiceLocalSide);
}

final $_PerformanceServiceLocalSideRegistered = (() {
  $autoRegisterPerformanceServiceLocalSide();
  return true;
})();

// Service client for EventReceiverService
class EventReceiverServiceClient extends EventReceiverService {
  EventReceiverServiceClient(this._proxy);
  final ServiceProxy<EventReceiverService> _proxy;

  @override
  Future<Map<String, dynamic>> getStats() async {
    return await _proxy.callMethod('getStats', [], namedArgs: {});
  }
}

void $registerEventReceiverServiceClientFactory() {
  GeneratedClientRegistry.register<EventReceiverService>(
    (proxy) => EventReceiverServiceClient(proxy),
  );
}

class _EventReceiverServiceMethods {
  static const int getStatsId = 1;
}

Future<dynamic> _EventReceiverServiceDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as EventReceiverService;
  switch (methodId) {
    case _EventReceiverServiceMethods.getStatsId:
      return await s.getStats();
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void $registerEventReceiverServiceDispatcher() {
  GeneratedDispatcherRegistry.register<EventReceiverService>(
    _EventReceiverServiceDispatcher,
  );
}

void $registerEventReceiverServiceMethodIds() {
  ServiceMethodIdRegistry.register<EventReceiverService>({
    'getStats': _EventReceiverServiceMethods.getStatsId,
  });
}

void registerEventReceiverServiceGenerated() {
  $registerEventReceiverServiceClientFactory();
  $registerEventReceiverServiceMethodIds();
}

// Local service implementation that auto-registers local side
class EventReceiverServiceImpl extends EventReceiverService {
  EventReceiverServiceImpl() {
    // 🚀 AUTO-REGISTRATION: Register local side when instance is created
    $registerEventReceiverServiceLocalSide();
  }
}

void $registerEventReceiverServiceLocalSide() {
  $registerEventReceiverServiceDispatcher();
  $registerEventReceiverServiceClientFactory();
  $registerEventReceiverServiceMethodIds();
}

void $autoRegisterEventReceiverServiceLocalSide() {
  LocalSideRegistry.register<EventReceiverService>(
      $registerEventReceiverServiceLocalSide);
}

final $_EventReceiverServiceLocalSideRegistered = (() {
  $autoRegisterEventReceiverServiceLocalSide();
  return true;
})();

// Service client for LoadTestService
class LoadTestServiceClient extends LoadTestService {
  LoadTestServiceClient(this._proxy);
  final ServiceProxy<LoadTestService> _proxy;

  @override
  Future<void> sendBurstEvents(int count) async {
    return await _proxy.callMethod('sendBurstEvents', [count], namedArgs: {});
  }

  @override
  Future<Map<String, dynamic>> getStats() async {
    return await _proxy.callMethod('getStats', [], namedArgs: {});
  }
}

void $registerLoadTestServiceClientFactory() {
  GeneratedClientRegistry.register<LoadTestService>(
    (proxy) => LoadTestServiceClient(proxy),
  );
}

class _LoadTestServiceMethods {
  static const int sendBurstEventsId = 1;
  static const int getStatsId = 2;
}

Future<dynamic> _LoadTestServiceDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as LoadTestService;
  switch (methodId) {
    case _LoadTestServiceMethods.sendBurstEventsId:
      return await s.sendBurstEvents(positionalArgs[0]);
    case _LoadTestServiceMethods.getStatsId:
      return await s.getStats();
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void $registerLoadTestServiceDispatcher() {
  GeneratedDispatcherRegistry.register<LoadTestService>(
    _LoadTestServiceDispatcher,
  );
}

void $registerLoadTestServiceMethodIds() {
  ServiceMethodIdRegistry.register<LoadTestService>({
    'sendBurstEvents': _LoadTestServiceMethods.sendBurstEventsId,
    'getStats': _LoadTestServiceMethods.getStatsId,
  });
}

void registerLoadTestServiceGenerated() {
  $registerLoadTestServiceClientFactory();
  $registerLoadTestServiceMethodIds();
}

// Local service implementation that auto-registers local side
class LoadTestServiceImpl extends LoadTestService {
  LoadTestServiceImpl() {
    // 🚀 AUTO-REGISTRATION: Register local side when instance is created
    $registerLoadTestServiceLocalSide();
  }
}

void $registerLoadTestServiceLocalSide() {
  $registerLoadTestServiceDispatcher();
  $registerLoadTestServiceClientFactory();
  $registerLoadTestServiceMethodIds();
}

void $autoRegisterLoadTestServiceLocalSide() {
  LocalSideRegistry.register<LoadTestService>(
      $registerLoadTestServiceLocalSide);
}

final $_LoadTestServiceLocalSideRegistered = (() {
  $autoRegisterLoadTestServiceLocalSide();
  return true;
})();

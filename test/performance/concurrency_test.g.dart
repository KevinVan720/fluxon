// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'concurrency_test.dart';

// **************************************************************************
// ServiceGenerator
// **************************************************************************

// Service client for ConcurrentService
class ConcurrentServiceClient extends ConcurrentService {
  ConcurrentServiceClient(this._proxy);
  final ServiceProxy<ConcurrentService> _proxy;

  @override
  Future<int> incrementCounter() async {
    return await _proxy.callMethod('incrementCounter', [], namedArgs: {});
  }

  @override
  Future<String> performOperation(String operationName) async {
    return await _proxy
        .callMethod('performOperation', [operationName], namedArgs: {});
  }

  @override
  Future<Map<String, dynamic>> getState() async {
    return await _proxy.callMethod('getState', [], namedArgs: {});
  }

  @override
  Future<void> reset() async {
    return await _proxy.callMethod('reset', [], namedArgs: {});
  }
}

void $registerConcurrentServiceClientFactory() {
  GeneratedClientRegistry.register<ConcurrentService>(
    (proxy) => ConcurrentServiceClient(proxy),
  );
}

class _ConcurrentServiceMethods {
  static const int incrementCounterId = 1;
  static const int performOperationId = 2;
  static const int getStateId = 3;
  static const int resetId = 4;
}

Future<dynamic> _ConcurrentServiceDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as ConcurrentService;
  switch (methodId) {
    case _ConcurrentServiceMethods.incrementCounterId:
      return await s.incrementCounter();
    case _ConcurrentServiceMethods.performOperationId:
      return await s.performOperation(positionalArgs[0]);
    case _ConcurrentServiceMethods.getStateId:
      return await s.getState();
    case _ConcurrentServiceMethods.resetId:
      return await s.reset();
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void $registerConcurrentServiceDispatcher() {
  GeneratedDispatcherRegistry.register<ConcurrentService>(
    _ConcurrentServiceDispatcher,
  );
}

void $registerConcurrentServiceMethodIds() {
  ServiceMethodIdRegistry.register<ConcurrentService>({
    'incrementCounter': _ConcurrentServiceMethods.incrementCounterId,
    'performOperation': _ConcurrentServiceMethods.performOperationId,
    'getState': _ConcurrentServiceMethods.getStateId,
    'reset': _ConcurrentServiceMethods.resetId,
  });
}

void registerConcurrentServiceGenerated() {
  $registerConcurrentServiceClientFactory();
  $registerConcurrentServiceMethodIds();
}

// Remote service implementation that auto-registers the dispatcher
class ConcurrentServiceImpl extends ConcurrentService {
  @override
  Type get clientBaseType => ConcurrentService;
  @override
  Future<void> registerHostSide() async {
    $registerConcurrentServiceClientFactory();
    $registerConcurrentServiceMethodIds();
  }

  @override
  Future<void> initialize() async {
    $registerConcurrentServiceDispatcher();
    await super.initialize();
  }
}

void $registerConcurrentServiceLocalSide() {
  $registerConcurrentServiceDispatcher();
  $registerConcurrentServiceClientFactory();
  $registerConcurrentServiceMethodIds();
}

void $autoRegisterConcurrentServiceLocalSide() {
  LocalSideRegistry.register<ConcurrentService>(
      $registerConcurrentServiceLocalSide);
}

final $_ConcurrentServiceLocalSideRegistered = (() {
  $autoRegisterConcurrentServiceLocalSide();
  return true;
})();

// Service client for RaceConditionService
class RaceConditionServiceClient extends RaceConditionService {
  RaceConditionServiceClient(this._proxy);
  final ServiceProxy<RaceConditionService> _proxy;

  @override
  Future<void> triggerRaceCondition(
      int threadCount, int operationsPerThread) async {
    return await _proxy.callMethod(
        'triggerRaceCondition', [threadCount, operationsPerThread],
        namedArgs: {});
  }

  @override
  Future<Map<String, dynamic>> getRaceResults() async {
    return await _proxy.callMethod('getRaceResults', [], namedArgs: {});
  }
}

void $registerRaceConditionServiceClientFactory() {
  GeneratedClientRegistry.register<RaceConditionService>(
    (proxy) => RaceConditionServiceClient(proxy),
  );
}

class _RaceConditionServiceMethods {
  static const int triggerRaceConditionId = 1;
  static const int getRaceResultsId = 2;
}

Future<dynamic> _RaceConditionServiceDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as RaceConditionService;
  switch (methodId) {
    case _RaceConditionServiceMethods.triggerRaceConditionId:
      return await s.triggerRaceCondition(positionalArgs[0], positionalArgs[1]);
    case _RaceConditionServiceMethods.getRaceResultsId:
      return await s.getRaceResults();
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void $registerRaceConditionServiceDispatcher() {
  GeneratedDispatcherRegistry.register<RaceConditionService>(
    _RaceConditionServiceDispatcher,
  );
}

void $registerRaceConditionServiceMethodIds() {
  ServiceMethodIdRegistry.register<RaceConditionService>({
    'triggerRaceCondition': _RaceConditionServiceMethods.triggerRaceConditionId,
    'getRaceResults': _RaceConditionServiceMethods.getRaceResultsId,
  });
}

void registerRaceConditionServiceGenerated() {
  $registerRaceConditionServiceClientFactory();
  $registerRaceConditionServiceMethodIds();
}

// Local service implementation that auto-registers local side
class RaceConditionServiceImpl extends RaceConditionService {
  RaceConditionServiceImpl() {
    // 🚀 AUTO-REGISTRATION: Register local side when instance is created
    $registerRaceConditionServiceLocalSide();
  }
}

void $registerRaceConditionServiceLocalSide() {
  $registerRaceConditionServiceDispatcher();
  $registerRaceConditionServiceClientFactory();
  $registerRaceConditionServiceMethodIds();
}

void $autoRegisterRaceConditionServiceLocalSide() {
  LocalSideRegistry.register<RaceConditionService>(
      $registerRaceConditionServiceLocalSide);
}

final $_RaceConditionServiceLocalSideRegistered = (() {
  $autoRegisterRaceConditionServiceLocalSide();
  return true;
})();

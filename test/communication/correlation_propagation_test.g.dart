// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'correlation_propagation_test.dart';

// **************************************************************************
// ServiceGenerator
// **************************************************************************

// Service client for CorrWorker
class CorrWorkerClient extends CorrWorker {
  CorrWorkerClient(this._proxy);
  final ServiceProxy<CorrWorker> _proxy;

  @override
  Future<void> bump(String corr) async {
    await _proxy.callMethod('bump', [corr], namedArgs: {});
  }
}

void $registerCorrWorkerClientFactory() {
  GeneratedClientRegistry.register<CorrWorker>(
    (proxy) => CorrWorkerClient(proxy),
  );
}

class _CorrWorkerMethods {
  static const int bumpId = 1;
}

Future<dynamic> _CorrWorkerDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as CorrWorker;
  switch (methodId) {
    case _CorrWorkerMethods.bumpId:
      return await s.bump(positionalArgs[0]);
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void $registerCorrWorkerDispatcher() {
  GeneratedDispatcherRegistry.register<CorrWorker>(
    _CorrWorkerDispatcher,
  );
}

void $registerCorrWorkerMethodIds() {
  ServiceMethodIdRegistry.register<CorrWorker>({
    'bump': _CorrWorkerMethods.bumpId,
  });
}

void registerCorrWorkerGenerated() {
  $registerCorrWorkerClientFactory();
  $registerCorrWorkerMethodIds();
}

// Remote service implementation that auto-registers the dispatcher
class CorrWorkerImpl extends CorrWorker {
  @override
  bool get isRemote => true;
  @override
  Type get clientBaseType => CorrWorker;
  @override
  Future<void> registerHostSide() async {
    $registerCorrWorkerClientFactory();
    $registerCorrWorkerMethodIds();
  }

  @override
  Future<void> initialize() async {
    $registerCorrWorkerDispatcher();
    await super.initialize();
  }
}

void $registerCorrWorkerLocalSide() {
  $registerCorrWorkerDispatcher();
  $registerCorrWorkerClientFactory();
  $registerCorrWorkerMethodIds();
}

void $autoRegisterCorrWorkerLocalSide() {
  LocalSideRegistry.register<CorrWorker>($registerCorrWorkerLocalSide);
}

final $_CorrWorkerLocalSideRegistered = (() {
  $autoRegisterCorrWorkerLocalSide();
  return true;
})();

// Service client for CorrOrchestrator
class CorrOrchestratorClient extends CorrOrchestrator {
  CorrOrchestratorClient(this._proxy);
  final ServiceProxy<CorrOrchestrator> _proxy;

  @override
  Future<void> start(String corr) async {
    await _proxy.callMethod('start', [corr], namedArgs: {});
  }
}

void $registerCorrOrchestratorClientFactory() {
  GeneratedClientRegistry.register<CorrOrchestrator>(
    (proxy) => CorrOrchestratorClient(proxy),
  );
}

class _CorrOrchestratorMethods {
  static const int startId = 1;
}

Future<dynamic> _CorrOrchestratorDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as CorrOrchestrator;
  switch (methodId) {
    case _CorrOrchestratorMethods.startId:
      return await s.start(positionalArgs[0]);
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void $registerCorrOrchestratorDispatcher() {
  GeneratedDispatcherRegistry.register<CorrOrchestrator>(
    _CorrOrchestratorDispatcher,
  );
}

void $registerCorrOrchestratorMethodIds() {
  ServiceMethodIdRegistry.register<CorrOrchestrator>({
    'start': _CorrOrchestratorMethods.startId,
  });
}

void registerCorrOrchestratorGenerated() {
  $registerCorrOrchestratorClientFactory();
  $registerCorrOrchestratorMethodIds();
}

// Local service implementation that auto-registers local side
class CorrOrchestratorImpl extends CorrOrchestrator {
  CorrOrchestratorImpl() {
    // 🚀 AUTO-REGISTRATION: Register local side when instance is created
    $registerCorrOrchestratorLocalSide();
  }
}

void $registerCorrOrchestratorLocalSide() {
  $registerCorrOrchestratorDispatcher();
  $registerCorrOrchestratorClientFactory();
  $registerCorrOrchestratorMethodIds();
}

void $autoRegisterCorrOrchestratorLocalSide() {
  LocalSideRegistry.register<CorrOrchestrator>(
      $registerCorrOrchestratorLocalSide);
}

final $_CorrOrchestratorLocalSideRegistered = (() {
  $autoRegisterCorrOrchestratorLocalSide();
  return true;
})();

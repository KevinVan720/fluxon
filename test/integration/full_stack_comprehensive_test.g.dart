// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'full_stack_comprehensive_test.dart';

// **************************************************************************
// ServiceGenerator
// **************************************************************************

// Service client for OrchestratorService
class OrchestratorServiceClient extends OrchestratorService {
  OrchestratorServiceClient(this._proxy);
  final ServiceProxy<OrchestratorService> _proxy;

  @override
  Future<int> orchestrateComputation(int x) async {
    return await _proxy
        .callMethod('orchestrateComputation', [x], namedArgs: {});
  }
}

void $registerOrchestratorServiceClientFactory() {
  GeneratedClientRegistry.register<OrchestratorService>(
    (proxy) => OrchestratorServiceClient(proxy),
  );
}

class _OrchestratorServiceMethods {
  static const int orchestrateComputationId = 1;
}

Future<dynamic> _OrchestratorServiceDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as OrchestratorService;
  switch (methodId) {
    case _OrchestratorServiceMethods.orchestrateComputationId:
      return await s.orchestrateComputation(positionalArgs[0]);
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void $registerOrchestratorServiceDispatcher() {
  GeneratedDispatcherRegistry.register<OrchestratorService>(
    _OrchestratorServiceDispatcher,
  );
}

void $registerOrchestratorServiceMethodIds() {
  ServiceMethodIdRegistry.register<OrchestratorService>({
    'orchestrateComputation':
        _OrchestratorServiceMethods.orchestrateComputationId,
  });
}

void registerOrchestratorServiceGenerated() {
  $registerOrchestratorServiceClientFactory();
  $registerOrchestratorServiceMethodIds();
}

// Local service implementation that auto-registers local side
class OrchestratorServiceImpl extends OrchestratorService {
  OrchestratorServiceImpl() {
    // 🚀 AUTO-REGISTRATION: Register local side when instance is created
    $registerOrchestratorServiceLocalSide();
  }
}

void $registerOrchestratorServiceLocalSide() {
  $registerOrchestratorServiceDispatcher();
  $registerOrchestratorServiceClientFactory();
  $registerOrchestratorServiceMethodIds();
  try {
    $registerComputeWorkerClientFactory();
  } catch (_) {}
  try {
    $registerComputeWorkerMethodIds();
  } catch (_) {}
  try {
    $registerStorageWorkerClientFactory();
  } catch (_) {}
  try {
    $registerStorageWorkerMethodIds();
  } catch (_) {}
}

void $autoRegisterOrchestratorServiceLocalSide() {
  LocalSideRegistry.register<OrchestratorService>(
      $registerOrchestratorServiceLocalSide);
}

final $_OrchestratorServiceLocalSideRegistered = (() {
  $autoRegisterOrchestratorServiceLocalSide();
  return true;
})();

// Service client for ComputeWorker
class ComputeWorkerClient extends ComputeWorker {
  ComputeWorkerClient(this._proxy);
  final ServiceProxy<ComputeWorker> _proxy;

  @override
  Future<int> complexCompute(int x) async {
    return await _proxy.callMethod('complexCompute', [x], namedArgs: {});
  }
}

void $registerComputeWorkerClientFactory() {
  GeneratedClientRegistry.register<ComputeWorker>(
    (proxy) => ComputeWorkerClient(proxy),
  );
}

class _ComputeWorkerMethods {
  static const int complexComputeId = 1;
}

Future<dynamic> _ComputeWorkerDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as ComputeWorker;
  switch (methodId) {
    case _ComputeWorkerMethods.complexComputeId:
      return await s.complexCompute(positionalArgs[0]);
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void $registerComputeWorkerDispatcher() {
  GeneratedDispatcherRegistry.register<ComputeWorker>(
    _ComputeWorkerDispatcher,
  );
}

void $registerComputeWorkerMethodIds() {
  ServiceMethodIdRegistry.register<ComputeWorker>({
    'complexCompute': _ComputeWorkerMethods.complexComputeId,
  });
}

void registerComputeWorkerGenerated() {
  $registerComputeWorkerClientFactory();
  $registerComputeWorkerMethodIds();
}

// Remote service implementation that auto-registers the dispatcher
class ComputeWorkerImpl extends ComputeWorker {
  @override
  bool get isRemote => true;
  @override
  Type get clientBaseType => ComputeWorker;
  @override
  Future<void> registerHostSide() async {
    $registerComputeWorkerClientFactory();
    $registerComputeWorkerMethodIds();
    // Auto-registered from dependencies/optionalDependencies
    try {
      $registerStorageWorkerClientFactory();
    } catch (_) {}
    try {
      $registerStorageWorkerMethodIds();
    } catch (_) {}
  }

  @override
  Future<void> initialize() async {
    $registerComputeWorkerDispatcher();
    // Ensure worker isolate can create clients for dependencies
    try {
      $registerStorageWorkerClientFactory();
    } catch (_) {}
    try {
      $registerStorageWorkerMethodIds();
    } catch (_) {}
    await super.initialize();
  }
}

void $registerComputeWorkerLocalSide() {
  $registerComputeWorkerDispatcher();
  $registerComputeWorkerClientFactory();
  $registerComputeWorkerMethodIds();
  try {
    $registerStorageWorkerClientFactory();
  } catch (_) {}
  try {
    $registerStorageWorkerMethodIds();
  } catch (_) {}
}

void $autoRegisterComputeWorkerLocalSide() {
  LocalSideRegistry.register<ComputeWorker>($registerComputeWorkerLocalSide);
}

final $_ComputeWorkerLocalSideRegistered = (() {
  $autoRegisterComputeWorkerLocalSide();
  return true;
})();

// Service client for StorageWorker
class StorageWorkerClient extends StorageWorker {
  StorageWorkerClient(this._proxy);
  final ServiceProxy<StorageWorker> _proxy;

  @override
  Future<void> store(String key, Object? value) async {
    return await _proxy.callMethod('store', [key, value], namedArgs: {});
  }

  @override
  Future<int?> get(String key) async {
    return await _proxy.callMethod('get', [key], namedArgs: {});
  }
}

void $registerStorageWorkerClientFactory() {
  GeneratedClientRegistry.register<StorageWorker>(
    (proxy) => StorageWorkerClient(proxy),
  );
}

class _StorageWorkerMethods {
  static const int storeId = 1;
  static const int getId = 2;
}

Future<dynamic> _StorageWorkerDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as StorageWorker;
  switch (methodId) {
    case _StorageWorkerMethods.storeId:
      return await s.store(positionalArgs[0], positionalArgs[1]);
    case _StorageWorkerMethods.getId:
      return await s.get(positionalArgs[0]);
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void $registerStorageWorkerDispatcher() {
  GeneratedDispatcherRegistry.register<StorageWorker>(
    _StorageWorkerDispatcher,
  );
}

void $registerStorageWorkerMethodIds() {
  ServiceMethodIdRegistry.register<StorageWorker>({
    'store': _StorageWorkerMethods.storeId,
    'get': _StorageWorkerMethods.getId,
  });
}

void registerStorageWorkerGenerated() {
  $registerStorageWorkerClientFactory();
  $registerStorageWorkerMethodIds();
}

// Remote service implementation that auto-registers the dispatcher
class StorageWorkerImpl extends StorageWorker {
  @override
  bool get isRemote => true;
  @override
  Type get clientBaseType => StorageWorker;
  @override
  Future<void> registerHostSide() async {
    $registerStorageWorkerClientFactory();
    $registerStorageWorkerMethodIds();
  }

  @override
  Future<void> initialize() async {
    $registerStorageWorkerDispatcher();
    await super.initialize();
  }
}

void $registerStorageWorkerLocalSide() {
  $registerStorageWorkerDispatcher();
  $registerStorageWorkerClientFactory();
  $registerStorageWorkerMethodIds();
}

void $autoRegisterStorageWorkerLocalSide() {
  LocalSideRegistry.register<StorageWorker>($registerStorageWorkerLocalSide);
}

final $_StorageWorkerLocalSideRegistered = (() {
  $autoRegisterStorageWorkerLocalSide();
  return true;
})();

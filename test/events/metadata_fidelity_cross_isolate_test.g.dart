// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'metadata_fidelity_cross_isolate_test.dart';

// **************************************************************************
// ServiceGenerator
// **************************************************************************

// Service client for MetaWorker
class MetaWorkerClient extends MetaWorker {
  MetaWorkerClient(this._proxy);
  final ServiceProxy<MetaWorker> _proxy;

  @override
  Future<Map<String, dynamic>?> getLast() async {
    return await _proxy
        .callMethod<Map<String, dynamic>?>('getLast', [], namedArgs: {});
  }
}

void $registerMetaWorkerClientFactory() {
  GeneratedClientRegistry.register<MetaWorker>(
    (proxy) => MetaWorkerClient(proxy),
  );
}

class _MetaWorkerMethods {
  static const int getLastId = 1;
}

Future<dynamic> _MetaWorkerDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as MetaWorker;
  switch (methodId) {
    case _MetaWorkerMethods.getLastId:
      return await s.getLast();
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void $registerMetaWorkerDispatcher() {
  GeneratedDispatcherRegistry.register<MetaWorker>(
    _MetaWorkerDispatcher,
  );
}

void $registerMetaWorkerMethodIds() {
  ServiceMethodIdRegistry.register<MetaWorker>({
    'getLast': _MetaWorkerMethods.getLastId,
  });
}

void registerMetaWorkerGenerated() {
  $registerMetaWorkerClientFactory();
  $registerMetaWorkerMethodIds();
}

// Remote service implementation that auto-registers the dispatcher
class MetaWorkerImpl extends MetaWorker {
  @override
  bool get isRemote => true;
  @override
  Type get clientBaseType => MetaWorker;
  @override
  Future<void> registerHostSide() async {
    $registerMetaWorkerClientFactory();
    $registerMetaWorkerMethodIds();
  }

  @override
  Future<void> initialize() async {
    $registerMetaWorkerDispatcher();
    await super.initialize();
  }
}

void $registerMetaWorkerLocalSide() {
  $registerMetaWorkerDispatcher();
  $registerMetaWorkerClientFactory();
  $registerMetaWorkerMethodIds();
}

void $autoRegisterMetaWorkerLocalSide() {
  LocalSideRegistry.register<MetaWorker>($registerMetaWorkerLocalSide);
}

final $_MetaWorkerLocalSideRegistered = (() {
  $autoRegisterMetaWorkerLocalSide();
  return true;
})();

// Service client for MetaHost
class MetaHostClient extends MetaHost {
  MetaHostClient(this._proxy);
  final ServiceProxy<MetaHost> _proxy;

  @override
  Future<void> sendWithMeta(Map<String, dynamic> meta) async {
    await _proxy.callMethod<void>('sendWithMeta', [meta], namedArgs: {});
  }
}

void $registerMetaHostClientFactory() {
  GeneratedClientRegistry.register<MetaHost>(
    (proxy) => MetaHostClient(proxy),
  );
}

class _MetaHostMethods {
  static const int sendWithMetaId = 1;
}

Future<dynamic> _MetaHostDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as MetaHost;
  switch (methodId) {
    case _MetaHostMethods.sendWithMetaId:
      return await s.sendWithMeta(positionalArgs[0]);
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void $registerMetaHostDispatcher() {
  GeneratedDispatcherRegistry.register<MetaHost>(
    _MetaHostDispatcher,
  );
}

void $registerMetaHostMethodIds() {
  ServiceMethodIdRegistry.register<MetaHost>({
    'sendWithMeta': _MetaHostMethods.sendWithMetaId,
  });
}

void registerMetaHostGenerated() {
  $registerMetaHostClientFactory();
  $registerMetaHostMethodIds();
}

// Local service implementation that auto-registers local side
class MetaHostImpl extends MetaHost {
  MetaHostImpl() {
    // 🚀 AUTO-REGISTRATION: Register local side when instance is created
    $registerMetaHostLocalSide();
  }
}

void $registerMetaHostLocalSide() {
  $registerMetaHostDispatcher();
  $registerMetaHostClientFactory();
  $registerMetaHostMethodIds();
}

void $autoRegisterMetaHostLocalSide() {
  LocalSideRegistry.register<MetaHost>($registerMetaHostLocalSide);
}

final $_MetaHostLocalSideRegistered = (() {
  $autoRegisterMetaHostLocalSide();
  return true;
})();

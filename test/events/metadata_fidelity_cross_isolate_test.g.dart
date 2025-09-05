// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'metadata_fidelity_cross_isolate_test.dart';

// **************************************************************************
// ServiceGenerator (handwritten for test)
// **************************************************************************

// Service client for MetaWorker
class MetaWorkerClient extends MetaWorker {
  MetaWorkerClient(this._proxy);
  final ServiceProxy<MetaWorker> _proxy;

  @override
  Future<Map<String, dynamic>?> getLast() async {
    return await _proxy.callMethod('getLast', [], namedArgs: {});
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

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reregister_after_destroy_test.dart';

// **************************************************************************
// ServiceGenerator (handwritten for test)
// **************************************************************************

// Service client for SimpleWorker
class SimpleWorkerClient extends SimpleWorker {
  SimpleWorkerClient(this._proxy);
  final ServiceProxy<SimpleWorker> _proxy;

  @override
  Future<int> add(int a, int b) async {
    return await _proxy.callMethod('add', [a, b], namedArgs: {});
  }
}

void $registerSimpleWorkerClientFactory() {
  GeneratedClientRegistry.register<SimpleWorker>(
    (proxy) => SimpleWorkerClient(proxy),
  );
}

class _SimpleWorkerMethods {
  static const int addId = 1;
}

Future<dynamic> _SimpleWorkerDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as SimpleWorker;
  switch (methodId) {
    case _SimpleWorkerMethods.addId:
      return await s.add(positionalArgs[0], positionalArgs[1]);
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void $registerSimpleWorkerDispatcher() {
  GeneratedDispatcherRegistry.register<SimpleWorker>(
    _SimpleWorkerDispatcher,
  );
}

void $registerSimpleWorkerMethodIds() {
  ServiceMethodIdRegistry.register<SimpleWorker>({
    'add': _SimpleWorkerMethods.addId,
  });
}

void registerSimpleWorkerGenerated() {
  $registerSimpleWorkerClientFactory();
  $registerSimpleWorkerMethodIds();
}

class SimpleWorkerImpl extends SimpleWorker {
  @override
  bool get isRemote => true;
  @override
  Type get clientBaseType => SimpleWorker;
  @override
  Future<void> registerHostSide() async {
    $registerSimpleWorkerClientFactory();
    $registerSimpleWorkerMethodIds();
  }

  @override
  Future<void> initialize() async {
    $registerSimpleWorkerDispatcher();
    await super.initialize();
  }
}

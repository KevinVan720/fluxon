// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'correlation_propagation_test.dart';

// **************************************************************************
// ServiceGenerator (handwritten for test)
// **************************************************************************

// Service client for CorrWorker
class CorrWorkerClient extends CorrWorker {
  CorrWorkerClient(this._proxy);
  final ServiceProxy<CorrWorker> _proxy;

  @override
  Future<void> bump(String corr) async {
    return await _proxy.callMethod('bump', [corr], namedArgs: {});
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

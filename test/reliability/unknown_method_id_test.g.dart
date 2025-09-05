// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unknown_method_id_test.dart';

// **************************************************************************
// ServiceGenerator (handwritten for test)
// **************************************************************************

// Service client for IdMissingService
class IdMissingServiceClient extends IdMissingService {
  IdMissingServiceClient(this._proxy);
  final ServiceProxy<IdMissingService> _proxy;

  @override
  Future<String> doWork(String x) async {
    return await _proxy.callMethod('doWork', [x], namedArgs: {});
  }
}

void $registerIdMissingServiceClientFactory() {
  GeneratedClientRegistry.register<IdMissingService>(
    (proxy) => IdMissingServiceClient(proxy),
  );
}

// Intentionally DO NOT register method ids to simulate missing id

Future<dynamic> _IdMissingServiceDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as IdMissingService;
  // We still dispatch by id operationally; only 'doWork' is known as 1
  switch (methodId) {
    case 1:
      return await s.doWork(positionalArgs[0]);
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void $registerIdMissingServiceDispatcher() {
  GeneratedDispatcherRegistry.register<IdMissingService>(
    _IdMissingServiceDispatcher,
  );
}

class IdMissingServiceImpl extends IdMissingService {
  @override
  bool get isRemote => true;
  @override
  Type get clientBaseType => IdMissingService;
  @override
  Future<void> registerHostSide() async {
    $registerIdMissingServiceClientFactory();
    // Note: no method id registration on purpose
  }

  @override
  Future<void> initialize() async {
    $registerIdMissingServiceDispatcher();
    await super.initialize();
  }
}

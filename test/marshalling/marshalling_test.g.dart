// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'marshalling_test.dart';

// **************************************************************************
// ServiceGenerator
// **************************************************************************

// Service client for MarshallingTestService
class MarshallingTestServiceClient extends MarshallingTestService {
  MarshallingTestServiceClient(this._proxy);
  final ServiceProxy<MarshallingTestService> _proxy;

  @override
  Future<CustomData> processData(CustomData input) async {
    return await _proxy.callMethod('processData', [input], namedArgs: {});
  }

  @override
  Future<List<CustomData>> processDataList(List<CustomData> inputs) async {
    return await _proxy.callMethod('processDataList', [inputs], namedArgs: {});
  }

  @override
  Future<Map<String, List<CustomData>>> getNestedData(String key) async {
    return await _proxy.callMethod('getNestedData', [key], namedArgs: {});
  }
}

void $registerMarshallingTestServiceClientFactory() {
  GeneratedClientRegistry.register<MarshallingTestService>(
    (proxy) => MarshallingTestServiceClient(proxy),
  );
}

class _MarshallingTestServiceMethods {
  static const int processDataId = 1;
  static const int processDataListId = 2;
  static const int getNestedDataId = 3;
}

Future<dynamic> _MarshallingTestServiceDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as MarshallingTestService;
  switch (methodId) {
    case _MarshallingTestServiceMethods.processDataId:
      return await s.processData(positionalArgs[0]);
    case _MarshallingTestServiceMethods.processDataListId:
      return await s.processDataList(positionalArgs[0]);
    case _MarshallingTestServiceMethods.getNestedDataId:
      return await s.getNestedData(positionalArgs[0]);
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void $registerMarshallingTestServiceDispatcher() {
  GeneratedDispatcherRegistry.register<MarshallingTestService>(
    _MarshallingTestServiceDispatcher,
  );
}

void $registerMarshallingTestServiceMethodIds() {
  ServiceMethodIdRegistry.register<MarshallingTestService>({
    'processData': _MarshallingTestServiceMethods.processDataId,
    'processDataList': _MarshallingTestServiceMethods.processDataListId,
    'getNestedData': _MarshallingTestServiceMethods.getNestedDataId,
  });
}

void registerMarshallingTestServiceGenerated() {
  $registerMarshallingTestServiceClientFactory();
  $registerMarshallingTestServiceMethodIds();
}

// Remote service implementation that auto-registers the dispatcher
class MarshallingTestServiceImpl extends MarshallingTestService {
  @override
  bool get isRemote => true;
  @override
  Type get clientBaseType => MarshallingTestService;
  @override
  Future<void> registerHostSide() async {
    $registerMarshallingTestServiceClientFactory();
    $registerMarshallingTestServiceMethodIds();
  }

  @override
  Future<void> initialize() async {
    $registerMarshallingTestServiceDispatcher();
    await super.initialize();
  }
}

void $registerMarshallingTestServiceLocalSide() {
  $registerMarshallingTestServiceDispatcher();
  $registerMarshallingTestServiceClientFactory();
  $registerMarshallingTestServiceMethodIds();
}

void $autoRegisterMarshallingTestServiceLocalSide() {
  LocalSideRegistry.register<MarshallingTestService>(
      $registerMarshallingTestServiceLocalSide);
}

final $_MarshallingTestServiceLocalSideRegistered = (() {
  $autoRegisterMarshallingTestServiceLocalSide();
  return true;
})();

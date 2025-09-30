// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'serialization_optimization_test.dart';

// **************************************************************************
// ServiceGenerator
// **************************************************************************

// Service client for SerializationTestService
class SerializationTestServiceClient extends SerializationTestService {
  SerializationTestServiceClient(this._proxy);
  final ServiceProxy<SerializationTestService> _proxy;

  @override
  Future<void> sendTestEvents(int count,
      {bool measureSerialization = false}) async {
    await _proxy.callMethod<void>('sendTestEvents', [count],
        namedArgs: {'measureSerialization': measureSerialization});
  }

  @override
  Future<Map<String, dynamic>> getSerializationStats() async {
    return await _proxy.callMethod<Map<String, dynamic>>(
        'getSerializationStats', [],
        namedArgs: {});
  }
}

void $registerSerializationTestServiceClientFactory() {
  GeneratedClientRegistry.register<SerializationTestService>(
    (proxy) => SerializationTestServiceClient(proxy),
  );
}

class _SerializationTestServiceMethods {
  static const int sendTestEventsId = 1;
  static const int getSerializationStatsId = 2;
}

Future<dynamic> _SerializationTestServiceDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as SerializationTestService;
  switch (methodId) {
    case _SerializationTestServiceMethods.sendTestEventsId:
      return await s.sendTestEvents(positionalArgs[0],
          measureSerialization: namedArgs['measureSerialization']);
    case _SerializationTestServiceMethods.getSerializationStatsId:
      return await s.getSerializationStats();
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void $registerSerializationTestServiceDispatcher() {
  GeneratedDispatcherRegistry.register<SerializationTestService>(
    _SerializationTestServiceDispatcher,
  );
}

void $registerSerializationTestServiceMethodIds() {
  ServiceMethodIdRegistry.register<SerializationTestService>({
    'sendTestEvents': _SerializationTestServiceMethods.sendTestEventsId,
    'getSerializationStats':
        _SerializationTestServiceMethods.getSerializationStatsId,
  });
}

void registerSerializationTestServiceGenerated() {
  $registerSerializationTestServiceClientFactory();
  $registerSerializationTestServiceMethodIds();
}

// Remote service implementation that auto-registers the dispatcher
class SerializationTestServiceImpl extends SerializationTestService {
  @override
  bool get isRemote => true;
  @override
  Type get clientBaseType => SerializationTestService;
  @override
  Future<void> registerHostSide() async {
    $registerSerializationTestServiceClientFactory();
    $registerSerializationTestServiceMethodIds();
  }

  @override
  Future<void> initialize() async {
    $registerSerializationTestServiceDispatcher();
    await super.initialize();
  }
}

void $registerSerializationTestServiceLocalSide() {
  $registerSerializationTestServiceDispatcher();
  $registerSerializationTestServiceClientFactory();
  $registerSerializationTestServiceMethodIds();
}

void $autoRegisterSerializationTestServiceLocalSide() {
  LocalSideRegistry.register<SerializationTestService>(
      $registerSerializationTestServiceLocalSide);
}

final $_SerializationTestServiceLocalSideRegistered = (() {
  $autoRegisterSerializationTestServiceLocalSide();
  return true;
})();

// Service client for SerializationTestListener
class SerializationTestListenerClient extends SerializationTestListener {
  SerializationTestListenerClient(this._proxy);
  final ServiceProxy<SerializationTestListener> _proxy;

  @override
  Future<Map<String, dynamic>> getProcessingStats() async {
    return await _proxy.callMethod<Map<String, dynamic>>(
        'getProcessingStats', [],
        namedArgs: {});
  }
}

void $registerSerializationTestListenerClientFactory() {
  GeneratedClientRegistry.register<SerializationTestListener>(
    (proxy) => SerializationTestListenerClient(proxy),
  );
}

class _SerializationTestListenerMethods {
  static const int getProcessingStatsId = 1;
}

Future<dynamic> _SerializationTestListenerDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as SerializationTestListener;
  switch (methodId) {
    case _SerializationTestListenerMethods.getProcessingStatsId:
      return await s.getProcessingStats();
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void $registerSerializationTestListenerDispatcher() {
  GeneratedDispatcherRegistry.register<SerializationTestListener>(
    _SerializationTestListenerDispatcher,
  );
}

void $registerSerializationTestListenerMethodIds() {
  ServiceMethodIdRegistry.register<SerializationTestListener>({
    'getProcessingStats':
        _SerializationTestListenerMethods.getProcessingStatsId,
  });
}

void registerSerializationTestListenerGenerated() {
  $registerSerializationTestListenerClientFactory();
  $registerSerializationTestListenerMethodIds();
}

// Local service implementation that auto-registers local side
class SerializationTestListenerImpl extends SerializationTestListener {
  SerializationTestListenerImpl() {
    // 🚀 AUTO-REGISTRATION: Register local side when instance is created
    $registerSerializationTestListenerLocalSide();
  }
}

void $registerSerializationTestListenerLocalSide() {
  $registerSerializationTestListenerDispatcher();
  $registerSerializationTestListenerClientFactory();
  $registerSerializationTestListenerMethodIds();
}

void $autoRegisterSerializationTestListenerLocalSide() {
  LocalSideRegistry.register<SerializationTestListener>(
      $registerSerializationTestListenerLocalSide);
}

final $_SerializationTestListenerLocalSideRegistered = (() {
  $autoRegisterSerializationTestListenerLocalSide();
  return true;
})();

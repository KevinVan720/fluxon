// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'large_nested_payload_test.dart';

// **************************************************************************
// ServiceGenerator
// **************************************************************************

// Service client for PayloadService
class PayloadServiceClient extends PayloadService {
  PayloadServiceClient(this._proxy);
  final ServiceProxy<PayloadService> _proxy;

  @override
  Future<Map<String, dynamic>> getBigPayload(int depth, int breadth) async {
    return await _proxy
        .callMethod('getBigPayload', [depth, breadth], namedArgs: {});
  }
}

void $registerPayloadServiceClientFactory() {
  GeneratedClientRegistry.register<PayloadService>(
    (proxy) => PayloadServiceClient(proxy),
  );
}

class _PayloadServiceMethods {
  static const int getBigPayloadId = 1;
}

Future<dynamic> _PayloadServiceDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as PayloadService;
  switch (methodId) {
    case _PayloadServiceMethods.getBigPayloadId:
      return await s.getBigPayload(positionalArgs[0], positionalArgs[1]);
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void $registerPayloadServiceDispatcher() {
  GeneratedDispatcherRegistry.register<PayloadService>(
    _PayloadServiceDispatcher,
  );
}

void $registerPayloadServiceMethodIds() {
  ServiceMethodIdRegistry.register<PayloadService>({
    'getBigPayload': _PayloadServiceMethods.getBigPayloadId,
  });
}

void registerPayloadServiceGenerated() {
  $registerPayloadServiceClientFactory();
  $registerPayloadServiceMethodIds();
}

// Remote service implementation that auto-registers the dispatcher
class PayloadServiceImpl extends PayloadService {
  @override
  bool get isRemote => true;
  @override
  Type get clientBaseType => PayloadService;
  @override
  Future<void> registerHostSide() async {
    $registerPayloadServiceClientFactory();
    $registerPayloadServiceMethodIds();
  }

  @override
  Future<void> initialize() async {
    $registerPayloadServiceDispatcher();
    await super.initialize();
  }
}

void $registerPayloadServiceLocalSide() {
  $registerPayloadServiceDispatcher();
  $registerPayloadServiceClientFactory();
  $registerPayloadServiceMethodIds();
}

void $autoRegisterPayloadServiceLocalSide() {
  LocalSideRegistry.register<PayloadService>($registerPayloadServiceLocalSide);
}

final $_PayloadServiceLocalSideRegistered = (() {
  $autoRegisterPayloadServiceLocalSide();
  return true;
})();

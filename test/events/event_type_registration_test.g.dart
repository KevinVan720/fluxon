// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_type_registration_test.dart';

// **************************************************************************
// ServiceGenerator (handwritten for test until build_runner)
// **************************************************************************

// Service client for SenderService
class SenderServiceClient extends SenderService {
  SenderServiceClient(this._proxy);
  final ServiceProxy<SenderService> _proxy;

  @override
  Future<void> sendTyped(String text) async {
    return await _proxy.callMethod('sendTyped', [text], namedArgs: {});
  }
}

void $registerSenderServiceClientFactory() {
  GeneratedClientRegistry.register<SenderService>(
    (proxy) => SenderServiceClient(proxy),
  );
}

class _SenderServiceMethods {
  static const int sendTypedId = 1;
}

Future<dynamic> _SenderServiceDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as SenderService;
  switch (methodId) {
    case _SenderServiceMethods.sendTypedId:
      return await s.sendTyped(positionalArgs[0]);
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void $registerSenderServiceDispatcher() {
  GeneratedDispatcherRegistry.register<SenderService>(
    _SenderServiceDispatcher,
  );
}

void $registerSenderServiceMethodIds() {
  ServiceMethodIdRegistry.register<SenderService>({
    'sendTyped': _SenderServiceMethods.sendTypedId,
  });
}

void registerSenderServiceGenerated() {
  $registerSenderServiceClientFactory();
  $registerSenderServiceMethodIds();
}

// Remote service implementation that auto-registers the dispatcher
class SenderServiceImpl extends SenderService {
  @override
  bool get isRemote => true;
  @override
  Type get clientBaseType => SenderService;
  @override
  Future<void> registerHostSide() async {
    $registerSenderServiceClientFactory();
    $registerSenderServiceMethodIds();
  }

  @override
  Future<void> initialize() async {
    $registerSenderServiceDispatcher();
    await super.initialize();
  }
}

void $registerSenderServiceLocalSide() {
  $registerSenderServiceDispatcher();
  $registerSenderServiceClientFactory();
  $registerSenderServiceMethodIds();
}

void $autoRegisterSenderServiceLocalSide() {
  LocalSideRegistry.register<SenderService>($registerSenderServiceLocalSide);
}

final $_SenderServiceLocalSideRegistered = (() {
  $autoRegisterSenderServiceLocalSide();
  return true;
})();

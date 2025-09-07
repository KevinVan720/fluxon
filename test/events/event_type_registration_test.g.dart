// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_type_registration_test.dart';

// **************************************************************************
// ServiceGenerator
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

// Service client for ReceiverService
class ReceiverServiceClient extends ReceiverService {
  ReceiverServiceClient(this._proxy);
  final ServiceProxy<ReceiverService> _proxy;
}

void $registerReceiverServiceClientFactory() {
  GeneratedClientRegistry.register<ReceiverService>(
    (proxy) => ReceiverServiceClient(proxy),
  );
}

class _ReceiverServiceMethods {}

Future<dynamic> _ReceiverServiceDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as ReceiverService;
  switch (methodId) {
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void $registerReceiverServiceDispatcher() {
  GeneratedDispatcherRegistry.register<ReceiverService>(
    _ReceiverServiceDispatcher,
  );
}

void $registerReceiverServiceMethodIds() {
  ServiceMethodIdRegistry.register<ReceiverService>({});
}

void registerReceiverServiceGenerated() {
  $registerReceiverServiceClientFactory();
  $registerReceiverServiceMethodIds();
}

// Local service implementation that auto-registers local side
class ReceiverServiceImpl extends ReceiverService {
  ReceiverServiceImpl() {
    // 🚀 AUTO-REGISTRATION: Register local side when instance is created
    $registerReceiverServiceLocalSide();
  }
}

void $registerReceiverServiceLocalSide() {
  $registerReceiverServiceDispatcher();
  $registerReceiverServiceClientFactory();
  $registerReceiverServiceMethodIds();
}

void $autoRegisterReceiverServiceLocalSide() {
  LocalSideRegistry.register<ReceiverService>(
      $registerReceiverServiceLocalSide);
}

final $_ReceiverServiceLocalSideRegistered = (() {
  $autoRegisterReceiverServiceLocalSide();
  return true;
})();

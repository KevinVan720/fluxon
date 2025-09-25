// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_excludes_test.dart';

// **************************************************************************
// ServiceGenerator
// **************************************************************************

// Service client for AService
class AServiceClient extends AService {
  AServiceClient(this._proxy);
  final ServiceProxy<AService> _proxy;
}

void $registerAServiceClientFactory() {
  GeneratedClientRegistry.register<AService>(
    (proxy) => AServiceClient(proxy),
  );
}

class _AServiceMethods {}

Future<dynamic> _AServiceDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as AService;
  switch (methodId) {
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void $registerAServiceDispatcher() {
  GeneratedDispatcherRegistry.register<AService>(
    _AServiceDispatcher,
  );
}

void $registerAServiceMethodIds() {
  ServiceMethodIdRegistry.register<AService>({});
}

void registerAServiceGenerated() {
  $registerAServiceClientFactory();
  $registerAServiceMethodIds();
}

// Local service implementation that auto-registers local side
class AServiceImpl extends AService {
  AServiceImpl() {
    // 🚀 AUTO-REGISTRATION: Register local side when instance is created
    $registerAServiceLocalSide();
  }
}

void $registerAServiceLocalSide() {
  $registerAServiceDispatcher();
  $registerAServiceClientFactory();
  $registerAServiceMethodIds();
}

void $autoRegisterAServiceLocalSide() {
  LocalSideRegistry.register<AService>($registerAServiceLocalSide);
}

final $_AServiceLocalSideRegistered = (() {
  $autoRegisterAServiceLocalSide();
  return true;
})();

// Service client for BService
class BServiceClient extends BService {
  BServiceClient(this._proxy);
  final ServiceProxy<BService> _proxy;
}

void $registerBServiceClientFactory() {
  GeneratedClientRegistry.register<BService>(
    (proxy) => BServiceClient(proxy),
  );
}

class _BServiceMethods {}

Future<dynamic> _BServiceDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as BService;
  switch (methodId) {
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void $registerBServiceDispatcher() {
  GeneratedDispatcherRegistry.register<BService>(
    _BServiceDispatcher,
  );
}

void $registerBServiceMethodIds() {
  ServiceMethodIdRegistry.register<BService>({});
}

void registerBServiceGenerated() {
  $registerBServiceClientFactory();
  $registerBServiceMethodIds();
}

// Local service implementation that auto-registers local side
class BServiceImpl extends BService {
  BServiceImpl() {
    // 🚀 AUTO-REGISTRATION: Register local side when instance is created
    $registerBServiceLocalSide();
  }
}

void $registerBServiceLocalSide() {
  $registerBServiceDispatcher();
  $registerBServiceClientFactory();
  $registerBServiceMethodIds();
}

void $autoRegisterBServiceLocalSide() {
  LocalSideRegistry.register<BService>($registerBServiceLocalSide);
}

final $_BServiceLocalSideRegistered = (() {
  $autoRegisterBServiceLocalSide();
  return true;
})();

// Service client for Sender
class SenderClient extends Sender {
  SenderClient(this._proxy);
  final ServiceProxy<Sender> _proxy;

  @override
  Future<EventDistributionResult> fire(EventDistribution d) async {
    return await _proxy
        .callMethod<EventDistributionResult>('fire', [d], namedArgs: {});
  }
}

void $registerSenderClientFactory() {
  GeneratedClientRegistry.register<Sender>(
    (proxy) => SenderClient(proxy),
  );
}

class _SenderMethods {
  static const int fireId = 1;
}

Future<dynamic> _SenderDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as Sender;
  switch (methodId) {
    case _SenderMethods.fireId:
      return await s.fire(positionalArgs[0]);
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void $registerSenderDispatcher() {
  GeneratedDispatcherRegistry.register<Sender>(
    _SenderDispatcher,
  );
}

void $registerSenderMethodIds() {
  ServiceMethodIdRegistry.register<Sender>({
    'fire': _SenderMethods.fireId,
  });
}

void registerSenderGenerated() {
  $registerSenderClientFactory();
  $registerSenderMethodIds();
}

// Local service implementation that auto-registers local side
class SenderImpl extends Sender {
  SenderImpl() {
    // 🚀 AUTO-REGISTRATION: Register local side when instance is created
    $registerSenderLocalSide();
  }
}

void $registerSenderLocalSide() {
  $registerSenderDispatcher();
  $registerSenderClientFactory();
  $registerSenderMethodIds();
}

void $autoRegisterSenderLocalSide() {
  LocalSideRegistry.register<Sender>($registerSenderLocalSide);
}

final $_SenderLocalSideRegistered = (() {
  $autoRegisterSenderLocalSide();
  return true;
})();

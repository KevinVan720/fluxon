// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'topology_event_flows_test.dart';

// **************************************************************************
// ServiceGenerator
// **************************************************************************

// Service client for RemoteEmitterA
class RemoteEmitterAClient extends RemoteEmitterA {
  RemoteEmitterAClient(this._proxy);
  final ServiceProxy<RemoteEmitterA> _proxy;

  @override
  Future<void> fire(String payload) async {
    return await _proxy.callMethod('fire', [payload], namedArgs: {});
  }
}

void $registerRemoteEmitterAClientFactory() {
  GeneratedClientRegistry.register<RemoteEmitterA>(
    (proxy) => RemoteEmitterAClient(proxy),
  );
}

class _RemoteEmitterAMethods {
  static const int fireId = 1;
}

Future<dynamic> _RemoteEmitterADispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as RemoteEmitterA;
  switch (methodId) {
    case _RemoteEmitterAMethods.fireId:
      return await s.fire(positionalArgs[0]);
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void $registerRemoteEmitterADispatcher() {
  GeneratedDispatcherRegistry.register<RemoteEmitterA>(
    _RemoteEmitterADispatcher,
  );
}

void $registerRemoteEmitterAMethodIds() {
  ServiceMethodIdRegistry.register<RemoteEmitterA>({
    'fire': _RemoteEmitterAMethods.fireId,
  });
}

void registerRemoteEmitterAGenerated() {
  $registerRemoteEmitterAClientFactory();
  $registerRemoteEmitterAMethodIds();
}

// Remote service implementation that auto-registers the dispatcher
class RemoteEmitterAImpl extends RemoteEmitterA {
  @override
  bool get isRemote => true;
  @override
  Type get clientBaseType => RemoteEmitterA;
  @override
  Future<void> registerHostSide() async {
    $registerRemoteEmitterAClientFactory();
    $registerRemoteEmitterAMethodIds();
  }

  @override
  Future<void> initialize() async {
    $registerRemoteEmitterADispatcher();
    await super.initialize();
  }
}

void $registerRemoteEmitterALocalSide() {
  $registerRemoteEmitterADispatcher();
  $registerRemoteEmitterAClientFactory();
  $registerRemoteEmitterAMethodIds();
}

void $autoRegisterRemoteEmitterALocalSide() {
  LocalSideRegistry.register<RemoteEmitterA>($registerRemoteEmitterALocalSide);
}

final $_RemoteEmitterALocalSideRegistered = (() {
  $autoRegisterRemoteEmitterALocalSide();
  return true;
})();

// Service client for RemoteListenerB
class RemoteListenerBClient extends RemoteListenerB {
  RemoteListenerBClient(this._proxy);
  final ServiceProxy<RemoteListenerB> _proxy;

  @override
  Future<List<String>> getSeen() async {
    return await _proxy.callMethod('getSeen', [], namedArgs: {});
  }
}

void $registerRemoteListenerBClientFactory() {
  GeneratedClientRegistry.register<RemoteListenerB>(
    (proxy) => RemoteListenerBClient(proxy),
  );
}

class _RemoteListenerBMethods {
  static const int getSeenId = 1;
}

Future<dynamic> _RemoteListenerBDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as RemoteListenerB;
  switch (methodId) {
    case _RemoteListenerBMethods.getSeenId:
      return await s.getSeen();
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void $registerRemoteListenerBDispatcher() {
  GeneratedDispatcherRegistry.register<RemoteListenerB>(
    _RemoteListenerBDispatcher,
  );
}

void $registerRemoteListenerBMethodIds() {
  ServiceMethodIdRegistry.register<RemoteListenerB>({
    'getSeen': _RemoteListenerBMethods.getSeenId,
  });
}

void registerRemoteListenerBGenerated() {
  $registerRemoteListenerBClientFactory();
  $registerRemoteListenerBMethodIds();
}

// Remote service implementation that auto-registers the dispatcher
class RemoteListenerBImpl extends RemoteListenerB {
  @override
  bool get isRemote => true;
  @override
  Type get clientBaseType => RemoteListenerB;
  @override
  Future<void> registerHostSide() async {
    $registerRemoteListenerBClientFactory();
    $registerRemoteListenerBMethodIds();
  }

  @override
  Future<void> initialize() async {
    $registerRemoteListenerBDispatcher();
    await super.initialize();
  }
}

void $registerRemoteListenerBLocalSide() {
  $registerRemoteListenerBDispatcher();
  $registerRemoteListenerBClientFactory();
  $registerRemoteListenerBMethodIds();
}

void $autoRegisterRemoteListenerBLocalSide() {
  LocalSideRegistry.register<RemoteListenerB>(
      $registerRemoteListenerBLocalSide);
}

final $_RemoteListenerBLocalSideRegistered = (() {
  $autoRegisterRemoteListenerBLocalSide();
  return true;
})();

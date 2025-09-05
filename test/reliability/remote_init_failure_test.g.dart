// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'remote_init_failure_test.dart';

// **************************************************************************
// ServiceGenerator (handwritten for test)
// **************************************************************************

// Service client for ExplodingRemote
class ExplodingRemoteClient extends ExplodingRemote {
  ExplodingRemoteClient(this._proxy);
  final ServiceProxy<ExplodingRemote> _proxy;

  @override
  Future<String> hello() async {
    return await _proxy.callMethod('hello', [], namedArgs: {});
  }
}

void $registerExplodingRemoteClientFactory() {
  GeneratedClientRegistry.register<ExplodingRemote>(
    (proxy) => ExplodingRemoteClient(proxy),
  );
}

class _ExplodingRemoteMethods {
  static const int helloId = 1;
}

Future<dynamic> _ExplodingRemoteDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as ExplodingRemote;
  switch (methodId) {
    case _ExplodingRemoteMethods.helloId:
      return await s.hello();
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void $registerExplodingRemoteDispatcher() {
  GeneratedDispatcherRegistry.register<ExplodingRemote>(
    _ExplodingRemoteDispatcher,
  );
}

void $registerExplodingRemoteMethodIds() {
  ServiceMethodIdRegistry.register<ExplodingRemote>({
    'hello': _ExplodingRemoteMethods.helloId,
  });
}

void registerExplodingRemoteGenerated() {
  $registerExplodingRemoteClientFactory();
  $registerExplodingRemoteMethodIds();
}

// Remote service implementation that auto-registers the dispatcher
class ExplodingRemoteImpl extends ExplodingRemote {
  @override
  bool get isRemote => true;
  @override
  Type get clientBaseType => ExplodingRemote;
  @override
  Future<void> registerHostSide() async {
    $registerExplodingRemoteClientFactory();
    $registerExplodingRemoteMethodIds();
  }

  @override
  Future<void> initialize() async {
    $registerExplodingRemoteDispatcher();
    await super.initialize();
    // Will throw from base initialize override
  }
}

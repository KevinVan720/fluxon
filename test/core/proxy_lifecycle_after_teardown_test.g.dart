// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'proxy_lifecycle_after_teardown_test.dart';

// **************************************************************************
// ServiceGenerator (handwritten for test)
// **************************************************************************

// Service client for EchoService
class EchoServiceClient extends EchoService {
  EchoServiceClient(this._proxy);
  final ServiceProxy<EchoService> _proxy;

  @override
  Future<String> echo(String v) async {
    return await _proxy.callMethod('echo', [v], namedArgs: {});
  }
}

void $registerEchoServiceClientFactory() {
  GeneratedClientRegistry.register<EchoService>(
    (proxy) => EchoServiceClient(proxy),
  );
}

class _EchoServiceMethods {
  static const int echoId = 1;
}

Future<dynamic> _EchoServiceDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as EchoService;
  switch (methodId) {
    case _EchoServiceMethods.echoId:
      return await s.echo(positionalArgs[0]);
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void $registerEchoServiceDispatcher() {
  GeneratedDispatcherRegistry.register<EchoService>(
    _EchoServiceDispatcher,
  );
}

void $registerEchoServiceMethodIds() {
  ServiceMethodIdRegistry.register<EchoService>({
    'echo': _EchoServiceMethods.echoId,
  });
}

class EchoServiceImpl extends EchoService {
  @override
  bool get isRemote => true;
  @override
  Type get clientBaseType => EchoService;
  @override
  Future<void> registerHostSide() async {
    $registerEchoServiceClientFactory();
    $registerEchoServiceMethodIds();
  }

  @override
  Future<void> initialize() async {
    $registerEchoServiceDispatcher();
    await super.initialize();
  }
}

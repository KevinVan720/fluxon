// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unknown_method_id_test.dart';

// **************************************************************************
// ServiceGenerator
// **************************************************************************

// Service client for IdMissingService
class IdMissingServiceClient extends IdMissingService {
  IdMissingServiceClient(this._proxy);
  final ServiceProxy<IdMissingService> _proxy;

  @override
  Future<String> doWork(String x) async {
    final result = await _proxy.callMethod('doWork', [x], namedArgs: {});
    return result as String;
  }
}

void $registerIdMissingServiceClientFactory() {
  GeneratedClientRegistry.register<IdMissingService>(
    (proxy) => IdMissingServiceClient(proxy),
  );
}

class _IdMissingServiceMethods {
  static const int doWorkId = 1;
}

Future<dynamic> _IdMissingServiceDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as IdMissingService;
  switch (methodId) {
    case _IdMissingServiceMethods.doWorkId:
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

void $registerIdMissingServiceMethodIds() {
  ServiceMethodIdRegistry.register<IdMissingService>({
    'doWork': _IdMissingServiceMethods.doWorkId,
  });
}

void registerIdMissingServiceGenerated() {
  $registerIdMissingServiceClientFactory();
  $registerIdMissingServiceMethodIds();
}

// Remote service implementation that auto-registers the dispatcher
class IdMissingServiceImpl extends IdMissingService {
  @override
  bool get isRemote => true;
  @override
  Type get clientBaseType => IdMissingService;
  @override
  Future<void> registerHostSide() async {
    $registerIdMissingServiceClientFactory();
    $registerIdMissingServiceMethodIds();
  }

  @override
  Future<void> initialize() async {
    $registerIdMissingServiceDispatcher();
    await super.initialize();
  }
}

void $registerIdMissingServiceLocalSide() {
  $registerIdMissingServiceDispatcher();
  $registerIdMissingServiceClientFactory();
  $registerIdMissingServiceMethodIds();
}

void $autoRegisterIdMissingServiceLocalSide() {
  LocalSideRegistry.register<IdMissingService>(
      $registerIdMissingServiceLocalSide);
}

final $_IdMissingServiceLocalSideRegistered = (() {
  $autoRegisterIdMissingServiceLocalSide();
  return true;
})();

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'retry_timeout_demo_test.dart';

// **************************************************************************
// ServiceGenerator
// **************************************************************************

// Service client for FlakyService
class FlakyServiceClient extends FlakyService {
  FlakyServiceClient(this._proxy);
  final ServiceProxy<FlakyService> _proxy;

  @override
  Future<String> succeedAfter(int attempts) async {
    return await _proxy.callMethod('succeedAfter', [attempts], namedArgs: {});
  }

  @override
  Future<String> slowOperation(Duration delay) async {
    return await _proxy.callMethod('slowOperation', [delay], namedArgs: {});
  }
}

void $registerFlakyServiceClientFactory() {
  GeneratedClientRegistry.register<FlakyService>(
    (proxy) => FlakyServiceClient(proxy),
  );
}

class _FlakyServiceMethods {
  static const int succeedAfterId = 1;
  static const int slowOperationId = 2;
}

Future<dynamic> _FlakyServiceDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as FlakyService;
  switch (methodId) {
    case _FlakyServiceMethods.succeedAfterId:
      return await s.succeedAfter(positionalArgs[0]);
    case _FlakyServiceMethods.slowOperationId:
      return await s.slowOperation(positionalArgs[0]);
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void $registerFlakyServiceDispatcher() {
  GeneratedDispatcherRegistry.register<FlakyService>(
    _FlakyServiceDispatcher,
  );
}

void $registerFlakyServiceMethodIds() {
  ServiceMethodIdRegistry.register<FlakyService>({
    'succeedAfter': _FlakyServiceMethods.succeedAfterId,
    'slowOperation': _FlakyServiceMethods.slowOperationId,
  });
}

void registerFlakyServiceGenerated() {
  $registerFlakyServiceClientFactory();
  $registerFlakyServiceMethodIds();
}

// Worker implementation that auto-registers the dispatcher
class FlakyServiceWorker extends FlakyService {
  @override
  Type get clientBaseType => FlakyService;
  @override
  Future<void> registerHostSide() async {
    $registerFlakyServiceClientFactory();
    $registerFlakyServiceMethodIds();
  }

  @override
  Future<void> initialize() async {
    $registerFlakyServiceDispatcher();
    await super.initialize();
  }
}

void $registerFlakyServiceLocalSide() {
  $registerFlakyServiceDispatcher();
  $registerFlakyServiceClientFactory();
  $registerFlakyServiceMethodIds();
}

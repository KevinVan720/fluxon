// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'per_call_timeout_override_test.dart';

// **************************************************************************
// ServiceGenerator
// **************************************************************************

// Service client for SleeperService
class SleeperServiceClient extends SleeperService {
  SleeperServiceClient(this._proxy);
  final ServiceProxy<SleeperService> _proxy;

  @override
  Future<String> snooze(Duration d) async {
    return await _proxy.callMethod('snooze', [d], namedArgs: {});
  }
}

void $registerSleeperServiceClientFactory() {
  GeneratedClientRegistry.register<SleeperService>(
    (proxy) => SleeperServiceClient(proxy),
  );
}

class _SleeperServiceMethods {
  static const int snoozeId = 1;
}

Future<dynamic> _SleeperServiceDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as SleeperService;
  switch (methodId) {
    case _SleeperServiceMethods.snoozeId:
      return await s.snooze(positionalArgs[0]);
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void $registerSleeperServiceDispatcher() {
  GeneratedDispatcherRegistry.register<SleeperService>(
    _SleeperServiceDispatcher,
  );
}

void $registerSleeperServiceMethodIds() {
  ServiceMethodIdRegistry.register<SleeperService>({
    'snooze': _SleeperServiceMethods.snoozeId,
  });
}

void registerSleeperServiceGenerated() {
  $registerSleeperServiceClientFactory();
  $registerSleeperServiceMethodIds();
}

// Remote service implementation that auto-registers the dispatcher
class SleeperServiceImpl extends SleeperService {
  @override
  bool get isRemote => true;
  @override
  Type get clientBaseType => SleeperService;
  @override
  Future<void> registerHostSide() async {
    $registerSleeperServiceClientFactory();
    $registerSleeperServiceMethodIds();
  }

  @override
  Future<void> initialize() async {
    $registerSleeperServiceDispatcher();
    await super.initialize();
  }
}

void $registerSleeperServiceLocalSide() {
  $registerSleeperServiceDispatcher();
  $registerSleeperServiceClientFactory();
  $registerSleeperServiceMethodIds();
}

void $autoRegisterSleeperServiceLocalSide() {
  LocalSideRegistry.register<SleeperService>($registerSleeperServiceLocalSide);
}

final $_SleeperServiceLocalSideRegistered = (() {
  $autoRegisterSleeperServiceLocalSide();
  return true;
})();

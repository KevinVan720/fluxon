// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'worker_crash_recovery_test.dart';

// **************************************************************************
// ServiceGenerator
// **************************************************************************

// Service client for CrashyService
class CrashyServiceClient extends CrashyService {
  CrashyServiceClient(this._proxy);
  final ServiceProxy<CrashyService> _proxy;

  @override
  Future<void> boom() async {
    return await _proxy.callMethod('boom', [], namedArgs: {});
  }

  @override
  Future<String> ok() async {
    return await _proxy.callMethod('ok', [], namedArgs: {});
  }
}

void $registerCrashyServiceClientFactory() {
  GeneratedClientRegistry.register<CrashyService>(
    (proxy) => CrashyServiceClient(proxy),
  );
}

class _CrashyServiceMethods {
  static const int boomId = 1;
  static const int okId = 2;
}

Future<dynamic> _CrashyServiceDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as CrashyService;
  switch (methodId) {
    case _CrashyServiceMethods.boomId:
      return await s.boom();
    case _CrashyServiceMethods.okId:
      return await s.ok();
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void $registerCrashyServiceDispatcher() {
  GeneratedDispatcherRegistry.register<CrashyService>(
    _CrashyServiceDispatcher,
  );
}

void $registerCrashyServiceMethodIds() {
  ServiceMethodIdRegistry.register<CrashyService>({
    'boom': _CrashyServiceMethods.boomId,
    'ok': _CrashyServiceMethods.okId,
  });
}

void registerCrashyServiceGenerated() {
  $registerCrashyServiceClientFactory();
  $registerCrashyServiceMethodIds();
}

// Remote service implementation that auto-registers the dispatcher
class CrashyServiceImpl extends CrashyService {
  @override
  bool get isRemote => true;
  @override
  Type get clientBaseType => CrashyService;
  @override
  Future<void> registerHostSide() async {
    $registerCrashyServiceClientFactory();
    $registerCrashyServiceMethodIds();
  }

  @override
  Future<void> initialize() async {
    $registerCrashyServiceDispatcher();
    await super.initialize();
  }
}

void $registerCrashyServiceLocalSide() {
  $registerCrashyServiceDispatcher();
  $registerCrashyServiceClientFactory();
  $registerCrashyServiceMethodIds();
}

void $autoRegisterCrashyServiceLocalSide() {
  LocalSideRegistry.register<CrashyService>($registerCrashyServiceLocalSide);
}

final $_CrashyServiceLocalSideRegistered = (() {
  $autoRegisterCrashyServiceLocalSide();
  return true;
})();

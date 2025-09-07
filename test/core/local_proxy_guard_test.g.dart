// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_proxy_guard_test.dart';

// **************************************************************************
// ServiceGenerator
// **************************************************************************

// Service client for GuardTestService
class GuardTestServiceClient extends GuardTestService {
  GuardTestServiceClient(this._proxy);
  final ServiceProxy<GuardTestService> _proxy;

  @override
  Future<String> greet() async {
    return await _proxy.callMethod('greet', [], namedArgs: {});
  }
}

void $registerGuardTestServiceClientFactory() {
  GeneratedClientRegistry.register<GuardTestService>(
    (proxy) => GuardTestServiceClient(proxy),
  );
}

class _GuardTestServiceMethods {
  static const int greetId = 1;
}

Future<dynamic> _GuardTestServiceDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as GuardTestService;
  switch (methodId) {
    case _GuardTestServiceMethods.greetId:
      return await s.greet();
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void $registerGuardTestServiceDispatcher() {
  GeneratedDispatcherRegistry.register<GuardTestService>(
    _GuardTestServiceDispatcher,
  );
}

void $registerGuardTestServiceMethodIds() {
  ServiceMethodIdRegistry.register<GuardTestService>({
    'greet': _GuardTestServiceMethods.greetId,
  });
}

void registerGuardTestServiceGenerated() {
  $registerGuardTestServiceClientFactory();
  $registerGuardTestServiceMethodIds();
}

// Local service implementation that auto-registers local side
class GuardTestServiceImpl extends GuardTestService {
  GuardTestServiceImpl() {
    // 🚀 AUTO-REGISTRATION: Register local side when instance is created
    $registerGuardTestServiceLocalSide();
  }
}

void $registerGuardTestServiceLocalSide() {
  $registerGuardTestServiceDispatcher();
  $registerGuardTestServiceClientFactory();
  $registerGuardTestServiceMethodIds();
}

void $autoRegisterGuardTestServiceLocalSide() {
  LocalSideRegistry.register<GuardTestService>(
      $registerGuardTestServiceLocalSide);
}

final $_GuardTestServiceLocalSideRegistered = (() {
  $autoRegisterGuardTestServiceLocalSide();
  return true;
})();

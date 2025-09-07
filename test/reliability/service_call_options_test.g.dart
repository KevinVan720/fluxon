// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_call_options_test.dart';

// **************************************************************************
// ServiceGenerator
// **************************************************************************

// Service client for TimeoutTestService
class TimeoutTestServiceClient extends TimeoutTestService {
  TimeoutTestServiceClient(this._proxy);
  final ServiceProxy<TimeoutTestService> _proxy;

  @override
  Future<String> fastMethod() async {
    return await _proxy.callMethod('fastMethod', [], namedArgs: {});
  }

  @override
  Future<String> slowMethod(int delayMs) async {
    return await _proxy.callMethod('slowMethod', [delayMs], namedArgs: {});
  }

  @override
  Future<String> verySlowMethod() async {
    return await _proxy.callMethod('verySlowMethod', [], namedArgs: {});
  }
}

void $registerTimeoutTestServiceClientFactory() {
  GeneratedClientRegistry.register<TimeoutTestService>(
    (proxy) => TimeoutTestServiceClient(proxy),
  );
}

class _TimeoutTestServiceMethods {
  static const int fastMethodId = 1;
  static const int slowMethodId = 2;
  static const int verySlowMethodId = 3;
}

Future<dynamic> _TimeoutTestServiceDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as TimeoutTestService;
  switch (methodId) {
    case _TimeoutTestServiceMethods.fastMethodId:
      return await s.fastMethod();
    case _TimeoutTestServiceMethods.slowMethodId:
      return await s.slowMethod(positionalArgs[0]);
    case _TimeoutTestServiceMethods.verySlowMethodId:
      return await s.verySlowMethod();
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void $registerTimeoutTestServiceDispatcher() {
  GeneratedDispatcherRegistry.register<TimeoutTestService>(
    _TimeoutTestServiceDispatcher,
  );
}

void $registerTimeoutTestServiceMethodIds() {
  ServiceMethodIdRegistry.register<TimeoutTestService>({
    'fastMethod': _TimeoutTestServiceMethods.fastMethodId,
    'slowMethod': _TimeoutTestServiceMethods.slowMethodId,
    'verySlowMethod': _TimeoutTestServiceMethods.verySlowMethodId,
  });
}

void registerTimeoutTestServiceGenerated() {
  $registerTimeoutTestServiceClientFactory();
  $registerTimeoutTestServiceMethodIds();
}

// Remote service implementation that auto-registers the dispatcher
class TimeoutTestServiceImpl extends TimeoutTestService {
  @override
  bool get isRemote => true;
  @override
  Type get clientBaseType => TimeoutTestService;
  @override
  Future<void> registerHostSide() async {
    $registerTimeoutTestServiceClientFactory();
    $registerTimeoutTestServiceMethodIds();
  }

  @override
  Future<void> initialize() async {
    $registerTimeoutTestServiceDispatcher();
    await super.initialize();
  }
}

void $registerTimeoutTestServiceLocalSide() {
  $registerTimeoutTestServiceDispatcher();
  $registerTimeoutTestServiceClientFactory();
  $registerTimeoutTestServiceMethodIds();
}

void $autoRegisterTimeoutTestServiceLocalSide() {
  LocalSideRegistry.register<TimeoutTestService>(
      $registerTimeoutTestServiceLocalSide);
}

final $_TimeoutTestServiceLocalSideRegistered = (() {
  $autoRegisterTimeoutTestServiceLocalSide();
  return true;
})();

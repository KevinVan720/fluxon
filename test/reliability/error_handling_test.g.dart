// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'error_handling_test.dart';

// **************************************************************************
// ServiceGenerator
// **************************************************************************

// Service client for FailingInitService
class FailingInitServiceClient extends FailingInitService {
  FailingInitServiceClient(this._proxy);
  final ServiceProxy<FailingInitService> _proxy;
}

void $registerFailingInitServiceClientFactory() {
  GeneratedClientRegistry.register<FailingInitService>(
    (proxy) => FailingInitServiceClient(proxy),
  );
}

class _FailingInitServiceMethods {}

Future<dynamic> _FailingInitServiceDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as FailingInitService;
  switch (methodId) {
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void $registerFailingInitServiceDispatcher() {
  GeneratedDispatcherRegistry.register<FailingInitService>(
    _FailingInitServiceDispatcher,
  );
}

void $registerFailingInitServiceMethodIds() {
  ServiceMethodIdRegistry.register<FailingInitService>({});
}

void registerFailingInitServiceGenerated() {
  $registerFailingInitServiceClientFactory();
  $registerFailingInitServiceMethodIds();
}

// Local service implementation that auto-registers local side
class FailingInitServiceImpl extends FailingInitService {
  FailingInitServiceImpl() {
    // 🚀 AUTO-REGISTRATION: Register local side when instance is created
    $registerFailingInitServiceLocalSide();
  }
}

void $registerFailingInitServiceLocalSide() {
  $registerFailingInitServiceDispatcher();
  $registerFailingInitServiceClientFactory();
  $registerFailingInitServiceMethodIds();
}

void $autoRegisterFailingInitServiceLocalSide() {
  LocalSideRegistry.register<FailingInitService>(
      $registerFailingInitServiceLocalSide);
}

final $_FailingInitServiceLocalSideRegistered = (() {
  $autoRegisterFailingInitServiceLocalSide();
  return true;
})();

// Service client for FailingMethodService
class FailingMethodServiceClient extends FailingMethodService {
  FailingMethodServiceClient(this._proxy);
  final ServiceProxy<FailingMethodService> _proxy;

  @override
  Future<String> alwaysFails() async {
    return await _proxy.callMethod('alwaysFails', [], namedArgs: {});
  }

  @override
  Future<String> failsRandomly() async {
    return await _proxy.callMethod('failsRandomly', [], namedArgs: {});
  }
}

void $registerFailingMethodServiceClientFactory() {
  GeneratedClientRegistry.register<FailingMethodService>(
    (proxy) => FailingMethodServiceClient(proxy),
  );
}

class _FailingMethodServiceMethods {
  static const int alwaysFailsId = 1;
  static const int failsRandomlyId = 2;
}

Future<dynamic> _FailingMethodServiceDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as FailingMethodService;
  switch (methodId) {
    case _FailingMethodServiceMethods.alwaysFailsId:
      return await s.alwaysFails();
    case _FailingMethodServiceMethods.failsRandomlyId:
      return await s.failsRandomly();
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void $registerFailingMethodServiceDispatcher() {
  GeneratedDispatcherRegistry.register<FailingMethodService>(
    _FailingMethodServiceDispatcher,
  );
}

void $registerFailingMethodServiceMethodIds() {
  ServiceMethodIdRegistry.register<FailingMethodService>({
    'alwaysFails': _FailingMethodServiceMethods.alwaysFailsId,
    'failsRandomly': _FailingMethodServiceMethods.failsRandomlyId,
  });
}

void registerFailingMethodServiceGenerated() {
  $registerFailingMethodServiceClientFactory();
  $registerFailingMethodServiceMethodIds();
}

// Remote service implementation that auto-registers the dispatcher
class FailingMethodServiceImpl extends FailingMethodService {
  @override
  bool get isRemote => true;
  @override
  Type get clientBaseType => FailingMethodService;
  @override
  Future<void> registerHostSide() async {
    $registerFailingMethodServiceClientFactory();
    $registerFailingMethodServiceMethodIds();
  }

  @override
  Future<void> initialize() async {
    $registerFailingMethodServiceDispatcher();
    await super.initialize();
  }
}

void $registerFailingMethodServiceLocalSide() {
  $registerFailingMethodServiceDispatcher();
  $registerFailingMethodServiceClientFactory();
  $registerFailingMethodServiceMethodIds();
}

void $autoRegisterFailingMethodServiceLocalSide() {
  LocalSideRegistry.register<FailingMethodService>(
      $registerFailingMethodServiceLocalSide);
}

final $_FailingMethodServiceLocalSideRegistered = (() {
  $autoRegisterFailingMethodServiceLocalSide();
  return true;
})();

// Service client for InvalidDependencyService
class InvalidDependencyServiceClient extends InvalidDependencyService {
  InvalidDependencyServiceClient(this._proxy);
  final ServiceProxy<InvalidDependencyService> _proxy;

  @override
  Future<void> doSomething() async {
    return await _proxy.callMethod('doSomething', [], namedArgs: {});
  }
}

void $registerInvalidDependencyServiceClientFactory() {
  GeneratedClientRegistry.register<InvalidDependencyService>(
    (proxy) => InvalidDependencyServiceClient(proxy),
  );
}

class _InvalidDependencyServiceMethods {
  static const int doSomethingId = 1;
}

Future<dynamic> _InvalidDependencyServiceDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as InvalidDependencyService;
  switch (methodId) {
    case _InvalidDependencyServiceMethods.doSomethingId:
      return await s.doSomething();
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void $registerInvalidDependencyServiceDispatcher() {
  GeneratedDispatcherRegistry.register<InvalidDependencyService>(
    _InvalidDependencyServiceDispatcher,
  );
}

void $registerInvalidDependencyServiceMethodIds() {
  ServiceMethodIdRegistry.register<InvalidDependencyService>({
    'doSomething': _InvalidDependencyServiceMethods.doSomethingId,
  });
}

void registerInvalidDependencyServiceGenerated() {
  $registerInvalidDependencyServiceClientFactory();
  $registerInvalidDependencyServiceMethodIds();
}

// Local service implementation that auto-registers local side
class InvalidDependencyServiceImpl extends InvalidDependencyService {
  InvalidDependencyServiceImpl() {
    // 🚀 AUTO-REGISTRATION: Register local side when instance is created
    $registerInvalidDependencyServiceLocalSide();
  }
}

void $registerInvalidDependencyServiceLocalSide() {
  $registerInvalidDependencyServiceDispatcher();
  $registerInvalidDependencyServiceClientFactory();
  $registerInvalidDependencyServiceMethodIds();
  try {
    $registerFailingInitServiceClientFactory();
  } catch (_) {}
  try {
    $registerFailingInitServiceMethodIds();
  } catch (_) {}
}

void $autoRegisterInvalidDependencyServiceLocalSide() {
  LocalSideRegistry.register<InvalidDependencyService>(
      $registerInvalidDependencyServiceLocalSide);
}

final $_InvalidDependencyServiceLocalSideRegistered = (() {
  $autoRegisterInvalidDependencyServiceLocalSide();
  return true;
})();

// Service client for CorruptingService
class CorruptingServiceClient extends CorruptingService {
  CorruptingServiceClient(this._proxy);
  final ServiceProxy<CorruptingService> _proxy;

  @override
  Future<void> sendCorruptedEvent() async {
    return await _proxy.callMethod('sendCorruptedEvent', [], namedArgs: {});
  }
}

void $registerCorruptingServiceClientFactory() {
  GeneratedClientRegistry.register<CorruptingService>(
    (proxy) => CorruptingServiceClient(proxy),
  );
}

class _CorruptingServiceMethods {
  static const int sendCorruptedEventId = 1;
}

Future<dynamic> _CorruptingServiceDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as CorruptingService;
  switch (methodId) {
    case _CorruptingServiceMethods.sendCorruptedEventId:
      return await s.sendCorruptedEvent();
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void $registerCorruptingServiceDispatcher() {
  GeneratedDispatcherRegistry.register<CorruptingService>(
    _CorruptingServiceDispatcher,
  );
}

void $registerCorruptingServiceMethodIds() {
  ServiceMethodIdRegistry.register<CorruptingService>({
    'sendCorruptedEvent': _CorruptingServiceMethods.sendCorruptedEventId,
  });
}

void registerCorruptingServiceGenerated() {
  $registerCorruptingServiceClientFactory();
  $registerCorruptingServiceMethodIds();
}

// Local service implementation that auto-registers local side
class CorruptingServiceImpl extends CorruptingService {
  CorruptingServiceImpl() {
    // 🚀 AUTO-REGISTRATION: Register local side when instance is created
    $registerCorruptingServiceLocalSide();
  }
}

void $registerCorruptingServiceLocalSide() {
  $registerCorruptingServiceDispatcher();
  $registerCorruptingServiceClientFactory();
  $registerCorruptingServiceMethodIds();
}

void $autoRegisterCorruptingServiceLocalSide() {
  LocalSideRegistry.register<CorruptingService>(
      $registerCorruptingServiceLocalSide);
}

final $_CorruptingServiceLocalSideRegistered = (() {
  $autoRegisterCorruptingServiceLocalSide();
  return true;
})();

// Service client for SlowService
class SlowServiceClient extends SlowService {
  SlowServiceClient(this._proxy);
  final ServiceProxy<SlowService> _proxy;

  @override
  Future<String> verySlowMethod() async {
    return await _proxy.callMethod('verySlowMethod', [], namedArgs: {});
  }

  @override
  Future<String> fastMethod() async {
    return await _proxy.callMethod('fastMethod', [], namedArgs: {});
  }
}

void $registerSlowServiceClientFactory() {
  GeneratedClientRegistry.register<SlowService>(
    (proxy) => SlowServiceClient(proxy),
  );
}

class _SlowServiceMethods {
  static const int verySlowMethodId = 1;
  static const int fastMethodId = 2;
}

Future<dynamic> _SlowServiceDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as SlowService;
  switch (methodId) {
    case _SlowServiceMethods.verySlowMethodId:
      return await s.verySlowMethod();
    case _SlowServiceMethods.fastMethodId:
      return await s.fastMethod();
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void $registerSlowServiceDispatcher() {
  GeneratedDispatcherRegistry.register<SlowService>(
    _SlowServiceDispatcher,
  );
}

void $registerSlowServiceMethodIds() {
  ServiceMethodIdRegistry.register<SlowService>({
    'verySlowMethod': _SlowServiceMethods.verySlowMethodId,
    'fastMethod': _SlowServiceMethods.fastMethodId,
  });
}

void registerSlowServiceGenerated() {
  $registerSlowServiceClientFactory();
  $registerSlowServiceMethodIds();
}

// Remote service implementation that auto-registers the dispatcher
class SlowServiceImpl extends SlowService {
  @override
  bool get isRemote => true;
  @override
  Type get clientBaseType => SlowService;
  @override
  Future<void> registerHostSide() async {
    $registerSlowServiceClientFactory();
    $registerSlowServiceMethodIds();
  }

  @override
  Future<void> initialize() async {
    $registerSlowServiceDispatcher();
    await super.initialize();
  }
}

void $registerSlowServiceLocalSide() {
  $registerSlowServiceDispatcher();
  $registerSlowServiceClientFactory();
  $registerSlowServiceMethodIds();
}

void $autoRegisterSlowServiceLocalSide() {
  LocalSideRegistry.register<SlowService>($registerSlowServiceLocalSide);
}

final $_SlowServiceLocalSideRegistered = (() {
  $autoRegisterSlowServiceLocalSide();
  return true;
})();

// Service client for MemoryLeakService
class MemoryLeakServiceClient extends MemoryLeakService {
  MemoryLeakServiceClient(this._proxy);
  final ServiceProxy<MemoryLeakService> _proxy;

  @override
  Future<void> consumeMemory() async {
    return await _proxy.callMethod('consumeMemory', [], namedArgs: {});
  }
}

void $registerMemoryLeakServiceClientFactory() {
  GeneratedClientRegistry.register<MemoryLeakService>(
    (proxy) => MemoryLeakServiceClient(proxy),
  );
}

class _MemoryLeakServiceMethods {
  static const int consumeMemoryId = 1;
}

Future<dynamic> _MemoryLeakServiceDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as MemoryLeakService;
  switch (methodId) {
    case _MemoryLeakServiceMethods.consumeMemoryId:
      return await s.consumeMemory();
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void $registerMemoryLeakServiceDispatcher() {
  GeneratedDispatcherRegistry.register<MemoryLeakService>(
    _MemoryLeakServiceDispatcher,
  );
}

void $registerMemoryLeakServiceMethodIds() {
  ServiceMethodIdRegistry.register<MemoryLeakService>({
    'consumeMemory': _MemoryLeakServiceMethods.consumeMemoryId,
  });
}

void registerMemoryLeakServiceGenerated() {
  $registerMemoryLeakServiceClientFactory();
  $registerMemoryLeakServiceMethodIds();
}

// Local service implementation that auto-registers local side
class MemoryLeakServiceImpl extends MemoryLeakService {
  MemoryLeakServiceImpl() {
    // 🚀 AUTO-REGISTRATION: Register local side when instance is created
    $registerMemoryLeakServiceLocalSide();
  }
}

void $registerMemoryLeakServiceLocalSide() {
  $registerMemoryLeakServiceDispatcher();
  $registerMemoryLeakServiceClientFactory();
  $registerMemoryLeakServiceMethodIds();
}

void $autoRegisterMemoryLeakServiceLocalSide() {
  LocalSideRegistry.register<MemoryLeakService>(
      $registerMemoryLeakServiceLocalSide);
}

final $_MemoryLeakServiceLocalSideRegistered = (() {
  $autoRegisterMemoryLeakServiceLocalSide();
  return true;
})();

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

void _registerFailingInitServiceClientFactory() {
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

void _registerFailingInitServiceDispatcher() {
  GeneratedDispatcherRegistry.register<FailingInitService>(
    _FailingInitServiceDispatcher,
  );
}

void _registerFailingInitServiceMethodIds() {
  ServiceMethodIdRegistry.register<FailingInitService>({});
}

void registerFailingInitServiceGenerated() {
  _registerFailingInitServiceClientFactory();
  _registerFailingInitServiceMethodIds();
}

void _registerFailingInitServiceLocalSide() {
  _registerFailingInitServiceDispatcher();
  _registerFailingInitServiceClientFactory();
  _registerFailingInitServiceMethodIds();
}

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

void _registerFailingMethodServiceClientFactory() {
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

void _registerFailingMethodServiceDispatcher() {
  GeneratedDispatcherRegistry.register<FailingMethodService>(
    _FailingMethodServiceDispatcher,
  );
}

void _registerFailingMethodServiceMethodIds() {
  ServiceMethodIdRegistry.register<FailingMethodService>({
    'alwaysFails': _FailingMethodServiceMethods.alwaysFailsId,
    'failsRandomly': _FailingMethodServiceMethods.failsRandomlyId,
  });
}

void registerFailingMethodServiceGenerated() {
  _registerFailingMethodServiceClientFactory();
  _registerFailingMethodServiceMethodIds();
}

// Worker implementation that auto-registers the dispatcher
class FailingMethodServiceWorker extends FailingMethodService {
  @override
  Type get clientBaseType => FailingMethodService;
  @override
  Future<void> registerHostSide() async {
    _registerFailingMethodServiceClientFactory();
    _registerFailingMethodServiceMethodIds();
  }

  @override
  Future<void> initialize() async {
    _registerFailingMethodServiceDispatcher();
    await super.initialize();
  }
}

void _registerFailingMethodServiceLocalSide() {
  _registerFailingMethodServiceDispatcher();
  _registerFailingMethodServiceClientFactory();
  _registerFailingMethodServiceMethodIds();
}

// Service client for InvalidDependencyService
class InvalidDependencyServiceClient extends InvalidDependencyService {
  InvalidDependencyServiceClient(this._proxy);
  final ServiceProxy<InvalidDependencyService> _proxy;

  @override
  Future<void> doSomething() async {
    return await _proxy.callMethod('doSomething', [], namedArgs: {});
  }
}

void _registerInvalidDependencyServiceClientFactory() {
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

void _registerInvalidDependencyServiceDispatcher() {
  GeneratedDispatcherRegistry.register<InvalidDependencyService>(
    _InvalidDependencyServiceDispatcher,
  );
}

void _registerInvalidDependencyServiceMethodIds() {
  ServiceMethodIdRegistry.register<InvalidDependencyService>({
    'doSomething': _InvalidDependencyServiceMethods.doSomethingId,
  });
}

void registerInvalidDependencyServiceGenerated() {
  _registerInvalidDependencyServiceClientFactory();
  _registerInvalidDependencyServiceMethodIds();
}

void _registerInvalidDependencyServiceLocalSide() {
  _registerInvalidDependencyServiceDispatcher();
  _registerInvalidDependencyServiceClientFactory();
  _registerInvalidDependencyServiceMethodIds();
  try {
    _registerFailingInitServiceClientFactory();
  } catch (_) {}
  try {
    _registerFailingInitServiceMethodIds();
  } catch (_) {}
}

// Service client for CorruptingService
class CorruptingServiceClient extends CorruptingService {
  CorruptingServiceClient(this._proxy);
  final ServiceProxy<CorruptingService> _proxy;

  @override
  Future<void> sendCorruptedEvent() async {
    return await _proxy.callMethod('sendCorruptedEvent', [], namedArgs: {});
  }
}

void _registerCorruptingServiceClientFactory() {
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

void _registerCorruptingServiceDispatcher() {
  GeneratedDispatcherRegistry.register<CorruptingService>(
    _CorruptingServiceDispatcher,
  );
}

void _registerCorruptingServiceMethodIds() {
  ServiceMethodIdRegistry.register<CorruptingService>({
    'sendCorruptedEvent': _CorruptingServiceMethods.sendCorruptedEventId,
  });
}

void registerCorruptingServiceGenerated() {
  _registerCorruptingServiceClientFactory();
  _registerCorruptingServiceMethodIds();
}

void _registerCorruptingServiceLocalSide() {
  _registerCorruptingServiceDispatcher();
  _registerCorruptingServiceClientFactory();
  _registerCorruptingServiceMethodIds();
}

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

void _registerSlowServiceClientFactory() {
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

void _registerSlowServiceDispatcher() {
  GeneratedDispatcherRegistry.register<SlowService>(
    _SlowServiceDispatcher,
  );
}

void _registerSlowServiceMethodIds() {
  ServiceMethodIdRegistry.register<SlowService>({
    'verySlowMethod': _SlowServiceMethods.verySlowMethodId,
    'fastMethod': _SlowServiceMethods.fastMethodId,
  });
}

void registerSlowServiceGenerated() {
  _registerSlowServiceClientFactory();
  _registerSlowServiceMethodIds();
}

// Worker implementation that auto-registers the dispatcher
class SlowServiceWorker extends SlowService {
  @override
  Type get clientBaseType => SlowService;
  @override
  Future<void> registerHostSide() async {
    _registerSlowServiceClientFactory();
    _registerSlowServiceMethodIds();
  }

  @override
  Future<void> initialize() async {
    _registerSlowServiceDispatcher();
    await super.initialize();
  }
}

void _registerSlowServiceLocalSide() {
  _registerSlowServiceDispatcher();
  _registerSlowServiceClientFactory();
  _registerSlowServiceMethodIds();
}

// Service client for MemoryLeakService
class MemoryLeakServiceClient extends MemoryLeakService {
  MemoryLeakServiceClient(this._proxy);
  final ServiceProxy<MemoryLeakService> _proxy;

  @override
  Future<void> consumeMemory() async {
    return await _proxy.callMethod('consumeMemory', [], namedArgs: {});
  }
}

void _registerMemoryLeakServiceClientFactory() {
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

void _registerMemoryLeakServiceDispatcher() {
  GeneratedDispatcherRegistry.register<MemoryLeakService>(
    _MemoryLeakServiceDispatcher,
  );
}

void _registerMemoryLeakServiceMethodIds() {
  ServiceMethodIdRegistry.register<MemoryLeakService>({
    'consumeMemory': _MemoryLeakServiceMethods.consumeMemoryId,
  });
}

void registerMemoryLeakServiceGenerated() {
  _registerMemoryLeakServiceClientFactory();
  _registerMemoryLeakServiceMethodIds();
}

void _registerMemoryLeakServiceLocalSide() {
  _registerMemoryLeakServiceDispatcher();
  _registerMemoryLeakServiceClientFactory();
  _registerMemoryLeakServiceMethodIds();
}

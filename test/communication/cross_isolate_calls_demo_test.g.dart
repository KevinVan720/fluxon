// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cross_isolate_calls_demo_test.dart';

// **************************************************************************
// ServiceGenerator
// **************************************************************************

// Service client for ServiceA
class ServiceAClient extends ServiceA {
  ServiceAClient(this._proxy);
  final ServiceProxy<ServiceA> _proxy;

  @override
  Future<int> increment(int x) async {
    return await _proxy.callMethod('increment', [x], namedArgs: {});
  }
}

void $registerServiceAClientFactory() {
  GeneratedClientRegistry.register<ServiceA>(
    (proxy) => ServiceAClient(proxy),
  );
}

class _ServiceAMethods {
  static const int incrementId = 1;
}

Future<dynamic> _ServiceADispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as ServiceA;
  switch (methodId) {
    case _ServiceAMethods.incrementId:
      return await s.increment(positionalArgs[0]);
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void $registerServiceADispatcher() {
  GeneratedDispatcherRegistry.register<ServiceA>(
    _ServiceADispatcher,
  );
}

void $registerServiceAMethodIds() {
  ServiceMethodIdRegistry.register<ServiceA>({
    'increment': _ServiceAMethods.incrementId,
  });
}

void registerServiceAGenerated() {
  $registerServiceAClientFactory();
  $registerServiceAMethodIds();
}

// Worker implementation that auto-registers the dispatcher
class ServiceAWorker extends ServiceA {
  @override
  Type get clientBaseType => ServiceA;
  @override
  Future<void> registerHostSide() async {
    $registerServiceAClientFactory();
    $registerServiceAMethodIds();
    // Auto-registered from dependencies/optionalDependencies
    try {
      $registerServiceBClientFactory();
    } catch (_) {}
    try {
      $registerServiceBMethodIds();
    } catch (_) {}
  }

  @override
  Future<void> initialize() async {
    $registerServiceADispatcher();
    // Ensure worker isolate can create clients for dependencies
    try {
      $registerServiceBClientFactory();
    } catch (_) {}
    try {
      $registerServiceBMethodIds();
    } catch (_) {}
    await super.initialize();
  }
}

void $registerServiceALocalSide() {
  $registerServiceADispatcher();
  $registerServiceAClientFactory();
  $registerServiceAMethodIds();
  try {
    $registerServiceBClientFactory();
  } catch (_) {}
  try {
    $registerServiceBMethodIds();
  } catch (_) {}
}

// Service client for ServiceB
class ServiceBClient extends ServiceB {
  ServiceBClient(this._proxy);
  final ServiceProxy<ServiceB> _proxy;

  @override
  Future<int> doubleIt(int x) async {
    return await _proxy.callMethod('doubleIt', [x], namedArgs: {});
  }
}

void $registerServiceBClientFactory() {
  GeneratedClientRegistry.register<ServiceB>(
    (proxy) => ServiceBClient(proxy),
  );
}

class _ServiceBMethods {
  static const int doubleItId = 1;
}

Future<dynamic> _ServiceBDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as ServiceB;
  switch (methodId) {
    case _ServiceBMethods.doubleItId:
      return await s.doubleIt(positionalArgs[0]);
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void $registerServiceBDispatcher() {
  GeneratedDispatcherRegistry.register<ServiceB>(
    _ServiceBDispatcher,
  );
}

void $registerServiceBMethodIds() {
  ServiceMethodIdRegistry.register<ServiceB>({
    'doubleIt': _ServiceBMethods.doubleItId,
  });
}

void registerServiceBGenerated() {
  $registerServiceBClientFactory();
  $registerServiceBMethodIds();
}

// Worker implementation that auto-registers the dispatcher
class ServiceBWorker extends ServiceB {
  @override
  Type get clientBaseType => ServiceB;
  @override
  Future<void> registerHostSide() async {
    $registerServiceBClientFactory();
    $registerServiceBMethodIds();
    // Auto-registered from dependencies/optionalDependencies
    try {
      $registerServiceAClientFactory();
    } catch (_) {}
    try {
      $registerServiceAMethodIds();
    } catch (_) {}
  }

  @override
  Future<void> initialize() async {
    $registerServiceBDispatcher();
    // Ensure worker isolate can create clients for dependencies
    try {
      $registerServiceAClientFactory();
    } catch (_) {}
    try {
      $registerServiceAMethodIds();
    } catch (_) {}
    await super.initialize();
  }
}

void $registerServiceBLocalSide() {
  $registerServiceBDispatcher();
  $registerServiceBClientFactory();
  $registerServiceBMethodIds();
  try {
    $registerServiceAClientFactory();
  } catch (_) {}
  try {
    $registerServiceAMethodIds();
  } catch (_) {}
}

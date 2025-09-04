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

void _registerServiceAClientFactory() {
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

void _registerServiceADispatcher() {
  GeneratedDispatcherRegistry.register<ServiceA>(
    _ServiceADispatcher,
  );
}

void _registerServiceAMethodIds() {
  ServiceMethodIdRegistry.register<ServiceA>({
    'increment': _ServiceAMethods.incrementId,
  });
}

void registerServiceAGenerated() {
  _registerServiceAClientFactory();
  _registerServiceAMethodIds();
}

// Worker implementation that auto-registers the dispatcher
class ServiceAWorker extends ServiceA {
  @override
  Future<void> initialize() async {
    _registerServiceADispatcher();
    await super.initialize();
  }
}

// 🚀 FLUX: Single registration call mixin
mixin ServiceARegistration {
  void registerService() {
    _registerServiceADispatcher();
  }
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

void _registerServiceBClientFactory() {
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

void _registerServiceBDispatcher() {
  GeneratedDispatcherRegistry.register<ServiceB>(
    _ServiceBDispatcher,
  );
}

void _registerServiceBMethodIds() {
  ServiceMethodIdRegistry.register<ServiceB>({
    'doubleIt': _ServiceBMethods.doubleItId,
  });
}

void registerServiceBGenerated() {
  _registerServiceBClientFactory();
  _registerServiceBMethodIds();
}

// Worker implementation that auto-registers the dispatcher
class ServiceBWorker extends ServiceB {
  @override
  Future<void> initialize() async {
    _registerServiceBDispatcher();
    await super.initialize();
  }
}

// 🚀 FLUX: Single registration call mixin
mixin ServiceBRegistration {
  void registerService() {
    _registerServiceBDispatcher();
  }
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of '04_cross_isolate_calls_demo.dart';

// **************************************************************************
// ServiceGenerator
// **************************************************************************

// Service client for ServiceA
class ServiceAClient extends ServiceA {
  ServiceAClient(this._proxy);
  final ServiceProxy<ServiceA> _proxy;

  @override
  Future<int> incThenDouble(int x) async {
    return await _proxy.callMethod('incThenDouble', [x], namedArgs: {});
  }

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
  static const int incThenDoubleId = 1;
  static const int incrementId = 2;
}

Future<dynamic> _ServiceADispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as ServiceA;
  switch (methodId) {
    case _ServiceAMethods.incThenDoubleId:
      return await s.incThenDouble(positionalArgs[0]);
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
    'incThenDouble': _ServiceAMethods.incThenDoubleId,
    'increment': _ServiceAMethods.incrementId,
  });
}

void registerServiceAGenerated() {
  _registerServiceAClientFactory();
  _registerServiceAMethodIds();
}

// Service client for ServiceB
class ServiceBClient extends ServiceB {
  ServiceBClient(this._proxy);
  final ServiceProxy<ServiceB> _proxy;

  @override
  Future<int> doubleThenInc(int x) async {
    return await _proxy.callMethod('doubleThenInc', [x], namedArgs: {});
  }

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
  static const int doubleThenIncId = 1;
  static const int doubleItId = 2;
}

Future<dynamic> _ServiceBDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as ServiceB;
  switch (methodId) {
    case _ServiceBMethods.doubleThenIncId:
      return await s.doubleThenInc(positionalArgs[0]);
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
    'doubleThenInc': _ServiceBMethods.doubleThenIncId,
    'doubleIt': _ServiceBMethods.doubleItId,
  });
}

void registerServiceBGenerated() {
  _registerServiceBClientFactory();
  _registerServiceBMethodIds();
}

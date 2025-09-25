// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dependency_shutdown_order_test.dart';

// **************************************************************************
// ServiceGenerator
// **************************************************************************

// Service client for ServiceA
class ServiceAClient extends ServiceA {
  ServiceAClient(this._proxy);
  final ServiceProxy<ServiceA> _proxy;
}

void $registerServiceAClientFactory() {
  GeneratedClientRegistry.register<ServiceA>(
    (proxy) => ServiceAClient(proxy),
  );
}

class _ServiceAMethods {}

Future<dynamic> _ServiceADispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as ServiceA;
  switch (methodId) {
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
  ServiceMethodIdRegistry.register<ServiceA>({});
}

void registerServiceAGenerated() {
  $registerServiceAClientFactory();
  $registerServiceAMethodIds();
}

// Local service implementation that auto-registers local side
class ServiceAImpl extends ServiceA {
  ServiceAImpl() {
    // 🚀 AUTO-REGISTRATION: Register local side when instance is created
    $registerServiceALocalSide();
  }
}

void $registerServiceALocalSide() {
  $registerServiceADispatcher();
  $registerServiceAClientFactory();
  $registerServiceAMethodIds();
}

void $autoRegisterServiceALocalSide() {
  LocalSideRegistry.register<ServiceA>($registerServiceALocalSide);
}

final $_ServiceALocalSideRegistered = (() {
  $autoRegisterServiceALocalSide();
  return true;
})();

// Service client for ServiceB
class ServiceBClient extends ServiceB {
  ServiceBClient(this._proxy);
  final ServiceProxy<ServiceB> _proxy;

  @override
  Future<String> id() async {
    return await _proxy.callMethod<String>('id', [], namedArgs: {});
  }
}

void $registerServiceBClientFactory() {
  GeneratedClientRegistry.register<ServiceB>(
    (proxy) => ServiceBClient(proxy),
  );
}

class _ServiceBMethods {
  static const int idId = 1;
}

Future<dynamic> _ServiceBDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as ServiceB;
  switch (methodId) {
    case _ServiceBMethods.idId:
      return await s.id();
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
    'id': _ServiceBMethods.idId,
  });
}

void registerServiceBGenerated() {
  $registerServiceBClientFactory();
  $registerServiceBMethodIds();
}

// Remote service implementation that auto-registers the dispatcher
class ServiceBImpl extends ServiceB {
  @override
  bool get isRemote => true;
  @override
  Type get clientBaseType => ServiceB;
  @override
  Future<void> registerHostSide() async {
    $registerServiceBClientFactory();
    $registerServiceBMethodIds();
  }

  @override
  Future<void> initialize() async {
    $registerServiceBDispatcher();
    await super.initialize();
  }
}

void $registerServiceBLocalSide() {
  $registerServiceBDispatcher();
  $registerServiceBClientFactory();
  $registerServiceBMethodIds();
}

void $autoRegisterServiceBLocalSide() {
  LocalSideRegistry.register<ServiceB>($registerServiceBLocalSide);
}

final $_ServiceBLocalSideRegistered = (() {
  $autoRegisterServiceBLocalSide();
  return true;
})();

// Service client for ServiceC
class ServiceCClient extends ServiceC {
  ServiceCClient(this._proxy);
  final ServiceProxy<ServiceC> _proxy;
}

void $registerServiceCClientFactory() {
  GeneratedClientRegistry.register<ServiceC>(
    (proxy) => ServiceCClient(proxy),
  );
}

class _ServiceCMethods {}

Future<dynamic> _ServiceCDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as ServiceC;
  switch (methodId) {
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void $registerServiceCDispatcher() {
  GeneratedDispatcherRegistry.register<ServiceC>(
    _ServiceCDispatcher,
  );
}

void $registerServiceCMethodIds() {
  ServiceMethodIdRegistry.register<ServiceC>({});
}

void registerServiceCGenerated() {
  $registerServiceCClientFactory();
  $registerServiceCMethodIds();
}

// Local service implementation that auto-registers local side
class ServiceCImpl extends ServiceC {
  ServiceCImpl() {
    // 🚀 AUTO-REGISTRATION: Register local side when instance is created
    $registerServiceCLocalSide();
  }
}

void $registerServiceCLocalSide() {
  $registerServiceCDispatcher();
  $registerServiceCClientFactory();
  $registerServiceCMethodIds();
}

void $autoRegisterServiceCLocalSide() {
  LocalSideRegistry.register<ServiceC>($registerServiceCLocalSide);
}

final $_ServiceCLocalSideRegistered = (() {
  $autoRegisterServiceCLocalSide();
  return true;
})();

// Service client for Collector
class CollectorClient extends Collector {
  CollectorClient(this._proxy);
  final ServiceProxy<Collector> _proxy;
}

void $registerCollectorClientFactory() {
  GeneratedClientRegistry.register<Collector>(
    (proxy) => CollectorClient(proxy),
  );
}

class _CollectorMethods {}

Future<dynamic> _CollectorDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as Collector;
  switch (methodId) {
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void $registerCollectorDispatcher() {
  GeneratedDispatcherRegistry.register<Collector>(
    _CollectorDispatcher,
  );
}

void $registerCollectorMethodIds() {
  ServiceMethodIdRegistry.register<Collector>({});
}

void registerCollectorGenerated() {
  $registerCollectorClientFactory();
  $registerCollectorMethodIds();
}

// Local service implementation that auto-registers local side
class CollectorImpl extends Collector {
  CollectorImpl() {
    // 🚀 AUTO-REGISTRATION: Register local side when instance is created
    $registerCollectorLocalSide();
  }
}

void $registerCollectorLocalSide() {
  $registerCollectorDispatcher();
  $registerCollectorClientFactory();
  $registerCollectorMethodIds();
}

void $autoRegisterCollectorLocalSide() {
  LocalSideRegistry.register<Collector>($registerCollectorLocalSide);
}

final $_CollectorLocalSideRegistered = (() {
  $autoRegisterCollectorLocalSide();
  return true;
})();

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dependency_shutdown_order_test.dart';

// **************************************************************************
// ServiceGenerator (handwritten for test)
// **************************************************************************

// Service client for ServiceB
class ServiceBClient extends ServiceB {
  ServiceBClient(this._proxy);
  final ServiceProxy<ServiceB> _proxy;

  @override
  Future<String> id() async {
    return await _proxy.callMethod('id', [], namedArgs: {});
  }
}

void $registerServiceBClientFactory() {
  GeneratedClientRegistry.register<ServiceB>(
    (proxy) => ServiceBClient(proxy),
  );
}

class _ServiceBMethods {
  static const int id = 1;
}

Future<dynamic> _ServiceBDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  // no methods to dispatch in this test
  final s = service as ServiceB;
  switch (methodId) {
    case _ServiceBMethods.id:
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

class ServiceBImpl extends ServiceB {
  @override
  bool get isRemote => true;
  @override
  Type get clientBaseType => ServiceB;
  @override
  Future<void> registerHostSide() async {
    $registerServiceBClientFactory();
    ServiceMethodIdRegistry.register<ServiceB>({'id': _ServiceBMethods.id});
  }

  @override
  Future<void> initialize() async {
    $registerServiceBDispatcher();
    await super.initialize();
  }
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fanout_aggregation_demo_test.dart';

// **************************************************************************
// ServiceGenerator
// **************************************************************************

// Service client for PricingService
class PricingServiceClient extends PricingService {
  PricingServiceClient(this._proxy);
  final ServiceProxy<PricingService> _proxy;

  @override
  Future<double> getPrice(String sku) async {
    return await _proxy.callMethod('getPrice', [sku], namedArgs: {});
  }
}

void $registerPricingServiceClientFactory() {
  GeneratedClientRegistry.register<PricingService>(
    (proxy) => PricingServiceClient(proxy),
  );
}

class _PricingServiceMethods {
  static const int getPriceId = 1;
}

Future<dynamic> _PricingServiceDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as PricingService;
  switch (methodId) {
    case _PricingServiceMethods.getPriceId:
      return await s.getPrice(positionalArgs[0]);
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void $registerPricingServiceDispatcher() {
  GeneratedDispatcherRegistry.register<PricingService>(
    _PricingServiceDispatcher,
  );
}

void $registerPricingServiceMethodIds() {
  ServiceMethodIdRegistry.register<PricingService>({
    'getPrice': _PricingServiceMethods.getPriceId,
  });
}

void registerPricingServiceGenerated() {
  $registerPricingServiceClientFactory();
  $registerPricingServiceMethodIds();
}

// Worker implementation that auto-registers the dispatcher
class PricingServiceWorker extends PricingService {
  @override
  Type get clientBaseType => PricingService;
  @override
  Future<void> registerHostSide() async {
    $registerPricingServiceClientFactory();
    $registerPricingServiceMethodIds();
  }

  @override
  Future<void> initialize() async {
    $registerPricingServiceDispatcher();
    await super.initialize();
  }
}

void $registerPricingServiceLocalSide() {
  $registerPricingServiceDispatcher();
  $registerPricingServiceClientFactory();
  $registerPricingServiceMethodIds();
}

// Service client for InventoryService
class InventoryServiceClient extends InventoryService {
  InventoryServiceClient(this._proxy);
  final ServiceProxy<InventoryService> _proxy;

  @override
  Future<int> getStock(String sku) async {
    return await _proxy.callMethod('getStock', [sku], namedArgs: {});
  }
}

void $registerInventoryServiceClientFactory() {
  GeneratedClientRegistry.register<InventoryService>(
    (proxy) => InventoryServiceClient(proxy),
  );
}

class _InventoryServiceMethods {
  static const int getStockId = 1;
}

Future<dynamic> _InventoryServiceDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as InventoryService;
  switch (methodId) {
    case _InventoryServiceMethods.getStockId:
      return await s.getStock(positionalArgs[0]);
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void $registerInventoryServiceDispatcher() {
  GeneratedDispatcherRegistry.register<InventoryService>(
    _InventoryServiceDispatcher,
  );
}

void $registerInventoryServiceMethodIds() {
  ServiceMethodIdRegistry.register<InventoryService>({
    'getStock': _InventoryServiceMethods.getStockId,
  });
}

void registerInventoryServiceGenerated() {
  $registerInventoryServiceClientFactory();
  $registerInventoryServiceMethodIds();
}

// Worker implementation that auto-registers the dispatcher
class InventoryServiceWorker extends InventoryService {
  @override
  Type get clientBaseType => InventoryService;
  @override
  Future<void> registerHostSide() async {
    $registerInventoryServiceClientFactory();
    $registerInventoryServiceMethodIds();
  }

  @override
  Future<void> initialize() async {
    $registerInventoryServiceDispatcher();
    await super.initialize();
  }
}

void $registerInventoryServiceLocalSide() {
  $registerInventoryServiceDispatcher();
  $registerInventoryServiceClientFactory();
  $registerInventoryServiceMethodIds();
}

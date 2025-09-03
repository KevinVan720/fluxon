// GENERATED CODE - DO NOT MODIFY BY HAND

part of '07_fanout_aggregation_demo.dart';

// **************************************************************************
// ServiceGenerator
// **************************************************************************

// Service client for PricingService
class PricingServiceClient extends PricingService {
  PricingServiceClient(this._proxy);
  final ServiceProxy<PricingService> _proxy;

  @override
  Future<double> priceOf(String sku, {required String region}) async {
    return await _proxy
        .callMethod('priceOf', [sku], namedArgs: {'region': region});
  }
}

void _registerPricingServiceClientFactory() {
  GeneratedClientRegistry.register<PricingService>(
    (proxy) => PricingServiceClient(proxy),
  );
}

class _PricingServiceMethods {
  static const int priceOfId = 1;
}

Future<dynamic> _PricingServiceDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as PricingService;
  switch (methodId) {
    case _PricingServiceMethods.priceOfId:
      return await s.priceOf(positionalArgs[0], region: namedArgs['region']);
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void _registerPricingServiceDispatcher() {
  GeneratedDispatcherRegistry.register<PricingService>(
    _PricingServiceDispatcher,
  );
}

void _registerPricingServiceMethodIds() {
  ServiceMethodIdRegistry.register<PricingService>({
    'priceOf': _PricingServiceMethods.priceOfId,
  });
}

void registerPricingServiceGenerated() {
  _registerPricingServiceClientFactory();
  _registerPricingServiceMethodIds();
}

// Service client for InventoryService
class InventoryServiceClient extends InventoryService {
  InventoryServiceClient(this._proxy);
  final ServiceProxy<InventoryService> _proxy;

  @override
  Future<int> stockOf(String sku, {required String warehouse}) async {
    return await _proxy
        .callMethod('stockOf', [sku], namedArgs: {'warehouse': warehouse});
  }
}

void _registerInventoryServiceClientFactory() {
  GeneratedClientRegistry.register<InventoryService>(
    (proxy) => InventoryServiceClient(proxy),
  );
}

class _InventoryServiceMethods {
  static const int stockOfId = 1;
}

Future<dynamic> _InventoryServiceDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as InventoryService;
  switch (methodId) {
    case _InventoryServiceMethods.stockOfId:
      return await s.stockOf(positionalArgs[0],
          warehouse: namedArgs['warehouse']);
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void _registerInventoryServiceDispatcher() {
  GeneratedDispatcherRegistry.register<InventoryService>(
    _InventoryServiceDispatcher,
  );
}

void _registerInventoryServiceMethodIds() {
  ServiceMethodIdRegistry.register<InventoryService>({
    'stockOf': _InventoryServiceMethods.stockOfId,
  });
}

void registerInventoryServiceGenerated() {
  _registerInventoryServiceClientFactory();
  _registerInventoryServiceMethodIds();
}

import 'package:dart_service_framework/dart_service_framework.dart';

part '07_fanout_aggregation_demo.g.dart';

@ServiceContract(remote: true)
abstract class PricingService extends BaseService {
  Future<double> priceOf(String sku, {required String region});
}

@ServiceContract(remote: true)
abstract class InventoryService extends BaseService {
  Future<int> stockOf(String sku, {required String warehouse});
}

class PricingServiceImpl extends PricingService {
  @override
  Future<void> initialize() async {
    _registerPricingServiceDispatcher();
  }

  @override
  Future<double> priceOf(String sku, {required String region}) async {
    // pretend: region-based price
    final base = sku.hashCode.abs() % 100;
    return base + (region.hashCode.abs() % 5);
  }
}

class InventoryServiceImpl extends InventoryService {
  @override
  Future<void> initialize() async {
    _registerInventoryServiceDispatcher();
  }

  @override
  Future<int> stockOf(String sku, {required String warehouse}) async {
    // pretend: warehouse-based stock
    return (sku.hashCode.abs() % 50) + (warehouse.hashCode.abs() % 10);
  }
}

class Aggregator extends BaseService with ServiceClientMixin {
  @override
  List<Type> get optionalDependencies => [PricingService, InventoryService];

  Future<Map<String, dynamic>> getOffer(String sku) async {
    ensureInitialized();
    final pricing = getService<PricingService>();
    final inventory = getService<InventoryService>();
    final priceF = pricing.priceOf(sku, region: 'US');
    final stockF = inventory.stockOf(sku, warehouse: 'W1');
    final results = await Future.wait([priceF, stockF]);
    return {'sku': sku, 'price': results[0], 'stock': results[1]};
  }
}

Future<void> main() async {
  final locator = EnhancedServiceLocator();
  try {
    locator.register<Aggregator>(() => Aggregator());
    await locator.registerWorkerServiceProxy<PricingService>(
      serviceName: 'PricingService',
      serviceFactory: () => PricingServiceImpl(),
      registerGenerated: registerPricingServiceGenerated,
    );
    await locator.registerWorkerServiceProxy<InventoryService>(
      serviceName: 'InventoryService',
      serviceFactory: () => InventoryServiceImpl(),
      registerGenerated: registerInventoryServiceGenerated,
    );
    await locator.initializeAll();

    final agg = locator.get<Aggregator>();
    final offer = await agg.getOffer('SKU-123');
    print(
        'Offer: sku=${offer['sku']} price=${offer['price']} stock=${offer['stock']}');
  } finally {
    await locator.destroyAll();
  }
}

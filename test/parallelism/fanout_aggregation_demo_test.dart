import 'package:test/test.dart';
import 'package:dart_service_framework/dart_service_framework.dart';

part 'fanout_aggregation_demo_test.g.dart';

@ServiceContract(remote: true)
abstract class PricingService extends BaseService {
  Future<double> getPrice(String sku);
}

@ServiceContract(remote: true)
abstract class InventoryService extends BaseService {
  Future<int> getStock(String sku);
}

class Aggregator extends BaseService with ServiceClientMixin {
  @override
  List<Type> get optionalDependencies => [PricingService, InventoryService];

  Future<String> getOffer(String sku) async {
    final pricing = getService<PricingService>();
    final inventory = getService<InventoryService>();
    final results = await Future.wait([
      pricing.getPrice(sku),
      inventory.getStock(sku),
    ]);
    final price = results[0] as double;
    final stock = results[1] as int;
    return 'Offer for $sku: price=\$${price.toStringAsFixed(2)}, stock=$stock';
  }
}

class PricingServiceImpl extends PricingService {
  @override
  Future<void> initialize() async {
    _registerPricingServiceDispatcher();
  }

  @override
  Future<double> getPrice(String sku) async => 19.99;
}

class InventoryServiceImpl extends InventoryService {
  @override
  Future<void> initialize() async {
    _registerInventoryServiceDispatcher();
  }

  @override
  Future<int> getStock(String sku) async => 42;
}

Future<void> _runFanoutaggregationdemoDemo() async {
  final locator = ServiceLocator();
  
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

    await locator.destroyAll();
}

void main() {
  group('Fanout Aggregation Demo', () {
    test('runs fanout aggregation demo successfully', () async {
      await _runFanoutaggregationdemoDemo();
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}

import 'package:dart_service_framework/dart_service_framework.dart';

part '04_cross_isolate_calls_demo.g.dart';

@ServiceContract(remote: true)
abstract class ServiceA extends BaseService {
  Future<int> incThenDouble(int x);
  Future<int> increment(int x);
}

@ServiceContract(remote: true)
abstract class ServiceB extends BaseService {
  Future<int> doubleThenInc(int x);
  Future<int> doubleIt(int x);
}

class ServiceAImpl extends ServiceA with ServiceClientMixin {
  @override
  Future<void> initialize() async {
    logger.info('ServiceAImpl initialized');
    // Register dispatcher for A in the worker isolate
    _registerServiceADispatcher();
    // Register client factory for B in worker so A can call B via bridge
    _registerServiceBClientFactory();
  }

  @override
  Future<int> incThenDouble(int x) async {
    final b = getService<ServiceB>();
    final y = await b.doubleIt(x + 1);
    return y;
  }

  @override
  Future<int> increment(int x) async => x + 1;
}

class ServiceBImpl extends ServiceB with ServiceClientMixin {
  @override
  Future<void> initialize() async {
    logger.info('ServiceBImpl initialized');
    // Register dispatcher for B in the worker isolate
    _registerServiceBDispatcher();
    // Register client factory for A in worker so B can call A via bridge
    _registerServiceAClientFactory();
  }

  @override
  Future<int> doubleThenInc(int x) async {
    final a = getService<ServiceA>();
    final y = await a.increment(x * 2);
    return y;
  }

  @override
  Future<int> doubleIt(int x) async => x * 2;
}

class Orchestrator extends BaseService with ServiceClientMixin {
  @override
  List<Type> get dependencies => const [];

  @override
  List<Type> get optionalDependencies => [ServiceA, ServiceB];

  Future<Map<String, int>> runScenario(int x) async {
    ensureInitialized();
    final a = getService<ServiceA>();
    final b = getService<ServiceB>();
    final r1 = await a.incThenDouble(x);
    final r2 = await b.doubleThenInc(x);
    return {'A.incThenDouble': r1, 'B.doubleThenInc': r2};
  }
}

Future<void> main() async {
  final locator = EnhancedServiceLocator();
  try {
    // Register generated clients & method IDs in host
    _registerServiceAClientFactory();
    _registerServiceAMethodIds();
    _registerServiceBClientFactory();
    _registerServiceBMethodIds();

    // Local orchestrator
    locator.register<Orchestrator>(() => Orchestrator());

    // Worker-backed services
    await locator.registerWorkerServiceProxy<ServiceA>(
      serviceName: 'ServiceA',
      serviceFactory: () => ServiceAImpl(),
    );
    await locator.registerWorkerServiceProxy<ServiceB>(
      serviceName: 'ServiceB',
      serviceFactory: () => ServiceBImpl(),
    );

    await locator.initializeAll();

    final orchestration = locator.get<Orchestrator>();
    final results = await orchestration.runScenario(10);
    print('Results: A.incThenDouble(10) => ${results['A.incThenDouble']}, '
        'B.doubleThenInc(10) => ${results['B.doubleThenInc']}');
  } finally {
    await locator.destroyAll();
  }
}

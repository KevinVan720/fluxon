import 'package:dart_service_framework/dart_service_framework.dart';

part 'cross_isolate_calls_demo.g.dart';

@ServiceContract(remote: true)
abstract class ServiceA extends BaseService {
  Future<int> increment(int x);
}

@ServiceContract(remote: true)
abstract class ServiceB extends BaseService {
  Future<int> doubleIt(int x);
}

class Orchestrator extends BaseService with ServiceClientMixin {
  @override
  List<Type> get optionalDependencies => [ServiceA, ServiceB];

  Future<int> run(int x) async {
    final a = getService<ServiceA>();
    final b = getService<ServiceB>();
    final inc = await a.increment(x);
    return await b.doubleIt(inc);
  }
}

class ServiceAImpl extends ServiceA with ServiceClientMixin {
  @override
  List<Type> get optionalDependencies => [ServiceB];

  @override
  Future<void> initialize() async {
    _registerServiceADispatcher();
    // Register client factory for ServiceB inside worker so A can call B via bridge
    _registerServiceBClientFactory();
  }

  @override
  Future<int> increment(int x) async {
    final b = getService<ServiceB>();
    return await b.doubleIt(x + 1);
  }
}

class ServiceBImpl extends ServiceB with ServiceClientMixin {
  @override
  List<Type> get optionalDependencies => [ServiceA];

  @override
  Future<void> initialize() async {
    _registerServiceBDispatcher();
    // Register client factory for ServiceA inside worker so B can call A via bridge
    _registerServiceAClientFactory();
  }

  @override
  Future<int> doubleIt(int x) async => x * 2;
}

Future<void> main() async {
  final locator = ServiceLocator();
  try {
    locator.register<Orchestrator>(() => Orchestrator());

    await locator.registerWorkerServiceProxy<ServiceA>(
      serviceName: 'ServiceA',
      serviceFactory: () => ServiceAImpl(),
      registerGenerated: registerServiceAGenerated,
    );
    await locator.registerWorkerServiceProxy<ServiceB>(
      serviceName: 'ServiceB',
      serviceFactory: () => ServiceBImpl(),
      registerGenerated: registerServiceBGenerated,
    );

    await locator.initializeAll();

    final orch = locator.get<Orchestrator>();
    final result = await orch.run(10);
    print('Result: $result');
  } finally {
    await locator.destroyAll();
  }
}

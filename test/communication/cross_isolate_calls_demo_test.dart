import 'package:test/test.dart';
import 'package:dart_service_framework/dart_service_framework.dart';

part 'cross_isolate_calls_demo_test.g.dart';

// 🚀 SINGLE CLASS: No interface needed!
@ServiceContract(remote: true)
class ServiceA extends FluxService {
  @override
  List<Type> get optionalDependencies => [ServiceB];

  @override
  Future<void> initialize() async {
    // 🚀 FLUX: Worker class will register dispatcher automatically
    _registerServiceBClientFactory();
    await super.initialize();
  }

  Future<int> increment(int x) async {
    // This demonstrates a worker service calling another worker service
    final b = getService<ServiceB>();
    final doubled = await b.doubleIt(x);
    return doubled + 1; // double the input, then add 1
  }
}

// 🚀 SINGLE CLASS: No interface needed!
@ServiceContract(remote: true)
class ServiceB extends FluxService {
  @override
  List<Type> get optionalDependencies => [ServiceA];

  @override
  Future<void> initialize() async {
    // 🚀 FLUX: Worker class will register dispatcher automatically
    _registerServiceAClientFactory();
    await super.initialize();
  }

  Future<int> doubleIt(int x) async => x * 2;
}

// 🚀 SINGLE CLASS: Local orchestrator
class Orchestrator extends FluxService {
  @override
  List<Type> get optionalDependencies => [ServiceA, ServiceB];

  Future<int> run(int x) async {
    final a = getService<ServiceA>();
    final b = getService<ServiceB>();
    final inc = await a.increment(x);
    return await b.doubleIt(inc);
  }
}

Future<void> _runCrossisolatecallsdemoDemo() async {
  final locator = ServiceLocator();

  locator.register<Orchestrator>(() => Orchestrator());

  // 🚀 SINGLE CLASS: Same class for interface and implementation!
  await locator.registerWorkerServiceProxy<ServiceA>(
    serviceName: 'ServiceA',
    serviceFactory: () => ServiceAWorker(),
    registerGenerated: registerServiceAGenerated,
  );
  await locator.registerWorkerServiceProxy<ServiceB>(
    serviceName: 'ServiceB',
    serviceFactory: () => ServiceBWorker(),
    registerGenerated: registerServiceBGenerated,
  );

  await locator.initializeAll();

  final orch = locator.get<Orchestrator>();
  final result = await orch.run(10);
  expect(result,
      equals(42)); // 10 -> doubleIt(10) = 20, 20+1 = 21 -> doubleIt(21) = 42

  await locator.destroyAll();
}

void main() {
  group('Cross Isolate Calls Demo', () {
    test('runs cross isolate calls demo successfully', () async {
      await _runCrossisolatecallsdemoDemo();
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}

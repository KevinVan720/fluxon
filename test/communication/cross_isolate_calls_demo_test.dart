import 'package:flux/flux.dart';
import 'package:test/test.dart';

part 'cross_isolate_calls_demo_test.g.dart';

// 🚀 SINGLE CLASS: No interface needed!
@ServiceContract(remote: true)
class ServiceA extends FluxService {
  @override
  List<Type> get optionalDependencies => [ServiceB];

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
    return b.doubleIt(inc);
  }
}

Future<void> _runCrossisolatecallsdemoDemo() async {
  final locator = FluxRuntime();

  locator.register<Orchestrator>(Orchestrator.new);

  // 🚀 SIMPLE API: same register() for local and remote (worker auto-detected)
  locator.register<ServiceA>(ServiceAImpl.new);
  locator.register<ServiceB>(ServiceBImpl.new);

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

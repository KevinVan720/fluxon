import 'package:test/test.dart';
import 'package:dart_service_framework/dart_service_framework.dart';
// no direct import needed; generated file uses ServiceMethodIdRegistry from the package

part 'isolate_codegen_demo_test.g.dart';

@ServiceContract(remote: true)
abstract class MathService extends BaseService {
  Future<int> add(int a, int b);
}

class MathServiceImpl extends MathService {
  @override
  Future<void> initialize() async {
    _registerMathServiceDispatcher();
  }

  @override
  Future<int> add(int a, int b) async => a + b;
}

Future<void> _runIsolateCodegenDemo() async {
  final locator = ServiceLocator();

  await locator.registerWorkerServiceProxy<MathService>(
    serviceName: 'MathService',
    serviceFactory: () => MathServiceImpl(),
    registerGenerated: registerMathServiceGenerated,
  );

  await locator.initializeAll();

  final math = locator.proxyRegistry.getProxy<MathService>();
  final result = await math.callMethod<int>('add', [3, 4]);
  expect(result, equals(7));

  await locator.destroyAll();
}

void main() {
  group('Isolate Codegen Demo', () {
    test('runs isolate codegen demo successfully', () async {
      await _runIsolateCodegenDemo();
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}

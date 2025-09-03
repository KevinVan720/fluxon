import 'package:dart_service_framework/dart_service_framework.dart';
// no direct import needed; generated file uses ServiceMethodIdRegistry from the package

part 'isolate_codegen_demo.g.dart';

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

Future<void> main() async {
  final locator = ServiceLocator();
  try {
    await locator.registerWorkerServiceProxy<MathService>(
      serviceName: 'MathService',
      serviceFactory: () => MathServiceImpl(),
      registerGenerated: registerMathServiceGenerated,
    );

    await locator.initializeAll();

    final math = locator.proxyRegistry.getProxy<MathService>();
    final result = await math.callMethod<int>('add', [3, 4]);
    print('3 + 4 = $result');
  } finally {
    await locator.destroyAll();
  }
}

import 'package:dart_service_framework/dart_service_framework.dart';
// no direct import needed; generated file uses ServiceMethodIdRegistry from the package

part 'phase3_demo.g.dart';

@ServiceContract(remote: true)
abstract class MathService extends BaseService {
  Future<int> add(int a, int b);
}

class MathServiceImpl extends MathService {
  @override
  Future<void> initialize() async {
    logger.info('MathServiceImpl initialized');
    // Ensure dispatcher is registered in the worker isolate
    _registerMathServiceDispatcher();
  }

  @override
  Future<int> add(int a, int b) async => a + b;
}

class ApiGateway extends BaseService with ServiceClientMixin {
  @override
  List<Type> get dependencies => const [];

  @override
  List<Type> get optionalDependencies => [MathService];

  Future<int> computeSum(int a, int b) async {
    ensureInitialized();
    if (!hasService<MathService>()) {
      throw Exception('MathService not available');
    }
    final math = getService<MathService>();
    return await math.add(a, b);
  }
}

Future<void> main() async {
  final locator = EnhancedServiceLocator();

  try {
    _registerMathServiceClientFactory();
    _registerMathServiceDispatcher();
    _registerMathServiceMethodIds();
    // Register a local caller service
    locator.register<ApiGateway>(() => ApiGateway());

    // Register a worker proxy for MathService
    await locator.registerWorkerServiceProxy<MathService>(
      serviceName: 'MathService',
      serviceFactory: () => MathServiceImpl(),
    );

    await locator.initializeAll();

    final api = locator.get<ApiGateway>();
    final result = await api.computeSum(2, 3);
    print('2 + 3 = $result');
  } finally {
    await locator.destroyAll();
  }
}

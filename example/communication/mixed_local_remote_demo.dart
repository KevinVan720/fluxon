import 'package:dart_service_framework/dart_service_framework.dart';

part 'mixed_local_remote_demo.g.dart';

@ServiceContract(remote: true)
abstract class RemoteMath extends BaseService {
  Future<int> mul(int a, int b);
  Future<int> addViaLocal(int a, int b);
}

@ServiceContract(remote: false)
class LocalAdder extends BaseService {
  @override
  Future<void> initialize() async {
    _registerLocalAdderDispatcher();
  }

  Future<int> add(int a, int b) async => a + b;
}

class RemoteMathImpl extends RemoteMath with ServiceClientMixin {
  @override
  List<Type> get optionalDependencies => [LocalAdder];

  @override
  Future<void> initialize() async {
    _registerRemoteMathDispatcher();
    // Worker needs LocalAdder client factory to call host via bridge
    _registerLocalAdderClientFactory();
  }

  @override
  Future<int> mul(int a, int b) async => a * b;

  @override
  Future<int> addViaLocal(int a, int b) async {
    // Remote (worker) service calling a local service via bridge
    final adder = getService<LocalAdder>();
    return await adder.add(a, b);
  }
}

class LocalGateway extends BaseService with ServiceClientMixin {
  @override
  List<Type> get optionalDependencies => [RemoteMath, LocalAdder];

  Future<int> mixedCompute(int a, int b) async {
    ensureInitialized();
    final math = getService<RemoteMath>();
    final local = getService<LocalAdder>();
    final p1 = math.mul(a, b); // remote
    final p2 = local.add(a, b); // local
    final r = await Future.wait([p1, p2]);
    return (r[0] as int) + (r[1] as int);
  }

  Future<int> remoteAddViaLocal(int a, int b) async {
    ensureInitialized();
    final math = getService<RemoteMath>();
    return await math.addViaLocal(a, b);
  }
}

Future<void> main() async {
  final locator = ServiceLocator();
  try {
    // Local services
    locator.register<LocalAdder>(() => LocalAdder());
    locator.register<LocalGateway>(() => LocalGateway());

    // Remote service
    await locator.registerWorkerServiceProxy<RemoteMath>(
      serviceName: 'RemoteMath',
      serviceFactory: () => RemoteMathImpl(),
      registerGenerated: registerRemoteMathGenerated,
    );

    // Host-side registration for local service method IDs
    registerLocalAdderGenerated();

    await locator.initializeAll();

    final gw = locator.get<LocalGateway>();
    final results = await Future.wait([
      gw.mixedCompute(6, 7),
      gw.remoteAddViaLocal(20, 22),
    ]);
    print('Mixed result (6*7 + 6+7) = ${results[0]}');
    print('Remote calling local add(20,22) => ${results[1]}');
  } finally {
    await locator.destroyAll();
  }
}

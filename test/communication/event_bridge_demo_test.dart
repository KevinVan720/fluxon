import 'package:test/test.dart';
import 'package:dart_service_framework/dart_service_framework.dart';

part 'event_bridge_demo_test.g.dart';

@ServiceContract(remote: true)
abstract class RemoteEmitter extends BaseService {
  Future<void> emitTick(String id);
}

@ServiceContract(remote: true)
abstract class RemoteListener extends BaseService {
  Future<void> onTick(String id);
  Future<int> count();
}

@ServiceContract(remote: false)
class LocalHub extends BaseService {
  int _ticks = 0;

  @override
  Future<void> initialize() async {
    _registerLocalHubDispatcher();
  }

  Future<void> onTick(String id) async {
    _ticks++;
    logger.info('Hub received tick', metadata: {'id': id, 'ticks': _ticks});
  }
}

class RemoteEmitterImpl extends RemoteEmitter with ServiceClientMixin {
  @override
  List<Type> get optionalDependencies => [LocalHub, RemoteListener];

  @override
  Future<void> initialize() async {
    _registerRemoteEmitterDispatcher();
    // Worker needs LocalHub client factory to call host hub via bridge
    _registerLocalHubClientFactory();
    // Worker also needs RemoteListener client to call another worker via host bridge
    _registerRemoteListenerClientFactory();
  }

  @override
  Future<void> emitTick(String id) async {
    // Call host-local hub
    final hub = getService<LocalHub>();
    await hub.onTick(id);

    // Call remote listener in another worker
    final listener = getService<RemoteListener>();
    await listener.onTick(id);
  }
}

class RemoteListenerImpl extends RemoteListener {
  int _count = 0;

  @override
  Future<void> initialize() async {
    _registerRemoteListenerDispatcher();
  }

  @override
  Future<void> onTick(String id) async {
    _count++;
    logger.info('Listener saw tick', metadata: {'id': id, 'count': _count});
  }

  @override
  Future<int> count() async => _count;
}

class Orchestrator extends BaseService with ServiceClientMixin {
  @override
  List<Type> get optionalDependencies => [RemoteEmitter, RemoteListener];

  Future<int> run() async {
    ensureInitialized();
    final emitter = getService<RemoteEmitter>();
    final listener = getService<RemoteListener>();
    await emitter.emitTick('tick-1');
    await emitter.emitTick('tick-2');
    return await listener.count();
  }
}

Future<void> _runEventbridgedemoDemo() async {
  final locator = ServiceLocator();
  
    // Local hub must register IDs for host-side dispatch
    registerLocalHubGenerated();
    locator.register<LocalHub>(() => LocalHub());
    locator.register<Orchestrator>(() => Orchestrator());

    await locator.registerWorkerServiceProxy<RemoteListener>(
      serviceName: 'RemoteListener',
      serviceFactory: () => RemoteListenerImpl(),
      registerGenerated: registerRemoteListenerGenerated,
    );
    await locator.registerWorkerServiceProxy<RemoteEmitter>(
      serviceName: 'RemoteEmitter',
      serviceFactory: () => RemoteEmitterImpl(),
      registerGenerated: registerRemoteEmitterGenerated,
    );

    await locator.initializeAll();

    final orchestrator = locator.get<Orchestrator>();
    final count = await orchestrator.run();

    await locator.destroyAll();
}

void main() {
  group('Event Bridge Demo', () {
    test('runs event bridge demo successfully', () async {
      await _runEventbridgedemoDemo();
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}

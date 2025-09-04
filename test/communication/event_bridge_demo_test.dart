import 'package:dart_service_framework/dart_service_framework.dart';
import 'package:test/test.dart';

part 'event_bridge_demo_test.g.dart';

// 🚀 SINGLE CLASS: Remote emitter service
@ServiceContract(remote: true)
class RemoteEmitter extends FluxService {
  @override
  List<Type> get optionalDependencies => [LocalHub, RemoteListener];

  @override
  Future<void> initialize() async {
    // 🚀 FLUX: Worker class will register dispatcher automatically
    _registerLocalHubClientFactory();
    _registerRemoteListenerClientFactory();
    await super.initialize();
  }

  Future<void> emitTick(String id) async {
    // Call host-local hub
    final hub = getService<LocalHub>();
    await hub.onTick(id);

    // Call remote listener in another worker
    final listener = getService<RemoteListener>();
    await listener.onTick(id);
  }
}

// 🚀 SINGLE CLASS: Remote listener service
@ServiceContract(remote: true)
class RemoteListener extends FluxService {
  int _count = 0;

  @override
  Future<void> initialize() async {
    // 🚀 FLUX: Worker class will register dispatcher automatically
    await super.initialize();
  }

  Future<void> onTick(String id) async {
    _count++;
    logger.info('Listener saw tick', metadata: {'id': id, 'count': _count});
  }

  Future<int> count() async => _count;
}

// 🚀 SINGLE CLASS: Local hub service (stays in main isolate)
@ServiceContract(remote: false)
class LocalHub extends FluxService {
  int _ticks = 0;

  @override
  Future<void> initialize() async {
    // 🚀 FLUX: Minimal boilerplate for local service
    _registerLocalHubDispatcher();
    await super.initialize();
  }

  Future<void> onTick(String id) async {
    _ticks++;
    logger.info('Hub received tick', metadata: {'id': id, 'ticks': _ticks});
  }

  Future<int> getTicks() async => _ticks;
}

// 🚀 SINGLE CLASS: Implementation moved into main classes above

// 🚀 SINGLE CLASS: Local orchestrator
class Orchestrator extends FluxService {
  @override
  List<Type> get optionalDependencies => [RemoteEmitter, RemoteListener];

  Future<int> run() async {
    ensureInitialized();
    final emitter = getService<RemoteEmitter>();
    final listener = getService<RemoteListener>();
    await emitter.emitTick('tick-1');
    await emitter.emitTick('tick-2');
    return listener.count();
  }
}

Future<void> _runEventbridgedemoDemo() async {
  final locator = ServiceLocator();

  // 🚀 WORKER-TO-MAIN: LocalHub stays local, workers call it via bridge
  registerLocalHubGenerated();
  locator.register<LocalHub>(LocalHub.new);
  locator.register<Orchestrator>(Orchestrator.new);
  locator.register<RemoteListener>(RemoteListenerWorker.new);
  locator.register<RemoteEmitter>(RemoteEmitterWorker.new);

  await locator.initializeAll();

  final orchestrator = locator.get<Orchestrator>();
  await orchestrator.run();

  await locator.destroyAll();
}

void main() {
  group('Event Bridge Demo', () {
    test('runs event bridge demo successfully', () async {
      await _runEventbridgedemoDemo();
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}

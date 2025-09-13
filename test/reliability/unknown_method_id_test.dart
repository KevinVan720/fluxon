import 'package:fluxon/fluxon.dart';
import 'package:test/test.dart';

part 'unknown_method_id_test.g.dart';

@ServiceContract(remote: true)
class IdMissingService extends FluxonService {
  Future<String> doWork(String x) async => 'ok:$x';
}

void main() {
  group('Unknown method id / dispatcher path', () {
    late FluxonRuntime runtime;

    setUp(() {
      runtime = FluxonRuntime();
    });

    tearDown(() async {
      await runtime.destroyAll();
    });

    test('host throws when method id not registered for client', () async {
      // Note: Impl registers client factory but NOT method ids
      runtime.register<IdMissingService>(IdMissingServiceImpl.new);
      await runtime.initializeAll();

      // Ensure the client-side method IDs are NOT registered to simulate the error path
      ServiceMethodIdRegistry.register<IdMissingService>({});

      final svc = runtime.get<IdMissingService>();
      expect(
        () => svc.doWork('x'),
        throwsA(isA<ServiceException>()),
      );
    });
  });
}

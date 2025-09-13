import 'package:fluxon/fluxon.dart';
import 'package:test/test.dart';

part 'reregister_after_destroy_test.g.dart';

@ServiceContract(remote: true)
class SimpleWorker extends FluxonService {
  Future<int> add(int a, int b) async => a + b;
}

void main() {
  group('Re-register after destroy', () {
    test('runtime can re-initialize remote services cleanly', () async {
      var runtime = FluxonRuntime();
      runtime.register<SimpleWorker>(SimpleWorkerImpl.new);
      await runtime.initializeAll();
      final w1 = runtime.get<SimpleWorker>();
      expect(await w1.add(1, 2), equals(3));

      await runtime.destroyAll();
      expect(runtime.isInitialized, isFalse);

      // Rebuild fresh runtime and re-register
      runtime = FluxonRuntime();
      runtime.register<SimpleWorker>(SimpleWorkerImpl.new);
      await runtime.initializeAll();
      final w2 = runtime.get<SimpleWorker>();
      expect(await w2.add(2, 3), equals(5));
    });
  });
}

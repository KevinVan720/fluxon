import 'package:flux/flux.dart';
import 'package:test/test.dart';

part 'worker_crash_recovery_test.g.dart';

@ServiceContract(remote: true)
class CrashyService extends FluxService {
  Future<void> boom() async {
    throw StateError('crash');
  }

  Future<String> ok() async => 'ok';
}

void main() {
  group('Worker crash/recovery path', () {
    test('method throws, then runtime can restart cleanly', () async {
      final runtime = FluxRuntime();
      runtime.register<CrashyService>(CrashyServiceImpl.new);
      await runtime.initializeAll();

      final svc = runtime.get<CrashyService>();
      expect(() => svc.boom(), throwsA(isA<ServiceRetryExceededException>()));

      await runtime.destroyAll();
      expect(runtime.isInitialized, isFalse);

      final runtime2 = FluxRuntime();
      runtime2.register<CrashyService>(CrashyServiceImpl.new);
      await runtime2.initializeAll();
      final svc2 = runtime2.get<CrashyService>();
      expect(await svc2.ok(), 'ok');
      await runtime2.destroyAll();
    });
  });
}

import 'package:flux/flux.dart';
import 'package:test/test.dart';

part 'per_call_timeout_override_test.g.dart';

@ServiceContract(remote: true)
class SleeperService extends FluxService {
  Future<String> snooze(Duration d) async {
    await Future.delayed(d);
    return 'done';
  }
}

void main() {
  group('Per-call timeout override', () {
    test('tight timeout fails; relaxed timeout succeeds', () async {
      final runtime = FluxRuntime();
      runtime.register<SleeperService>(SleeperServiceImpl.new);
      await runtime.initializeAll();

      final svc = runtime.get<SleeperService>() as SleeperServiceClient;

      // Tight timeout should fail
      expect(
        () => svc.snoozeWithOptions(const Duration(milliseconds: 300),
            const ServiceCallOptions(timeout: Duration(milliseconds: 50))),
        throwsA(isA<ServiceTimeoutException>()),
      );

      // Relaxed timeout should succeed
      final ok = await svc.snoozeWithOptions(const Duration(milliseconds: 200),
          const ServiceCallOptions(timeout: Duration(milliseconds: 500)));
      expect(ok, equals('done'));

      await runtime.destroyAll();
    });
  });
}

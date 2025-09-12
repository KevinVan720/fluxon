import 'package:fluxon/flux.dart';
import 'package:test/test.dart';

part 'proxy_lifecycle_after_teardown_test.g.dart';

@ServiceContract(remote: true)
class EchoService extends FluxService {
  Future<String> echo(String v) async => v;
}

void main() {
  group('Proxy lifecycle after teardown', () {
    test('proxy errors after destroy and works after re-init', () async {
      final runtime = FluxRuntime();
      runtime.register<EchoService>(EchoServiceImpl.new);
      await runtime.initializeAll();

      final svc = runtime.get<EchoService>();
      expect(await svc.echo('hi'), 'hi');

      await runtime.destroyAll();
      expect(runtime.isInitialized, isFalse);

      // Old proxy should now fail on calls
      expect(
        () => svc.echo('boom'),
        throwsA(isA<ServiceException>()),
      );

      // New runtime and service should work
      final runtime2 = FluxRuntime();
      runtime2.register<EchoService>(EchoServiceImpl.new);
      await runtime2.initializeAll();
      final svc2 = runtime2.get<EchoService>();
      expect(await svc2.echo('ok'), 'ok');

      await runtime2.destroyAll();
    });
  });
}

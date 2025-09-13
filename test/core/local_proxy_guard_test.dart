import 'package:fluxon/fluxon.dart';
import 'package:test/test.dart';

part 'local_proxy_guard_test.g.dart';

@ServiceContract(remote: false)
class GuardTestService extends FluxService {
  Future<String> greet() async => 'hello';
}

void main() {
  group('LocalServiceProxy name-based guard', () {
    late FluxRuntime runtime;

    setUp(() async {
      runtime = FluxRuntime();
      runtime.register<GuardTestService>(() => GuardTestServiceImpl());
      await runtime.initializeAll();
    });

    tearDown(() async {
      await runtime.destroyAll();
    });

    test('callMethod throws on LocalServiceProxy', () async {
      final proxy = runtime.proxyRegistry.getProxy<GuardTestService>();
      expect(
        () => proxy.callMethod<String>('greet', const []),
        throwsA(isA<ServiceException>()),
      );
    });

    test('direct instance path still works', () async {
      final svc = runtime.get<GuardTestService>();
      final result = await svc.greet();
      expect(result, 'hello');
    });
  });
}

import 'package:fluxon/fluxon.dart';
import 'package:test/test.dart';

part 'proxy_registry_test.g.dart';

@ServiceContract(remote: false)
class StatsService extends FluxonService {
  Future<String> ping() async => 'pong';
}

void main() {
  group('ServiceProxyRegistry lifecycle', () {
    late FluxonRuntime runtime;

    setUp(() async {
      runtime = FluxonRuntime();
      runtime.register<StatsService>(() => StatsServiceImpl());
      await runtime.initializeAll();
    });

    tearDown(() async {
      await runtime.destroyAll();
    });

    test('getStatistics reflects registered proxies and disconnectAll clears',
        () async {
      final before = runtime.proxyRegistry.getStatistics();
      expect(before.containsKey('StatsService'), isTrue);
      expect(before['StatsService']['connected'], isTrue);

      await runtime.proxyRegistry.disconnectAll();
      final after = runtime.proxyRegistry.getStatistics();
      expect(after.isEmpty, isTrue);
    });
  });
}

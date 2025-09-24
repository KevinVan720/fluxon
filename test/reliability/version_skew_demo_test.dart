import 'package:fluxon/fluxon.dart';
import 'package:test/test.dart';

part 'version_skew_demo_test.g.dart';

@ServiceContract(remote: true)
class ApiV1 extends FluxonService {
  Future<String> greet(String name) async => 'hello $name';
}

Future<void> _runVersionskewdemoDemo() async {
  final locator = FluxonRuntime();
  try {
    // Register worker with ApiV1
    locator.register<ApiV1>(ApiV1Impl.new);

    await locator.initializeAll();

    // Simulate client with wrong method IDs by re-registering different IDs
    // Register fake mapping that doesn't match the worker
    ServiceMethodIdRegistry.register<ApiV1>({
      'greet': 42, // wrong id on purpose
    });

    final client = locator.proxyRegistry.getProxy<ApiV1>();
    try {
      await client.callMethod<String>('greet', ['world']);
    } catch (e) {
      expect(e.toString(), contains('Unknown method id'));
    }
  } finally {
    await locator.destroyAll();
  }
}

void main() {
  group('Version Skew Demo', () {
    test('runs version skew demo successfully', () async {
      await _runVersionskewdemoDemo();
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}

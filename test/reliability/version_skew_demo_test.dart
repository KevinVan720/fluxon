import 'package:test/test.dart';
import 'package:dart_service_framework/dart_service_framework.dart';

part 'version_skew_demo_test.g.dart';

@ServiceContract(remote: true)
class ApiV1 extends FluxService {
  Future<String> greet(String name) async => 'hello $name';
}

Future<void> _runVersionskewdemoDemo() async {
  final locator = ServiceLocator();
  try {
    // Register worker with ApiV1
    await locator.registerWorkerServiceProxy<ApiV1>(
      serviceName: 'ApiV1',
      serviceFactory: () => ApiV1Worker(),
    );

    await locator.initializeAll();

    // Simulate client with wrong method IDs by re-registering different IDs
    // Register fake mapping that doesn't match the worker
    ServiceMethodIdRegistry.register<ApiV1>({
      'greet': 42, // wrong id on purpose
    });

    final client = locator.proxyRegistry.getProxy<ApiV1>();
    try {
      await client.callMethod<String>('greet', ['world']);
    } on ServiceRetryExceededException catch (e) {
      print('Version skew detected (retry exceeded): ${e.message}');
    } on ServiceException {}
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

import 'package:dart_service_framework/dart_service_framework.dart';

part '12_version_skew_demo.g.dart';

@ServiceContract(remote: true)
abstract class ApiV1 extends BaseService {
  Future<String> greet(String name);
}

// Intentionally mismatched implementation that uses different ordering
class ApiV1Impl extends ApiV1 {
  @override
  Future<void> initialize() async {
    _registerApiV1Dispatcher();
  }

  @override
  Future<String> greet(String name) async => 'hello $name';
}

Future<void> main() async {
  final locator = EnhancedServiceLocator();
  try {
    // Register worker with ApiV1
    await locator.registerWorkerServiceProxy<ApiV1>(
      serviceName: 'ApiV1',
      serviceFactory: () => ApiV1Impl(),
      registerGenerated: registerApiV1Generated,
    );

    await locator.initializeAll();

    // Simulate client with wrong method IDs by re-registering different IDs
    // Register fake mapping that doesn't match the worker
    ServiceMethodIdRegistry.register<ApiV1>({
      'greet': 42, // wrong id on purpose
    });

    final client = locator.proxyRegistry.getProxy<ApiV1>();
    try {
      final res = await client.callMethod<String>('greet', ['world']);
      print('Unexpected success: $res');
    } on ServiceRetryExceededException catch (e) {
      print('Version skew detected (retry exceeded): ${e.message}');
    } on ServiceException catch (e) {
      print('Version skew detected: ${e.message}');
    }
  } finally {
    await locator.destroyAll();
  }
}

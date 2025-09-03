import 'package:dart_service_framework/dart_service_framework.dart';

part 'cancellation_demo.g.dart';

@ServiceContract(remote: true)
abstract class SlowService extends BaseService {
  Future<String> sleepMs(int ms);
  Future<String> quick();
}

class SlowServiceImpl extends SlowService {
  @override
  Future<void> initialize() async {
    _registerSlowServiceDispatcher();
  }

  @override
  Future<String> sleepMs(int ms) async {
    await Future.delayed(Duration(milliseconds: ms));
    return 'slept ${ms}ms';
  }

  @override
  Future<String> quick() async => 'quick-ok';
}

Future<void> main() async {
  final locator = ServiceLocator();
  try {
    await locator.registerWorkerServiceProxy<SlowService>(
      serviceName: 'SlowService',
      serviceFactory: () => SlowServiceImpl(),
      registerGenerated: registerSlowServiceGenerated,
    );

    await locator.initializeAll();

    final proxy = locator.proxyRegistry.getProxy<SlowService>();

    // Simulate cancellation via timeout
    try {
      await proxy.callMethod<String>(
        'sleepMs',
        [300],
        options: const ServiceCallOptions(
          timeout: Duration(milliseconds: 50),
          retryAttempts: 0,
        ),
      );
    } on ServiceTimeoutException catch (e) {
      print('Call timed out (canceled): ${e.message}');
    }

    // Verify subsequent call still works
    final ok = await proxy.callMethod<String>('quick', [],
        options: const ServiceCallOptions(timeout: Duration(seconds: 2)));
    print('Quick call result: $ok');
  } finally {
    await locator.destroyAll();
  }
}

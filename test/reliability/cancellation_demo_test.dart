import 'package:flux/flux.dart';
import 'package:test/test.dart';

part 'cancellation_demo_test.g.dart';

@ServiceContract(remote: true)
class SlowService extends FluxService {
  Future<String> sleepMs(int ms) async {
    await Future.delayed(Duration(milliseconds: ms));
    return 'slept ${ms}ms';
  }

  Future<String> quick() async => 'quick-ok';
}

Future<void> _runCancellationdemoDemo() async {
  final locator = FluxRuntime();
  try {
    locator.register<SlowService>(SlowServiceImpl.new);

    await locator.initializeAll();

    final proxy = locator.proxyRegistry.getProxy<SlowService>();

    // Simulate cancellation via timeout
    try {
      await proxy.callMethod<String>(
        'sleepMs',
        [300],
        options: const ServiceCallOptions(
          timeout: Duration(milliseconds: 50),
        ),
      );
    } on ServiceTimeoutException catch (e) {
      print('Call timed out (canceled): ${e.message}');
    }

    // Verify subsequent call still works
    await proxy.callMethod<String>('quick', [],
        options: const ServiceCallOptions(timeout: Duration(seconds: 2)));
  } finally {
    await locator.destroyAll();
  }
}

void main() {
  group('Cancellation Demo', () {
    test('runs cancellation demo successfully', () async {
      await _runCancellationdemoDemo();
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}

import 'package:test/test.dart';
import 'dart:async';
import 'package:test/test.dart';
import 'package:dart_service_framework/dart_service_framework.dart';

part 'retry_timeout_demo_test.g.dart';

@ServiceContract(remote: true)
abstract class FlakyService extends BaseService {
  Future<String> succeedAfter(int attempts);
  Future<String> slowOperation(Duration delay);
}

class FlakyServiceImpl extends FlakyService {
  int _counter = 0;

  @override
  Future<void> initialize() async {
    _registerFlakyServiceDispatcher();
  }

  @override
  Future<String> succeedAfter(int attempts) async {
    _counter++;
    if (_counter < attempts) {
      throw StateError('Not yet!');
    }
    return 'ok@$_counter';
  }

  @override
  Future<String> slowOperation(Duration delay) async {
    await Future.delayed(delay);
    return 'done in ${delay.inMilliseconds}ms';
  }
}

Future<void> _runRetrytimeoutdemoDemo() async {
  final locator = ServiceLocator();
  try {
    await locator.registerWorkerServiceProxy<FlakyService>(
      serviceName: 'FlakyService',
      serviceFactory: () => FlakyServiceImpl(),
      registerGenerated: registerFlakyServiceGenerated,
    );

    await locator.initializeAll();

    final proxy = locator.proxyRegistry.getProxy<FlakyService>();

    // Retry demo: expect failures, then success
    final retriesResult = await proxy.callMethod<String>(
      'succeedAfter',
      [3],
      options: const ServiceCallOptions(
        retryAttempts: 2,
        retryDelay: Duration(milliseconds: 50),
      ),
    );// Timeout demo: call with short timeout to force timeout
    try {
      await proxy.callMethod<String>(
        'slowOperation',
        [const Duration(milliseconds: 300)],
        options: const ServiceCallOptions(
          timeout: Duration(milliseconds: 50),
          retryAttempts: 0,
        ),
      );
    } on ServiceTimeoutException catch (e) {}

    // Now call with longer timeout via options
    final ok = await proxy.callMethod<String>(
      'slowOperation',
      [const Duration(milliseconds: 150)],
      options: const ServiceCallOptions(
        timeout: Duration(seconds: 2),
        retryAttempts: 1,
        retryDelay: Duration(milliseconds: 50),
      ),
    );} finally {
    await locator.destroyAll();
  }
}

void main() {
  group('Retry Timeout Demo', () {
    test('runs retry timeout demo successfully', () async {
      await _runRetrytimeoutdemoDemo();
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}

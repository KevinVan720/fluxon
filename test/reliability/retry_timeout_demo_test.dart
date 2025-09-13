import 'dart:async';

import 'package:fluxon/fluxon.dart';
import 'package:test/test.dart';

part 'retry_timeout_demo_test.g.dart';

@ServiceContract(remote: true)
class FlakyService extends FluxonService {
  int _counter = 0;

  Future<String> succeedAfter(int attempts) async {
    _counter++;
    if (_counter < attempts) {
      throw StateError('Not yet!');
    }
    return 'ok@$_counter';
  }

  Future<String> slowOperation(Duration delay) async {
    await Future.delayed(delay);
    return 'done in ${delay.inMilliseconds}ms';
  }
}

Future<void> _runRetrytimeoutdemoDemo() async {
  final locator = FluxonRuntime();
  try {
    locator.register<FlakyService>(FlakyServiceImpl.new);

    await locator.initializeAll();

    final proxy = locator.proxyRegistry.getProxy<FlakyService>();

    // Retry demo: expect failures, then success
    await proxy.callMethod<String>(
      'succeedAfter',
      [3],
      options: const ServiceCallOptions(
        retryAttempts: 2,
        retryDelay: Duration(milliseconds: 50),
      ),
    ); // Timeout demo: call with short timeout to force timeout
    try {
      await proxy.callMethod<String>(
        'slowOperation',
        [const Duration(milliseconds: 300)],
        options: const ServiceCallOptions(
          timeout: Duration(milliseconds: 50),
        ),
      );
    } on ServiceTimeoutException {}

    // Now call with longer timeout via options
    await proxy.callMethod<String>(
      'slowOperation',
      [const Duration(milliseconds: 150)],
      options: const ServiceCallOptions(
        timeout: Duration(seconds: 2),
        retryAttempts: 1,
        retryDelay: Duration(milliseconds: 50),
      ),
    );
  } finally {
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

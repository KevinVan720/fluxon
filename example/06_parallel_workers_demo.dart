import 'dart:math';
import 'package:dart_service_framework/dart_service_framework.dart';

part '06_parallel_workers_demo.g.dart';

@ServiceContract(remote: true)
abstract class CruncherService extends BaseService {
  Future<int> fib(int n);
}

class CruncherServiceImpl extends CruncherService {
  @override
  Future<void> initialize() async {
    logger.info('CruncherServiceImpl initialized');
    _registerCruncherServiceDispatcher();
  }

  @override
  Future<int> fib(int n) async => _fib(n);

  int _fib(int n) {
    if (n <= 1) return n;
    return _fib(n - 1) + _fib(n - 2);
  }
}

Future<void> main() async {
  // Host-side: register generated IDs for method lookup
  registerCruncherServiceGenerated();

  // Build a worker pool manually for the same service type
  final pool = ServiceWorkerPool(maxWorkers: 2, minWorkers: 0);
  pool.registerService<CruncherService>(
      'CruncherService', () => CruncherServiceImpl());

  // Submit a batch of CPU-bound jobs
  final jobs = <int>[for (var i = 28; i < 34; i++) i];
  final rnd = Random(42);
  final futures = jobs.map((n) async {
    final w = await pool.getWorker('CruncherService');
    final started = DateTime.now();
    final result = await w.send(6, args: [
      _CruncherServiceMethods.fibId,
      [n],
      const <String, dynamic>{},
    ]) as int;
    final elapsed = DateTime.now().difference(started).inMilliseconds;
    print('fib($n) = $result (${elapsed}ms) by ${w.serviceName}');
    // Simulate slight jitter between requests
    await Future.delayed(Duration(milliseconds: rnd.nextInt(50)));
    return result;
  }).toList();

  await Future.wait(futures);
  await pool.shutdown();
}

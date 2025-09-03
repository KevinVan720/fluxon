import 'package:test/test.dart';
import 'dart:math';
import 'package:test/test.dart';
import 'package:dart_service_framework/dart_service_framework.dart';

part 'parallel_workers_demo_test.g.dart';

@ServiceContract(remote: true)
abstract class CruncherService extends BaseService {
  Future<int> fibonacci(int n);
}

class CruncherServiceImpl extends CruncherService {
  @override
  Future<void> initialize() async {
    _registerCruncherServiceDispatcher();
  }

  int _fib(int n) => n <= 1 ? n : _fib(n - 1) + _fib(n - 2);

  @override
  Future<int> fibonacci(int n) async => _fib(n);
}

Future<void> _runParallelworkersdemoDemo() async {
  final pool = ServiceWorkerPool(maxWorkers: 2, minWorkers: 1);
  pool.registerService<CruncherService>(
      'CruncherService', () => CruncherServiceImpl());

  final worker1 = await pool.getWorker('CruncherService');
  final worker2 = await pool.getWorker('CruncherService');

  final proxyFactory = ServiceProxyFactory();
  final proxy1 = proxyFactory.createWorkerProxy<CruncherService>(
      logger: ServiceLogger(serviceName: 'CruncherService'))
    ..connect(worker1);
  final proxy2 = proxyFactory.createWorkerProxy<CruncherService>(
      logger: ServiceLogger(serviceName: 'CruncherService'))
    ..connect(worker2);

  _registerCruncherServiceClientFactory();
  _registerCruncherServiceMethodIds();

  final c1 = GeneratedClientRegistry.create<CruncherService>(proxy1)!;
  final c2 = GeneratedClientRegistry.create<CruncherService>(proxy2)!;

  final futures = [
    c1.fibonacci(20),
    c2.fibonacci(22),
  ];
  final results = await Future.wait(futures);
  print('fib(20)=${results[0]}, fib(22)=${results[1]}');

  await pool.shutdown();
}

void main() {
  group('Parallel Workers Demo', () {
    test('runs parallel workers demo successfully', () async {
      await _runParallelworkersdemoDemo();
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}

import 'package:dart_service_framework/dart_service_framework.dart';
import 'package:test/test.dart';

part 'named_parameters_demo_test.g.dart';

@ServiceContract(remote: true)
class ReportService extends FluxService {
  Future<String> generateReport(String title,
          {int? year, bool detailed = false}) async =>
      '[title=$title, year=${year ?? 'n/a'}, detailed=$detailed]';
}

@ServiceContract(remote: false)
class Coordinator extends FluxService {
  @override
  List<Type> get optionalDependencies => [ReportService];

  Future<void> run() async {
    final report = getService<ReportService>();
    final res =
        await report.generateReport('Ops Summary', year: 2025, detailed: true);
    logger.info('Report generated: $res');
  }
}

Future<void> _runNamedparametersdemoDemo() async {
  final locator = FluxRuntime();

  locator.register<Coordinator>(Coordinator.new);
  locator.register<ReportService>(ReportServiceImpl.new);
  await locator.initializeAll();
  final c = locator.get<Coordinator>();
  await c.run();

  await locator.destroyAll();
}

void main() {
  group('Named Parameters Demo', () {
    test('runs named parameters demo successfully', () async {
      await _runNamedparametersdemoDemo();
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}

import 'package:test/test.dart';
import 'package:dart_service_framework/dart_service_framework.dart';

part 'named_parameters_demo_test.g.dart';

@ServiceContract(remote: true)
class ReportService extends FluxService {
  Future<String> generateReport(String title,
      {int? year, bool detailed = false}) async {
    return '[title=$title, year=${year ?? 'n/a'}, detailed=$detailed]';
  }
}

class Coordinator extends BaseService with ServiceClientMixin {
  @override
  List<Type> get optionalDependencies => [ReportService];

  Future<void> run() async {
    final report = getService<ReportService>();
    final res =
        await report.generateReport('Ops Summary', year: 2025, detailed: true);
    print(res);
  }
}

Future<void> _runNamedparametersdemoDemo() async {
  final locator = ServiceLocator();

  locator.register<Coordinator>(() => Coordinator());
  locator.register<ReportService>(() => ReportServiceWorker());
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

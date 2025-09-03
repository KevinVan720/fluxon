import 'package:dart_service_framework/dart_service_framework.dart';

part 'named_parameters_demo.g.dart';

@ServiceContract(remote: true)
abstract class ReportService extends BaseService {
  Future<String> generateReport(String title,
      {int? year, bool detailed = false});
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

class ReportServiceImpl extends ReportService {
  @override
  Future<void> initialize() async {
    _registerReportServiceDispatcher();
  }

  @override
  Future<String> generateReport(String title,
      {int? year, bool detailed = false}) async {
    return '[title=$title, year=${year ?? 'n/a'}, detailed=$detailed]';
  }
}

Future<void> main() async {
  final locator = ServiceLocator();
  try {
    locator.register<Coordinator>(() => Coordinator());
    await locator.registerWorkerServiceProxy<ReportService>(
      serviceName: 'ReportService',
      serviceFactory: () => ReportServiceImpl(),
      registerGenerated: registerReportServiceGenerated,
    );
    await locator.initializeAll();
    final c = locator.get<Coordinator>();
    await c.run();
  } finally {
    await locator.destroyAll();
  }
}

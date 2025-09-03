import 'package:dart_service_framework/dart_service_framework.dart';

part '05_named_parameters_demo.g.dart';

@ServiceContract(remote: true)
abstract class ReportService extends BaseService {
  Future<String> buildReport(int base, {required int multiplier, String label});
}

class ReportServiceImpl extends ReportService {
  @override
  Future<void> initialize() async {
    logger.info('ReportServiceImpl initialized');
    _registerReportServiceDispatcher();
  }

  @override
  Future<String> buildReport(int base,
      {required int multiplier, String label = 'Report'}) async {
    final value = base * multiplier;
    return '$label: $value';
  }
}

class Coordinator extends BaseService with ServiceClientMixin {
  @override
  List<Type> get optionalDependencies => [ReportService];

  Future<void> run() async {
    ensureInitialized();
    final report = getService<ReportService>();
    final a = await report.buildReport(10, multiplier: 3, label: 'Sales');
    final b = await report.buildReport(7, multiplier: 5, label: 'Ops');
    print(a);
    print(b);
  }
}

Future<void> main() async {
  final locator = EnhancedServiceLocator();
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

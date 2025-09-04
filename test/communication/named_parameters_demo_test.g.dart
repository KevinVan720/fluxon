// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'named_parameters_demo_test.dart';

// **************************************************************************
// ServiceGenerator
// **************************************************************************

// Service client for ReportService
class ReportServiceClient extends ReportService {
  ReportServiceClient(this._proxy);
  final ServiceProxy<ReportService> _proxy;

  @override
  Future<String> generateReport(String title,
      {int? year, bool detailed = false}) async {
    return await _proxy.callMethod('generateReport', [title],
        namedArgs: {'year': year, 'detailed': detailed});
  }
}

void _registerReportServiceClientFactory() {
  GeneratedClientRegistry.register<ReportService>(
    (proxy) => ReportServiceClient(proxy),
  );
}

class _ReportServiceMethods {
  static const int generateReportId = 1;
}

Future<dynamic> _ReportServiceDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as ReportService;
  switch (methodId) {
    case _ReportServiceMethods.generateReportId:
      return await s.generateReport(positionalArgs[0],
          year: namedArgs['year'], detailed: namedArgs['detailed']);
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void _registerReportServiceDispatcher() {
  GeneratedDispatcherRegistry.register<ReportService>(
    _ReportServiceDispatcher,
  );
}

void _registerReportServiceMethodIds() {
  ServiceMethodIdRegistry.register<ReportService>({
    'generateReport': _ReportServiceMethods.generateReportId,
  });
}

void registerReportServiceGenerated() {
  _registerReportServiceClientFactory();
  _registerReportServiceMethodIds();
}

// Worker implementation that auto-registers the dispatcher
class ReportServiceWorker extends ReportService {
  @override
  Type get clientBaseType => ReportService;
  @override
  Future<void> registerHostSide() async {
    _registerReportServiceClientFactory();
    _registerReportServiceMethodIds();
  }

  @override
  Future<void> initialize() async {
    _registerReportServiceDispatcher();
    await super.initialize();
  }
}

void _registerReportServiceLocalSide() {
  _registerReportServiceDispatcher();
  _registerReportServiceClientFactory();
  _registerReportServiceMethodIds();
}

// Service client for Coordinator
class CoordinatorClient extends Coordinator {
  CoordinatorClient(this._proxy);
  final ServiceProxy<Coordinator> _proxy;

  @override
  Future<void> run() async {
    return await _proxy.callMethod('run', [], namedArgs: {});
  }
}

void _registerCoordinatorClientFactory() {
  GeneratedClientRegistry.register<Coordinator>(
    (proxy) => CoordinatorClient(proxy),
  );
}

class _CoordinatorMethods {
  static const int runId = 1;
}

Future<dynamic> _CoordinatorDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as Coordinator;
  switch (methodId) {
    case _CoordinatorMethods.runId:
      return await s.run();
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void _registerCoordinatorDispatcher() {
  GeneratedDispatcherRegistry.register<Coordinator>(
    _CoordinatorDispatcher,
  );
}

void _registerCoordinatorMethodIds() {
  ServiceMethodIdRegistry.register<Coordinator>({
    'run': _CoordinatorMethods.runId,
  });
}

void registerCoordinatorGenerated() {
  _registerCoordinatorClientFactory();
  _registerCoordinatorMethodIds();
}

void _registerCoordinatorLocalSide() {
  _registerCoordinatorDispatcher();
  _registerCoordinatorClientFactory();
  _registerCoordinatorMethodIds();
  try {
    _registerReportServiceClientFactory();
  } catch (_) {}
  try {
    _registerReportServiceMethodIds();
  } catch (_) {}
}

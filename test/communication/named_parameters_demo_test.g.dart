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

void $registerReportServiceClientFactory() {
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

void $registerReportServiceDispatcher() {
  GeneratedDispatcherRegistry.register<ReportService>(
    _ReportServiceDispatcher,
  );
}

void $registerReportServiceMethodIds() {
  ServiceMethodIdRegistry.register<ReportService>({
    'generateReport': _ReportServiceMethods.generateReportId,
  });
}

void registerReportServiceGenerated() {
  $registerReportServiceClientFactory();
  $registerReportServiceMethodIds();
}

// Remote service implementation that auto-registers the dispatcher
class ReportServiceImpl extends ReportService {
  @override
  bool get isRemote => true;
  @override
  Type get clientBaseType => ReportService;
  @override
  Future<void> registerHostSide() async {
    $registerReportServiceClientFactory();
    $registerReportServiceMethodIds();
  }

  @override
  Future<void> initialize() async {
    $registerReportServiceDispatcher();
    await super.initialize();
  }
}

void $registerReportServiceLocalSide() {
  $registerReportServiceDispatcher();
  $registerReportServiceClientFactory();
  $registerReportServiceMethodIds();
}

void $autoRegisterReportServiceLocalSide() {
  LocalSideRegistry.register<ReportService>($registerReportServiceLocalSide);
}

final $_ReportServiceLocalSideRegistered = (() {
  $autoRegisterReportServiceLocalSide();
  return true;
})();

// Service client for Coordinator
class CoordinatorClient extends Coordinator {
  CoordinatorClient(this._proxy);
  final ServiceProxy<Coordinator> _proxy;

  @override
  Future<void> run() async {
    return await _proxy.callMethod('run', [], namedArgs: {});
  }
}

void $registerCoordinatorClientFactory() {
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

void $registerCoordinatorDispatcher() {
  GeneratedDispatcherRegistry.register<Coordinator>(
    _CoordinatorDispatcher,
  );
}

void $registerCoordinatorMethodIds() {
  ServiceMethodIdRegistry.register<Coordinator>({
    'run': _CoordinatorMethods.runId,
  });
}

void registerCoordinatorGenerated() {
  $registerCoordinatorClientFactory();
  $registerCoordinatorMethodIds();
}

// Local service implementation that auto-registers local side
class CoordinatorImpl extends Coordinator {
  CoordinatorImpl() {
    // 🚀 AUTO-REGISTRATION: Register local side when instance is created
    $registerCoordinatorLocalSide();
  }
}

void $registerCoordinatorLocalSide() {
  $registerCoordinatorDispatcher();
  $registerCoordinatorClientFactory();
  $registerCoordinatorMethodIds();
  try {
    $registerReportServiceClientFactory();
  } catch (_) {}
  try {
    $registerReportServiceMethodIds();
  } catch (_) {}
}

void $autoRegisterCoordinatorLocalSide() {
  LocalSideRegistry.register<Coordinator>($registerCoordinatorLocalSide);
}

final $_CoordinatorLocalSideRegistered = (() {
  $autoRegisterCoordinatorLocalSide();
  return true;
})();

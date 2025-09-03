// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'named_parameters_demo.dart';

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

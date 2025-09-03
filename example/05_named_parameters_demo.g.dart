// GENERATED CODE - DO NOT MODIFY BY HAND

part of '05_named_parameters_demo.dart';

// **************************************************************************
// ServiceGenerator
// **************************************************************************

// Service client for ReportService
class ReportServiceClient extends ReportService {
  ReportServiceClient(this._proxy);
  final ServiceProxy<ReportService> _proxy;

  @override
  Future<String> buildReport(int base,
      {required int multiplier, String label = 'Report'}) async {
    return await _proxy.callMethod('buildReport', [base],
        namedArgs: {'multiplier': multiplier, 'label': label});
  }
}

void _registerReportServiceClientFactory() {
  GeneratedClientRegistry.register<ReportService>(
    (proxy) => ReportServiceClient(proxy),
  );
}

class _ReportServiceMethods {
  static const int buildReportId = 1;
}

Future<dynamic> _ReportServiceDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as ReportService;
  switch (methodId) {
    case _ReportServiceMethods.buildReportId:
      return await s.buildReport(positionalArgs[0],
          multiplier: namedArgs['multiplier'], label: namedArgs['label']);
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
    'buildReport': _ReportServiceMethods.buildReportId,
  });
}

void registerReportServiceGenerated() {
  _registerReportServiceClientFactory();
  _registerReportServiceMethodIds();
}

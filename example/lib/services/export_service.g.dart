// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'export_service.dart';

// **************************************************************************
// ServiceGenerator
// **************************************************************************

// Service client for ExportService
class ExportServiceClient extends ExportService {
  ExportServiceClient(this._proxy);
  final ServiceProxy<ExportService> _proxy;

  @override
  Future<ExportResult> exportTasksAsCsv(List<InvalidType> tasks,
      {ExportOptions? options}) async {
    return await _proxy.callMethod('exportTasksAsCsv', [tasks],
        namedArgs: {'options': options},
        options:
            const ServiceCallOptions(timeout: Duration(milliseconds: 10000)));
  }

  @override
  Future<ExportResult> exportTasksAsPdf(List<InvalidType> tasks,
      {ExportOptions? options}) async {
    return await _proxy.callMethod('exportTasksAsPdf', [tasks],
        namedArgs: {'options': options},
        options:
            const ServiceCallOptions(timeout: Duration(milliseconds: 15000)));
  }

  @override
  Future<ExportResult> generateSummaryReport(
      List<InvalidType> tasks, InvalidType stats) async {
    return await _proxy.callMethod('generateSummaryReport', [tasks, stats],
        namedArgs: {},
        options:
            const ServiceCallOptions(timeout: Duration(milliseconds: 8000)));
  }

  @override
  Future<List<ExportTemplate>> getExportTemplates() async {
    return await _proxy.callMethod('getExportTemplates', [], namedArgs: {});
  }

  @override
  Future<List<ExportRecord>> getExportHistory({int limit = 20}) async {
    return await _proxy
        .callMethod('getExportHistory', [], namedArgs: {'limit': limit});
  }
}

void _registerExportServiceClientFactory() {
  GeneratedClientRegistry.register<ExportService>(
    (proxy) => ExportServiceClient(proxy),
  );
}

class _ExportServiceMethods {
  static const int exportTasksAsCsvId = 1;
  static const int exportTasksAsPdfId = 2;
  static const int generateSummaryReportId = 3;
  static const int getExportTemplatesId = 4;
  static const int getExportHistoryId = 5;
}

Future<dynamic> _ExportServiceDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as ExportService;
  switch (methodId) {
    case _ExportServiceMethods.exportTasksAsCsvId:
      return await s.exportTasksAsCsv(positionalArgs[0],
          options: namedArgs['options']);
    case _ExportServiceMethods.exportTasksAsPdfId:
      return await s.exportTasksAsPdf(positionalArgs[0],
          options: namedArgs['options']);
    case _ExportServiceMethods.generateSummaryReportId:
      return await s.generateSummaryReport(
          positionalArgs[0], positionalArgs[1]);
    case _ExportServiceMethods.getExportTemplatesId:
      return await s.getExportTemplates();
    case _ExportServiceMethods.getExportHistoryId:
      return await s.getExportHistory(limit: namedArgs['limit']);
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void _registerExportServiceDispatcher() {
  GeneratedDispatcherRegistry.register<ExportService>(
    _ExportServiceDispatcher,
  );
}

void _registerExportServiceMethodIds() {
  ServiceMethodIdRegistry.register<ExportService>({
    'exportTasksAsCsv': _ExportServiceMethods.exportTasksAsCsvId,
    'exportTasksAsPdf': _ExportServiceMethods.exportTasksAsPdfId,
    'generateSummaryReport': _ExportServiceMethods.generateSummaryReportId,
    'getExportTemplates': _ExportServiceMethods.getExportTemplatesId,
    'getExportHistory': _ExportServiceMethods.getExportHistoryId,
  });
}

void registerExportServiceGenerated() {
  _registerExportServiceClientFactory();
  _registerExportServiceMethodIds();
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analytics_service.dart';

// **************************************************************************
// ServiceGenerator
// **************************************************************************

// Service client for AnalyticsService
class AnalyticsServiceClient extends AnalyticsService {
  AnalyticsServiceClient(this._proxy);
  final ServiceProxy<AnalyticsService> _proxy;

  @override
  Future<void> trackEvent(
      String action, String entity, Map<String, dynamic> properties) async {
    return await _proxy
        .callMethod('trackEvent', [action, entity, properties], namedArgs: {});
  }

  @override
  Future<Map<String, dynamic>> getAnalyticsSummary() async {
    return await _proxy.callMethod('getAnalyticsSummary', [], namedArgs: {});
  }

  @override
  Future<List<Map<String, dynamic>>> getEventHistory(
      {int limit = 100, String? action, String? entity}) async {
    return await _proxy.callMethod('getEventHistory', [],
        namedArgs: {'limit': limit, 'action': action, 'entity': entity});
  }

  @override
  Future<Map<String, dynamic>> generateReport(
      {DateTime? startDate, DateTime? endDate}) async {
    return await _proxy.callMethod('generateReport', [],
        namedArgs: {'startDate': startDate, 'endDate': endDate});
  }
}

void $registerAnalyticsServiceClientFactory() {
  GeneratedClientRegistry.register<AnalyticsService>(
    (proxy) => AnalyticsServiceClient(proxy),
  );
}

class _AnalyticsServiceMethods {
  static const int trackEventId = 1;
  static const int getAnalyticsSummaryId = 2;
  static const int getEventHistoryId = 3;
  static const int generateReportId = 4;
}

Future<dynamic> _AnalyticsServiceDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as AnalyticsService;
  switch (methodId) {
    case _AnalyticsServiceMethods.trackEventId:
      return await s.trackEvent(
          positionalArgs[0], positionalArgs[1], positionalArgs[2]);
    case _AnalyticsServiceMethods.getAnalyticsSummaryId:
      return await s.getAnalyticsSummary();
    case _AnalyticsServiceMethods.getEventHistoryId:
      return await s.getEventHistory(
          limit: namedArgs['limit'],
          action: namedArgs['action'],
          entity: namedArgs['entity']);
    case _AnalyticsServiceMethods.generateReportId:
      return await s.generateReport(
          startDate: namedArgs['startDate'], endDate: namedArgs['endDate']);
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void $registerAnalyticsServiceDispatcher() {
  GeneratedDispatcherRegistry.register<AnalyticsService>(
    _AnalyticsServiceDispatcher,
  );
}

void $registerAnalyticsServiceMethodIds() {
  ServiceMethodIdRegistry.register<AnalyticsService>({
    'trackEvent': _AnalyticsServiceMethods.trackEventId,
    'getAnalyticsSummary': _AnalyticsServiceMethods.getAnalyticsSummaryId,
    'getEventHistory': _AnalyticsServiceMethods.getEventHistoryId,
    'generateReport': _AnalyticsServiceMethods.generateReportId,
  });
}

void registerAnalyticsServiceGenerated() {
  $registerAnalyticsServiceClientFactory();
  $registerAnalyticsServiceMethodIds();
}

// Worker implementation that auto-registers the dispatcher
class AnalyticsServiceWorker extends AnalyticsService {
  @override
  Type get clientBaseType => AnalyticsService;
  @override
  Future<void> registerHostSide() async {
    $registerAnalyticsServiceClientFactory();
    $registerAnalyticsServiceMethodIds();
  }

  @override
  Future<void> initialize() async {
    $registerAnalyticsServiceDispatcher();
    await super.initialize();
  }
}

void $registerAnalyticsServiceLocalSide() {
  $registerAnalyticsServiceDispatcher();
  $registerAnalyticsServiceClientFactory();
  $registerAnalyticsServiceMethodIds();
}

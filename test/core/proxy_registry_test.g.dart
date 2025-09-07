// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'proxy_registry_test.dart';

// **************************************************************************
// ServiceGenerator
// **************************************************************************

// Service client for StatsService
class StatsServiceClient extends StatsService {
  StatsServiceClient(this._proxy);
  final ServiceProxy<StatsService> _proxy;

  @override
  Future<String> ping() async {
    return await _proxy.callMethod('ping', [], namedArgs: {});
  }
}

void $registerStatsServiceClientFactory() {
  GeneratedClientRegistry.register<StatsService>(
    (proxy) => StatsServiceClient(proxy),
  );
}

class _StatsServiceMethods {
  static const int pingId = 1;
}

Future<dynamic> _StatsServiceDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as StatsService;
  switch (methodId) {
    case _StatsServiceMethods.pingId:
      return await s.ping();
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void $registerStatsServiceDispatcher() {
  GeneratedDispatcherRegistry.register<StatsService>(
    _StatsServiceDispatcher,
  );
}

void $registerStatsServiceMethodIds() {
  ServiceMethodIdRegistry.register<StatsService>({
    'ping': _StatsServiceMethods.pingId,
  });
}

void registerStatsServiceGenerated() {
  $registerStatsServiceClientFactory();
  $registerStatsServiceMethodIds();
}

// Local service implementation that auto-registers local side
class StatsServiceImpl extends StatsService {
  StatsServiceImpl() {
    // 🚀 AUTO-REGISTRATION: Register local side when instance is created
    $registerStatsServiceLocalSide();
  }
}

void $registerStatsServiceLocalSide() {
  $registerStatsServiceDispatcher();
  $registerStatsServiceClientFactory();
  $registerStatsServiceMethodIds();
}

void $autoRegisterStatsServiceLocalSide() {
  LocalSideRegistry.register<StatsService>($registerStatsServiceLocalSide);
}

final $_StatsServiceLocalSideRegistered = (() {
  $autoRegisterStatsServiceLocalSide();
  return true;
})();

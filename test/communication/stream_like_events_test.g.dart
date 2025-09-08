// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stream_like_events_test.dart';

// **************************************************************************
// ServiceGenerator
// **************************************************************************

// Service client for StreamerService
class StreamerServiceClient extends StreamerService {
  StreamerServiceClient(this._proxy);
  final ServiceProxy<StreamerService> _proxy;

  @override
  Future<void> startStream(String streamId, int count, int intervalMs) async {
    return await _proxy.callMethod('startStream', [streamId, count, intervalMs],
        namedArgs: {});
  }
}

void $registerStreamerServiceClientFactory() {
  GeneratedClientRegistry.register<StreamerService>(
    (proxy) => StreamerServiceClient(proxy),
  );
}

class _StreamerServiceMethods {
  static const int startStreamId = 1;
}

Future<dynamic> _StreamerServiceDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as StreamerService;
  switch (methodId) {
    case _StreamerServiceMethods.startStreamId:
      return await s.startStream(
          positionalArgs[0], positionalArgs[1], positionalArgs[2]);
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void $registerStreamerServiceDispatcher() {
  GeneratedDispatcherRegistry.register<StreamerService>(
    _StreamerServiceDispatcher,
  );
}

void $registerStreamerServiceMethodIds() {
  ServiceMethodIdRegistry.register<StreamerService>({
    'startStream': _StreamerServiceMethods.startStreamId,
  });
}

void registerStreamerServiceGenerated() {
  $registerStreamerServiceClientFactory();
  $registerStreamerServiceMethodIds();
}

// Remote service implementation that auto-registers the dispatcher
class StreamerServiceImpl extends StreamerService {
  @override
  bool get isRemote => true;
  @override
  Type get clientBaseType => StreamerService;
  @override
  Future<void> registerHostSide() async {
    $registerStreamerServiceClientFactory();
    $registerStreamerServiceMethodIds();
  }

  @override
  Future<void> initialize() async {
    $registerStreamerServiceDispatcher();
    await super.initialize();
  }
}

void $registerStreamerServiceLocalSide() {
  $registerStreamerServiceDispatcher();
  $registerStreamerServiceClientFactory();
  $registerStreamerServiceMethodIds();
}

void $autoRegisterStreamerServiceLocalSide() {
  LocalSideRegistry.register<StreamerService>(
      $registerStreamerServiceLocalSide);
}

final $_StreamerServiceLocalSideRegistered = (() {
  $autoRegisterStreamerServiceLocalSide();
  return true;
})();

// Service client for RemoteStreamAggregator
class RemoteStreamAggregatorClient extends RemoteStreamAggregator {
  RemoteStreamAggregatorClient(this._proxy);
  final ServiceProxy<RemoteStreamAggregator> _proxy;

  @override
  Future<List<int>> waitFor(String streamId, int count) async {
    return await _proxy.callMethod('waitFor', [streamId, count], namedArgs: {});
  }
}

void $registerRemoteStreamAggregatorClientFactory() {
  GeneratedClientRegistry.register<RemoteStreamAggregator>(
    (proxy) => RemoteStreamAggregatorClient(proxy),
  );
}

class _RemoteStreamAggregatorMethods {
  static const int waitForId = 1;
}

Future<dynamic> _RemoteStreamAggregatorDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as RemoteStreamAggregator;
  switch (methodId) {
    case _RemoteStreamAggregatorMethods.waitForId:
      return await s.waitFor(positionalArgs[0], positionalArgs[1]);
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void $registerRemoteStreamAggregatorDispatcher() {
  GeneratedDispatcherRegistry.register<RemoteStreamAggregator>(
    _RemoteStreamAggregatorDispatcher,
  );
}

void $registerRemoteStreamAggregatorMethodIds() {
  ServiceMethodIdRegistry.register<RemoteStreamAggregator>({
    'waitFor': _RemoteStreamAggregatorMethods.waitForId,
  });
}

void registerRemoteStreamAggregatorGenerated() {
  $registerRemoteStreamAggregatorClientFactory();
  $registerRemoteStreamAggregatorMethodIds();
}

// Remote service implementation that auto-registers the dispatcher
class RemoteStreamAggregatorImpl extends RemoteStreamAggregator {
  @override
  bool get isRemote => true;
  @override
  Type get clientBaseType => RemoteStreamAggregator;
  @override
  Future<void> registerHostSide() async {
    $registerRemoteStreamAggregatorClientFactory();
    $registerRemoteStreamAggregatorMethodIds();
  }

  @override
  Future<void> initialize() async {
    $registerRemoteStreamAggregatorDispatcher();
    await super.initialize();
  }
}

void $registerRemoteStreamAggregatorLocalSide() {
  $registerRemoteStreamAggregatorDispatcher();
  $registerRemoteStreamAggregatorClientFactory();
  $registerRemoteStreamAggregatorMethodIds();
}

void $autoRegisterRemoteStreamAggregatorLocalSide() {
  LocalSideRegistry.register<RemoteStreamAggregator>(
      $registerRemoteStreamAggregatorLocalSide);
}

final $_RemoteStreamAggregatorLocalSideRegistered = (() {
  $autoRegisterRemoteStreamAggregatorLocalSide();
  return true;
})();

// Service client for RemoteEmitter
class RemoteEmitterClient extends RemoteEmitter {
  RemoteEmitterClient(this._proxy);
  final ServiceProxy<RemoteEmitter> _proxy;

  @override
  Future<void> emit(String streamId, int count) async {
    return await _proxy.callMethod('emit', [streamId, count], namedArgs: {});
  }
}

void $registerRemoteEmitterClientFactory() {
  GeneratedClientRegistry.register<RemoteEmitter>(
    (proxy) => RemoteEmitterClient(proxy),
  );
}

class _RemoteEmitterMethods {
  static const int emitId = 1;
}

Future<dynamic> _RemoteEmitterDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as RemoteEmitter;
  switch (methodId) {
    case _RemoteEmitterMethods.emitId:
      return await s.emit(positionalArgs[0], positionalArgs[1]);
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void $registerRemoteEmitterDispatcher() {
  GeneratedDispatcherRegistry.register<RemoteEmitter>(
    _RemoteEmitterDispatcher,
  );
}

void $registerRemoteEmitterMethodIds() {
  ServiceMethodIdRegistry.register<RemoteEmitter>({
    'emit': _RemoteEmitterMethods.emitId,
  });
}

void registerRemoteEmitterGenerated() {
  $registerRemoteEmitterClientFactory();
  $registerRemoteEmitterMethodIds();
}

// Remote service implementation that auto-registers the dispatcher
class RemoteEmitterImpl extends RemoteEmitter {
  @override
  bool get isRemote => true;
  @override
  Type get clientBaseType => RemoteEmitter;
  @override
  Future<void> registerHostSide() async {
    $registerRemoteEmitterClientFactory();
    $registerRemoteEmitterMethodIds();
  }

  @override
  Future<void> initialize() async {
    $registerRemoteEmitterDispatcher();
    await super.initialize();
  }
}

void $registerRemoteEmitterLocalSide() {
  $registerRemoteEmitterDispatcher();
  $registerRemoteEmitterClientFactory();
  $registerRemoteEmitterMethodIds();
}

void $autoRegisterRemoteEmitterLocalSide() {
  LocalSideRegistry.register<RemoteEmitter>($registerRemoteEmitterLocalSide);
}

final $_RemoteEmitterLocalSideRegistered = (() {
  $autoRegisterRemoteEmitterLocalSide();
  return true;
})();

// Service client for RemoteCollector
class RemoteCollectorClient extends RemoteCollector {
  RemoteCollectorClient(this._proxy);
  final ServiceProxy<RemoteCollector> _proxy;

  @override
  Future<List<int>> waitFor(String streamId, int count) async {
    return await _proxy.callMethod('waitFor', [streamId, count], namedArgs: {});
  }
}

void $registerRemoteCollectorClientFactory() {
  GeneratedClientRegistry.register<RemoteCollector>(
    (proxy) => RemoteCollectorClient(proxy),
  );
}

class _RemoteCollectorMethods {
  static const int waitForId = 1;
}

Future<dynamic> _RemoteCollectorDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as RemoteCollector;
  switch (methodId) {
    case _RemoteCollectorMethods.waitForId:
      return await s.waitFor(positionalArgs[0], positionalArgs[1]);
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void $registerRemoteCollectorDispatcher() {
  GeneratedDispatcherRegistry.register<RemoteCollector>(
    _RemoteCollectorDispatcher,
  );
}

void $registerRemoteCollectorMethodIds() {
  ServiceMethodIdRegistry.register<RemoteCollector>({
    'waitFor': _RemoteCollectorMethods.waitForId,
  });
}

void registerRemoteCollectorGenerated() {
  $registerRemoteCollectorClientFactory();
  $registerRemoteCollectorMethodIds();
}

// Remote service implementation that auto-registers the dispatcher
class RemoteCollectorImpl extends RemoteCollector {
  @override
  bool get isRemote => true;
  @override
  Type get clientBaseType => RemoteCollector;
  @override
  Future<void> registerHostSide() async {
    $registerRemoteCollectorClientFactory();
    $registerRemoteCollectorMethodIds();
  }

  @override
  Future<void> initialize() async {
    $registerRemoteCollectorDispatcher();
    await super.initialize();
  }
}

void $registerRemoteCollectorLocalSide() {
  $registerRemoteCollectorDispatcher();
  $registerRemoteCollectorClientFactory();
  $registerRemoteCollectorMethodIds();
}

void $autoRegisterRemoteCollectorLocalSide() {
  LocalSideRegistry.register<RemoteCollector>(
      $registerRemoteCollectorLocalSide);
}

final $_RemoteCollectorLocalSideRegistered = (() {
  $autoRegisterRemoteCollectorLocalSide();
  return true;
})();

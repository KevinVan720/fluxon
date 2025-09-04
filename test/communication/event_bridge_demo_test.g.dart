// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_bridge_demo_test.dart';

// **************************************************************************
// ServiceGenerator
// **************************************************************************

// Service client for RemoteEmitter
class RemoteEmitterClient extends RemoteEmitter {
  RemoteEmitterClient(this._proxy);
  final ServiceProxy<RemoteEmitter> _proxy;

  @override
  Future<void> emitTick(String id) async {
    return await _proxy.callMethod('emitTick', [id], namedArgs: {});
  }
}

void $registerRemoteEmitterClientFactory() {
  GeneratedClientRegistry.register<RemoteEmitter>(
    (proxy) => RemoteEmitterClient(proxy),
  );
}

class _RemoteEmitterMethods {
  static const int emitTickId = 1;
}

Future<dynamic> _RemoteEmitterDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as RemoteEmitter;
  switch (methodId) {
    case _RemoteEmitterMethods.emitTickId:
      return await s.emitTick(positionalArgs[0]);
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
    'emitTick': _RemoteEmitterMethods.emitTickId,
  });
}

void registerRemoteEmitterGenerated() {
  $registerRemoteEmitterClientFactory();
  $registerRemoteEmitterMethodIds();
}

// Worker implementation that auto-registers the dispatcher
class RemoteEmitterWorker extends RemoteEmitter {
  @override
  Type get clientBaseType => RemoteEmitter;
  @override
  Future<void> registerHostSide() async {
    $registerRemoteEmitterClientFactory();
    $registerRemoteEmitterMethodIds();
    // Auto-registered from dependencies/optionalDependencies
    try {
      _registerLocalHubClientFactory();
    } catch (_) {}
    try {
      _registerLocalHubMethodIds();
    } catch (_) {}
    // Auto-registered from dependencies/optionalDependencies
    try {
      _registerRemoteListenerClientFactory();
    } catch (_) {}
    try {
      _registerRemoteListenerMethodIds();
    } catch (_) {}
  }

  @override
  Future<void> initialize() async {
    $registerRemoteEmitterDispatcher();
    // Ensure worker isolate can create clients for dependencies
    try {
      _registerLocalHubClientFactory();
    } catch (_) {}
    try {
      _registerLocalHubMethodIds();
    } catch (_) {}
    // Ensure worker isolate can create clients for dependencies
    try {
      _registerRemoteListenerClientFactory();
    } catch (_) {}
    try {
      _registerRemoteListenerMethodIds();
    } catch (_) {}
    await super.initialize();
  }
}

void $registerRemoteEmitterLocalSide() {
  $registerRemoteEmitterDispatcher();
  $registerRemoteEmitterClientFactory();
  $registerRemoteEmitterMethodIds();
  try {
    $registerLocalHubClientFactory();
  } catch (_) {}
  try {
    $registerLocalHubMethodIds();
  } catch (_) {}
  try {
    $registerRemoteListenerClientFactory();
  } catch (_) {}
  try {
    $registerRemoteListenerMethodIds();
  } catch (_) {}
}

// Service client for RemoteListener
class RemoteListenerClient extends RemoteListener {
  RemoteListenerClient(this._proxy);
  final ServiceProxy<RemoteListener> _proxy;

  @override
  Future<void> onTick(String id) async {
    return await _proxy.callMethod('onTick', [id], namedArgs: {});
  }

  @override
  Future<int> count() async {
    return await _proxy.callMethod('count', [], namedArgs: {});
  }
}

void $registerRemoteListenerClientFactory() {
  GeneratedClientRegistry.register<RemoteListener>(
    (proxy) => RemoteListenerClient(proxy),
  );
}

class _RemoteListenerMethods {
  static const int onTickId = 1;
  static const int countId = 2;
}

Future<dynamic> _RemoteListenerDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as RemoteListener;
  switch (methodId) {
    case _RemoteListenerMethods.onTickId:
      return await s.onTick(positionalArgs[0]);
    case _RemoteListenerMethods.countId:
      return await s.count();
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void $registerRemoteListenerDispatcher() {
  GeneratedDispatcherRegistry.register<RemoteListener>(
    _RemoteListenerDispatcher,
  );
}

void $registerRemoteListenerMethodIds() {
  ServiceMethodIdRegistry.register<RemoteListener>({
    'onTick': _RemoteListenerMethods.onTickId,
    'count': _RemoteListenerMethods.countId,
  });
}

void registerRemoteListenerGenerated() {
  $registerRemoteListenerClientFactory();
  $registerRemoteListenerMethodIds();
}

// Worker implementation that auto-registers the dispatcher
class RemoteListenerWorker extends RemoteListener {
  @override
  Type get clientBaseType => RemoteListener;
  @override
  Future<void> registerHostSide() async {
    $registerRemoteListenerClientFactory();
    $registerRemoteListenerMethodIds();
  }

  @override
  Future<void> initialize() async {
    $registerRemoteListenerDispatcher();
    await super.initialize();
  }
}

void $registerRemoteListenerLocalSide() {
  $registerRemoteListenerDispatcher();
  $registerRemoteListenerClientFactory();
  $registerRemoteListenerMethodIds();
}

// Service client for LocalHub
class LocalHubClient extends LocalHub {
  LocalHubClient(this._proxy);
  final ServiceProxy<LocalHub> _proxy;

  @override
  Future<void> onTick(String id) async {
    return await _proxy.callMethod('onTick', [id], namedArgs: {});
  }

  @override
  Future<int> getTicks() async {
    return await _proxy.callMethod('getTicks', [], namedArgs: {});
  }
}

void $registerLocalHubClientFactory() {
  GeneratedClientRegistry.register<LocalHub>(
    (proxy) => LocalHubClient(proxy),
  );
}

class _LocalHubMethods {
  static const int onTickId = 1;
  static const int getTicksId = 2;
}

Future<dynamic> _LocalHubDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as LocalHub;
  switch (methodId) {
    case _LocalHubMethods.onTickId:
      return await s.onTick(positionalArgs[0]);
    case _LocalHubMethods.getTicksId:
      return await s.getTicks();
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void $registerLocalHubDispatcher() {
  GeneratedDispatcherRegistry.register<LocalHub>(
    _LocalHubDispatcher,
  );
}

void $registerLocalHubMethodIds() {
  ServiceMethodIdRegistry.register<LocalHub>({
    'onTick': _LocalHubMethods.onTickId,
    'getTicks': _LocalHubMethods.getTicksId,
  });
}

void registerLocalHubGenerated() {
  $registerLocalHubClientFactory();
  $registerLocalHubMethodIds();
}

void $registerLocalHubLocalSide() {
  $registerLocalHubDispatcher();
  $registerLocalHubClientFactory();
  $registerLocalHubMethodIds();
}

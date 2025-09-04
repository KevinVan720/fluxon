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

void _registerRemoteEmitterClientFactory() {
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

void _registerRemoteEmitterDispatcher() {
  GeneratedDispatcherRegistry.register<RemoteEmitter>(
    _RemoteEmitterDispatcher,
  );
}

void _registerRemoteEmitterMethodIds() {
  ServiceMethodIdRegistry.register<RemoteEmitter>({
    'emitTick': _RemoteEmitterMethods.emitTickId,
  });
}

void registerRemoteEmitterGenerated() {
  _registerRemoteEmitterClientFactory();
  _registerRemoteEmitterMethodIds();
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

void _registerRemoteListenerClientFactory() {
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

void _registerRemoteListenerDispatcher() {
  GeneratedDispatcherRegistry.register<RemoteListener>(
    _RemoteListenerDispatcher,
  );
}

void _registerRemoteListenerMethodIds() {
  ServiceMethodIdRegistry.register<RemoteListener>({
    'onTick': _RemoteListenerMethods.onTickId,
    'count': _RemoteListenerMethods.countId,
  });
}

void registerRemoteListenerGenerated() {
  _registerRemoteListenerClientFactory();
  _registerRemoteListenerMethodIds();
}

// Service client for LocalHub
class LocalHubClient extends LocalHub {
  LocalHubClient(this._proxy);
  final ServiceProxy<LocalHub> _proxy;

  @override
  Future<void> onTick(String id) async {
    return await _proxy.callMethod('onTick', [id], namedArgs: {});
  }
}

void _registerLocalHubClientFactory() {
  GeneratedClientRegistry.register<LocalHub>(
    (proxy) => LocalHubClient(proxy),
  );
}

class _LocalHubMethods {
  static const int onTickId = 1;
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
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void _registerLocalHubDispatcher() {
  GeneratedDispatcherRegistry.register<LocalHub>(
    _LocalHubDispatcher,
  );
}

void _registerLocalHubMethodIds() {
  ServiceMethodIdRegistry.register<LocalHub>({
    'onTick': _LocalHubMethods.onTickId,
  });
}

void registerLocalHubGenerated() {
  _registerLocalHubClientFactory();
  _registerLocalHubMethodIds();
}

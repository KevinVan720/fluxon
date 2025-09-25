// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'generic_method_test.dart';

// **************************************************************************
// ServiceGenerator
// **************************************************************************

// Service client for GenericSvc
class GenericSvcClient extends GenericSvc {
  GenericSvcClient(this._proxy);
  final ServiceProxy<GenericSvc> _proxy;

  @override
  Future<T> echo<T extends Object>(T value) async {
    return await _proxy.callMethod<T>('echo', [value], namedArgs: {});
  }

  @override
  Future<List<T>> listify<T>(T value) async {
    return await _proxy.callMethod<List<T>>('listify', [value], namedArgs: {});
  }

  @override
  Future<Map<String, T>> mapify<T>(String key, T value) async {
    return await _proxy
        .callMethod<Map<String, T>>('mapify', [key, value], namedArgs: {});
  }

  @override
  Future<void> remember<T>(T value) async {
    await _proxy.callMethod<void>('remember', [value], namedArgs: {});
  }

  @override
  Future<List<dynamic>> dumpStash() async {
    return await _proxy
        .callMethod<List<dynamic>>('dumpStash', [], namedArgs: {});
  }
}

void $registerGenericSvcClientFactory() {
  GeneratedClientRegistry.register<GenericSvc>(
    (proxy) => GenericSvcClient(proxy),
  );
}

class _GenericSvcMethods {
  static const int echoId = 1;
  static const int listifyId = 2;
  static const int mapifyId = 3;
  static const int rememberId = 4;
  static const int dumpStashId = 5;
}

Future<dynamic> _GenericSvcDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as GenericSvc;
  switch (methodId) {
    case _GenericSvcMethods.echoId:
      return await s.echo(positionalArgs[0]);
    case _GenericSvcMethods.listifyId:
      return await s.listify(positionalArgs[0]);
    case _GenericSvcMethods.mapifyId:
      return await s.mapify(positionalArgs[0], positionalArgs[1]);
    case _GenericSvcMethods.rememberId:
      return await s.remember(positionalArgs[0]);
    case _GenericSvcMethods.dumpStashId:
      return await s.dumpStash();
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void $registerGenericSvcDispatcher() {
  GeneratedDispatcherRegistry.register<GenericSvc>(
    _GenericSvcDispatcher,
  );
}

void $registerGenericSvcMethodIds() {
  ServiceMethodIdRegistry.register<GenericSvc>({
    'echo': _GenericSvcMethods.echoId,
    'listify': _GenericSvcMethods.listifyId,
    'mapify': _GenericSvcMethods.mapifyId,
    'remember': _GenericSvcMethods.rememberId,
    'dumpStash': _GenericSvcMethods.dumpStashId,
  });
}

void registerGenericSvcGenerated() {
  $registerGenericSvcClientFactory();
  $registerGenericSvcMethodIds();
}

// Remote service implementation that auto-registers the dispatcher
class GenericSvcImpl extends GenericSvc {
  @override
  bool get isRemote => true;
  @override
  Type get clientBaseType => GenericSvc;
  @override
  Future<void> registerHostSide() async {
    $registerGenericSvcClientFactory();
    $registerGenericSvcMethodIds();
  }

  @override
  Future<void> initialize() async {
    $registerGenericSvcDispatcher();
    await super.initialize();
  }
}

void $registerGenericSvcLocalSide() {
  $registerGenericSvcDispatcher();
  $registerGenericSvcClientFactory();
  $registerGenericSvcMethodIds();
}

void $autoRegisterGenericSvcLocalSide() {
  LocalSideRegistry.register<GenericSvc>($registerGenericSvcLocalSide);
}

final $_GenericSvcLocalSideRegistered = (() {
  $autoRegisterGenericSvcLocalSide();
  return true;
})();

// Service client for GenericCaller
class GenericCallerClient extends GenericCaller {
  GenericCallerClient(this._proxy);
  final ServiceProxy<GenericCaller> _proxy;

  @override
  Future<(int, String)> run() async {
    return await _proxy.callMethod<(int, String)>('run', [], namedArgs: {});
  }
}

void $registerGenericCallerClientFactory() {
  GeneratedClientRegistry.register<GenericCaller>(
    (proxy) => GenericCallerClient(proxy),
  );
}

class _GenericCallerMethods {
  static const int runId = 1;
}

Future<dynamic> _GenericCallerDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as GenericCaller;
  switch (methodId) {
    case _GenericCallerMethods.runId:
      return await s.run();
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void $registerGenericCallerDispatcher() {
  GeneratedDispatcherRegistry.register<GenericCaller>(
    _GenericCallerDispatcher,
  );
}

void $registerGenericCallerMethodIds() {
  ServiceMethodIdRegistry.register<GenericCaller>({
    'run': _GenericCallerMethods.runId,
  });
}

void registerGenericCallerGenerated() {
  $registerGenericCallerClientFactory();
  $registerGenericCallerMethodIds();
}

// Local service implementation that auto-registers local side
class GenericCallerImpl extends GenericCaller {
  GenericCallerImpl() {
    // 🚀 AUTO-REGISTRATION: Register local side when instance is created
    $registerGenericCallerLocalSide();
  }
}

void $registerGenericCallerLocalSide() {
  $registerGenericCallerDispatcher();
  $registerGenericCallerClientFactory();
  $registerGenericCallerMethodIds();
  try {
    $registerGenericSvcClientFactory();
  } catch (_) {}
  try {
    $registerGenericSvcMethodIds();
  } catch (_) {}
}

void $autoRegisterGenericCallerLocalSide() {
  LocalSideRegistry.register<GenericCaller>($registerGenericCallerLocalSide);
}

final $_GenericCallerLocalSideRegistered = (() {
  $autoRegisterGenericCallerLocalSide();
  return true;
})();

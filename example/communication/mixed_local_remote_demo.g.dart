// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mixed_local_remote_demo.dart';

// **************************************************************************
// ServiceGenerator
// **************************************************************************

// Service client for RemoteMath
class RemoteMathClient extends RemoteMath {
  RemoteMathClient(this._proxy);
  final ServiceProxy<RemoteMath> _proxy;

  @override
  Future<int> mul(int a, int b) async {
    return await _proxy.callMethod('mul', [a, b], namedArgs: {});
  }

  @override
  Future<int> addViaLocal(int a, int b) async {
    return await _proxy.callMethod('addViaLocal', [a, b], namedArgs: {});
  }
}

void _registerRemoteMathClientFactory() {
  GeneratedClientRegistry.register<RemoteMath>(
    (proxy) => RemoteMathClient(proxy),
  );
}

class _RemoteMathMethods {
  static const int mulId = 1;
  static const int addViaLocalId = 2;
}

Future<dynamic> _RemoteMathDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as RemoteMath;
  switch (methodId) {
    case _RemoteMathMethods.mulId:
      return await s.mul(positionalArgs[0], positionalArgs[1]);
    case _RemoteMathMethods.addViaLocalId:
      return await s.addViaLocal(positionalArgs[0], positionalArgs[1]);
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void _registerRemoteMathDispatcher() {
  GeneratedDispatcherRegistry.register<RemoteMath>(
    _RemoteMathDispatcher,
  );
}

void _registerRemoteMathMethodIds() {
  ServiceMethodIdRegistry.register<RemoteMath>({
    'mul': _RemoteMathMethods.mulId,
    'addViaLocal': _RemoteMathMethods.addViaLocalId,
  });
}

void registerRemoteMathGenerated() {
  _registerRemoteMathClientFactory();
  _registerRemoteMathMethodIds();
}

// Service client for LocalAdder
class LocalAdderClient extends LocalAdder {
  LocalAdderClient(this._proxy);
  final ServiceProxy<LocalAdder> _proxy;

  @override
  Future<int> add(int a, int b) async {
    return await _proxy.callMethod('add', [a, b], namedArgs: {});
  }
}

void _registerLocalAdderClientFactory() {
  GeneratedClientRegistry.register<LocalAdder>(
    (proxy) => LocalAdderClient(proxy),
  );
}

class _LocalAdderMethods {
  static const int addId = 1;
}

Future<dynamic> _LocalAdderDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as LocalAdder;
  switch (methodId) {
    case _LocalAdderMethods.addId:
      return await s.add(positionalArgs[0], positionalArgs[1]);
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void _registerLocalAdderDispatcher() {
  GeneratedDispatcherRegistry.register<LocalAdder>(
    _LocalAdderDispatcher,
  );
}

void _registerLocalAdderMethodIds() {
  ServiceMethodIdRegistry.register<LocalAdder>({
    'add': _LocalAdderMethods.addId,
  });
}

void registerLocalAdderGenerated() {
  _registerLocalAdderClientFactory();
  _registerLocalAdderMethodIds();
}

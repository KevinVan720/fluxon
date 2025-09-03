// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'version_skew_demo_test.dart';

// **************************************************************************
// ServiceGenerator
// **************************************************************************

// Service client for ApiV1
class ApiV1Client extends ApiV1 {
  ApiV1Client(this._proxy);
  final ServiceProxy<ApiV1> _proxy;

  @override
  Future<String> greet(String name) async {
    return await _proxy.callMethod('greet', [name], namedArgs: {});
  }
}

void _registerApiV1ClientFactory() {
  GeneratedClientRegistry.register<ApiV1>(
    (proxy) => ApiV1Client(proxy),
  );
}

class _ApiV1Methods {
  static const int greetId = 1;
}

Future<dynamic> _ApiV1Dispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as ApiV1;
  switch (methodId) {
    case _ApiV1Methods.greetId:
      return await s.greet(positionalArgs[0]);
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void _registerApiV1Dispatcher() {
  GeneratedDispatcherRegistry.register<ApiV1>(
    _ApiV1Dispatcher,
  );
}

void _registerApiV1MethodIds() {
  ServiceMethodIdRegistry.register<ApiV1>({
    'greet': _ApiV1Methods.greetId,
  });
}

void registerApiV1Generated() {
  _registerApiV1ClientFactory();
  _registerApiV1MethodIds();
}

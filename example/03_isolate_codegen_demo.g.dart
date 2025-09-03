// GENERATED CODE - DO NOT MODIFY BY HAND

part of '03_isolate_codegen_demo.dart';

// **************************************************************************
// ServiceGenerator
// **************************************************************************

// Service client for MathService
class MathServiceClient extends MathService {
  MathServiceClient(this._proxy);
  final ServiceProxy<MathService> _proxy;

  @override
  Future<int> add(int a, int b) async {
    return await _proxy.callMethod('add', [a, b]);
  }
}

void _registerMathServiceClientFactory() {
  GeneratedClientRegistry.register<MathService>(
    (proxy) => MathServiceClient(proxy),
  );
}

class _MathServiceMethods {
  static const int addId = 1;
}

Future<dynamic> _MathServiceDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> args,
) async {
  final s = service as MathService;
  switch (methodId) {
    case _MathServiceMethods.addId:
      return await s.add(args[0], args[1]);
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void _registerMathServiceDispatcher() {
  GeneratedDispatcherRegistry.register<MathService>(_MathServiceDispatcher);
}

void _registerMathServiceMethodIds() {
  ServiceMethodIdRegistry.register<MathService>({
    'add': _MathServiceMethods.addId,
  });
}

void registerMathServiceGenerated() {
  _registerMathServiceClientFactory();
  _registerMathServiceMethodIds();
}

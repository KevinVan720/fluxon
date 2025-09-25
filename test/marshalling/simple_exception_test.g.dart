// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'simple_exception_test.dart';

// **************************************************************************
// ServiceGenerator
// **************************************************************************

// Service client for SimpleExceptionService
class SimpleExceptionServiceClient extends SimpleExceptionService {
  SimpleExceptionServiceClient(this._proxy);
  final ServiceProxy<SimpleExceptionService> _proxy;

  @override
  Future<String> throwSimpleException() async {
    final result =
        await _proxy.callMethod('throwSimpleException', [], namedArgs: {});
    return result as String;
  }

  @override
  Future<String> conditionalMethod(bool shouldFail) async {
    final result = await _proxy
        .callMethod('conditionalMethod', [shouldFail], namedArgs: {});
    return result as String;
  }

  @override
  Future<String> throwWithDetails() async {
    final result =
        await _proxy.callMethod('throwWithDetails', [], namedArgs: {});
    return result as String;
  }
}

void $registerSimpleExceptionServiceClientFactory() {
  GeneratedClientRegistry.register<SimpleExceptionService>(
    (proxy) => SimpleExceptionServiceClient(proxy),
  );
}

class _SimpleExceptionServiceMethods {
  static const int throwSimpleExceptionId = 1;
  static const int conditionalMethodId = 2;
  static const int throwWithDetailsId = 3;
}

Future<dynamic> _SimpleExceptionServiceDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as SimpleExceptionService;
  switch (methodId) {
    case _SimpleExceptionServiceMethods.throwSimpleExceptionId:
      return await s.throwSimpleException();
    case _SimpleExceptionServiceMethods.conditionalMethodId:
      return await s.conditionalMethod(positionalArgs[0]);
    case _SimpleExceptionServiceMethods.throwWithDetailsId:
      return await s.throwWithDetails();
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void $registerSimpleExceptionServiceDispatcher() {
  GeneratedDispatcherRegistry.register<SimpleExceptionService>(
    _SimpleExceptionServiceDispatcher,
  );
}

void $registerSimpleExceptionServiceMethodIds() {
  ServiceMethodIdRegistry.register<SimpleExceptionService>({
    'throwSimpleException':
        _SimpleExceptionServiceMethods.throwSimpleExceptionId,
    'conditionalMethod': _SimpleExceptionServiceMethods.conditionalMethodId,
    'throwWithDetails': _SimpleExceptionServiceMethods.throwWithDetailsId,
  });
}

void registerSimpleExceptionServiceGenerated() {
  $registerSimpleExceptionServiceClientFactory();
  $registerSimpleExceptionServiceMethodIds();
}

// Remote service implementation that auto-registers the dispatcher
class SimpleExceptionServiceImpl extends SimpleExceptionService {
  @override
  bool get isRemote => true;
  @override
  Type get clientBaseType => SimpleExceptionService;
  @override
  Future<void> registerHostSide() async {
    $registerSimpleExceptionServiceClientFactory();
    $registerSimpleExceptionServiceMethodIds();
  }

  @override
  Future<void> initialize() async {
    $registerSimpleExceptionServiceDispatcher();
    await super.initialize();
  }
}

void $registerSimpleExceptionServiceLocalSide() {
  $registerSimpleExceptionServiceDispatcher();
  $registerSimpleExceptionServiceClientFactory();
  $registerSimpleExceptionServiceMethodIds();
}

void $autoRegisterSimpleExceptionServiceLocalSide() {
  LocalSideRegistry.register<SimpleExceptionService>(
      $registerSimpleExceptionServiceLocalSide);
}

final $_SimpleExceptionServiceLocalSideRegistered = (() {
  $autoRegisterSimpleExceptionServiceLocalSide();
  return true;
})();

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exception_marshalling_test.dart';

// **************************************************************************
// ServiceGenerator
// **************************************************************************

// Service client for ExceptionTestService
class ExceptionTestServiceClient extends ExceptionTestService {
  ExceptionTestServiceClient(this._proxy);
  final ServiceProxy<ExceptionTestService> _proxy;

  @override
  Future<String> throwStandardException() async {
    return await _proxy.callMethod('throwStandardException', [], namedArgs: {});
  }

  @override
  Future<String> throwServiceException() async {
    return await _proxy.callMethod('throwServiceException', [], namedArgs: {});
  }

  @override
  Future<String> throwCustomException() async {
    return await _proxy.callMethod('throwCustomException', [], namedArgs: {});
  }

  @override
  Future<String> throwComplexException() async {
    return await _proxy.callMethod('throwComplexException', [], namedArgs: {});
  }

  @override
  Future<String> conditionalThrow(bool shouldThrow, String errorType) async {
    return await _proxy.callMethod('conditionalThrow', [shouldThrow, errorType],
        namedArgs: {});
  }

  @override
  Future<String> throwDuringAsyncWork() async {
    return await _proxy.callMethod('throwDuringAsyncWork', [], namedArgs: {});
  }

  @override
  Future<String> catchAndRethrow() async {
    return await _proxy.callMethod('catchAndRethrow', [], namedArgs: {});
  }
}

void $registerExceptionTestServiceClientFactory() {
  GeneratedClientRegistry.register<ExceptionTestService>(
    (proxy) => ExceptionTestServiceClient(proxy),
  );
}

class _ExceptionTestServiceMethods {
  static const int throwStandardExceptionId = 1;
  static const int throwServiceExceptionId = 2;
  static const int throwCustomExceptionId = 3;
  static const int throwComplexExceptionId = 4;
  static const int conditionalThrowId = 5;
  static const int throwDuringAsyncWorkId = 6;
  static const int catchAndRethrowId = 7;
}

Future<dynamic> _ExceptionTestServiceDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as ExceptionTestService;
  switch (methodId) {
    case _ExceptionTestServiceMethods.throwStandardExceptionId:
      return await s.throwStandardException();
    case _ExceptionTestServiceMethods.throwServiceExceptionId:
      return await s.throwServiceException();
    case _ExceptionTestServiceMethods.throwCustomExceptionId:
      return await s.throwCustomException();
    case _ExceptionTestServiceMethods.throwComplexExceptionId:
      return await s.throwComplexException();
    case _ExceptionTestServiceMethods.conditionalThrowId:
      return await s.conditionalThrow(positionalArgs[0], positionalArgs[1]);
    case _ExceptionTestServiceMethods.throwDuringAsyncWorkId:
      return await s.throwDuringAsyncWork();
    case _ExceptionTestServiceMethods.catchAndRethrowId:
      return await s.catchAndRethrow();
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void $registerExceptionTestServiceDispatcher() {
  GeneratedDispatcherRegistry.register<ExceptionTestService>(
    _ExceptionTestServiceDispatcher,
  );
}

void $registerExceptionTestServiceMethodIds() {
  ServiceMethodIdRegistry.register<ExceptionTestService>({
    'throwStandardException':
        _ExceptionTestServiceMethods.throwStandardExceptionId,
    'throwServiceException':
        _ExceptionTestServiceMethods.throwServiceExceptionId,
    'throwCustomException': _ExceptionTestServiceMethods.throwCustomExceptionId,
    'throwComplexException':
        _ExceptionTestServiceMethods.throwComplexExceptionId,
    'conditionalThrow': _ExceptionTestServiceMethods.conditionalThrowId,
    'throwDuringAsyncWork': _ExceptionTestServiceMethods.throwDuringAsyncWorkId,
    'catchAndRethrow': _ExceptionTestServiceMethods.catchAndRethrowId,
  });
}

void registerExceptionTestServiceGenerated() {
  $registerExceptionTestServiceClientFactory();
  $registerExceptionTestServiceMethodIds();
}

// Remote service implementation that auto-registers the dispatcher
class ExceptionTestServiceImpl extends ExceptionTestService {
  @override
  bool get isRemote => true;
  @override
  Type get clientBaseType => ExceptionTestService;
  @override
  Future<void> registerHostSide() async {
    $registerExceptionTestServiceClientFactory();
    $registerExceptionTestServiceMethodIds();
  }

  @override
  Future<void> initialize() async {
    $registerExceptionTestServiceDispatcher();
    await super.initialize();
  }
}

void $registerExceptionTestServiceLocalSide() {
  $registerExceptionTestServiceDispatcher();
  $registerExceptionTestServiceClientFactory();
  $registerExceptionTestServiceMethodIds();
}

void $autoRegisterExceptionTestServiceLocalSide() {
  LocalSideRegistry.register<ExceptionTestService>(
      $registerExceptionTestServiceLocalSide);
}

final $_ExceptionTestServiceLocalSideRegistered = (() {
  $autoRegisterExceptionTestServiceLocalSide();
  return true;
})();

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'complex_marshalling_test.dart';

// **************************************************************************
// ServiceGenerator
// **************************************************************************

// Service client for ComplexMarshallingService
class ComplexMarshallingServiceClient extends ComplexMarshallingService {
  ComplexMarshallingServiceClient(this._proxy);
  final ServiceProxy<ComplexMarshallingService> _proxy;

  @override
  Future<ComplexUser> processUser(ComplexUser user) async {
    return await _proxy
        .callMethod<ComplexUser>('processUser', [user], namedArgs: {});
  }

  @override
  Future<Map<Priority, List<ComplexUser>>> groupUsersByPriority(
      List<ComplexUser> users) async {
    return await _proxy.callMethod<Map<Priority, List<ComplexUser>>>(
        'groupUsersByPriority', [users],
        namedArgs: {});
  }

  @override
  Future<Map<String, Map<Priority, List<Project>>>> getProjectMatrix(
      List<ComplexUser> users) async {
    return await _proxy.callMethod<Map<String, Map<Priority, List<Project>>>>(
        'getProjectMatrix', [users],
        namedArgs: {});
  }

  @override
  Future<ComplexUser> createUserWithManager() async {
    return await _proxy
        .callMethod<ComplexUser>('createUserWithManager', [], namedArgs: {});
  }
}

void $registerComplexMarshallingServiceClientFactory() {
  GeneratedClientRegistry.register<ComplexMarshallingService>(
    (proxy) => ComplexMarshallingServiceClient(proxy),
  );
}

class _ComplexMarshallingServiceMethods {
  static const int processUserId = 1;
  static const int groupUsersByPriorityId = 2;
  static const int getProjectMatrixId = 3;
  static const int createUserWithManagerId = 4;
}

Future<dynamic> _ComplexMarshallingServiceDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as ComplexMarshallingService;
  switch (methodId) {
    case _ComplexMarshallingServiceMethods.processUserId:
      return await s.processUser(positionalArgs[0]);
    case _ComplexMarshallingServiceMethods.groupUsersByPriorityId:
      return await s.groupUsersByPriority(positionalArgs[0]);
    case _ComplexMarshallingServiceMethods.getProjectMatrixId:
      return await s.getProjectMatrix(positionalArgs[0]);
    case _ComplexMarshallingServiceMethods.createUserWithManagerId:
      return await s.createUserWithManager();
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void $registerComplexMarshallingServiceDispatcher() {
  GeneratedDispatcherRegistry.register<ComplexMarshallingService>(
    _ComplexMarshallingServiceDispatcher,
  );
}

void $registerComplexMarshallingServiceMethodIds() {
  ServiceMethodIdRegistry.register<ComplexMarshallingService>({
    'processUser': _ComplexMarshallingServiceMethods.processUserId,
    'groupUsersByPriority':
        _ComplexMarshallingServiceMethods.groupUsersByPriorityId,
    'getProjectMatrix': _ComplexMarshallingServiceMethods.getProjectMatrixId,
    'createUserWithManager':
        _ComplexMarshallingServiceMethods.createUserWithManagerId,
  });
}

void registerComplexMarshallingServiceGenerated() {
  $registerComplexMarshallingServiceClientFactory();
  $registerComplexMarshallingServiceMethodIds();
}

// Remote service implementation that auto-registers the dispatcher
class ComplexMarshallingServiceImpl extends ComplexMarshallingService {
  @override
  bool get isRemote => true;
  @override
  Type get clientBaseType => ComplexMarshallingService;
  @override
  Future<void> registerHostSide() async {
    $registerComplexMarshallingServiceClientFactory();
    $registerComplexMarshallingServiceMethodIds();
  }

  @override
  Future<void> initialize() async {
    $registerComplexMarshallingServiceDispatcher();
    await super.initialize();
  }
}

void $registerComplexMarshallingServiceLocalSide() {
  $registerComplexMarshallingServiceDispatcher();
  $registerComplexMarshallingServiceClientFactory();
  $registerComplexMarshallingServiceMethodIds();
}

void $autoRegisterComplexMarshallingServiceLocalSide() {
  LocalSideRegistry.register<ComplexMarshallingService>(
      $registerComplexMarshallingServiceLocalSide);
}

final $_ComplexMarshallingServiceLocalSideRegistered = (() {
  $autoRegisterComplexMarshallingServiceLocalSide();
  return true;
})();

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
    final result =
        await _proxy.callMethod('processUser', [user], namedArgs: {});
    return result as ComplexUser;
  }

  @override
  Future<Map<Priority, List<ComplexUser>>> groupUsersByPriority(
      List<ComplexUser> users) async {
    final result =
        await _proxy.callMethod('groupUsersByPriority', [users], namedArgs: {});
    return result as Map<Priority, List<ComplexUser>>;
  }

  @override
  Future<Map<String, Map<Priority, List<Project>>>> getProjectMatrix(
      List<ComplexUser> users) async {
    final result =
        await _proxy.callMethod('getProjectMatrix', [users], namedArgs: {});
    return result as Map<String, Map<Priority, List<Project>>>;
  }

  @override
  Future<ComplexUser> createUserWithManager() async {
    final result =
        await _proxy.callMethod('createUserWithManager', [], namedArgs: {});
    return result as ComplexUser;
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

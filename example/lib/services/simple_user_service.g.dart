// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'simple_user_service.dart';

// **************************************************************************
// ServiceGenerator
// **************************************************************************

// Service client for SimpleUserService
class SimpleUserServiceClient extends SimpleUserService {
  SimpleUserServiceClient(this._proxy);
  final ServiceProxy<SimpleUserService> _proxy;

  @override
  Future<List<User>> getAllUsers() async {
    return await _proxy.callMethod('getAllUsers', [], namedArgs: {});
  }

  @override
  Future<User> getUserById(String userId) async {
    return await _proxy.callMethod('getUserById', [userId], namedArgs: {});
  }

  @override
  Future<User> getCurrentUser() async {
    return await _proxy.callMethod('getCurrentUser', [], namedArgs: {});
  }
}

void $registerSimpleUserServiceClientFactory() {
  GeneratedClientRegistry.register<SimpleUserService>(
    (proxy) => SimpleUserServiceClient(proxy),
  );
}

class _SimpleUserServiceMethods {
  static const int getAllUsersId = 1;
  static const int getUserByIdId = 2;
  static const int getCurrentUserId = 3;
}

Future<dynamic> _SimpleUserServiceDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as SimpleUserService;
  switch (methodId) {
    case _SimpleUserServiceMethods.getAllUsersId:
      return await s.getAllUsers();
    case _SimpleUserServiceMethods.getUserByIdId:
      return await s.getUserById(positionalArgs[0]);
    case _SimpleUserServiceMethods.getCurrentUserId:
      return await s.getCurrentUser();
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void $registerSimpleUserServiceDispatcher() {
  GeneratedDispatcherRegistry.register<SimpleUserService>(
    _SimpleUserServiceDispatcher,
  );
}

void $registerSimpleUserServiceMethodIds() {
  ServiceMethodIdRegistry.register<SimpleUserService>({
    'getAllUsers': _SimpleUserServiceMethods.getAllUsersId,
    'getUserById': _SimpleUserServiceMethods.getUserByIdId,
    'getCurrentUser': _SimpleUserServiceMethods.getCurrentUserId,
  });
}

void registerSimpleUserServiceGenerated() {
  $registerSimpleUserServiceClientFactory();
  $registerSimpleUserServiceMethodIds();
}

void $registerSimpleUserServiceLocalSide() {
  $registerSimpleUserServiceDispatcher();
  $registerSimpleUserServiceClientFactory();
  $registerSimpleUserServiceMethodIds();
}

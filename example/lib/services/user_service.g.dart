// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_service.dart';

// **************************************************************************
// ServiceGenerator
// **************************************************************************

// Service client for UserService
class UserServiceClient extends UserService {
  UserServiceClient(this._proxy);
  final ServiceProxy<UserService> _proxy;

  @override
  Future<List<User>> getAllUsers() async {
    return await _proxy.callMethod('getAllUsers', [], namedArgs: {});
  }

  @override
  Future<User> getUserById(String userId) async {
    return await _proxy.callMethod('getUserById', [userId], namedArgs: {});
  }

  @override
  Future<List<User>> getUsersByRole(UserRole role) async {
    return await _proxy.callMethod('getUsersByRole', [role], namedArgs: {});
  }

  @override
  Future<User> createUser(
      {required String name,
      required String email,
      UserRole role = UserRole.member,
      String? avatar}) async {
    return await _proxy.callMethod('createUser', [], namedArgs: {
      'name': name,
      'email': email,
      'role': role,
      'avatar': avatar
    });
  }

  @override
  Future<User> updateUser(String userId,
      {String? name, String? email, UserRole? role, String? avatar}) async {
    return await _proxy.callMethod('updateUser', [
      userId
    ], namedArgs: {
      'name': name,
      'email': email,
      'role': role,
      'avatar': avatar
    });
  }

  @override
  Future<List<User>> searchUsers(String query) async {
    return await _proxy.callMethod('searchUsers', [query], namedArgs: {});
  }

  @override
  Future<User> getCurrentUser() async {
    return await _proxy.callMethod('getCurrentUser', [], namedArgs: {});
  }
}

void $registerUserServiceClientFactory() {
  GeneratedClientRegistry.register<UserService>(
    (proxy) => UserServiceClient(proxy),
  );
}

class _UserServiceMethods {
  static const int getAllUsersId = 1;
  static const int getUserByIdId = 2;
  static const int getUsersByRoleId = 3;
  static const int createUserId = 4;
  static const int updateUserId = 5;
  static const int searchUsersId = 6;
  static const int getCurrentUserId = 7;
}

Future<dynamic> _UserServiceDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as UserService;
  switch (methodId) {
    case _UserServiceMethods.getAllUsersId:
      return await s.getAllUsers();
    case _UserServiceMethods.getUserByIdId:
      return await s.getUserById(positionalArgs[0]);
    case _UserServiceMethods.getUsersByRoleId:
      return await s.getUsersByRole(positionalArgs[0]);
    case _UserServiceMethods.createUserId:
      return await s.createUser(
          name: namedArgs['name'],
          email: namedArgs['email'],
          role: namedArgs['role'],
          avatar: namedArgs['avatar']);
    case _UserServiceMethods.updateUserId:
      return await s.updateUser(positionalArgs[0],
          name: namedArgs['name'],
          email: namedArgs['email'],
          role: namedArgs['role'],
          avatar: namedArgs['avatar']);
    case _UserServiceMethods.searchUsersId:
      return await s.searchUsers(positionalArgs[0]);
    case _UserServiceMethods.getCurrentUserId:
      return await s.getCurrentUser();
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void $registerUserServiceDispatcher() {
  GeneratedDispatcherRegistry.register<UserService>(
    _UserServiceDispatcher,
  );
}

void $registerUserServiceMethodIds() {
  ServiceMethodIdRegistry.register<UserService>({
    'getAllUsers': _UserServiceMethods.getAllUsersId,
    'getUserById': _UserServiceMethods.getUserByIdId,
    'getUsersByRole': _UserServiceMethods.getUsersByRoleId,
    'createUser': _UserServiceMethods.createUserId,
    'updateUser': _UserServiceMethods.updateUserId,
    'searchUsers': _UserServiceMethods.searchUsersId,
    'getCurrentUser': _UserServiceMethods.getCurrentUserId,
  });
}

void registerUserServiceGenerated() {
  $registerUserServiceClientFactory();
  $registerUserServiceMethodIds();
}

void $registerUserServiceLocalSide() {
  $registerUserServiceDispatcher();
  $registerUserServiceClientFactory();
  $registerUserServiceMethodIds();
  try {
    $registerStorageServiceClientFactory();
  } catch (_) {}
  try {
    $registerStorageServiceMethodIds();
  } catch (_) {}
}

void $autoRegisterUserServiceLocalSide() {
  LocalSideRegistry.register<UserService>($registerUserServiceLocalSide);
}

final $_UserServiceLocalSideRegistered = (() {
  $autoRegisterUserServiceLocalSide();
  return true;
})();

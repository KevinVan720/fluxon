// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'storage_service.dart';

// **************************************************************************
// ServiceGenerator
// **************************************************************************

// Service client for StorageService
class StorageServiceClient extends StorageService {
  StorageServiceClient(this._proxy);
  final ServiceProxy<StorageService> _proxy;

  @override
  Future<void> saveTasks(List<Task> tasks) async {
    return await _proxy.callMethod('saveTasks', [tasks], namedArgs: {});
  }

  @override
  Future<List<Task>> loadTasks() async {
    return await _proxy.callMethod('loadTasks', [], namedArgs: {});
  }

  @override
  Future<void> saveUsers(List<User> users) async {
    return await _proxy.callMethod('saveUsers', [users], namedArgs: {});
  }

  @override
  Future<List<User>> loadUsers() async {
    return await _proxy.callMethod('loadUsers', [], namedArgs: {});
  }

  @override
  Future<void> clearAll() async {
    return await _proxy.callMethod('clearAll', [], namedArgs: {});
  }
}

void $registerStorageServiceClientFactory() {
  GeneratedClientRegistry.register<StorageService>(
    (proxy) => StorageServiceClient(proxy),
  );
}

class _StorageServiceMethods {
  static const int saveTasksId = 1;
  static const int loadTasksId = 2;
  static const int saveUsersId = 3;
  static const int loadUsersId = 4;
  static const int clearAllId = 5;
}

Future<dynamic> _StorageServiceDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as StorageService;
  switch (methodId) {
    case _StorageServiceMethods.saveTasksId:
      return await s.saveTasks(positionalArgs[0]);
    case _StorageServiceMethods.loadTasksId:
      return await s.loadTasks();
    case _StorageServiceMethods.saveUsersId:
      return await s.saveUsers(positionalArgs[0]);
    case _StorageServiceMethods.loadUsersId:
      return await s.loadUsers();
    case _StorageServiceMethods.clearAllId:
      return await s.clearAll();
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void $registerStorageServiceDispatcher() {
  GeneratedDispatcherRegistry.register<StorageService>(
    _StorageServiceDispatcher,
  );
}

void $registerStorageServiceMethodIds() {
  ServiceMethodIdRegistry.register<StorageService>({
    'saveTasks': _StorageServiceMethods.saveTasksId,
    'loadTasks': _StorageServiceMethods.loadTasksId,
    'saveUsers': _StorageServiceMethods.saveUsersId,
    'loadUsers': _StorageServiceMethods.loadUsersId,
    'clearAll': _StorageServiceMethods.clearAllId,
  });
}

void registerStorageServiceGenerated() {
  $registerStorageServiceClientFactory();
  $registerStorageServiceMethodIds();
}

void $registerStorageServiceLocalSide() {
  $registerStorageServiceDispatcher();
  $registerStorageServiceClientFactory();
  $registerStorageServiceMethodIds();
}

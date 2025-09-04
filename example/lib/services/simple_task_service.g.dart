// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'simple_task_service.dart';

// **************************************************************************
// ServiceGenerator
// **************************************************************************

// Service client for SimpleTaskService
class SimpleTaskServiceClient extends SimpleTaskService {
  SimpleTaskServiceClient(this._proxy);
  final ServiceProxy<SimpleTaskService> _proxy;

  @override
  Future<Task> createTask(
      {required String title,
      required String description,
      required String assignedTo,
      TaskPriority priority = TaskPriority.medium,
      DateTime? dueDate,
      List<String> tags = const []}) async {
    return await _proxy.callMethod('createTask', [], namedArgs: {
      'title': title,
      'description': description,
      'assignedTo': assignedTo,
      'priority': priority,
      'dueDate': dueDate,
      'tags': tags
    });
  }

  @override
  Future<Task> updateTaskStatus(
      String taskId, TaskStatus newStatus, String changedBy) async {
    return await _proxy.callMethod(
        'updateTaskStatus', [taskId, newStatus, changedBy],
        namedArgs: {});
  }

  @override
  Future<List<Task>> getAllTasks() async {
    return await _proxy.callMethod('getAllTasks', [], namedArgs: {});
  }

  @override
  Future<List<Task>> getTasksByStatus(TaskStatus status) async {
    return await _proxy.callMethod('getTasksByStatus', [status], namedArgs: {});
  }

  @override
  Future<List<Task>> getTasksForUser(String userId) async {
    return await _proxy.callMethod('getTasksForUser', [userId], namedArgs: {});
  }

  @override
  Future<void> deleteTask(String taskId) async {
    return await _proxy.callMethod('deleteTask', [taskId], namedArgs: {});
  }

  @override
  Future<Map<String, dynamic>> getTaskStats() async {
    return await _proxy.callMethod('getTaskStats', [], namedArgs: {});
  }
}

void $registerSimpleTaskServiceClientFactory() {
  GeneratedClientRegistry.register<SimpleTaskService>(
    (proxy) => SimpleTaskServiceClient(proxy),
  );
}

class _SimpleTaskServiceMethods {
  static const int createTaskId = 1;
  static const int updateTaskStatusId = 2;
  static const int getAllTasksId = 3;
  static const int getTasksByStatusId = 4;
  static const int getTasksForUserId = 5;
  static const int deleteTaskId = 6;
  static const int getTaskStatsId = 7;
}

Future<dynamic> _SimpleTaskServiceDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as SimpleTaskService;
  switch (methodId) {
    case _SimpleTaskServiceMethods.createTaskId:
      return await s.createTask(
          title: namedArgs['title'],
          description: namedArgs['description'],
          assignedTo: namedArgs['assignedTo'],
          priority: namedArgs['priority'],
          dueDate: namedArgs['dueDate'],
          tags: namedArgs['tags']);
    case _SimpleTaskServiceMethods.updateTaskStatusId:
      return await s.updateTaskStatus(
          positionalArgs[0], positionalArgs[1], positionalArgs[2]);
    case _SimpleTaskServiceMethods.getAllTasksId:
      return await s.getAllTasks();
    case _SimpleTaskServiceMethods.getTasksByStatusId:
      return await s.getTasksByStatus(positionalArgs[0]);
    case _SimpleTaskServiceMethods.getTasksForUserId:
      return await s.getTasksForUser(positionalArgs[0]);
    case _SimpleTaskServiceMethods.deleteTaskId:
      return await s.deleteTask(positionalArgs[0]);
    case _SimpleTaskServiceMethods.getTaskStatsId:
      return await s.getTaskStats();
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void $registerSimpleTaskServiceDispatcher() {
  GeneratedDispatcherRegistry.register<SimpleTaskService>(
    _SimpleTaskServiceDispatcher,
  );
}

void $registerSimpleTaskServiceMethodIds() {
  ServiceMethodIdRegistry.register<SimpleTaskService>({
    'createTask': _SimpleTaskServiceMethods.createTaskId,
    'updateTaskStatus': _SimpleTaskServiceMethods.updateTaskStatusId,
    'getAllTasks': _SimpleTaskServiceMethods.getAllTasksId,
    'getTasksByStatus': _SimpleTaskServiceMethods.getTasksByStatusId,
    'getTasksForUser': _SimpleTaskServiceMethods.getTasksForUserId,
    'deleteTask': _SimpleTaskServiceMethods.deleteTaskId,
    'getTaskStats': _SimpleTaskServiceMethods.getTaskStatsId,
  });
}

void registerSimpleTaskServiceGenerated() {
  $registerSimpleTaskServiceClientFactory();
  $registerSimpleTaskServiceMethodIds();
}

void $registerSimpleTaskServiceLocalSide() {
  $registerSimpleTaskServiceDispatcher();
  $registerSimpleTaskServiceClientFactory();
  $registerSimpleTaskServiceMethodIds();
}

void $autoRegisterSimpleTaskServiceLocalSide() {
  LocalSideRegistry.register<SimpleTaskService>(
      $registerSimpleTaskServiceLocalSide);
}

final $_SimpleTaskServiceLocalSideRegistered = (() {
  $autoRegisterSimpleTaskServiceLocalSide();
  return true;
})();

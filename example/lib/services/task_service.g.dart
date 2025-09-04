// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_service.dart';

// **************************************************************************
// ServiceGenerator
// **************************************************************************

// Service client for TaskService
class TaskServiceClient extends TaskService {
  TaskServiceClient(this._proxy);
  final ServiceProxy<TaskService> _proxy;

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
  Future<List<Task>> searchTasks(String query) async {
    return await _proxy.callMethod('searchTasks', [query], namedArgs: {});
  }

  @override
  Future<Map<String, dynamic>> getTaskStats() async {
    return await _proxy.callMethod('getTaskStats', [], namedArgs: {});
  }
}

void $registerTaskServiceClientFactory() {
  GeneratedClientRegistry.register<TaskService>(
    (proxy) => TaskServiceClient(proxy),
  );
}

class _TaskServiceMethods {
  static const int createTaskId = 1;
  static const int updateTaskStatusId = 2;
  static const int getAllTasksId = 3;
  static const int getTasksByStatusId = 4;
  static const int getTasksForUserId = 5;
  static const int deleteTaskId = 6;
  static const int searchTasksId = 7;
  static const int getTaskStatsId = 8;
}

Future<dynamic> _TaskServiceDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as TaskService;
  switch (methodId) {
    case _TaskServiceMethods.createTaskId:
      return await s.createTask(
          title: namedArgs['title'],
          description: namedArgs['description'],
          assignedTo: namedArgs['assignedTo'],
          priority: namedArgs['priority'],
          dueDate: namedArgs['dueDate'],
          tags: namedArgs['tags']);
    case _TaskServiceMethods.updateTaskStatusId:
      return await s.updateTaskStatus(
          positionalArgs[0], positionalArgs[1], positionalArgs[2]);
    case _TaskServiceMethods.getAllTasksId:
      return await s.getAllTasks();
    case _TaskServiceMethods.getTasksByStatusId:
      return await s.getTasksByStatus(positionalArgs[0]);
    case _TaskServiceMethods.getTasksForUserId:
      return await s.getTasksForUser(positionalArgs[0]);
    case _TaskServiceMethods.deleteTaskId:
      return await s.deleteTask(positionalArgs[0]);
    case _TaskServiceMethods.searchTasksId:
      return await s.searchTasks(positionalArgs[0]);
    case _TaskServiceMethods.getTaskStatsId:
      return await s.getTaskStats();
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void $registerTaskServiceDispatcher() {
  GeneratedDispatcherRegistry.register<TaskService>(
    _TaskServiceDispatcher,
  );
}

void $registerTaskServiceMethodIds() {
  ServiceMethodIdRegistry.register<TaskService>({
    'createTask': _TaskServiceMethods.createTaskId,
    'updateTaskStatus': _TaskServiceMethods.updateTaskStatusId,
    'getAllTasks': _TaskServiceMethods.getAllTasksId,
    'getTasksByStatus': _TaskServiceMethods.getTasksByStatusId,
    'getTasksForUser': _TaskServiceMethods.getTasksForUserId,
    'deleteTask': _TaskServiceMethods.deleteTaskId,
    'searchTasks': _TaskServiceMethods.searchTasksId,
    'getTaskStats': _TaskServiceMethods.getTaskStatsId,
  });
}

void registerTaskServiceGenerated() {
  $registerTaskServiceClientFactory();
  $registerTaskServiceMethodIds();
}

void $registerTaskServiceLocalSide() {
  $registerTaskServiceDispatcher();
  $registerTaskServiceClientFactory();
  $registerTaskServiceMethodIds();
  try {
    $registerStorageServiceClientFactory();
  } catch (_) {}
  try {
    $registerStorageServiceMethodIds();
  } catch (_) {}
}

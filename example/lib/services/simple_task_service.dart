import 'package:uuid/uuid.dart';
import 'package:flux/flux.dart';
import '../events/task_events.dart';
import '../models/task.dart';

part 'simple_task_service.g.dart';

/// Simplified task service without external dependencies
@ServiceContract(remote: false)
class SimpleTaskService extends FluxService {
  final List<Task> _tasks = [];
  final _uuid = const Uuid();

  @override
  Future<void> initialize() async {
    // Create some demo tasks
    _tasks.addAll([
      Task(
        id: _uuid.v4(),
        title: 'Setup Flux Framework Demo',
        description:
            'Create a comprehensive demo showing all Flux capabilities',
        assignedTo: '1',
        status: TaskStatus.completed,
        priority: TaskPriority.high,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        completedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Task(
        id: _uuid.v4(),
        title: 'Implement Real-Time Events',
        description: 'Add cross-isolate event communication between services',
        assignedTo: '2',
        status: TaskStatus.inProgress,
        priority: TaskPriority.high,
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      ),
      Task(
        id: _uuid.v4(),
        title: 'Add Analytics Dashboard',
        description: 'Create analytics service running in worker isolate',
        assignedTo: '3',
        status: TaskStatus.todo,
        priority: TaskPriority.medium,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        dueDate: DateTime.now().add(const Duration(days: 3)),
      ),
    ]);

    logger.info(
      'Simple task service initialized with ${_tasks.length} demo tasks',
    );
    await super.initialize();
  }

  /// Create a new task
  Future<Task> createTask({
    required String title,
    required String description,
    required String assignedTo,
    TaskPriority priority = TaskPriority.medium,
    DateTime? dueDate,
    List<String> tags = const [],
  }) async {
    final task = Task(
      id: _uuid.v4(),
      title: title,
      description: description,
      assignedTo: assignedTo,
      status: TaskStatus.todo,
      priority: priority,
      createdAt: DateTime.now(),
      dueDate: dueDate,
      tags: tags,
    );

    _tasks.add(task);

    // 📡 EVENT SYSTEM: Send event to notify other services
    await sendEvent(
      TaskCreatedEvent(
        taskId: task.id,
        title: task.title,
        assignedTo: task.assignedTo,
        eventId: _uuid.v4(),
        sourceService: serviceName,
        timestamp: DateTime.now(),
      ),
    );

    logger.info(
      'Created task: ${task.title}',
      metadata: {'taskId': task.id, 'assignedTo': task.assignedTo},
    );

    return task;
  }

  /// Update task status
  Future<Task> updateTaskStatus(
    String taskId,
    TaskStatus newStatus,
    String changedBy,
  ) async {
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1) {
      throw ServiceException('Task not found: $taskId');
    }

    final oldTask = _tasks[taskIndex];
    final updatedTask = oldTask.copyWith(
      status: newStatus,
      completedAt: newStatus == TaskStatus.completed ? DateTime.now() : null,
    );

    _tasks[taskIndex] = updatedTask;

    // 📡 EVENT SYSTEM: Broadcast status change
    await sendEvent(
      TaskStatusChangedEvent(
        taskId: taskId,
        oldStatus: oldTask.status.name,
        newStatus: newStatus.name,
        changedBy: changedBy,
        eventId: _uuid.v4(),
        sourceService: serviceName,
        timestamp: DateTime.now(),
      ),
    );

    logger.info(
      'Updated task status',
      metadata: {
        'taskId': taskId,
        'oldStatus': oldTask.status.name,
        'newStatus': newStatus.name,
        'changedBy': changedBy,
      },
    );

    return updatedTask;
  }

  /// Get all tasks
  Future<List<Task>> getAllTasks() async => List.from(_tasks);

  /// Get tasks by status
  Future<List<Task>> getTasksByStatus(TaskStatus status) async =>
      _tasks.where((task) => task.status == status).toList();

  /// Get tasks assigned to a user
  Future<List<Task>> getTasksForUser(String userId) async =>
      _tasks.where((task) => task.assignedTo == userId).toList();

  /// Delete a task
  Future<void> deleteTask(String taskId) async {
    _tasks.removeWhere((task) => task.id == taskId);
    logger.info('Deleted task', metadata: {'taskId': taskId});
  }

  /// Get task statistics
  Future<Map<String, dynamic>> getTaskStats() async => {
    'total': _tasks.length,
    'todo': _tasks.where((t) => t.status == TaskStatus.todo).length,
    'inProgress': _tasks.where((t) => t.status == TaskStatus.inProgress).length,
    'review': _tasks.where((t) => t.status == TaskStatus.review).length,
    'completed': _tasks.where((t) => t.status == TaskStatus.completed).length,
    'cancelled': _tasks.where((t) => t.status == TaskStatus.cancelled).length,
    'overdue': _tasks
        .where(
          (t) =>
              t.dueDate != null &&
              t.dueDate!.isBefore(DateTime.now()) &&
              t.status != TaskStatus.completed,
        )
        .length,
  };
}

import 'package:uuid/uuid.dart';
import 'package:flux/flux.dart';
import '../events/task_events.dart';
import 'user_service.dart';

part 'notification_service.g.dart';

/// Background notification service
/// This service runs in a worker isolate for non-blocking operation
@ServiceContract(remote: true)
class NotificationService extends FluxService {
  final List<Map<String, dynamic>> _notifications = [];
  final _uuid = const Uuid();

  // 🔗 DEPENDENCY SYSTEM: Optional dependency on UserService
  @override
  List<Type> get optionalDependencies => [UserService];

  @override
  Future<void> initialize() async {
    // Ensure event types are registered in worker isolate
    registerExampleEventTypes();

    // 📡 EVENT SYSTEM: Listen to task events from any service
    onEvent<TaskCreatedEvent>((event) async {
      await _sendTaskAssignmentNotification(
        event.assignedTo,
        event.title,
        event.taskId,
      );
      return const EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration(milliseconds: 10),
      );
    });

    onEvent<TaskStatusChangedEvent>((event) async {
      await _sendTaskStatusNotification(
        event.taskId,
        event.newStatus,
        event.changedBy,
      );
      return const EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration(milliseconds: 15),
      );
    });

    logger.info('Notification service initialized in worker isolate');
    await super.initialize();
  }

  /// Send a custom notification
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String message,
    String type = 'info',
  }) async {
    final notification = {
      'id': _uuid.v4(),
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'timestamp': DateTime.now().toIso8601String(),
      'read': false,
    };

    _notifications.add(notification);

    // 📡 EVENT SYSTEM: Send notification event
    await sendEvent(
      NotificationEvent(
        userId: userId,
        title: title,
        message: message,
        type: type,
        eventId: _uuid.v4(),
        sourceService: serviceName,
        timestamp: DateTime.now(),
      ),
    );

    logger.info(
      'Notification sent',
      metadata: {'userId': userId, 'title': title, 'type': type},
    );
  }

  /// Get notifications for a user
  Future<List<Map<String, dynamic>>> getNotificationsForUser(
    String userId,
  ) async {
    return _notifications.where((n) => n['userId'] == userId).toList()..sort(
      (a, b) => DateTime.parse(
        b['timestamp'],
      ).compareTo(DateTime.parse(a['timestamp'])),
    );
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    final notification = _notifications.firstWhere(
      (n) => n['id'] == notificationId,
      orElse: () => <String, dynamic>{},
    );

    if (notification.isNotEmpty) {
      notification['read'] = true;
      logger.info(
        'Notification marked as read',
        metadata: {'notificationId': notificationId},
      );
    }
  }

  /// Get unread count for user
  Future<int> getUnreadCount(String userId) async {
    return _notifications
        .where((n) => n['userId'] == userId && n['read'] == false)
        .length;
  }

  // Private helper methods
  Future<void> _sendTaskAssignmentNotification(
    String userId,
    String taskTitle,
    String taskId,
  ) async {
    // 🔄 SERVICE PROXY SYSTEM: Get user info if available
    try {
      final userService = getService<UserService>();
      await userService.getUserById(userId);

      await sendNotification(
        userId: userId,
        title: 'New Task Assigned',
        message: 'You have been assigned: "$taskTitle"',
        type: 'task_assigned',
      );
    } catch (e) {
      // UserService might not be available, send generic notification
      await sendNotification(
        userId: userId,
        title: 'New Task Assigned',
        message: 'You have been assigned: "$taskTitle"',
        type: 'task_assigned',
      );
    }
  }

  Future<void> _sendTaskStatusNotification(
    String taskId,
    String newStatus,
    String changedBy,
  ) async {
    // Find users who should be notified (could be expanded to get from task assignee)
    await sendNotification(
      userId: changedBy, // Notify the person who made the change
      title: 'Task Updated',
      message: 'Task status changed to: $newStatus',
      type: 'task_status_changed',
    );
  }
}

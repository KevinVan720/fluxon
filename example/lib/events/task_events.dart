import 'package:flux/flux.dart';

/// Event fired when a task is created
class TaskCreatedEvent extends ServiceEvent {
  const TaskCreatedEvent({
    required this.taskId,
    required this.title,
    required this.assignedTo,
    required super.eventId,
    required super.sourceService,
    required super.timestamp,
    super.metadata = const {},
    super.correlationId,
  });

  final String taskId;
  final String title;
  final String assignedTo;

  @override
  Map<String, dynamic> eventDataToJson() => {
    'taskId': taskId,
    'title': title,
    'assignedTo': assignedTo,
  };

  factory TaskCreatedEvent.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return TaskCreatedEvent(
      taskId: data['taskId'],
      title: data['title'],
      assignedTo: data['assignedTo'],
      eventId: json['eventId'],
      sourceService: json['sourceService'],
      timestamp: DateTime.parse(json['timestamp']),
      correlationId: json['correlationId'],
      metadata: json['metadata'] ?? {},
    );
  }
}

/// Event fired when a task status changes
class TaskStatusChangedEvent extends ServiceEvent {
  const TaskStatusChangedEvent({
    required this.taskId,
    required this.oldStatus,
    required this.newStatus,
    required this.changedBy,
    required super.eventId,
    required super.sourceService,
    required super.timestamp,
    super.metadata = const {},
    super.correlationId,
  });

  final String taskId;
  final String oldStatus;
  final String newStatus;
  final String changedBy;

  @override
  Map<String, dynamic> eventDataToJson() => {
    'taskId': taskId,
    'oldStatus': oldStatus,
    'newStatus': newStatus,
    'changedBy': changedBy,
  };

  factory TaskStatusChangedEvent.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return TaskStatusChangedEvent(
      taskId: data['taskId'],
      oldStatus: data['oldStatus'],
      newStatus: data['newStatus'],
      changedBy: data['changedBy'],
      eventId: json['eventId'],
      sourceService: json['sourceService'],
      timestamp: DateTime.parse(json['timestamp']),
      correlationId: json['correlationId'],
      metadata: json['metadata'] ?? {},
    );
  }
}

/// Event fired when a notification should be sent
class NotificationEvent extends ServiceEvent {
  const NotificationEvent({
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required super.eventId,
    required super.sourceService,
    required super.timestamp,
    super.metadata = const {},
    super.correlationId,
  });

  final String userId;
  final String title;
  final String message;
  final String type; // 'task_assigned', 'task_completed', 'reminder', etc.

  @override
  Map<String, dynamic> eventDataToJson() => {
    'userId': userId,
    'title': title,
    'message': message,
    'type': type,
  };

  factory NotificationEvent.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return NotificationEvent(
      userId: data['userId'],
      title: data['title'],
      message: data['message'],
      type: data['type'],
      eventId: json['eventId'],
      sourceService: json['sourceService'],
      timestamp: DateTime.parse(json['timestamp']),
      correlationId: json['correlationId'],
      metadata: json['metadata'] ?? {},
    );
  }
}

/// Event fired for analytics tracking
class AnalyticsEvent extends ServiceEvent {
  const AnalyticsEvent({
    required this.action,
    required this.entity,
    required this.properties,
    required super.eventId,
    required super.sourceService,
    required super.timestamp,
    super.metadata = const {},
    super.correlationId,
  });

  final String action; // 'create', 'update', 'delete', 'view'
  final String entity; // 'task', 'user', 'project'
  final Map<String, dynamic> properties;

  @override
  Map<String, dynamic> eventDataToJson() => {
    'action': action,
    'entity': entity,
    'properties': properties,
  };

  factory AnalyticsEvent.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return AnalyticsEvent(
      action: data['action'],
      entity: data['entity'],
      properties: data['properties'],
      eventId: json['eventId'],
      sourceService: json['sourceService'],
      timestamp: DateTime.parse(json['timestamp']),
      correlationId: json['correlationId'],
      metadata: json['metadata'] ?? {},
    );
  }
}

/// Register all example app event types in the current isolate
void registerExampleEventTypes() {
  EventTypeRegistry.register<TaskCreatedEvent>(
    (json) => TaskCreatedEvent.fromJson(json),
  );
  EventTypeRegistry.register<TaskStatusChangedEvent>(
    (json) => TaskStatusChangedEvent.fromJson(json),
  );
  EventTypeRegistry.register<NotificationEvent>(
    (json) => NotificationEvent.fromJson(json),
  );
  EventTypeRegistry.register<AnalyticsEvent>(
    (json) => AnalyticsEvent.fromJson(json),
  );
}

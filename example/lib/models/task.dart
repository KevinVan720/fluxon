/// Task data model
class Task {
  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.assignedTo,
    required this.status,
    required this.priority,
    required this.createdAt,
    this.dueDate,
    this.completedAt,
    this.tags = const [],
  });

  final String id;
  final String title;
  final String description;
  final String assignedTo;
  final TaskStatus status;
  final TaskPriority priority;
  final DateTime createdAt;
  final DateTime? dueDate;
  final DateTime? completedAt;
  final List<String> tags;

  /// Create a copy of this task with updated fields
  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? assignedTo,
    TaskStatus? status,
    TaskPriority? priority,
    DateTime? createdAt,
    DateTime? dueDate,
    DateTime? completedAt,
    List<String>? tags,
  }) => Task(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description ?? this.description,
    assignedTo: assignedTo ?? this.assignedTo,
    status: status ?? this.status,
    priority: priority ?? this.priority,
    createdAt: createdAt ?? this.createdAt,
    dueDate: dueDate ?? this.dueDate,
    completedAt: completedAt ?? this.completedAt,
    tags: tags ?? this.tags,
  );

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'assignedTo': assignedTo,
    'status': status.name,
    'priority': priority.name,
    'createdAt': createdAt.toIso8601String(),
    'dueDate': dueDate?.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'tags': tags,
  };

  /// Create from JSON
  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    assignedTo: json['assignedTo'],
    status: TaskStatus.values.byName(json['status']),
    priority: TaskPriority.values.byName(json['priority']),
    createdAt: DateTime.parse(json['createdAt']),
    dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
    completedAt: json['completedAt'] != null
        ? DateTime.parse(json['completedAt'])
        : null,
    tags: List<String>.from(json['tags'] ?? []),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Task && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Task(id: $id, title: $title, status: $status)';
}

/// Task status enumeration
enum TaskStatus {
  todo('To Do'),
  inProgress('In Progress'),
  review('In Review'),
  completed('Completed'),
  cancelled('Cancelled');

  const TaskStatus(this.displayName);
  final String displayName;
}

/// Task priority enumeration
enum TaskPriority {
  low('Low'),
  medium('Medium'),
  high('High'),
  urgent('Urgent');

  const TaskPriority(this.displayName);
  final String displayName;
}

/// User data model
class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    this.role = UserRole.member,
  });

  final String id;
  final String name;
  final String email;
  final String? avatar;
  final UserRole role;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'avatar': avatar,
    'role': role.name,
  };

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'],
    name: json['name'],
    email: json['email'],
    avatar: json['avatar'],
    role: UserRole.values.byName(json['role']),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

enum UserRole {
  admin('Admin'),
  manager('Manager'),
  member('Member');

  const UserRole(this.displayName);
  final String displayName;
}

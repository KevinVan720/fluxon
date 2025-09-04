import 'package:flutter/material.dart';
import 'package:dart_service_framework/dart_service_framework.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import '../services/user_service.dart';
import '../services/notification_service.dart';
// import '../services/analytics_service.dart'; // Unused
// import '../services/background_processor.dart'; // Unused
import 'task_details_screen.dart';
import 'analytics_screen.dart';
import 'create_task_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.runtime});

  final FluxRuntime runtime;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<Task> _tasks = [];
  List<User> _users = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // 🔄 SERVICE PROXY SYSTEM: Get services transparently (local/remote)
      final taskService = widget.runtime.get<TaskService>();
      final userService = widget.runtime.get<UserService>();

      // Load data from services
      final tasks = await taskService.getAllTasks();
      final users = await userService.getAllUsers();
      final stats = await taskService.getTaskStats();

      setState(() {
        _tasks = tasks;
        _users = users;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FluxTasks'),
        // subtitle: const Text('Powered by Flux Framework'), // Removed - not supported in newer Flutter
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.task), text: 'Tasks'),
            Tab(icon: Icon(Icons.people), text: 'Team'),
            Tab(icon: Icon(Icons.notifications), text: 'Alerts'),
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh Data',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showFrameworkInfo,
            tooltip: 'Framework Info',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTasksTab(),
                _buildTeamTab(),
                _buildNotificationsTab(),
                _buildAnalyticsTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createTask,
        child: const Icon(Icons.add),
        tooltip: 'Create New Task',
      ),
    );
  }

  Widget _buildTasksTab() {
    if (_tasks.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No tasks yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            Text('Tap + to create your first task'),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Stats cards
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total',
                  _stats['total']?.toString() ?? '0',
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'In Progress',
                  _stats['inProgress']?.toString() ?? '0',
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Completed',
                  _stats['completed']?.toString() ?? '0',
                  Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Overdue',
                  _stats['overdue']?.toString() ?? '0',
                  Colors.red,
                ),
              ),
            ],
          ),
        ),
        // Task list
        Expanded(
          child: ListView.builder(
            itemCount: _tasks.length,
            itemBuilder: (context, index) {
              final task = _tasks[index];
              return _buildTaskCard(task);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTeamTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        final userTasks = _tasks.where((t) => t.assignedTo == user.id).length;

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getRoleColor(user.role),
              child: Text(user.name.substring(0, 1).toUpperCase()),
            ),
            title: Text(user.name),
            subtitle: Text('${user.email} • ${user.role.displayName}'),
            trailing: Chip(
              label: Text('$userTasks tasks'),
              backgroundColor: Colors.blue.withOpacity(0.1),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationsTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getNotifications(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final notifications = snapshot.data ?? [];

        if (notifications.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No notifications',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index];
            return _buildNotificationCard(notification);
          },
        );
      },
    );
  }

  Widget _buildAnalyticsTab() {
    return AnalyticsScreen(runtime: widget.runtime);
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(Task task) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getPriorityColor(task.priority),
          child: Icon(
            _getStatusIcon(task.status),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.status == TaskStatus.completed
                ? TextDecoration.lineThrough
                : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task.description),
            const SizedBox(height: 4),
            Row(
              children: [
                Chip(
                  label: Text(task.status.displayName),
                  backgroundColor: _getStatusColor(
                    task.status,
                  ).withOpacity(0.2),
                  labelStyle: TextStyle(color: _getStatusColor(task.status)),
                ),
                const SizedBox(width: 8),
                if (task.dueDate != null)
                  Chip(
                    label: Text('Due: ${_formatDate(task.dueDate!)}'),
                    backgroundColor: _isDue(task.dueDate!)
                        ? Colors.red.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.2),
                  ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) => _handleTaskAction(task, action),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'start', child: Text('Start')),
            const PopupMenuItem(value: 'complete', child: Text('Complete')),
            const PopupMenuItem(value: 'details', child: Text('Details')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
        onTap: () => _showTaskDetails(task),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final isRead = notification['read'] as bool;

    return Card(
      color: isRead ? null : Colors.blue.withOpacity(0.05),
      child: ListTile(
        leading: Icon(
          _getNotificationIcon(notification['type']),
          color: isRead ? Colors.grey : Colors.blue,
        ),
        title: Text(
          notification['title'],
          style: TextStyle(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Text(notification['message']),
        trailing: Text(
          _formatTimestamp(notification['timestamp']),
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        onTap: () => _markNotificationAsRead(notification['id']),
      ),
    );
  }

  Future<void> _createTask() async {
    final result = await Navigator.push<Task>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CreateTaskScreen(runtime: widget.runtime, users: _users),
      ),
    );

    if (result != null) {
      await _loadData(); // Refresh data
    }
  }

  Future<void> _handleTaskAction(Task task, String action) async {
    final taskService = widget.runtime.get<TaskService>();
    final currentUser = await widget.runtime
        .get<UserService>()
        .getCurrentUser();

    try {
      switch (action) {
        case 'start':
          await taskService.updateTaskStatus(
            task.id,
            TaskStatus.inProgress,
            currentUser.id,
          );
          break;
        case 'complete':
          await taskService.updateTaskStatus(
            task.id,
            TaskStatus.completed,
            currentUser.id,
          );
          break;
        case 'details':
          await _showTaskDetails(task);
          return; // Don't refresh for details view
        case 'delete':
          await taskService.deleteTask(task.id);
          break;
      }

      await _loadData(); // Refresh after action

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Task ${action}d successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _showTaskDetails(Task task) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            TaskDetailsScreen(task: task, runtime: widget.runtime),
      ),
    );
    await _loadData(); // Refresh in case task was modified
  }

  Future<List<Map<String, dynamic>>> _getNotifications() async {
    try {
      final notificationService = widget.runtime.get<NotificationService>();
      final currentUser = await widget.runtime
          .get<UserService>()
          .getCurrentUser();
      return await notificationService.getNotificationsForUser(currentUser.id);
    } catch (e) {
      return [];
    }
  }

  Future<void> _markNotificationAsRead(String notificationId) async {
    try {
      final notificationService = widget.runtime.get<NotificationService>();
      await notificationService.markAsRead(notificationId);
      setState(() {}); // Refresh notifications
    } catch (e) {
      // Handle error silently for notifications
    }
  }

  void _showFrameworkInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🚀 Flux Framework Demo'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This app demonstrates all three core Flux systems:'),
            SizedBox(height: 12),
            Text('🔗 Dependency System:'),
            Text('• TaskService depends on StorageService'),
            Text('• Services initialize in correct order'),
            SizedBox(height: 8),
            Text('🔄 Service Proxy System:'),
            Text('• Local services: TaskService, UserService, StorageService'),
            Text(
              '• Remote services: NotificationService, AnalyticsService, BackgroundProcessor',
            ),
            Text('• Transparent method calls across isolates'),
            SizedBox(height: 8),
            Text('📡 Event System:'),
            Text('• TaskCreatedEvent → NotificationService'),
            Text('• TaskStatusChangedEvent → AnalyticsService'),
            Text('• All events flow automatically across isolates'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Helper methods
  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.high:
        return Colors.red;
      case TaskPriority.urgent:
        return Colors.purple;
    }
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return Colors.grey;
      case TaskStatus.inProgress:
        return Colors.blue;
      case TaskStatus.review:
        return Colors.orange;
      case TaskStatus.completed:
        return Colors.green;
      case TaskStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return Icons.radio_button_unchecked;
      case TaskStatus.inProgress:
        return Icons.play_circle;
      case TaskStatus.review:
        return Icons.rate_review;
      case TaskStatus.completed:
        return Icons.check_circle;
      case TaskStatus.cancelled:
        return Icons.cancel;
    }
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Colors.purple;
      case UserRole.manager:
        return Colors.blue;
      case UserRole.member:
        return Colors.green;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'task_assigned':
        return Icons.assignment;
      case 'task_status_changed':
        return Icons.update;
      case 'reminder':
        return Icons.alarm;
      default:
        return Icons.info;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Now';
    }
  }

  String _formatTimestamp(String timestamp) {
    final date = DateTime.parse(timestamp);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  bool _isDue(DateTime dueDate) {
    return dueDate.isBefore(DateTime.now());
  }
}

import 'package:flutter/material.dart';
import 'package:dart_service_framework/dart_service_framework.dart';
import '../models/task.dart';
import '../services/simple_task_service.dart';
import '../services/simple_user_service.dart';
// import '../services/notification_service.dart'; // Not directly used in UI
// import '../services/analytics_service.dart'; // Not directly used in UI

class HomeScreenSimple extends StatefulWidget {
  const HomeScreenSimple({super.key, required this.runtime});

  final FluxRuntime runtime;

  @override
  State<HomeScreenSimple> createState() => _HomeScreenSimpleState();
}

class _HomeScreenSimpleState extends State<HomeScreenSimple> {
  List<Task> _tasks = [];
  List<User> _users = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // 🔄 SERVICE PROXY SYSTEM: Get services transparently
      final taskService = widget.runtime.get<SimpleTaskService>();
      final userService = widget.runtime.get<SimpleUserService>();

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
        title: const Text('FluxTasks Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh Data',
          ),
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: _showFrameworkInfo,
            tooltip: 'Framework Info',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Stats row
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
                    ],
                  ),
                ),
                // Task list
                Expanded(
                  child: _tasks.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.task_outlined,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Demo tasks loaded!',
                                style: TextStyle(fontSize: 18),
                              ),
                              Text('Tap + to create more tasks'),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _tasks.length,
                          itemBuilder: (context, index) {
                            final task = _tasks[index];
                            return _buildTaskCard(task);
                          },
                        ),
                ),
                // Framework demo info
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.indigo.withAlpha(50)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.rocket_launch, color: Colors.indigo),
                          SizedBox(width: 8),
                          Text(
                            '🚀 Flux Framework Live Demo',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildDemoPoint(
                        '🔗 Dependency System',
                        'Services initialize in correct order automatically',
                      ),
                      _buildDemoPoint(
                        '🔄 Service Proxy System',
                        'AnalyticsService & NotificationService run in worker isolates',
                      ),
                      _buildDemoPoint(
                        '📡 Event System',
                        'TaskCreatedEvent flows to all services automatically',
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Create a task to see events flow across isolates in real-time!',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.indigo,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createDemoTask,
        child: const Icon(Icons.add),
        tooltip: 'Create Demo Task',
      ),
    );
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
    final user = _users.firstWhere(
      (u) => u.id == task.assignedTo,
      orElse: () => const User(
        id: 'unknown',
        name: 'Unknown',
        email: '',
        role: UserRole.member,
      ),
    );

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
            Text('Assigned to: ${user.name}'),
            const SizedBox(height: 4),
            Row(
              children: [
                Chip(
                  label: Text(task.status.displayName),
                  backgroundColor: _getStatusColor(task.status).withAlpha(50),
                  labelStyle: TextStyle(color: _getStatusColor(task.status)),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(task.priority.displayName),
                  backgroundColor: _getPriorityColor(
                    task.priority,
                  ).withAlpha(50),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) => _handleTaskAction(task, action),
          itemBuilder: (context) => [
            if (task.status != TaskStatus.inProgress)
              const PopupMenuItem(value: 'start', child: Text('Start')),
            if (task.status == TaskStatus.inProgress)
              const PopupMenuItem(value: 'complete', child: Text('Complete')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }

  Widget _buildDemoPoint(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 20, child: Text('•')),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87, fontSize: 14),
                children: [
                  TextSpan(
                    text: title,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const TextSpan(text: ': '),
                  TextSpan(text: description),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createDemoTask() async {
    final taskTitles = [
      'Review Flux Framework Architecture',
      'Implement Cross-Isolate Events',
      'Add Service Dependency Resolution',
      'Create Analytics Dashboard',
      'Setup Background Processing',
      'Add Real-Time Notifications',
    ];

    final descriptions = [
      'Deep dive into the three core Flux systems and their interactions',
      'Ensure events flow seamlessly between main isolate and worker isolates',
      'Verify dependency graph resolution works correctly',
      'Build comprehensive analytics using worker isolate for heavy computation',
      'Move CPU-intensive tasks to background workers',
      'Implement push notifications triggered by service events',
    ];

    final title = taskTitles[DateTime.now().millisecond % taskTitles.length];
    final description =
        descriptions[DateTime.now().millisecond % descriptions.length];
    final assignedUser = _users[DateTime.now().millisecond % _users.length];

    try {
      final taskService = widget.runtime.get<SimpleTaskService>();
      await taskService.createTask(
        title: title,
        description: description,
        assignedTo: assignedUser.id,
        priority: TaskPriority
            .values[DateTime.now().millisecond % TaskPriority.values.length],
        dueDate: DateTime.now().add(
          Duration(days: DateTime.now().millisecond % 7 + 1),
        ),
      );

      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Task created! Watch events flow to worker isolates',
            ),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'View Logs',
              onPressed: () {
                // In a real app, you could show logs or analytics
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Check console for Flux event logs!'),
                  ),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleTaskAction(Task task, String action) async {
    final taskService = widget.runtime.get<SimpleTaskService>();
    final currentUser = await widget.runtime
        .get<SimpleUserService>()
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
        case 'delete':
          await taskService.deleteTask(task.id);
          break;
      }

      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Task ${action}d! Events sent to worker services'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showFrameworkInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🚀 Flux Framework Demo'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This app demonstrates all three core Flux systems working together:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),

              Text(
                '🔗 Dependency System:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                '• Services declare dependencies and initialize in correct order',
              ),
              Text(
                '• SimpleTaskService and SimpleUserService have no external dependencies',
              ),
              Text('• Framework automatically resolves the dependency graph'),
              SizedBox(height: 12),

              Text(
                '🔄 Service Proxy System:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text('• Local services: SimpleTaskService, SimpleUserService'),
              Text('• Remote services: NotificationService, AnalyticsService'),
              Text('• UI calls methods transparently regardless of location'),
              SizedBox(height: 12),

              Text(
                '📡 Event System:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text('• TaskCreatedEvent → NotificationService (worker isolate)'),
              Text(
                '• TaskStatusChangedEvent → AnalyticsService (worker isolate)',
              ),
              Text(
                '• Events automatically serialize/deserialize across isolates',
              ),
              SizedBox(height: 12),

              Text(
                '🎯 Zero Boilerplate:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text('• Just extend FluxService and use @ServiceContract'),
              Text('• FluxRuntime handles all infrastructure automatically'),
              Text('• No manual event dispatcher or proxy setup needed'),
            ],
          ),
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
}

import 'package:flutter/material.dart';
import 'package:dart_service_framework/dart_service_framework.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import '../services/user_service.dart';
import '../services/background_processor.dart';

class TaskDetailsScreen extends StatefulWidget {
  const TaskDetailsScreen({
    super.key,
    required this.task,
    required this.runtime,
  });

  final Task task;
  final FluxRuntime runtime;

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  late Task _currentTask;
  User? _assignedUser;
  Map<String, dynamic>? _recommendations;
  bool _isLoadingRecommendations = false;

  @override
  void initState() {
    super.initState();
    _currentTask = widget.task;
    _loadTaskDetails();
  }

  Future<void> _loadTaskDetails() async {
    try {
      // 🔄 SERVICE PROXY SYSTEM: Get user details
      final userService = widget.runtime.get<UserService>();
      final user = await userService.getUserById(_currentTask.assignedTo);

      setState(() {
        _assignedUser = user;
      });
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _loadRecommendations() async {
    setState(() {
      _isLoadingRecommendations = true;
    });

    try {
      // 🔄 SERVICE PROXY SYSTEM: Call worker isolate service
      final backgroundProcessor = widget.runtime.get<BackgroundProcessor>();
      final recommendations = await backgroundProcessor
          .generateTaskRecommendations(_currentTask.assignedTo);

      setState(() {
        _recommendations = {'recommendations': recommendations};
        _isLoadingRecommendations = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingRecommendations = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading recommendations: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        actions: [
          PopupMenuButton<String>(
            onSelected: _handleAction,
            itemBuilder: (context) => [
              if (_currentTask.status != TaskStatus.inProgress)
                const PopupMenuItem(value: 'start', child: Text('Start Task')),
              if (_currentTask.status == TaskStatus.inProgress)
                const PopupMenuItem(
                  value: 'review',
                  child: Text('Submit for Review'),
                ),
              if (_currentTask.status == TaskStatus.review)
                const PopupMenuItem(
                  value: 'complete',
                  child: Text('Mark Complete'),
                ),
              const PopupMenuItem(
                value: 'recommendations',
                child: Text('Get AI Recommendations'),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentTask.title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            decoration:
                                _currentTask.status == TaskStatus.completed
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentTask.description,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      children: [
                        Chip(
                          label: Text(_currentTask.status.displayName),
                          backgroundColor: _getStatusColor(
                            _currentTask.status,
                          ).withOpacity(0.2),
                          labelStyle: TextStyle(
                            color: _getStatusColor(_currentTask.status),
                          ),
                        ),
                        Chip(
                          label: Text(_currentTask.priority.displayName),
                          backgroundColor: _getPriorityColor(
                            _currentTask.priority,
                          ).withOpacity(0.2),
                          labelStyle: TextStyle(
                            color: _getPriorityColor(_currentTask.priority),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Task metadata
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Details',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow('Task ID', _currentTask.id),
                    _buildDetailRow(
                      'Created',
                      _formatDateTime(_currentTask.createdAt),
                    ),
                    if (_currentTask.dueDate != null)
                      _buildDetailRow(
                        'Due Date',
                        _formatDateTime(_currentTask.dueDate!),
                      ),
                    if (_currentTask.completedAt != null)
                      _buildDetailRow(
                        'Completed',
                        _formatDateTime(_currentTask.completedAt!),
                      ),
                    if (_assignedUser != null)
                      _buildDetailRow(
                        'Assigned To',
                        '${_assignedUser!.name} (${_assignedUser!.email})',
                      ),
                    if (_currentTask.tags.isNotEmpty)
                      _buildDetailRow('Tags', _currentTask.tags.join(', ')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // AI Recommendations section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: Colors.purple),
                        const SizedBox(width: 8),
                        Text(
                          'AI Recommendations',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Spacer(),
                        if (!_isLoadingRecommendations)
                          TextButton(
                            onPressed: _loadRecommendations,
                            child: const Text('Generate'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_isLoadingRecommendations)
                      const Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 8),
                            Text('AI analyzing task patterns...'),
                            Text(
                              'Running in worker isolate',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (_recommendations != null)
                      _buildRecommendations()
                    else
                      const Text(
                        'Tap "Generate" to get AI-powered recommendations for this task.',
                        style: TextStyle(color: Colors.grey),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Framework info
            Card(
              color: Colors.indigo.withOpacity(0.05),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.rocket_launch, color: Colors.indigo),
                        SizedBox(width: 8),
                        Text(
                          'Flux Framework in Action',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildFluxPoint(
                      '🔗 Dependency System',
                      'TaskService automatically resolved UserService dependency',
                    ),
                    _buildFluxPoint(
                      '🔄 Service Proxy System',
                      'BackgroundProcessor runs in worker isolate transparently',
                    ),
                    _buildFluxPoint(
                      '📡 Event System',
                      'Task updates broadcast to NotificationService & AnalyticsService',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    final recommendations = _recommendations!['recommendations'] as List;

    return Column(
      children: recommendations.map<Widget>((rec) {
        final confidence = ((rec['confidence'] as double) * 100).round();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.purple.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      rec['title'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Chip(
                    label: Text('$confidence%'),
                    backgroundColor: Colors.purple.withOpacity(0.1),
                    labelStyle: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(rec['description']),
              const SizedBox(height: 4),
              Text(
                'Reasoning: ${rec['reasoning']}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFluxPoint(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
          Text(
            description,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAction(String action) async {
    final taskService = widget.runtime.get<TaskService>();
    final currentUser = await widget.runtime
        .get<UserService>()
        .getCurrentUser();

    try {
      TaskStatus newStatus;
      switch (action) {
        case 'start':
          newStatus = TaskStatus.inProgress;
          break;
        case 'review':
          newStatus = TaskStatus.review;
          break;
        case 'complete':
          newStatus = TaskStatus.completed;
          break;
        case 'recommendations':
          await _loadRecommendations();
          return;
        default:
          return;
      }

      final updatedTask = await taskService.updateTaskStatus(
        _currentTask.id,
        newStatus,
        currentUser.id,
      );

      setState(() {
        _currentTask = updatedTask;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Task updated to ${newStatus.displayName}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

import 'dart:math';
import 'package:uuid/uuid.dart';
import 'package:dart_service_framework/dart_service_framework.dart';
import '../events/task_events.dart';
import '../models/task.dart';
import 'task_service.dart';

part 'background_processor.g.dart';

/// Background processing service for heavy operations
/// This service runs in a worker isolate to avoid blocking the UI
@ServiceContract(remote: true)
class BackgroundProcessor extends FluxService {
  final _uuid = const Uuid();
  final _random = Random();

  // 🔗 DEPENDENCY SYSTEM: Optional dependency on TaskService
  @override
  List<Type> get optionalDependencies => [TaskService];

  @override
  Future<void> initialize() async {
    // 📡 EVENT SYSTEM: Listen for tasks that need processing
    onEvent<TaskCreatedEvent>((event) async {
      // Automatically analyze new tasks
      await _analyzeTaskComplexity(event.taskId, event.title);
      return const EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration(milliseconds: 100),
      );
    });

    logger.info('Background processor initialized in worker isolate');
    await super.initialize();
  }

  /// Process a large dataset (simulates heavy computation)
  Future<Map<String, dynamic>> processLargeDataset(
    List<Map<String, dynamic>> data,
  ) async {
    logger.info(
      'Starting large dataset processing',
      metadata: {'dataSize': data.length},
    );

    // Simulate heavy computation that would block UI if not in worker
    final results = <String, dynamic>{
      'processedAt': DateTime.now().toIso8601String(),
      'inputSize': data.length,
      'results': [],
    };

    for (var i = 0; i < data.length; i++) {
      // Simulate processing time (reduced for testing)
      await Future.delayed(const Duration(milliseconds: 1));

      final item = data[i];
      final processed = {
        'originalIndex': i,
        'processedValue': _processItem(item),
        'complexity': _calculateComplexity(item),
      };

      (results['results'] as List).add(processed);

      // Report progress for long operations
      if (i % 100 == 0) {
        logger.debug(
          'Processing progress',
          metadata: {
            'completed': i,
            'total': data.length,
            'percentage': ((i / data.length) * 100).round(),
          },
        );
      }
    }

    logger.info(
      'Large dataset processing completed',
      metadata: {
        'processedItems': data.length,
        'processingTimeMs':
            DateTime.now().millisecondsSinceEpoch -
            DateTime.parse(results['processedAt']).millisecondsSinceEpoch,
      },
    );

    return results;
  }

  /// Generate task recommendations based on patterns
  Future<List<Map<String, dynamic>>> generateTaskRecommendations(
    String userId,
  ) async {
    logger.info(
      'Generating task recommendations',
      metadata: {'userId': userId},
    );

    // Simulate ML/AI processing in worker isolate
    await Future.delayed(const Duration(milliseconds: 300));

    final recommendations = <Map<String, dynamic>>[];

    // 🔄 SERVICE PROXY SYSTEM: Try to get task data if available
    try {
      final taskService = getService<TaskService>();
      final userTasks = await taskService.getTasksForUser(userId);

      // Analyze patterns
      final completedTasks = userTasks
          .where((t) => t.status == TaskStatus.completed)
          .toList();
      final averageCompletionTime = _calculateAverageCompletionTime(
        completedTasks,
      );

      // Generate smart recommendations
      recommendations.addAll([
        {
          'type': 'productivity',
          'title': 'Optimize Your Workflow',
          'description':
              'Based on your completion patterns, consider breaking large tasks into smaller ones.',
          'confidence': 0.85,
          'reasoning':
              'You complete tasks ${averageCompletionTime.inDays} days on average.',
        },
        {
          'type': 'priority',
          'title': 'Focus on High Priority',
          'description':
              'You have ${userTasks.where((t) => t.priority == TaskPriority.high).length} high-priority tasks.',
          'confidence': 0.92,
          'reasoning':
              'High-priority tasks should be addressed first for better outcomes.',
        },
      ]);
    } catch (e) {
      // TaskService not available, generate generic recommendations
      recommendations.addAll([
        {
          'type': 'general',
          'title': 'Stay Organized',
          'description': 'Use tags and due dates to keep your tasks organized.',
          'confidence': 0.70,
          'reasoning': 'General productivity best practice.',
        },
      ]);
    }

    logger.info(
      'Generated ${recommendations.length} recommendations',
      metadata: {'userId': userId},
    );

    return recommendations;
  }

  /// Batch process multiple tasks (heavy operation)
  Future<Map<String, dynamic>> batchProcessTasks(List<String> taskIds) async {
    logger.info(
      'Starting batch task processing',
      metadata: {'taskCount': taskIds.length},
    );

    final results = <String, dynamic>{
      'processedAt': DateTime.now().toIso8601String(),
      'taskResults': <Map<String, dynamic>>[],
      'summary': {},
    };

    for (final taskId in taskIds) {
      // Simulate complex processing per task
      await Future.delayed(Duration(milliseconds: 50 + _random.nextInt(100)));

      final taskResult = {
        'taskId': taskId,
        'processingScore': _random.nextDouble() * 100,
        'recommendations': _generateTaskRecommendations(),
        'estimatedEffort': _random.nextInt(8) + 1, // 1-8 hours
      };

      (results['taskResults'] as List).add(taskResult);
    }

    // Generate summary
    final taskResults = results['taskResults'] as List<Map<String, dynamic>>;
    results['summary'] = {
      'averageScore':
          taskResults.map((r) => r['processingScore']).reduce((a, b) => a + b) /
          taskResults.length,
      'totalEstimatedHours': taskResults
          .map((r) => r['estimatedEffort'])
          .reduce((a, b) => a + b),
      'highScoreTasks': taskResults
          .where((r) => r['processingScore'] > 80)
          .length,
    };

    logger.info(
      'Batch processing completed',
      metadata: {
        'processedTasks': taskIds.length,
        'averageScore': results['summary']['averageScore'],
      },
    );

    return results;
  }

  // Private helper methods
  Future<void> _analyzeTaskComplexity(String taskId, String title) async {
    // Simulate AI/ML analysis
    await Future.delayed(const Duration(milliseconds: 200));

    final complexity = _calculateTextComplexity(title);

    logger.info(
      'Task complexity analyzed',
      metadata: {'taskId': taskId, 'complexity': complexity},
    );

    // Send analytics event about the analysis
    await sendEvent(
      AnalyticsEvent(
        action: 'task_analyzed',
        entity: 'task',
        properties: {
          'taskId': taskId,
          'complexity': complexity,
          'analysisType': 'automatic',
        },
        eventId: _uuid.v4(),
        sourceService: serviceName,
        timestamp: DateTime.now(),
      ),
    );
  }

  Map<String, dynamic> _processItem(Map<String, dynamic> item) => {
    'processed': true,
    'score': _random.nextDouble() * 100,
    'category': _categorizeItem(item),
    'processedAt': DateTime.now().toIso8601String(),
  };

  double _calculateComplexity(Map<String, dynamic> item) {
    // Simulate complexity calculation
    final keys = item.keys.length;
    final values = item.values.where((v) => v != null).length;
    return (keys * values / 10.0).clamp(0.0, 1.0);
  }

  String _categorizeItem(Map<String, dynamic> item) {
    final categories = ['simple', 'moderate', 'complex', 'critical'];
    return categories[_random.nextInt(categories.length)];
  }

  Duration _calculateAverageCompletionTime(List<Task> completedTasks) {
    if (completedTasks.isEmpty) return const Duration(days: 3);

    final totalDays = completedTasks
        .map((task) {
          if (task.completedAt == null) return 3;
          return task.completedAt!.difference(task.createdAt).inDays;
        })
        .reduce((a, b) => a + b);

    return Duration(days: totalDays ~/ completedTasks.length);
  }

  double _calculateTextComplexity(String text) {
    final words = text.split(' ').length;
    final chars = text.length;
    return (words * 0.3 + chars * 0.1).clamp(0.0, 100.0);
  }

  List<String> _generateTaskRecommendations() => [
    'Break into smaller subtasks',
    'Set intermediate milestones',
    'Assign clear deadlines',
    'Add relevant tags',
  ];
}

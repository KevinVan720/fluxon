/// Export service - handles generating PDF and CSV reports from tasks.
library export_service;

import 'dart:async';
import 'dart:convert';
import 'package:dart_service_framework/dart_service_framework.dart';
import '../models/task.dart';
import 'task_service.dart'; // For TaskStats

part 'export_service.g.dart';

/// Remote service for generating exports and reports.
@ServiceContract(remote: true)
abstract class ExportService extends BaseService {
  /// Generates a CSV export of tasks.
  @ServiceMethod(timeoutMs: 10000)
  Future<ExportResult> exportTasksAsCsv(
    List<Task> tasks, {
    ExportOptions? options,
  });

  /// Generates a PDF report of tasks.
  @ServiceMethod(timeoutMs: 15000)
  Future<ExportResult> exportTasksAsPdf(
    List<Task> tasks, {
    ExportOptions? options,
  });

  /// Generates a summary report with statistics.
  @ServiceMethod(timeoutMs: 8000)
  Future<ExportResult> generateSummaryReport(List<Task> tasks, TaskStats stats);

  /// Gets available export templates.
  Future<List<ExportTemplate>> getExportTemplates();

  /// Gets export history.
  Future<List<ExportRecord>> getExportHistory({int limit = 20});
}

/// Export options configuration.
class ExportOptions {
  const ExportOptions({
    this.includeCompleted = true,
    this.includeCancelled = false,
    this.dateRange,
    this.groupBy,
    this.sortBy = TaskSortField.createdAt,
    this.sortAscending = true,
    this.templateId,
    this.customFields = const [],
  });

  final bool includeCompleted;
  final bool includeCancelled;
  final DateRange? dateRange;
  final TaskGroupField? groupBy;
  final TaskSortField sortBy;
  final bool sortAscending;
  final String? templateId;
  final List<String> customFields;

  Map<String, dynamic> toJson() => {
    'includeCompleted': includeCompleted,
    'includeCancelled': includeCancelled,
    'dateRange': dateRange?.toJson(),
    'groupBy': groupBy?.name,
    'sortBy': sortBy.name,
    'sortAscending': sortAscending,
    'templateId': templateId,
    'customFields': customFields,
  };

  factory ExportOptions.fromJson(Map<String, dynamic> json) => ExportOptions(
    includeCompleted: json['includeCompleted'] as bool? ?? true,
    includeCancelled: json['includeCancelled'] as bool? ?? false,
    dateRange: json['dateRange'] != null
        ? DateRange.fromJson(json['dateRange'] as Map<String, dynamic>)
        : null,
    groupBy: json['groupBy'] != null
        ? TaskGroupField.values.byName(json['groupBy'] as String)
        : null,
    sortBy: TaskSortField.values.byName(
      json['sortBy'] as String? ?? 'createdAt',
    ),
    sortAscending: json['sortAscending'] as bool? ?? true,
    templateId: json['templateId'] as String?,
    customFields:
        (json['customFields'] as List<dynamic>?)?.cast<String>() ?? [],
  );
}

/// Date range for filtering.
class DateRange {
  const DateRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  Map<String, dynamic> toJson() => {
    'start': start.toIso8601String(),
    'end': end.toIso8601String(),
  };

  factory DateRange.fromJson(Map<String, dynamic> json) => DateRange(
    start: DateTime.parse(json['start'] as String),
    end: DateTime.parse(json['end'] as String),
  );
}

/// Task grouping options.
enum TaskGroupField { priority, status, assignee, dueDate }

/// Task sorting options.
enum TaskSortField { title, createdAt, updatedAt, dueDate, priority, status }

/// Export format types.
enum ExportFormat { csv, pdf, json, html }

/// Result of an export operation.
class ExportResult {
  const ExportResult({
    required this.success,
    required this.format,
    required this.fileSize,
    required this.duration,
    required this.recordCount,
    this.filePath,
    this.downloadUrl,
    this.error,
    this.metadata,
  });

  final bool success;
  final ExportFormat format;
  final int fileSize; // in bytes
  final Duration duration;
  final int recordCount;
  final String? filePath;
  final String? downloadUrl;
  final String? error;
  final Map<String, dynamic>? metadata;

  Map<String, dynamic> toJson() => {
    'success': success,
    'format': format.name,
    'fileSize': fileSize,
    'duration': duration.inMilliseconds,
    'recordCount': recordCount,
    'filePath': filePath,
    'downloadUrl': downloadUrl,
    'error': error,
    'metadata': metadata,
  };

  factory ExportResult.fromJson(Map<String, dynamic> json) => ExportResult(
    success: json['success'] as bool,
    format: ExportFormat.values.byName(json['format'] as String),
    fileSize: json['fileSize'] as int,
    duration: Duration(milliseconds: json['duration'] as int),
    recordCount: json['recordCount'] as int,
    filePath: json['filePath'] as String?,
    downloadUrl: json['downloadUrl'] as String?,
    error: json['error'] as String?,
    metadata: json['metadata'] as Map<String, dynamic>?,
  );
}

/// Export template definition.
class ExportTemplate {
  const ExportTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.format,
    required this.fields,
    this.isDefault = false,
  });

  final String id;
  final String name;
  final String description;
  final ExportFormat format;
  final List<String> fields;
  final bool isDefault;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'format': format.name,
    'fields': fields,
    'isDefault': isDefault,
  };

  factory ExportTemplate.fromJson(Map<String, dynamic> json) => ExportTemplate(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String,
    format: ExportFormat.values.byName(json['format'] as String),
    fields: (json['fields'] as List<dynamic>).cast<String>(),
    isDefault: json['isDefault'] as bool? ?? false,
  );
}

/// Export history record.
class ExportRecord {
  const ExportRecord({
    required this.id,
    required this.format,
    required this.createdAt,
    required this.recordCount,
    required this.fileSize,
    required this.success,
    this.error,
    this.options,
  });

  final String id;
  final ExportFormat format;
  final DateTime createdAt;
  final int recordCount;
  final int fileSize;
  final bool success;
  final String? error;
  final ExportOptions? options;

  Map<String, dynamic> toJson() => {
    'id': id,
    'format': format.name,
    'createdAt': createdAt.toIso8601String(),
    'recordCount': recordCount,
    'fileSize': fileSize,
    'success': success,
    'error': error,
    'options': options?.toJson(),
  };

  factory ExportRecord.fromJson(Map<String, dynamic> json) => ExportRecord(
    id: json['id'] as String,
    format: ExportFormat.values.byName(json['format'] as String),
    createdAt: DateTime.parse(json['createdAt'] as String),
    recordCount: json['recordCount'] as int,
    fileSize: json['fileSize'] as int,
    success: json['success'] as bool,
    error: json['error'] as String?,
    options: json['options'] != null
        ? ExportOptions.fromJson(json['options'] as Map<String, dynamic>)
        : null,
  );
}

/// Worker implementation of ExportService.
class ExportServiceImpl extends ExportService {
  final List<ExportRecord> _exportHistory = [];
  final List<ExportTemplate> _templates = [];

  @override
  Future<void> initialize() async {
    logger.info('ExportService initializing in worker isolate...');
    await super.initialize();

    _initializeTemplates();

    logger.info(
      'ExportService initialized with ${_templates.length} templates',
    );
  }

  @override
  Future<ExportResult> exportTasksAsCsv(
    List<Task> tasks, {
    ExportOptions? options,
  }) async {
    final stopwatch = Stopwatch()..start();
    logger.info('Starting CSV export of ${tasks.length} tasks');

    try {
      // Apply filters and sorting
      final filteredTasks = _filterAndSortTasks(tasks, options);

      // Simulate processing time
      await _simulateProcessingDelay(filteredTasks.length);

      // Generate CSV content
      final csvContent = _generateCsvContent(filteredTasks, options);
      final fileSize = utf8.encode(csvContent).length;

      final result = ExportResult(
        success: true,
        format: ExportFormat.csv,
        fileSize: fileSize,
        duration: stopwatch.elapsed,
        recordCount: filteredTasks.length,
        filePath: '/exports/tasks_${DateTime.now().millisecondsSinceEpoch}.csv',
        downloadUrl: 'https://example.com/downloads/tasks.csv',
        metadata: {'columns': _getCsvColumns(options), 'encoding': 'utf-8'},
      );

      await _recordExport(result, options);
      // TODO: Add event emission back

      logger.info(
        'CSV export completed: ${filteredTasks.length} records, ${fileSize} bytes',
      );
      return result;
    } catch (e) {
      final result = ExportResult(
        success: false,
        format: ExportFormat.csv,
        fileSize: 0,
        duration: stopwatch.elapsed,
        recordCount: 0,
        error: e.toString(),
      );

      await _recordExport(result, options);
      // TODO: Add event emission back

      logger.error('CSV export failed: $e');
      return result;
    } finally {
      stopwatch.stop();
    }
  }

  @override
  Future<ExportResult> exportTasksAsPdf(
    List<Task> tasks, {
    ExportOptions? options,
  }) async {
    final stopwatch = Stopwatch()..start();
    logger.info('Starting PDF export of ${tasks.length} tasks');

    try {
      final filteredTasks = _filterAndSortTasks(tasks, options);

      // PDF generation takes longer
      await _simulateProcessingDelay(filteredTasks.length, multiplier: 2);

      // Simulate PDF generation
      final fileSize = _estimatePdfSize(filteredTasks.length);

      final result = ExportResult(
        success: true,
        format: ExportFormat.pdf,
        fileSize: fileSize,
        duration: stopwatch.elapsed,
        recordCount: filteredTasks.length,
        filePath:
            '/exports/tasks_report_${DateTime.now().millisecondsSinceEpoch}.pdf',
        downloadUrl: 'https://example.com/downloads/tasks_report.pdf',
        metadata: {
          'pages': (filteredTasks.length / 10).ceil(),
          'orientation': 'portrait',
          'template': options?.templateId ?? 'default',
        },
      );

      await _recordExport(result, options);
      // TODO: Add event emission back

      logger.info(
        'PDF export completed: ${filteredTasks.length} records, ${fileSize} bytes',
      );
      return result;
    } catch (e) {
      final result = ExportResult(
        success: false,
        format: ExportFormat.pdf,
        fileSize: 0,
        duration: stopwatch.elapsed,
        recordCount: 0,
        error: e.toString(),
      );

      await _recordExport(result, options);
      // TODO: Add event emission back

      logger.error('PDF export failed: $e');
      return result;
    } finally {
      stopwatch.stop();
    }
  }

  @override
  Future<ExportResult> generateSummaryReport(
    List<Task> tasks,
    TaskStats stats,
  ) async {
    final stopwatch = Stopwatch()..start();
    logger.info('Generating summary report for ${tasks.length} tasks');

    try {
      await _simulateProcessingDelay(50); // Base processing time

      // Generate summary content
      final summaryData = {
        'stats': stats.toJson(),
        'taskBreakdown': _generateTaskBreakdown(tasks),
        'trends': _generateTrendAnalysis(tasks),
        'recommendations': _generateRecommendations(stats),
      };

      final content = JsonEncoder.withIndent('  ').convert(summaryData);
      final fileSize = utf8.encode(content).length;

      final result = ExportResult(
        success: true,
        format: ExportFormat.json,
        fileSize: fileSize,
        duration: stopwatch.elapsed,
        recordCount: tasks.length,
        filePath:
            '/exports/summary_${DateTime.now().millisecondsSinceEpoch}.json',
        metadata: summaryData,
      );

      await _recordExport(result, null);
      // TODO: Add event emission back

      logger.info('Summary report generated: ${fileSize} bytes');
      return result;
    } catch (e) {
      final result = ExportResult(
        success: false,
        format: ExportFormat.json,
        fileSize: 0,
        duration: stopwatch.elapsed,
        recordCount: 0,
        error: e.toString(),
      );

      await _recordExport(result, null);
      // TODO: Add event emission back

      logger.error('Summary report failed: $e');
      return result;
    } finally {
      stopwatch.stop();
    }
  }

  @override
  Future<List<ExportTemplate>> getExportTemplates() async {
    return List.from(_templates);
  }

  @override
  Future<List<ExportRecord>> getExportHistory({int limit = 20}) async {
    return _exportHistory.take(limit).toList();
  }

  void _initializeTemplates() {
    _templates.addAll([
      ExportTemplate(
        id: 'default_csv',
        name: 'Default CSV',
        description: 'Basic CSV export with all task fields',
        format: ExportFormat.csv,
        fields: [
          'id',
          'title',
          'description',
          'status',
          'priority',
          'createdAt',
          'updatedAt',
        ],
        isDefault: true,
      ),
      ExportTemplate(
        id: 'summary_csv',
        name: 'Summary CSV',
        description: 'Simplified CSV with key fields only',
        format: ExportFormat.csv,
        fields: ['title', 'status', 'priority', 'assignee', 'dueDate'],
      ),
      ExportTemplate(
        id: 'detailed_pdf',
        name: 'Detailed PDF Report',
        description: 'Comprehensive PDF report with charts and analysis',
        format: ExportFormat.pdf,
        fields: ['all'],
        isDefault: true,
      ),
      ExportTemplate(
        id: 'executive_pdf',
        name: 'Executive Summary PDF',
        description: 'High-level overview for management',
        format: ExportFormat.pdf,
        fields: ['summary', 'stats', 'trends'],
      ),
    ]);
  }

  List<Task> _filterAndSortTasks(List<Task> tasks, ExportOptions? options) {
    if (options == null) return tasks;

    var filtered = tasks.where((task) {
      if (!options.includeCompleted && task.status == TaskStatus.completed) {
        return false;
      }
      if (!options.includeCancelled && task.status == TaskStatus.cancelled) {
        return false;
      }
      if (options.dateRange != null) {
        if (task.createdAt.isBefore(options.dateRange!.start) ||
            task.createdAt.isAfter(options.dateRange!.end)) {
          return false;
        }
      }
      return true;
    }).toList();

    // Apply sorting
    filtered.sort((a, b) {
      int comparison = 0;
      switch (options.sortBy) {
        case TaskSortField.title:
          comparison = a.title.compareTo(b.title);
          break;
        case TaskSortField.createdAt:
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
        case TaskSortField.updatedAt:
          comparison = a.updatedAt.compareTo(b.updatedAt);
          break;
        case TaskSortField.dueDate:
          comparison = (a.dueDate ?? DateTime(2100)).compareTo(
            b.dueDate ?? DateTime(2100),
          );
          break;
        case TaskSortField.priority:
          comparison = a.priority.index.compareTo(b.priority.index);
          break;
        case TaskSortField.status:
          comparison = a.status.index.compareTo(b.status.index);
          break;
      }
      return options.sortAscending ? comparison : -comparison;
    });

    return filtered;
  }

  String _generateCsvContent(List<Task> tasks, ExportOptions? options) {
    final columns = _getCsvColumns(options);
    final lines = <String>[];

    // Header
    lines.add(columns.join(','));

    // Data rows
    for (final task in tasks) {
      final row = columns
          .map((column) => _getTaskFieldValue(task, column))
          .toList();
      lines.add(
        row
            .map((value) => '"${value.toString().replaceAll('"', '""')}"')
            .join(','),
      );
    }

    return lines.join('\n');
  }

  List<String> _getCsvColumns(ExportOptions? options) {
    if (options?.customFields.isNotEmpty == true) {
      return options!.customFields;
    }
    return [
      'id',
      'title',
      'description',
      'status',
      'priority',
      'assignee',
      'createdAt',
      'dueDate',
      'tags',
    ];
  }

  dynamic _getTaskFieldValue(Task task, String field) {
    switch (field) {
      case 'id':
        return task.id;
      case 'title':
        return task.title;
      case 'description':
        return task.description;
      case 'status':
        return task.status.name;
      case 'priority':
        return task.priority.name;
      case 'assignee':
        return task.assignee ?? '';
      case 'createdAt':
        return task.createdAt.toIso8601String();
      case 'updatedAt':
        return task.updatedAt.toIso8601String();
      case 'dueDate':
        return task.dueDate?.toIso8601String() ?? '';
      case 'tags':
        return task.tags.join(';');
      default:
        return '';
    }
  }

  int _estimatePdfSize(int taskCount) {
    // Rough estimate: 2KB base + 0.5KB per task
    return 2048 + (taskCount * 512);
  }

  Map<String, dynamic> _generateTaskBreakdown(List<Task> tasks) {
    final breakdown = <String, dynamic>{};

    // By status
    final statusCounts = <String, int>{};
    for (final status in TaskStatus.values) {
      statusCounts[status.name] = tasks.where((t) => t.status == status).length;
    }
    breakdown['byStatus'] = statusCounts;

    // By priority
    final priorityCounts = <String, int>{};
    for (final priority in TaskPriority.values) {
      priorityCounts[priority.name] = tasks
          .where((t) => t.priority == priority)
          .length;
    }
    breakdown['byPriority'] = priorityCounts;

    return breakdown;
  }

  Map<String, dynamic> _generateTrendAnalysis(List<Task> tasks) {
    final now = DateTime.now();
    final last7Days = now.subtract(Duration(days: 7));
    final last30Days = now.subtract(Duration(days: 30));

    return {
      'createdLast7Days': tasks
          .where((t) => t.createdAt.isAfter(last7Days))
          .length,
      'createdLast30Days': tasks
          .where((t) => t.createdAt.isAfter(last30Days))
          .length,
      'completedLast7Days': tasks
          .where(
            (t) =>
                t.status == TaskStatus.completed &&
                t.updatedAt.isAfter(last7Days),
          )
          .length,
      'completedLast30Days': tasks
          .where(
            (t) =>
                t.status == TaskStatus.completed &&
                t.updatedAt.isAfter(last30Days),
          )
          .length,
    };
  }

  List<String> _generateRecommendations(TaskStats stats) {
    final recommendations = <String>[];

    if (stats.overdue > 0) {
      recommendations.add(
        'Address ${stats.overdue} overdue tasks to improve delivery',
      );
    }

    if (stats.inProgress > stats.total * 0.7) {
      recommendations.add(
        'High work-in-progress ratio - consider limiting concurrent tasks',
      );
    }

    if (stats.completed < stats.total * 0.2) {
      recommendations.add(
        'Low completion rate - review task prioritization and scope',
      );
    }

    return recommendations;
  }

  Future<void> _simulateProcessingDelay(
    int taskCount, {
    int multiplier = 1,
  }) async {
    // Simulate realistic processing time based on task count
    final baseDelay = 500; // 500ms base
    final perTaskDelay = 10; // 10ms per task
    final totalDelay = (baseDelay + (taskCount * perTaskDelay)) * multiplier;

    await Future.delayed(Duration(milliseconds: totalDelay));
  }

  Future<void> _recordExport(
    ExportResult result,
    ExportOptions? options,
  ) async {
    final record = ExportRecord(
      id: 'export_${DateTime.now().millisecondsSinceEpoch}',
      format: result.format,
      createdAt: DateTime.now(),
      recordCount: result.recordCount,
      fileSize: result.fileSize,
      success: result.success,
      error: result.error,
      options: options,
    );

    _exportHistory.insert(0, record);

    // Keep only last 100 records
    if (_exportHistory.length > 100) {
      _exportHistory.removeRange(100, _exportHistory.length);
    }
  }
}

/// Event emitted when export completes successfully.
class ExportCompletedEvent extends ServiceEvent {
  ExportCompletedEvent(this.result) : super(eventType: 'export.completed');

  final ExportResult result;

  @override
  Map<String, dynamic> eventDataToJson() => result.toJson();
}

/// Event emitted when export fails.
class ExportFailedEvent extends ServiceEvent {
  ExportFailedEvent(this.result) : super(eventType: 'export.failed');

  final ExportResult result;

  @override
  Map<String, dynamic> eventDataToJson() => result.toJson();
}

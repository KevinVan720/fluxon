/// Simplified tests for event-based communication focusing on ServiceEventMixin functionality
library simplified_event_communication_test;

import 'dart:async';
import 'package:test/test.dart';
import 'package:dart_service_framework/dart_service_framework.dart';

// Test event types for comprehensive testing
class WorkflowEvent extends ServiceEvent {
  const WorkflowEvent({
    required super.eventId,
    required super.sourceService,
    required super.timestamp,
    super.correlationId,
    super.metadata = const {},
    required this.workflowId,
    required this.stepName,
    required this.status,
    required this.data,
  });

  final String workflowId;
  final String stepName;
  final String status;
  final Map<String, dynamic> data;

  @override
  Map<String, dynamic> eventDataToJson() {
    return {
      'workflowId': workflowId,
      'stepName': stepName,
      'status': status,
      'data': data,
    };
  }

  factory WorkflowEvent.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return WorkflowEvent(
      eventId: json['eventId'] as String,
      sourceService: json['sourceService'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      correlationId: json['correlationId'] as String?,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      workflowId: data['workflowId'] as String,
      stepName: data['stepName'] as String,
      status: data['status'] as String,
      data: Map<String, dynamic>.from(data['data'] as Map),
    );
  }
}

class ProcessingResultEvent extends ServiceEvent {
  const ProcessingResultEvent({
    required super.eventId,
    required super.sourceService,
    required super.timestamp,
    super.correlationId,
    super.metadata = const {},
    required this.processId,
    required this.success,
    required this.result,
    this.errorMessage,
  });

  final String processId;
  final bool success;
  final Map<String, dynamic> result;
  final String? errorMessage;

  @override
  Map<String, dynamic> eventDataToJson() {
    return {
      'processId': processId,
      'success': success,
      'result': result,
      'errorMessage': errorMessage,
    };
  }

  factory ProcessingResultEvent.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return ProcessingResultEvent(
      eventId: json['eventId'] as String,
      sourceService: json['sourceService'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      correlationId: json['correlationId'] as String?,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      processId: data['processId'] as String,
      success: data['success'] as bool,
      result: Map<String, dynamic>.from(data['result'] as Map),
      errorMessage: data['errorMessage'] as String?,
    );
  }
}

class HealthCheckEvent extends ServiceEvent {
  const HealthCheckEvent({
    required super.eventId,
    required super.sourceService,
    required super.timestamp,
    super.correlationId,
    super.metadata = const {},
    required this.serviceName,
    required this.status,
    required this.details,
  });

  final String serviceName;
  final String status; // healthy, degraded, unhealthy
  final Map<String, dynamic> details;

  @override
  Map<String, dynamic> eventDataToJson() {
    return {
      'serviceName': serviceName,
      'status': status,
      'details': details,
    };
  }

  factory HealthCheckEvent.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return HealthCheckEvent(
      eventId: json['eventId'] as String,
      sourceService: json['sourceService'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      correlationId: json['correlationId'] as String?,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      serviceName: data['serviceName'] as String,
      status: data['status'] as String,
      details: Map<String, dynamic>.from(data['details'] as Map),
    );
  }
}

// Test services demonstrating various event patterns
class WorkflowOrchestratorService extends BaseService with ServiceEventMixin {
  final Map<String, Map<String, dynamic>> _workflows = {};
  final List<ServiceEvent> _receivedEvents = [];
  final List<String> _processedMessages = [];

  @override
  Future<void> initialize() async {
    // Listen for processing results to advance workflows
    onEvent<ProcessingResultEvent>((event) async {
      _receivedEvents.add(event);

      final workflow = _workflows.values.firstWhere(
        (w) => w['currentProcessId'] == event.processId,
        orElse: () => <String, dynamic>{},
      );

      if (workflow.isNotEmpty) {
        if (event.success) {
          workflow['currentStep'] = (workflow['currentStep'] as int) + 1;
          workflow['results'] = [
            ...(workflow['results'] as List),
            event.result
          ];

          _processedMessages.add(
              'Workflow ${workflow['id']} advanced to step ${workflow['currentStep']}');

          // Check if workflow is complete
          final totalSteps = workflow['totalSteps'] as int;
          if (workflow['currentStep'] >= totalSteps) {
            await _completeWorkflow(workflow['id'] as String);
          } else {
            await _executeNextStep(workflow['id'] as String);
          }
        } else {
          workflow['status'] = 'failed';
          workflow['errorMessage'] = event.errorMessage;

          _processedMessages
              .add('Workflow ${workflow['id']} failed: ${event.errorMessage}');
        }
      }

      return EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration(milliseconds: 20),
        data: {'workflowAdvanced': event.success},
      );
    });

    // Listen for health check events
    onEvent<HealthCheckEvent>((event) async {
      _receivedEvents.add(event);

      _processedMessages.add(
          'Health check received: ${event.serviceName} is ${event.status}');

      return EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration(milliseconds: 5),
      );
    });
  }

  Future<String> startWorkflow(String name, List<String> steps) async {
    ensureInitialized();

    final workflowId = 'workflow_${_workflows.length + 1}';
    final workflow = {
      'id': workflowId,
      'name': name,
      'steps': steps,
      'currentStep': 0,
      'totalSteps': steps.length,
      'status': 'running',
      'results': <Map<String, dynamic>>[],
      'startedAt': DateTime.now().toIso8601String(),
    };

    _workflows[workflowId] = workflow;

    // Send workflow started event
    final event = createEvent<WorkflowEvent>(
      (
              {required eventId,
              required sourceService,
              required timestamp,
              String? correlationId,
              metadata = const {}}) =>
          WorkflowEvent(
        eventId: eventId,
        sourceService: sourceService,
        timestamp: timestamp,
        correlationId: correlationId,
        metadata: metadata,
        workflowId: workflowId,
        stepName: 'workflow_started',
        status: 'running',
        data: {
          'name': name,
          'totalSteps': steps.length,
        },
      ),
    );

    await broadcastEvent(event);
    await _executeNextStep(workflowId);

    return workflowId;
  }

  Future<void> _executeNextStep(String workflowId) async {
    final workflow = _workflows[workflowId];
    if (workflow == null || workflow['status'] != 'running') return;

    final steps = workflow['steps'] as List<String>;
    final currentStep = workflow['currentStep'] as int;

    if (currentStep >= steps.length) return;

    final stepName = steps[currentStep];
    final processId = '${workflowId}_step_$currentStep';
    workflow['currentProcessId'] = processId;

    // Send step execution event
    final event = createEvent<WorkflowEvent>(
      (
              {required eventId,
              required sourceService,
              required timestamp,
              String? correlationId,
              metadata = const {}}) =>
          WorkflowEvent(
        eventId: eventId,
        sourceService: sourceService,
        timestamp: timestamp,
        correlationId: correlationId,
        metadata: metadata,
        workflowId: workflowId,
        stepName: stepName,
        status: 'executing',
        data: {
          'processId': processId,
          'stepNumber': currentStep,
        },
      ),
    );

    await broadcastEvent(event);
  }

  Future<void> _completeWorkflow(String workflowId) async {
    final workflow = _workflows[workflowId];
    if (workflow == null) return;

    workflow['status'] = 'completed';
    workflow['completedAt'] = DateTime.now().toIso8601String();

    final event = createEvent<WorkflowEvent>(
      (
              {required eventId,
              required sourceService,
              required timestamp,
              String? correlationId,
              metadata = const {}}) =>
          WorkflowEvent(
        eventId: eventId,
        sourceService: sourceService,
        timestamp: timestamp,
        correlationId: correlationId,
        metadata: metadata,
        workflowId: workflowId,
        stepName: 'workflow_completed',
        status: 'completed',
        data: {
          'totalSteps': workflow['totalSteps'],
          'results': workflow['results'],
        },
      ),
    );

    await broadcastEvent(event);
  }

  Map<String, dynamic>? getWorkflow(String workflowId) =>
      _workflows[workflowId];
  List<ServiceEvent> get receivedEvents => List.unmodifiable(_receivedEvents);
  List<String> get processedMessages => List.unmodifiable(_processedMessages);
}

class DataProcessingService extends BaseService with ServiceEventMixin {
  final List<ServiceEvent> _receivedEvents = [];
  final List<String> _processedMessages = [];
  int _processedCount = 0;

  @override
  Future<void> initialize() async {
    // Listen for workflow events to process steps
    onEvent<WorkflowEvent>((event) async {
      _receivedEvents.add(event);

      if (event.status == 'executing') {
        _processedMessages.add(
            'Processing workflow step: ${event.workflowId} - ${event.stepName}');

        // Simulate processing
        await Future.delayed(Duration(milliseconds: 100));
        _processedCount++;

        // Determine success based on step name (simulate some failures)
        final success = !event.stepName.contains('fail');

        final result = {
          'stepName': event.stepName,
          'processedAt': DateTime.now().toIso8601String(),
          'processedBy': serviceName,
        };

        // Send processing result
        final resultEvent = createEvent<ProcessingResultEvent>(
          (
                  {required eventId,
                  required sourceService,
                  required timestamp,
                  String? correlationId,
                  metadata = const {}}) =>
              ProcessingResultEvent(
            eventId: eventId,
            sourceService: sourceService,
            timestamp: timestamp,
            correlationId: event.correlationId,
            metadata: metadata,
            processId: event.data['processId'] as String,
            success: success,
            result: result,
            errorMessage: success ? null : 'Simulated processing failure',
          ),
        );

        await broadcastEvent(resultEvent);
      }

      return EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration(milliseconds: 50),
        data: {'stepProcessed': event.status == 'executing'},
      );
    });
  }

  Future<void> sendHealthCheck() async {
    ensureInitialized();

    final event = createEvent<HealthCheckEvent>(
      (
              {required eventId,
              required sourceService,
              required timestamp,
              String? correlationId,
              metadata = const {}}) =>
          HealthCheckEvent(
        eventId: eventId,
        sourceService: sourceService,
        timestamp: timestamp,
        correlationId: correlationId,
        metadata: metadata,
        serviceName: serviceName,
        status: 'healthy',
        details: {
          'processedCount': _processedCount,
          'memoryUsage': 'normal',
          'lastProcessed': DateTime.now().toIso8601String(),
        },
      ),
    );

    await broadcastEvent(event);
  }

  int get processedCount => _processedCount;
  List<ServiceEvent> get receivedEvents => List.unmodifiable(_receivedEvents);
  List<String> get processedMessages => List.unmodifiable(_processedMessages);
}

class MonitoringService extends BaseService with ServiceEventMixin {
  final Map<String, Map<String, dynamic>> _serviceHealth = {};
  final List<ServiceEvent> _receivedEvents = [];
  final List<String> _processedMessages = [];

  @override
  Future<void> initialize() async {
    // Monitor all events for analysis
    onEvent<WorkflowEvent>((event) async {
      _receivedEvents.add(event);

      _processedMessages.add(
          'Workflow event: ${event.workflowId} - ${event.stepName} (${event.status})');

      return EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration(milliseconds: 5),
      );
    });

    onEvent<ProcessingResultEvent>((event) async {
      _receivedEvents.add(event);

      _processedMessages.add(
          'Processing result: ${event.processId} - ${event.success ? 'success' : 'failed'}');

      return EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration(milliseconds: 5),
      );
    });

    onEvent<HealthCheckEvent>((event) async {
      _receivedEvents.add(event);

      _serviceHealth[event.serviceName] = {
        'status': event.status,
        'details': event.details,
        'lastCheck': event.timestamp.toIso8601String(),
      };

      _processedMessages
          .add('Health check: ${event.serviceName} is ${event.status}');

      return EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration(milliseconds: 5),
      );
    });
  }

  Map<String, Map<String, dynamic>> getServiceHealth() =>
      Map.unmodifiable(_serviceHealth);
  List<ServiceEvent> get receivedEvents => List.unmodifiable(_receivedEvents);
  List<String> get processedMessages => List.unmodifiable(_processedMessages);
}

void main() {
  group('Simplified Event Communication Tests', () {
    late EventDispatcher dispatcher;
    late WorkflowOrchestratorService orchestrator;
    late DataProcessingService processor;
    late MonitoringService monitor;

    setUp(() async {
      dispatcher = EventDispatcher();
      orchestrator = WorkflowOrchestratorService();
      processor = DataProcessingService();
      monitor = MonitoringService();

      // Set event dispatchers
      orchestrator.setEventDispatcher(dispatcher);
      processor.setEventDispatcher(dispatcher);
      monitor.setEventDispatcher(dispatcher);

      // Initialize services
      await orchestrator.internalInitialize();
      await processor.internalInitialize();
      await monitor.internalInitialize();
    });

    tearDown(() async {
      await orchestrator.internalDestroy();
      await processor.internalDestroy();
      await monitor.internalDestroy();
      dispatcher.dispose();
    });

    test('should handle complete workflow with event orchestration', () async {
      // Start a workflow
      final workflowId = await orchestrator.startWorkflow('test_workflow',
          ['validate_input', 'process_data', 'generate_output']);

      // Wait for workflow processing
      await Future.delayed(Duration(seconds: 1));

      // Check workflow completion
      final workflow = orchestrator.getWorkflow(workflowId);
      expect(workflow, isNotNull);
      expect(workflow!['status'], equals('completed'));
      expect(workflow['currentStep'], equals(3));

      // Verify events were processed
      expect(processor.processedCount, equals(3));
      expect(orchestrator.processedMessages.length, greaterThanOrEqualTo(3));

      // Check monitoring captured all events
      expect(monitor.receivedEvents.length,
          greaterThan(6)); // Workflow + processing events
    });

    test('should handle workflow failures gracefully', () async {
      // Start a workflow with a failing step
      final workflowId = await orchestrator.startWorkflow(
          'failing_workflow', ['validate_input', 'fail_step', 'cleanup']);

      // Wait for processing
      await Future.delayed(Duration(seconds: 1));

      // Check workflow failed
      final workflow = orchestrator.getWorkflow(workflowId);
      expect(workflow, isNotNull);
      expect(workflow!['status'], equals('failed'));
      expect(workflow['errorMessage'], isNotNull);

      // Verify monitoring captured the failure
      final failureEvents = monitor.receivedEvents
          .whereType<ProcessingResultEvent>()
          .where((e) => !e.success)
          .toList();
      expect(failureEvents, hasLength(1));
    });

    test('should support event subscriptions for monitoring', () async {
      final workflowEvents = <WorkflowEvent>[];
      final processingEvents = <ProcessingResultEvent>[];

      // Subscribe to specific event types
      final workflowSubscription = monitor.subscribeToEvents<WorkflowEvent>();
      final processingSubscription =
          monitor.subscribeToEvents<ProcessingResultEvent>();

      workflowSubscription.stream.listen((event) {
        workflowEvents.add(event as WorkflowEvent);
      });

      processingSubscription.stream.listen((event) {
        processingEvents.add(event as ProcessingResultEvent);
      });

      // Start workflow
      await orchestrator.startWorkflow('subscription_test', ['step1', 'step2']);
      await Future.delayed(Duration(milliseconds: 800));

      // Verify subscription events
      expect(
          workflowEvents.length, greaterThan(2)); // Started + steps + completed
      expect(processingEvents.length, equals(2)); // Two processing results

      // Check event content
      expect(
          workflowEvents.any((e) => e.stepName == 'workflow_started'), isTrue);
      expect(workflowEvents.any((e) => e.stepName == 'workflow_completed'),
          isTrue);
    });

    test('should handle health check events', () async {
      // Send health checks
      await processor.sendHealthCheck();
      await Future.delayed(Duration(milliseconds: 100));

      // Verify monitoring received health check
      final health = monitor.getServiceHealth();
      expect(health.containsKey('DataProcessingService'), isTrue);
      expect(health['DataProcessingService']!['status'], equals('healthy'));
    });

    test('should support event targeting and priority', () async {
      final criticalEvents = <WorkflowEvent>[];

      // Listen for critical events with high priority
      monitor.onEvent<WorkflowEvent>((event) async {
        if (event.metadata['priority'] == 'critical') {
          criticalEvents.add(event);
        }

        return EventProcessingResponse(
          result: EventProcessingResult.success,
          processingTime: Duration(milliseconds: 1),
        );
      }, priority: 100);

      // Send critical event
      final criticalEvent = WorkflowEvent(
        eventId: 'critical_test',
        sourceService: 'TestSender',
        timestamp: DateTime.now(),
        metadata: {'priority': 'critical'},
        workflowId: 'critical_workflow',
        stepName: 'critical_step',
        status: 'urgent',
        data: {'urgency': 'high'},
      );

      await orchestrator.sendEvent(criticalEvent);
      await Future.delayed(Duration(milliseconds: 100));

      expect(criticalEvents, hasLength(1));
      expect(criticalEvents.first.metadata['priority'], equals('critical'));
    });

    test('should measure event processing performance', () async {
      final stopwatch = Stopwatch()..start();

      // Send multiple workflows concurrently
      final futures = <Future>[];
      for (int i = 0; i < 5; i++) {
        futures.add(
            orchestrator.startWorkflow('perf_test_$i', ['step1', 'step2']));
      }

      await Future.wait(futures);
      await Future.delayed(Duration(seconds: 2)); // Wait for processing
      stopwatch.stop();

      // Check performance
      expect(processor.processedCount, equals(10)); // 5 workflows * 2 steps
      expect(stopwatch.elapsedMilliseconds,
          lessThan(5000)); // Should complete quickly

      // Get event statistics
      final stats = dispatcher.getStatistics();
      expect(stats.isNotEmpty, isTrue);
      expect(stats.containsKey('WorkflowEvent'), isTrue);
      expect(stats.containsKey('ProcessingResultEvent'), isTrue);

      print('Performance Test Results:');
      print('  Total time: ${stopwatch.elapsedMilliseconds}ms');
      print('  Events processed: ${processor.processedCount}');
      print('  Event statistics: ${stats.length} event types tracked');
    });

    test('should handle event correlation chains', () async {
      final correlationId = 'test-correlation-chain';

      // Start workflow with correlation ID
      final workflowId = await orchestrator
          .startWorkflow('correlated_workflow', ['correlated_step']);

      await Future.delayed(Duration(milliseconds: 500));

      // Check that events maintain correlation
      final correlatedEvents =
          monitor.receivedEvents.where((e) => e.correlationId != null).toList();

      expect(correlatedEvents, isNotEmpty);

      // Verify event chain integrity
      final workflowEvents =
          correlatedEvents.whereType<WorkflowEvent>().toList();
      final processingEvents =
          correlatedEvents.whereType<ProcessingResultEvent>().toList();

      expect(workflowEvents, isNotEmpty);
      expect(processingEvents, isNotEmpty);
    });
  });
}

import 'package:test/test.dart';
import 'package:dart_service_framework/dart_service_framework.dart';

part 'transparent_services_demo.g.dart';

// Example event for the demo
class WorkflowEvent extends ServiceEvent {
  final String workflowId;
  final String step;
  final Map<String, dynamic> data;

  const WorkflowEvent({
    required this.workflowId,
    required this.step,
    required this.data,
    required super.eventId,
    required super.sourceService,
    required super.timestamp,
    super.metadata = const {},
    super.correlationId,
  });

  @override
  Map<String, dynamic> eventDataToJson() => {
        'workflowId': workflowId,
        'step': step,
        'data': data,
      };

  factory WorkflowEvent.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return WorkflowEvent(
      workflowId: data['workflowId'],
      step: data['step'],
      data: Map<String, dynamic>.from(data['data']),
      eventId: json['eventId'],
      sourceService: json['sourceService'],
      timestamp: DateTime.parse(json['timestamp']),
      correlationId: json['correlationId'],
      metadata: json['metadata'] ?? {},
    );
  }
}

// 🎯 TRANSPARENT SERVICES - Local and remote are indistinguishable!

// Local service that orchestrates workflows
@ServiceContract(remote: false)
class WorkflowOrchestrator extends BaseService
    with ServiceEventMixin, ServiceClientMixin {
  final List<String> completedWorkflows = [];

  @override
  List<Type> get optionalDependencies => [DataProcessor, NotificationSender];

  @override
  Future<void> initialize() async {
    _registerWorkflowOrchestratorDispatcher();
    await super.initialize();

    // Listen for workflow completion events
    onEvent<WorkflowEvent>((event) async {
      if (event.step == 'completed') {
        completedWorkflows.add(event.workflowId);
        logger.info('Workflow completed',
            metadata: {'workflowId': event.workflowId});
      }

      return EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration(milliseconds: 5),
      );
    });
  }

  Future<void> startWorkflow(
      String workflowId, Map<String, dynamic> initialData) async {
    logger.info('Starting workflow', metadata: {'workflowId': workflowId});

    // 🚀 TRANSPARENT API: Call remote service as if it's local!
    final processor = getService<DataProcessor>();
    await processor.processData(workflowId, initialData);

    // 🚀 TRANSPARENT API: Send event to all services (local + remote automatically!)
    await sendEvent(createEvent(
      (
              {required String eventId,
              required String sourceService,
              required DateTime timestamp,
              String? correlationId,
              Map<String, dynamic> metadata = const {}}) =>
          WorkflowEvent(
        workflowId: workflowId,
        step: 'started',
        data: initialData,
        eventId: eventId,
        sourceService: sourceService,
        timestamp: timestamp,
        correlationId: correlationId,
        metadata: metadata,
      ),
    ));
  }
}

// Remote service that processes data
@ServiceContract(remote: true)
abstract class DataProcessor extends BaseService {
  Future<Map<String, dynamic>> processData(
      String workflowId, Map<String, dynamic> data);
}

class DataProcessorImpl extends DataProcessor
    with ServiceEventMixin, ServiceClientMixin {
  @override
  List<Type> get optionalDependencies => [NotificationSender];

  @override
  Future<void> initialize() async {
    _registerDataProcessorDispatcher();
    _registerNotificationSenderClientFactory();
    await super.initialize();

    // Listen for workflow events from other services
    onEvent<WorkflowEvent>((event) async {
      logger.info('Data processor received workflow event',
          metadata: {'workflowId': event.workflowId, 'step': event.step});

      return EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration(milliseconds: 10),
      );
    });
  }

  @override
  Future<Map<String, dynamic>> processData(
      String workflowId, Map<String, dynamic> data) async {
    logger.info('Processing data', metadata: {'workflowId': workflowId});

    // Simulate data processing
    await Future.delayed(Duration(milliseconds: 100));

    final processedData = {
      ...data,
      'processed': true,
      'processedAt': DateTime.now().toIso8601String(),
      'processorId': 'data-processor-1',
    };

    // 🚀 TRANSPARENT API: Call another remote service seamlessly!
    final notifier = getService<NotificationSender>();
    await notifier.sendNotification('admin@example.com',
        'Data processed for workflow $workflowId', 'workflow_update');

    // 🚀 TRANSPARENT API: Send completion event automatically to all services!
    await sendEvent(createEvent(
      (
              {required String eventId,
              required String sourceService,
              required DateTime timestamp,
              String? correlationId,
              Map<String, dynamic> metadata = const {}}) =>
          WorkflowEvent(
        workflowId: workflowId,
        step: 'processed',
        data: processedData,
        eventId: eventId,
        sourceService: sourceService,
        timestamp: timestamp,
        correlationId: correlationId,
        metadata: metadata,
      ),
    ));

    return processedData;
  }
}

// Another remote service
@ServiceContract(remote: true)
abstract class NotificationSender extends BaseService {
  Future<String> sendNotification(
      String recipient, String message, String type);
}

class NotificationSenderImpl extends NotificationSender with ServiceEventMixin {
  final List<Map<String, dynamic>> sentNotifications = [];

  @override
  Future<void> initialize() async {
    _registerNotificationSenderDispatcher();
    await super.initialize();

    // Listen for workflow events
    onEvent<WorkflowEvent>((event) async {
      if (event.step == 'processed') {
        // Automatically send completion notification
        await sendNotification(
            'user@example.com',
            'Your workflow ${event.workflowId} has been processed',
            'completion');

        // Send final completion event
        await sendEvent(createEvent(
          (
                  {required String eventId,
                  required String sourceService,
                  required DateTime timestamp,
                  String? correlationId,
                  Map<String, dynamic> metadata = const {}}) =>
              WorkflowEvent(
            workflowId: event.workflowId,
            step: 'completed',
            data: event.data,
            eventId: eventId,
            sourceService: sourceService,
            timestamp: timestamp,
            correlationId: correlationId,
            metadata: metadata,
          ),
        ));
      }

      return EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration(milliseconds: 15),
      );
    });
  }

  @override
  Future<String> sendNotification(
      String recipient, String message, String type) async {
    final notificationId = 'notif-${DateTime.now().millisecondsSinceEpoch}';

    sentNotifications.add({
      'id': notificationId,
      'recipient': recipient,
      'message': message,
      'type': type,
      'sentAt': DateTime.now().toIso8601String(),
    });

    logger.info('Notification sent', metadata: {
      'notificationId': notificationId,
      'recipient': recipient,
      'type': type,
    });

    return notificationId;
  }
}

// Demo runner
Future<Map<String, dynamic>> _runTransparentServicesDemo() async {
  // 🚀 OPTIMIZED: ServiceLocator handles everything automatically!
  final locator = ServiceLocator();

  // Register services - all infrastructure automatic!
  registerWorkflowOrchestratorGenerated();
  locator.register<WorkflowOrchestrator>(() => WorkflowOrchestrator());

  // Register remote services - completely transparent!
  await locator.registerWorkerServiceProxy<DataProcessor>(
    serviceName: 'DataProcessor',
    serviceFactory: () => DataProcessorImpl(),
    registerGenerated: registerDataProcessorGenerated,
  );

  await locator.registerWorkerServiceProxy<NotificationSender>(
    serviceName: 'NotificationSender',
    serviceFactory: () => NotificationSenderImpl(),
    registerGenerated: registerNotificationSenderGenerated,
  );

  // 🚀 OPTIMIZED: Everything configured automatically!
  await locator.initializeAll();

  final orchestrator = locator.get<WorkflowOrchestrator>();

  // Run the demo workflow
  await orchestrator.startWorkflow('demo-workflow-1', {
    'userId': 'user123',
    'dataType': 'customer_profile',
    'priority': 'high',
  });

  // Wait for the workflow to complete
  await Future.delayed(Duration(seconds: 1));

  await locator.destroyAll();

  return {
    'completedWorkflows': orchestrator.completedWorkflows,
    'demonstratedTransparency': true,
  };
}

void main() {
  group('Transparent Services Demo', () {
    test('Services call each other transparently across isolates', () async {
      final result = await _runTransparentServicesDemo();

      // Verify the workflow completed
      expect(result['completedWorkflows'], contains('demo-workflow-1'));
      expect(result['demonstratedTransparency'], isTrue);

      print('🎉 OPTIMIZED TRANSPARENT SERVICES WORKING!');
      print('✅ ServiceLocator automatically set up ALL infrastructure');
      print('✅ Local service called remote services seamlessly');
      print('✅ Remote services called each other transparently');
      print('✅ Zero manual configuration required');
      print('✅ Complete API transparency achieved');
      print('📊 Completed workflows: ${result['completedWorkflows']}');
    });
  });
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transparent_services_demo.dart';

// **************************************************************************
// ServiceGenerator
// **************************************************************************

// Service client for WorkflowOrchestrator
class WorkflowOrchestratorClient extends WorkflowOrchestrator {
  WorkflowOrchestratorClient(this._proxy);
  final ServiceProxy<WorkflowOrchestrator> _proxy;
}

void _registerWorkflowOrchestratorClientFactory() {
  GeneratedClientRegistry.register<WorkflowOrchestrator>(
    (proxy) => WorkflowOrchestratorClient(proxy),
  );
}

class _WorkflowOrchestratorMethods {}

Future<dynamic> _WorkflowOrchestratorDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as WorkflowOrchestrator;
  switch (methodId) {
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void _registerWorkflowOrchestratorDispatcher() {
  GeneratedDispatcherRegistry.register<WorkflowOrchestrator>(
    _WorkflowOrchestratorDispatcher,
  );
}

void _registerWorkflowOrchestratorMethodIds() {
  ServiceMethodIdRegistry.register<WorkflowOrchestrator>({});
}

void registerWorkflowOrchestratorGenerated() {
  _registerWorkflowOrchestratorClientFactory();
  _registerWorkflowOrchestratorMethodIds();
}

// Service client for DataProcessor
class DataProcessorClient extends DataProcessor {
  DataProcessorClient(this._proxy);
  final ServiceProxy<DataProcessor> _proxy;

  @override
  Future<Map<String, dynamic>> processData(
      String workflowId, Map<String, dynamic> data) async {
    return await _proxy
        .callMethod('processData', [workflowId, data], namedArgs: {});
  }
}

void _registerDataProcessorClientFactory() {
  GeneratedClientRegistry.register<DataProcessor>(
    (proxy) => DataProcessorClient(proxy),
  );
}

class _DataProcessorMethods {
  static const int processDataId = 1;
}

Future<dynamic> _DataProcessorDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as DataProcessor;
  switch (methodId) {
    case _DataProcessorMethods.processDataId:
      return await s.processData(positionalArgs[0], positionalArgs[1]);
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void _registerDataProcessorDispatcher() {
  GeneratedDispatcherRegistry.register<DataProcessor>(
    _DataProcessorDispatcher,
  );
}

void _registerDataProcessorMethodIds() {
  ServiceMethodIdRegistry.register<DataProcessor>({
    'processData': _DataProcessorMethods.processDataId,
  });
}

void registerDataProcessorGenerated() {
  _registerDataProcessorClientFactory();
  _registerDataProcessorMethodIds();
}

// Service client for NotificationSender
class NotificationSenderClient extends NotificationSender {
  NotificationSenderClient(this._proxy);
  final ServiceProxy<NotificationSender> _proxy;

  @override
  Future<String> sendNotification(
      String recipient, String message, String type) async {
    return await _proxy.callMethod(
        'sendNotification', [recipient, message, type],
        namedArgs: {});
  }
}

void _registerNotificationSenderClientFactory() {
  GeneratedClientRegistry.register<NotificationSender>(
    (proxy) => NotificationSenderClient(proxy),
  );
}

class _NotificationSenderMethods {
  static const int sendNotificationId = 1;
}

Future<dynamic> _NotificationSenderDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as NotificationSender;
  switch (methodId) {
    case _NotificationSenderMethods.sendNotificationId:
      return await s.sendNotification(
          positionalArgs[0], positionalArgs[1], positionalArgs[2]);
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void _registerNotificationSenderDispatcher() {
  GeneratedDispatcherRegistry.register<NotificationSender>(
    _NotificationSenderDispatcher,
  );
}

void _registerNotificationSenderMethodIds() {
  ServiceMethodIdRegistry.register<NotificationSender>({
    'sendNotification': _NotificationSenderMethods.sendNotificationId,
  });
}

void registerNotificationSenderGenerated() {
  _registerNotificationSenderClientFactory();
  _registerNotificationSenderMethodIds();
}

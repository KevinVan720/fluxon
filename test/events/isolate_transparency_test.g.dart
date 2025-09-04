// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isolate_transparency_test.dart';

// **************************************************************************
// ServiceGenerator
// **************************************************************************

// Service client for TaskOrchestrator
class TaskOrchestratorClient extends TaskOrchestrator {
  TaskOrchestratorClient(this._proxy);
  final ServiceProxy<TaskOrchestrator> _proxy;

  @override
  Future<void> executeTask(String taskId, Map<String, dynamic> data) async {
    return await _proxy
        .callMethod('executeTask', [taskId, data], namedArgs: {});
  }
}

void _registerTaskOrchestratorClientFactory() {
  GeneratedClientRegistry.register<TaskOrchestrator>(
    (proxy) => TaskOrchestratorClient(proxy),
  );
}

class _TaskOrchestratorMethods {
  static const int executeTaskId = 1;
}

Future<dynamic> _TaskOrchestratorDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as TaskOrchestrator;
  switch (methodId) {
    case _TaskOrchestratorMethods.executeTaskId:
      return await s.executeTask(positionalArgs[0], positionalArgs[1]);
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void _registerTaskOrchestratorDispatcher() {
  GeneratedDispatcherRegistry.register<TaskOrchestrator>(
    _TaskOrchestratorDispatcher,
  );
}

void _registerTaskOrchestratorMethodIds() {
  ServiceMethodIdRegistry.register<TaskOrchestrator>({
    'executeTask': _TaskOrchestratorMethods.executeTaskId,
  });
}

void registerTaskOrchestratorGenerated() {
  _registerTaskOrchestratorClientFactory();
  _registerTaskOrchestratorMethodIds();
}

// 🚀 FLUX: Single registration call mixin
mixin TaskOrchestratorRegistration {
  void registerService() {
    _registerTaskOrchestratorDispatcher();
  }
}

// Service client for TaskProcessor
class TaskProcessorClient extends TaskProcessor {
  TaskProcessorClient(this._proxy);
  final ServiceProxy<TaskProcessor> _proxy;

  @override
  Future<Map<String, dynamic>> processTask(
      String taskId, Map<String, dynamic> data) async {
    return await _proxy
        .callMethod('processTask', [taskId, data], namedArgs: {});
  }
}

void _registerTaskProcessorClientFactory() {
  GeneratedClientRegistry.register<TaskProcessor>(
    (proxy) => TaskProcessorClient(proxy),
  );
}

class _TaskProcessorMethods {
  static const int processTaskId = 1;
}

Future<dynamic> _TaskProcessorDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as TaskProcessor;
  switch (methodId) {
    case _TaskProcessorMethods.processTaskId:
      return await s.processTask(positionalArgs[0], positionalArgs[1]);
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void _registerTaskProcessorDispatcher() {
  GeneratedDispatcherRegistry.register<TaskProcessor>(
    _TaskProcessorDispatcher,
  );
}

void _registerTaskProcessorMethodIds() {
  ServiceMethodIdRegistry.register<TaskProcessor>({
    'processTask': _TaskProcessorMethods.processTaskId,
  });
}

void registerTaskProcessorGenerated() {
  _registerTaskProcessorClientFactory();
  _registerTaskProcessorMethodIds();
}

// Worker implementation that auto-registers the dispatcher
class TaskProcessorWorker extends TaskProcessor {
  @override
  Future<void> initialize() async {
    _registerTaskProcessorDispatcher();
    await super.initialize();
  }
}

// 🚀 FLUX: Single registration call mixin
mixin TaskProcessorRegistration {
  void registerService() {
    _registerTaskProcessorDispatcher();
  }
}

// Service client for TaskLogger
class TaskLoggerClient extends TaskLogger {
  TaskLoggerClient(this._proxy);
  final ServiceProxy<TaskLogger> _proxy;

  @override
  Future<void> logTaskProgress(
      String taskId, String status, Map<String, dynamic> data) async {
    return await _proxy
        .callMethod('logTaskProgress', [taskId, status, data], namedArgs: {});
  }

  @override
  Future<List<Map<String, dynamic>>> getTaskLogs() async {
    return await _proxy.callMethod('getTaskLogs', [], namedArgs: {});
  }
}

void _registerTaskLoggerClientFactory() {
  GeneratedClientRegistry.register<TaskLogger>(
    (proxy) => TaskLoggerClient(proxy),
  );
}

class _TaskLoggerMethods {
  static const int logTaskProgressId = 1;
  static const int getTaskLogsId = 2;
}

Future<dynamic> _TaskLoggerDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as TaskLogger;
  switch (methodId) {
    case _TaskLoggerMethods.logTaskProgressId:
      return await s.logTaskProgress(
          positionalArgs[0], positionalArgs[1], positionalArgs[2]);
    case _TaskLoggerMethods.getTaskLogsId:
      return await s.getTaskLogs();
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void _registerTaskLoggerDispatcher() {
  GeneratedDispatcherRegistry.register<TaskLogger>(
    _TaskLoggerDispatcher,
  );
}

void _registerTaskLoggerMethodIds() {
  ServiceMethodIdRegistry.register<TaskLogger>({
    'logTaskProgress': _TaskLoggerMethods.logTaskProgressId,
    'getTaskLogs': _TaskLoggerMethods.getTaskLogsId,
  });
}

void registerTaskLoggerGenerated() {
  _registerTaskLoggerClientFactory();
  _registerTaskLoggerMethodIds();
}

// Worker implementation that auto-registers the dispatcher
class TaskLoggerWorker extends TaskLogger {
  @override
  Future<void> initialize() async {
    _registerTaskLoggerDispatcher();
    await super.initialize();
  }
}

// 🚀 FLUX: Single registration call mixin
mixin TaskLoggerRegistration {
  void registerService() {
    _registerTaskLoggerDispatcher();
  }
}

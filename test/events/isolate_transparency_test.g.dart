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

void $registerTaskOrchestratorClientFactory() {
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

void $registerTaskOrchestratorDispatcher() {
  GeneratedDispatcherRegistry.register<TaskOrchestrator>(
    _TaskOrchestratorDispatcher,
  );
}

void $registerTaskOrchestratorMethodIds() {
  ServiceMethodIdRegistry.register<TaskOrchestrator>({
    'executeTask': _TaskOrchestratorMethods.executeTaskId,
  });
}

void registerTaskOrchestratorGenerated() {
  $registerTaskOrchestratorClientFactory();
  $registerTaskOrchestratorMethodIds();
}

// Local worker implementation that auto-registers local side
class TaskOrchestratorLocalWorker extends TaskOrchestrator {
  TaskOrchestratorLocalWorker() {
    // 🚀 AUTO-REGISTRATION: Register local side when instance is created
    $registerTaskOrchestratorLocalSide();
  }
}

void $registerTaskOrchestratorLocalSide() {
  $registerTaskOrchestratorDispatcher();
  $registerTaskOrchestratorClientFactory();
  $registerTaskOrchestratorMethodIds();
  try {
    $registerTaskProcessorClientFactory();
  } catch (_) {}
  try {
    $registerTaskProcessorMethodIds();
  } catch (_) {}
  try {
    $registerTaskLoggerClientFactory();
  } catch (_) {}
  try {
    $registerTaskLoggerMethodIds();
  } catch (_) {}
}

void $autoRegisterTaskOrchestratorLocalSide() {
  LocalSideRegistry.register<TaskOrchestrator>(
      $registerTaskOrchestratorLocalSide);
}

final $_TaskOrchestratorLocalSideRegistered = (() {
  $autoRegisterTaskOrchestratorLocalSide();
  return true;
})();

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

void $registerTaskProcessorClientFactory() {
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

void $registerTaskProcessorDispatcher() {
  GeneratedDispatcherRegistry.register<TaskProcessor>(
    _TaskProcessorDispatcher,
  );
}

void $registerTaskProcessorMethodIds() {
  ServiceMethodIdRegistry.register<TaskProcessor>({
    'processTask': _TaskProcessorMethods.processTaskId,
  });
}

void registerTaskProcessorGenerated() {
  $registerTaskProcessorClientFactory();
  $registerTaskProcessorMethodIds();
}

// Worker implementation that auto-registers the dispatcher
class TaskProcessorWorker extends TaskProcessor {
  @override
  Type get clientBaseType => TaskProcessor;
  @override
  Future<void> registerHostSide() async {
    $registerTaskProcessorClientFactory();
    $registerTaskProcessorMethodIds();
    // Auto-registered from dependencies/optionalDependencies
    try {
      $registerTaskLoggerClientFactory();
    } catch (_) {}
    try {
      $registerTaskLoggerMethodIds();
    } catch (_) {}
  }

  @override
  Future<void> initialize() async {
    $registerTaskProcessorDispatcher();
    // Ensure worker isolate can create clients for dependencies
    try {
      $registerTaskLoggerClientFactory();
    } catch (_) {}
    try {
      $registerTaskLoggerMethodIds();
    } catch (_) {}
    await super.initialize();
  }
}

void $registerTaskProcessorLocalSide() {
  $registerTaskProcessorDispatcher();
  $registerTaskProcessorClientFactory();
  $registerTaskProcessorMethodIds();
  try {
    $registerTaskLoggerClientFactory();
  } catch (_) {}
  try {
    $registerTaskLoggerMethodIds();
  } catch (_) {}
}

void $autoRegisterTaskProcessorLocalSide() {
  LocalSideRegistry.register<TaskProcessor>($registerTaskProcessorLocalSide);
}

final $_TaskProcessorLocalSideRegistered = (() {
  $autoRegisterTaskProcessorLocalSide();
  return true;
})();

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

void $registerTaskLoggerClientFactory() {
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

void $registerTaskLoggerDispatcher() {
  GeneratedDispatcherRegistry.register<TaskLogger>(
    _TaskLoggerDispatcher,
  );
}

void $registerTaskLoggerMethodIds() {
  ServiceMethodIdRegistry.register<TaskLogger>({
    'logTaskProgress': _TaskLoggerMethods.logTaskProgressId,
    'getTaskLogs': _TaskLoggerMethods.getTaskLogsId,
  });
}

void registerTaskLoggerGenerated() {
  $registerTaskLoggerClientFactory();
  $registerTaskLoggerMethodIds();
}

// Worker implementation that auto-registers the dispatcher
class TaskLoggerWorker extends TaskLogger {
  @override
  Type get clientBaseType => TaskLogger;
  @override
  Future<void> registerHostSide() async {
    $registerTaskLoggerClientFactory();
    $registerTaskLoggerMethodIds();
  }

  @override
  Future<void> initialize() async {
    $registerTaskLoggerDispatcher();
    await super.initialize();
  }
}

void $registerTaskLoggerLocalSide() {
  $registerTaskLoggerDispatcher();
  $registerTaskLoggerClientFactory();
  $registerTaskLoggerMethodIds();
}

void $autoRegisterTaskLoggerLocalSide() {
  LocalSideRegistry.register<TaskLogger>($registerTaskLoggerLocalSide);
}

final $_TaskLoggerLocalSideRegistered = (() {
  $autoRegisterTaskLoggerLocalSide();
  return true;
})();

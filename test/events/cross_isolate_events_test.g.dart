// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cross_isolate_events_test.dart';

// **************************************************************************
// ServiceGenerator
// **************************************************************************

// Service client for MessageCoordinator
class MessageCoordinatorClient extends MessageCoordinator {
  MessageCoordinatorClient(this._proxy);
  final ServiceProxy<MessageCoordinator> _proxy;

  @override
  Future<void> sendMessage(
      String content, String sender, String recipient) async {
    return await _proxy
        .callMethod('sendMessage', [content, sender, recipient], namedArgs: {});
  }
}

void $registerMessageCoordinatorClientFactory() {
  GeneratedClientRegistry.register<MessageCoordinator>(
    (proxy) => MessageCoordinatorClient(proxy),
  );
}

class _MessageCoordinatorMethods {
  static const int sendMessageId = 1;
}

Future<dynamic> _MessageCoordinatorDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as MessageCoordinator;
  switch (methodId) {
    case _MessageCoordinatorMethods.sendMessageId:
      return await s.sendMessage(
          positionalArgs[0], positionalArgs[1], positionalArgs[2]);
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void $registerMessageCoordinatorDispatcher() {
  GeneratedDispatcherRegistry.register<MessageCoordinator>(
    _MessageCoordinatorDispatcher,
  );
}

void $registerMessageCoordinatorMethodIds() {
  ServiceMethodIdRegistry.register<MessageCoordinator>({
    'sendMessage': _MessageCoordinatorMethods.sendMessageId,
  });
}

void registerMessageCoordinatorGenerated() {
  $registerMessageCoordinatorClientFactory();
  $registerMessageCoordinatorMethodIds();
}

void $registerMessageCoordinatorLocalSide() {
  $registerMessageCoordinatorDispatcher();
  $registerMessageCoordinatorClientFactory();
  $registerMessageCoordinatorMethodIds();
  try {
    $registerMessageProcessorClientFactory();
  } catch (_) {}
  try {
    $registerMessageProcessorMethodIds();
  } catch (_) {}
  try {
    $registerMessageLoggerClientFactory();
  } catch (_) {}
  try {
    $registerMessageLoggerMethodIds();
  } catch (_) {}
}

// Service client for MessageProcessor
class MessageProcessorClient extends MessageProcessor {
  MessageProcessorClient(this._proxy);
  final ServiceProxy<MessageProcessor> _proxy;

  @override
  Future<void> processMessage(String messageId, String content) async {
    return await _proxy
        .callMethod('processMessage', [messageId, content], namedArgs: {});
  }
}

void $registerMessageProcessorClientFactory() {
  GeneratedClientRegistry.register<MessageProcessor>(
    (proxy) => MessageProcessorClient(proxy),
  );
}

class _MessageProcessorMethods {
  static const int processMessageId = 1;
}

Future<dynamic> _MessageProcessorDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as MessageProcessor;
  switch (methodId) {
    case _MessageProcessorMethods.processMessageId:
      return await s.processMessage(positionalArgs[0], positionalArgs[1]);
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void $registerMessageProcessorDispatcher() {
  GeneratedDispatcherRegistry.register<MessageProcessor>(
    _MessageProcessorDispatcher,
  );
}

void $registerMessageProcessorMethodIds() {
  ServiceMethodIdRegistry.register<MessageProcessor>({
    'processMessage': _MessageProcessorMethods.processMessageId,
  });
}

void registerMessageProcessorGenerated() {
  $registerMessageProcessorClientFactory();
  $registerMessageProcessorMethodIds();
}

// Worker implementation that auto-registers the dispatcher
class MessageProcessorWorker extends MessageProcessor {
  @override
  Type get clientBaseType => MessageProcessor;
  @override
  Future<void> registerHostSide() async {
    $registerMessageProcessorClientFactory();
    $registerMessageProcessorMethodIds();
    // Auto-registered from dependencies/optionalDependencies
    try {
      _registerMessageLoggerClientFactory();
    } catch (_) {}
    try {
      _registerMessageLoggerMethodIds();
    } catch (_) {}
  }

  @override
  Future<void> initialize() async {
    $registerMessageProcessorDispatcher();
    // Ensure worker isolate can create clients for dependencies
    try {
      _registerMessageLoggerClientFactory();
    } catch (_) {}
    try {
      _registerMessageLoggerMethodIds();
    } catch (_) {}
    await super.initialize();
  }
}

void $registerMessageProcessorLocalSide() {
  $registerMessageProcessorDispatcher();
  $registerMessageProcessorClientFactory();
  $registerMessageProcessorMethodIds();
  try {
    $registerMessageLoggerClientFactory();
  } catch (_) {}
  try {
    $registerMessageLoggerMethodIds();
  } catch (_) {}
}

// Service client for MessageLogger
class MessageLoggerClient extends MessageLogger {
  MessageLoggerClient(this._proxy);
  final ServiceProxy<MessageLogger> _proxy;

  @override
  Future<void> logMessage(
      String messageId, String status, String content) async {
    return await _proxy
        .callMethod('logMessage', [messageId, status, content], namedArgs: {});
  }

  @override
  Future<List<Map<String, dynamic>>> getMessageLogs() async {
    return await _proxy.callMethod('getMessageLogs', [], namedArgs: {});
  }
}

void $registerMessageLoggerClientFactory() {
  GeneratedClientRegistry.register<MessageLogger>(
    (proxy) => MessageLoggerClient(proxy),
  );
}

class _MessageLoggerMethods {
  static const int logMessageId = 1;
  static const int getMessageLogsId = 2;
}

Future<dynamic> _MessageLoggerDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as MessageLogger;
  switch (methodId) {
    case _MessageLoggerMethods.logMessageId:
      return await s.logMessage(
          positionalArgs[0], positionalArgs[1], positionalArgs[2]);
    case _MessageLoggerMethods.getMessageLogsId:
      return await s.getMessageLogs();
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void $registerMessageLoggerDispatcher() {
  GeneratedDispatcherRegistry.register<MessageLogger>(
    _MessageLoggerDispatcher,
  );
}

void $registerMessageLoggerMethodIds() {
  ServiceMethodIdRegistry.register<MessageLogger>({
    'logMessage': _MessageLoggerMethods.logMessageId,
    'getMessageLogs': _MessageLoggerMethods.getMessageLogsId,
  });
}

void registerMessageLoggerGenerated() {
  $registerMessageLoggerClientFactory();
  $registerMessageLoggerMethodIds();
}

// Worker implementation that auto-registers the dispatcher
class MessageLoggerWorker extends MessageLogger {
  @override
  Type get clientBaseType => MessageLogger;
  @override
  Future<void> registerHostSide() async {
    $registerMessageLoggerClientFactory();
    $registerMessageLoggerMethodIds();
  }

  @override
  Future<void> initialize() async {
    $registerMessageLoggerDispatcher();
    await super.initialize();
  }
}

void $registerMessageLoggerLocalSide() {
  $registerMessageLoggerDispatcher();
  $registerMessageLoggerClientFactory();
  $registerMessageLoggerMethodIds();
}

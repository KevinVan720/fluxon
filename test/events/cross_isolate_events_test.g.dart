// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cross_isolate_events_test.dart';

// **************************************************************************
// ServiceGenerator
// **************************************************************************

// Service client for MessageCoordinator
class MessageCoordinatorClient extends MessageCoordinator {
  MessageCoordinatorClient(this._proxy);
  final ServiceProxy<MessageCoordinator> _proxy;
}

void _registerMessageCoordinatorClientFactory() {
  GeneratedClientRegistry.register<MessageCoordinator>(
    (proxy) => MessageCoordinatorClient(proxy),
  );
}

class _MessageCoordinatorMethods {}

Future<dynamic> _MessageCoordinatorDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as MessageCoordinator;
  switch (methodId) {
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void _registerMessageCoordinatorDispatcher() {
  GeneratedDispatcherRegistry.register<MessageCoordinator>(
    _MessageCoordinatorDispatcher,
  );
}

void _registerMessageCoordinatorMethodIds() {
  ServiceMethodIdRegistry.register<MessageCoordinator>({});
}

void registerMessageCoordinatorGenerated() {
  _registerMessageCoordinatorClientFactory();
  _registerMessageCoordinatorMethodIds();
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

void _registerMessageProcessorClientFactory() {
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

void _registerMessageProcessorDispatcher() {
  GeneratedDispatcherRegistry.register<MessageProcessor>(
    _MessageProcessorDispatcher,
  );
}

void _registerMessageProcessorMethodIds() {
  ServiceMethodIdRegistry.register<MessageProcessor>({
    'processMessage': _MessageProcessorMethods.processMessageId,
  });
}

void registerMessageProcessorGenerated() {
  _registerMessageProcessorClientFactory();
  _registerMessageProcessorMethodIds();
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

void _registerMessageLoggerClientFactory() {
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

void _registerMessageLoggerDispatcher() {
  GeneratedDispatcherRegistry.register<MessageLogger>(
    _MessageLoggerDispatcher,
  );
}

void _registerMessageLoggerMethodIds() {
  ServiceMethodIdRegistry.register<MessageLogger>({
    'logMessage': _MessageLoggerMethods.logMessageId,
    'getMessageLogs': _MessageLoggerMethods.getMessageLogsId,
  });
}

void registerMessageLoggerGenerated() {
  _registerMessageLoggerClientFactory();
  _registerMessageLoggerMethodIds();
}

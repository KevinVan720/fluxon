// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'parallel_vs_sequential_test.dart';

// **************************************************************************
// ServiceGenerator
// **************************************************************************

// Service client for ProcessingServiceA
class ProcessingServiceAClient extends ProcessingServiceA {
  ProcessingServiceAClient(this._proxy);
  final ServiceProxy<ProcessingServiceA> _proxy;
}

void $registerProcessingServiceAClientFactory() {
  GeneratedClientRegistry.register<ProcessingServiceA>(
    (proxy) => ProcessingServiceAClient(proxy),
  );
}

class _ProcessingServiceAMethods {}

Future<dynamic> _ProcessingServiceADispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as ProcessingServiceA;
  switch (methodId) {
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void $registerProcessingServiceADispatcher() {
  GeneratedDispatcherRegistry.register<ProcessingServiceA>(
    _ProcessingServiceADispatcher,
  );
}

void $registerProcessingServiceAMethodIds() {
  ServiceMethodIdRegistry.register<ProcessingServiceA>({});
}

void registerProcessingServiceAGenerated() {
  $registerProcessingServiceAClientFactory();
  $registerProcessingServiceAMethodIds();
}

// Local service implementation that auto-registers local side
class ProcessingServiceAImpl extends ProcessingServiceA {
  ProcessingServiceAImpl() {
    // 🚀 AUTO-REGISTRATION: Register local side when instance is created
    $registerProcessingServiceALocalSide();
  }
}

void $registerProcessingServiceALocalSide() {
  $registerProcessingServiceADispatcher();
  $registerProcessingServiceAClientFactory();
  $registerProcessingServiceAMethodIds();
}

void $autoRegisterProcessingServiceALocalSide() {
  LocalSideRegistry.register<ProcessingServiceA>(
      $registerProcessingServiceALocalSide);
}

final $_ProcessingServiceALocalSideRegistered = (() {
  $autoRegisterProcessingServiceALocalSide();
  return true;
})();

// Service client for ProcessingServiceB
class ProcessingServiceBClient extends ProcessingServiceB {
  ProcessingServiceBClient(this._proxy);
  final ServiceProxy<ProcessingServiceB> _proxy;
}

void $registerProcessingServiceBClientFactory() {
  GeneratedClientRegistry.register<ProcessingServiceB>(
    (proxy) => ProcessingServiceBClient(proxy),
  );
}

class _ProcessingServiceBMethods {}

Future<dynamic> _ProcessingServiceBDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as ProcessingServiceB;
  switch (methodId) {
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void $registerProcessingServiceBDispatcher() {
  GeneratedDispatcherRegistry.register<ProcessingServiceB>(
    _ProcessingServiceBDispatcher,
  );
}

void $registerProcessingServiceBMethodIds() {
  ServiceMethodIdRegistry.register<ProcessingServiceB>({});
}

void registerProcessingServiceBGenerated() {
  $registerProcessingServiceBClientFactory();
  $registerProcessingServiceBMethodIds();
}

// Local service implementation that auto-registers local side
class ProcessingServiceBImpl extends ProcessingServiceB {
  ProcessingServiceBImpl() {
    // 🚀 AUTO-REGISTRATION: Register local side when instance is created
    $registerProcessingServiceBLocalSide();
  }
}

void $registerProcessingServiceBLocalSide() {
  $registerProcessingServiceBDispatcher();
  $registerProcessingServiceBClientFactory();
  $registerProcessingServiceBMethodIds();
}

void $autoRegisterProcessingServiceBLocalSide() {
  LocalSideRegistry.register<ProcessingServiceB>(
      $registerProcessingServiceBLocalSide);
}

final $_ProcessingServiceBLocalSideRegistered = (() {
  $autoRegisterProcessingServiceBLocalSide();
  return true;
})();

// Service client for EventSender
class EventSenderClient extends EventSender {
  EventSenderClient(this._proxy);
  final ServiceProxy<EventSender> _proxy;

  @override
  Future<EventDistributionResult> sendTestEvent(
      String message, EventDistribution distribution) async {
    final result = await _proxy
        .callMethod('sendTestEvent', [message, distribution], namedArgs: {});
    return result as EventDistributionResult;
  }
}

void $registerEventSenderClientFactory() {
  GeneratedClientRegistry.register<EventSender>(
    (proxy) => EventSenderClient(proxy),
  );
}

class _EventSenderMethods {
  static const int sendTestEventId = 1;
}

Future<dynamic> _EventSenderDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as EventSender;
  switch (methodId) {
    case _EventSenderMethods.sendTestEventId:
      return await s.sendTestEvent(positionalArgs[0], positionalArgs[1]);
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void $registerEventSenderDispatcher() {
  GeneratedDispatcherRegistry.register<EventSender>(
    _EventSenderDispatcher,
  );
}

void $registerEventSenderMethodIds() {
  ServiceMethodIdRegistry.register<EventSender>({
    'sendTestEvent': _EventSenderMethods.sendTestEventId,
  });
}

void registerEventSenderGenerated() {
  $registerEventSenderClientFactory();
  $registerEventSenderMethodIds();
}

// Local service implementation that auto-registers local side
class EventSenderImpl extends EventSender {
  EventSenderImpl() {
    // 🚀 AUTO-REGISTRATION: Register local side when instance is created
    $registerEventSenderLocalSide();
  }
}

void $registerEventSenderLocalSide() {
  $registerEventSenderDispatcher();
  $registerEventSenderClientFactory();
  $registerEventSenderMethodIds();
}

void $autoRegisterEventSenderLocalSide() {
  LocalSideRegistry.register<EventSender>($registerEventSenderLocalSide);
}

final $_EventSenderLocalSideRegistered = (() {
  $autoRegisterEventSenderLocalSide();
  return true;
})();

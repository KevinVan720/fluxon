/// Event bridge for cross-isolate event communication
library event_bridge;

import 'dart:async';
import 'dart:isolate';

import '../service_logger.dart';
import 'service_event.dart';
import 'event_dispatcher.dart';

/// Message types for cross-isolate event communication
enum EventMessageType {
  eventSend,
  eventSubscribe,
  eventUnsubscribe,
  eventSubscriptionResponse,
}

/// Message for cross-isolate event communication
class EventMessage {
  const EventMessage({
    required this.type,
    required this.requestId,
    this.eventData,
    this.eventType,
    this.sourceIsolate,
    this.targetIsolate,
    this.subscriptionId,
    this.success,
    this.error,
  });

  final EventMessageType type;
  final String requestId;
  final Map<String, dynamic>? eventData;
  final String? eventType;
  final String? sourceIsolate;
  final String? targetIsolate;
  final String? subscriptionId;
  final bool? success;
  final String? error;

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'requestId': requestId,
      'eventData': eventData,
      'eventType': eventType,
      'sourceIsolate': sourceIsolate,
      'targetIsolate': targetIsolate,
      'subscriptionId': subscriptionId,
      'success': success,
      'error': error,
    };
  }

  factory EventMessage.fromJson(Map<String, dynamic> json) {
    return EventMessage(
      type: EventMessageType.values.byName(json['type'] as String),
      requestId: json['requestId'] as String,
      eventData: json['eventData'] as Map<String, dynamic>?,
      eventType: json['eventType'] as String?,
      sourceIsolate: json['sourceIsolate'] as String?,
      targetIsolate: json['targetIsolate'] as String?,
      subscriptionId: json['subscriptionId'] as String?,
      success: json['success'] as bool?,
      error: json['error'] as String?,
    );
  }
}

/// Bridge for sending events across isolate boundaries
class EventBridge {
  EventBridge({
    required String isolateName,
    ServiceLogger? logger,
  })  : _isolateName = isolateName,
        _logger =
            logger ?? ServiceLogger(serviceName: 'EventBridge[$isolateName]');

  final String _isolateName;
  final ServiceLogger _logger;
  final Map<String, ReceivePort> _subscriptionPorts = {};
  final Map<String, EventSubscription> _remoteSubscriptions = {};
  final Map<String, Completer<bool>> _pendingSubscriptions = {};
  final Set<String> _knownIsolates = {};

  SendPort? _hostPort;
  ReceivePort? _isolatePort;
  StreamSubscription? _messageSubscription;
  EventDispatcher? _dispatcher;

  // Callback for broadcasting events to workers
  Future<void> Function(ServiceEvent)? _workerBroadcastCallback;

  /// Initialize the event bridge
  void initialize(EventDispatcher dispatcher,
      {SendPort? hostPort,
      Future<void> Function(ServiceEvent)? workerBroadcastCallback}) {
    _dispatcher = dispatcher;
    _hostPort = hostPort;
    _workerBroadcastCallback = workerBroadcastCallback;

    if (hostPort != null) {
      // This is a worker isolate, set up communication with host
      _isolatePort = ReceivePort();
      _messageSubscription = _isolatePort!.listen(_handleMessage);

      // Send our port to the host
      hostPort.send({
        'type': 'eventBridgeInit',
        'port': _isolatePort!.sendPort,
        'isolateName': _isolateName,
      });
    }

    _logger.info('Event bridge initialized', metadata: {
      'isolateName': _isolateName,
      'isHost': hostPort == null,
    });
  }

  /// Send an event across isolate boundaries
  Future<void> sendEventToRemote(
    ServiceEvent event,
    String targetIsolate,
  ) async {
    if (_hostPort == null) {
      throw StateError('Event bridge not connected to host');
    }

    final message = EventMessage(
      type: EventMessageType.eventSend,
      requestId: _generateRequestId(),
      eventData: event.toJson(),
      eventType: event.runtimeType.toString(),
      sourceIsolate: _isolateName,
      targetIsolate: targetIsolate,
    );

    _hostPort!.send(message.toJson());

    _logger.debug('Event sent to remote isolate', metadata: {
      'eventId': event.eventId,
      'eventType': event.eventType,
      'targetIsolate': targetIsolate,
    });
  }

  /// Send an event to all known remote isolates
  Future<void> sendEventToAllRemotes(ServiceEvent event) async {
    if (_hostPort == null) {
      // This is the main isolate - use worker broadcast callback
      if (_workerBroadcastCallback != null) {
        await _workerBroadcastCallback!(event);
      } else {
        _logger.debug('No worker broadcast callback available');
      }
      return;
    }

    // This is a worker isolate - send to host for distribution
    final message = {
      'cmd': 'broadcastEvent',
      'eventData': event.toJson(),
      'sourceIsolate': _isolateName,
    };

    _hostPort!.send(message);

    _logger.debug('Event broadcast request sent to host', metadata: {
      'eventId': event.eventId,
      'eventType': event.eventType,
      'sourceIsolate': _isolateName,
    });
  }

  /// Register a known isolate
  void registerIsolate(String isolateName) {
    _knownIsolates.add(isolateName);
    _logger.debug('Registered isolate', metadata: {'isolateName': isolateName});
  }

  /// Unregister an isolate
  void unregisterIsolate(String isolateName) {
    _knownIsolates.remove(isolateName);
    _logger
        .debug('Unregistered isolate', metadata: {'isolateName': isolateName});
  }

  /// Get list of known isolates
  Set<String> get knownIsolates => Set.from(_knownIsolates);

  /// Subscribe to events from remote isolates
  Future<String> subscribeToRemoteEvents<T extends ServiceEvent>(
    Type eventType,
    EventHandler<T> handler,
  ) async {
    if (_hostPort == null) {
      throw StateError('Event bridge not connected to host');
    }

    final subscriptionId = _generateRequestId();
    final completer = Completer<bool>();
    _pendingSubscriptions[subscriptionId] = completer;

    final message = EventMessage(
      type: EventMessageType.eventSubscribe,
      requestId: subscriptionId,
      eventType: eventType.toString(),
      sourceIsolate: _isolateName,
    );

    _hostPort!.send(message.toJson());

    // Wait for subscription confirmation
    final success = await completer.future.timeout(
      Duration(seconds: 5),
      onTimeout: () => throw TimeoutException(
          'Event subscription timeout', Duration(seconds: 5)),
    );

    if (!success) {
      throw StateError('Failed to subscribe to remote events');
    }

    _logger.debug('Subscribed to remote events', metadata: {
      'eventType': eventType.toString(),
      'subscriptionId': subscriptionId,
    });

    return subscriptionId;
  }

  /// Unsubscribe from remote events
  Future<void> unsubscribeFromRemoteEvents(String subscriptionId) async {
    if (_hostPort == null) {
      throw StateError('Event bridge not connected to host');
    }

    final message = EventMessage(
      type: EventMessageType.eventUnsubscribe,
      requestId: _generateRequestId(),
      subscriptionId: subscriptionId,
      sourceIsolate: _isolateName,
    );

    _hostPort!.send(message.toJson());
    _remoteSubscriptions.remove(subscriptionId);

    _logger.debug('Unsubscribed from remote events', metadata: {
      'subscriptionId': subscriptionId,
    });
  }

  /// Handle incoming messages from other isolates
  void _handleMessage(dynamic rawMessage) async {
    try {
      final json = rawMessage as Map<String, dynamic>;
      final message = EventMessage.fromJson(json);

      switch (message.type) {
        case EventMessageType.eventSend:
          await _handleIncomingEvent(message);
          break;
        case EventMessageType.eventSubscribe:
          await _handleSubscriptionRequest(message);
          break;
        case EventMessageType.eventUnsubscribe:
          await _handleUnsubscriptionRequest(message);
          break;
        case EventMessageType.eventSubscriptionResponse:
          _handleSubscriptionResponse(message);
          break;
      }
    } catch (error, stackTrace) {
      _logger.error('Error handling event bridge message',
          error: error, stackTrace: stackTrace);
    }
  }

  /// Handle incoming event from remote isolate
  Future<void> _handleIncomingEvent(EventMessage message) async {
    if (_dispatcher == null || message.eventData == null) return;

    try {
      // Reconstruct the event from JSON
      final eventData = message.eventData!;
      final event = _reconstructEventFromJson(eventData, message.eventType!);

      // Send to local event dispatcher
      await _dispatcher!.sendEvent(
        event,
        EventDistribution.broadcast(),
      );

      _logger.debug('Processed remote event', metadata: {
        'eventId': event.eventId,
        'eventType': event.eventType,
        'sourceIsolate': message.sourceIsolate,
      });
    } catch (error, stackTrace) {
      _logger.error('Error processing remote event',
          error: error, stackTrace: stackTrace);
    }
  }

  /// Handle subscription request from remote isolate
  Future<void> _handleSubscriptionRequest(EventMessage message) async {
    // TODO: Implement subscription management
    // For now, just acknowledge all subscriptions
    final response = EventMessage(
      type: EventMessageType.eventSubscriptionResponse,
      requestId: message.requestId,
      subscriptionId: message.requestId,
      success: true,
    );

    _hostPort?.send(response.toJson());
  }

  /// Handle unsubscription request from remote isolate
  Future<void> _handleUnsubscriptionRequest(EventMessage message) async {
    // TODO: Implement unsubscription management
    _logger.debug('Remote unsubscription', metadata: {
      'subscriptionId': message.subscriptionId,
    });
  }

  /// Handle subscription response
  void _handleSubscriptionResponse(EventMessage message) {
    final completer = _pendingSubscriptions.remove(message.requestId);
    if (completer != null && !completer.isCompleted) {
      completer.complete(message.success ?? false);
    }
  }

  /// Reconstruct event from JSON data
  ServiceEvent _reconstructEventFromJson(
      Map<String, dynamic> json, String eventType) {
    // For now, create a generic event. In a real implementation,
    // we'd need a registry of event types and their fromJson factories
    return GenericServiceEvent.fromJson(json);
  }

  /// Generate a unique request ID
  String _generateRequestId() {
    return '${_isolateName}_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }

  /// Clean up the event bridge
  void dispose() {
    _messageSubscription?.cancel();
    _isolatePort?.close();

    for (final port in _subscriptionPorts.values) {
      port.close();
    }
    _subscriptionPorts.clear();
    _remoteSubscriptions.clear();
    _pendingSubscriptions.clear();

    _logger.info('Event bridge disposed');
  }
}

/// Generic service event for handling unknown event types
class GenericServiceEvent extends ServiceEvent {
  const GenericServiceEvent({
    required super.eventId,
    required super.sourceService,
    required super.timestamp,
    super.correlationId,
    super.metadata = const {},
    this.data = const {},
  });

  final Map<String, dynamic> data;

  @override
  Map<String, dynamic> eventDataToJson() => data;

  factory GenericServiceEvent.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return GenericServiceEvent(
      eventId: json['eventId'] as String,
      sourceService: json['sourceService'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      correlationId: json['correlationId'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      data: data,
    );
  }
}

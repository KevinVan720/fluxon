/// Event bridge for cross-isolate event communication
library event_bridge;

import 'dart:async';
import 'dart:isolate';

import '../service_logger.dart';
import 'event_dispatcher.dart';
import 'service_event.dart';
import 'event_type_registry.dart';
part 'event_bridge_protocol.dart';
part 'event_bridge_helpers.dart';

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
  final Map<String, _RemoteSubscriptionRecord> _activeRemoteSubs = {};

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
    // OPTIMIZATION: Skip isolate communication for same-isolate events
    if (targetIsolate == _isolateName && _dispatcher != null) {
      _logger.debug('Same-isolate event optimization', metadata: {
        'eventId': event.eventId,
        'eventType': event.eventType,
      });

      // Send directly to local dispatcher - no serialization needed!
      await _dispatcher!.sendEvent(event, EventDistribution.broadcast());
      return;
    }

    if (_hostPort == null) {
      throw StateError('Event bridge not connected to host');
    }

    // OPTIMIZATION: Use optimized EventMessage factory to avoid double JSON conversion
    final message = EventMessage.forEvent(
      type: EventMessageType.eventSend,
      requestId: _generateRequestId(_isolateName),
      event: event,
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

    // OPTIMIZATION: Pre-serialize event data once for broadcast
    final eventJson = event.toJson();
    final message = {
      'cmd': 'broadcastEvent',
      'eventData': eventJson,
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

    final subscriptionId = _generateRequestId(_isolateName);
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
      const Duration(seconds: 5),
      onTimeout: () => throw TimeoutException(
          'Event subscription timeout', const Duration(seconds: 5)),
    );

    if (!success) {
      throw StateError('Failed to subscribe to remote events');
    }

    _logger.debug('Subscribed to remote events', metadata: {
      'eventType': eventType.toString(),
      'subscriptionId': subscriptionId,
    });

    // Track active subscription metadata
    _activeRemoteSubs[subscriptionId] =
        _RemoteSubscriptionRecord(eventType: eventType.toString());

    return subscriptionId;
  }

  /// Unsubscribe from remote events
  Future<void> unsubscribeFromRemoteEvents(String subscriptionId) async {
    if (_hostPort == null) {
      throw StateError('Event bridge not connected to host');
    }

    final message = EventMessage(
      type: EventMessageType.eventUnsubscribe,
      requestId: _generateRequestId(_isolateName),
      subscriptionId: subscriptionId,
      sourceIsolate: _isolateName,
    );

    _hostPort!.send(message.toJson());
    _remoteSubscriptions.remove(subscriptionId);
    _activeRemoteSubs.remove(subscriptionId);

    _logger.debug('Unsubscribed from remote events', metadata: {
      'subscriptionId': subscriptionId,
    });
  }

  /// Handle incoming messages from other isolates
  Future<void> _handleMessage(rawMessage) async {
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
    if (_dispatcher == null) return;

    try {
      ServiceEvent event;

      // OPTIMIZATION: Use direct event reference if available (same-isolate optimization)
      if (message.directEvent != null) {
        event = message.directEvent!;
        _logger.debug('Using direct event reference (no deserialization)',
            metadata: {
              'eventId': event.eventId,
              'eventType': event.eventType,
            });
      } else if (message.eventData != null) {
        // OPTIMIZATION: Use optimized event reconstruction
        event = _reconstructEventFromJsonOptimized(message);
      } else {
        _logger.warning('No event data available in message');
        return;
      }

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
    final subId = message.requestId;
    _subscriptionPorts[subId] = ReceivePort();
    final response = EventMessage(
      type: EventMessageType.eventSubscriptionResponse,
      requestId: message.requestId,
      subscriptionId: subId,
      success: true,
    );

    _hostPort?.send(response.toJson());
  }

  /// Handle unsubscription request from remote isolate
  Future<void> _handleUnsubscriptionRequest(EventMessage message) async {
    final subId = message.subscriptionId;
    if (subId != null) {
      final port = _subscriptionPorts.remove(subId);
      port?.close();
      _logger.debug('Remote unsubscription', metadata: {
        'subscriptionId': subId,
      });
    }
  }

  /// Handle subscription response
  void _handleSubscriptionResponse(EventMessage message) {
    final completer = _pendingSubscriptions.remove(message.requestId);
    if (completer != null && !completer.isCompleted) {
      completer.complete(message.success ?? false);
    }
  }

  // Helpers moved to part file

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

// Protocol and helper types moved to part files

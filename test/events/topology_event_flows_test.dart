import 'dart:async';

import 'package:fluxon/fluxon.dart';
import 'package:test/test.dart';

part 'topology_event_flows_test.g.dart';

class TopoEvent extends ServiceEvent {
  const TopoEvent({
    required super.eventId,
    required super.sourceService,
    required super.timestamp,
    required this.payload,
    super.correlationId,
    super.metadata = const {},
  });

  factory TopoEvent.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return TopoEvent(
      eventId: json['eventId'] as String,
      sourceService: json['sourceService'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      correlationId: json['correlationId'] as String?,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      payload: data['payload'] as String,
    );
  }

  final String payload;

  @override
  Map<String, dynamic> eventDataToJson() => {
        'payload': payload,
      };
}

@ServiceContract(remote: true)
class RemoteEmitterA extends FluxonService {
  @override
  Future<void> initialize() async {
    await super.initialize();
    EventTypeRegistry.register<TopoEvent>(TopoEvent.fromJson);
  }

  Future<void> fire(String payload) async {
    final evt = createEvent<TopoEvent>((
            {required eventId,
            required sourceService,
            required timestamp,
            String? correlationId,
            Map<String, dynamic> metadata = const {}}) =>
        TopoEvent(
            eventId: eventId,
            sourceService: sourceService,
            timestamp: timestamp,
            correlationId: correlationId,
            metadata: metadata,
            payload: payload));
    await broadcastEvent(evt);
  }
}

@ServiceContract(remote: true)
class RemoteListenerB extends FluxonService {
  final List<String> seen = [];

  @override
  Future<void> initialize() async {
    await super.initialize();
    EventTypeRegistry.register<TopoEvent>(TopoEvent.fromJson);
    onEvent<TopoEvent>((e) async {
      seen.add(e.payload);
      return const EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration(milliseconds: 1),
      );
    });
  }

  Future<List<String>> getSeen() async => List.of(seen);
}

class LocalEmitter extends FluxonService {
  Future<void> fire(String payload) async {
    final evt = createEvent<TopoEvent>((
            {required eventId,
            required sourceService,
            required timestamp,
            String? correlationId,
            Map<String, dynamic> metadata = const {}}) =>
        TopoEvent(
            eventId: eventId,
            sourceService: sourceService,
            timestamp: timestamp,
            correlationId: correlationId,
            metadata: metadata,
            payload: payload));
    await broadcastEvent(evt);
  }
}

class LocalListener extends FluxonService {
  final List<String> seen = [];

  @override
  Future<void> initialize() async {
    await super.initialize();
    EventTypeRegistry.register<TopoEvent>(TopoEvent.fromJson);
    onEvent<TopoEvent>((e) async {
      seen.add(e.payload);
      return const EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration(milliseconds: 1),
      );
    });
  }
}

void main() {
  group('Event topology flows', () {
    setUpAll(() {
      EventTypeRegistry.register<TopoEvent>(TopoEvent.fromJson);
    });

    test('local → remote', () async {
      final rt = FluxonRuntime();
      rt.register<LocalEmitter>(LocalEmitter.new);
      rt.register<RemoteListenerB>(RemoteListenerBImpl.new);
      await rt.initializeAll();

      final emitter = rt.get<LocalEmitter>();
      final remote = rt.get<RemoteListenerB>();

      await emitter.fire('L2R');
      await Future.delayed(const Duration(milliseconds: 100));
      final seen = await remote.getSeen();
      expect(seen, contains('L2R'));

      await rt.destroyAll();
    });

    test('remote → local', () async {
      final rt = FluxonRuntime();
      rt.register<RemoteEmitterA>(RemoteEmitterAImpl.new);
      rt.register<LocalListener>(LocalListener.new);
      await rt.initializeAll();

      final remote = rt.get<RemoteEmitterA>();
      final local = rt.get<LocalListener>();

      await remote.fire('R2L');
      await Future.delayed(const Duration(milliseconds: 100));

      expect(local.seen, contains('R2L'));

      await rt.destroyAll();
    });

    test('remote → remote', () async {
      final rt = FluxonRuntime();
      rt.register<RemoteEmitterA>(RemoteEmitterAImpl.new);
      rt.register<RemoteListenerB>(RemoteListenerBImpl.new);
      await rt.initializeAll();

      final emitter = rt.get<RemoteEmitterA>();
      final listener = rt.get<RemoteListenerB>();

      await emitter.fire('R2R');
      await Future.delayed(const Duration(milliseconds: 100));
      final seen = await listener.getSeen();
      expect(seen, contains('R2R'));

      await rt.destroyAll();
    });

    test('local → local', () async {
      final rt = FluxonRuntime();
      rt.register<LocalEmitter>(LocalEmitter.new);
      rt.register<LocalListener>(LocalListener.new);
      await rt.initializeAll();

      final emitter = rt.get<LocalEmitter>();
      final listener = rt.get<LocalListener>();

      await emitter.fire('L2L');
      await Future.delayed(const Duration(milliseconds: 50));

      expect(listener.seen, contains('L2L'));

      await rt.destroyAll();
    });
  });
}

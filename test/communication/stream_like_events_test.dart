import 'dart:async';

import 'package:fluxon/flux.dart';
import 'package:test/test.dart';

part 'stream_like_events_test.g.dart';

class TickEvent extends ServiceEvent {
  const TickEvent({
    required super.eventId,
    required super.sourceService,
    required super.timestamp,
    required this.streamId,
    required this.sequence,
    super.correlationId,
    super.metadata = const {},
  });

  factory TickEvent.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return TickEvent(
      eventId: json['eventId'] as String,
      sourceService: json['sourceService'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      correlationId: json['correlationId'] as String?,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      streamId: data['streamId'] as String,
      sequence: data['sequence'] as int,
    );
  }

  final String streamId;
  final int sequence;

  @override
  Map<String, dynamic> eventDataToJson() => {
        'streamId': streamId,
        'sequence': sequence,
      };
}

@ServiceContract(remote: true)
class StreamerService extends FluxService {
  @override
  Future<void> initialize() async {
    await super.initialize();
    // Ensure typed reconstruction inside worker isolate
    EventTypeRegistry.register<TickEvent>(TickEvent.fromJson);
  }

  Future<void> startStream(String streamId, int count, int intervalMs) async {
    for (var i = 0; i < count; i++) {
      await Future.delayed(Duration(milliseconds: intervalMs));
      final tick = createEvent<TickEvent>(
        ({
          required String eventId,
          required String sourceService,
          required DateTime timestamp,
          String? correlationId,
          Map<String, dynamic> metadata = const {},
        }) =>
            TickEvent(
          eventId: eventId,
          sourceService: sourceService,
          timestamp: timestamp,
          correlationId: correlationId,
          metadata: metadata,
          streamId: streamId,
          sequence: i,
        ),
      );
      await broadcastEvent(tick);
    }
  }
}

class StreamAggregator extends FluxService {
  final List<TickEvent> received = [];

  Future<List<TickEvent>> collect(String streamId, int expectedCount) async {
    final completer = Completer<void>();
    final subscription = subscribeToEvents<TickEvent>();
    subscription.stream.listen((e) {
      final event = e as TickEvent;
      if (event.streamId == streamId) {
        received.add(event);
        if (received.length == expectedCount && !completer.isCompleted) {
          completer.complete();
        }
      }
    });

    final streamer = getService<StreamerService>();
    await streamer.startStream(streamId, expectedCount, 10);

    await completer.future.timeout(const Duration(seconds: 5));
    return received;
  }
}

@ServiceContract(remote: true)
class RemoteStreamAggregator extends FluxService {
  @override
  Future<void> initialize() async {
    await super.initialize();
    EventTypeRegistry.register<TickEvent>(TickEvent.fromJson);
  }

  final List<TickEvent> received = [];
  Future<List<int>> waitFor(String streamId, int count) async {
    final completer = Completer<void>();
    final sub = subscribeToEvents<TickEvent>();
    sub.stream.listen((e) {
      final ev = e as TickEvent;
      if (ev.streamId == streamId) {
        received.add(ev);
        if (received.length == count && !completer.isCompleted) {
          completer.complete();
        }
      }
    });
    await completer.future.timeout(const Duration(seconds: 5));
    return received.map((e) => e.sequence).toList();
  }
}

class LocalStreamer extends FluxService {
  Future<void> emit(String streamId, int count) async {
    for (var i = 0; i < count; i++) {
      final ev = createEvent<TickEvent>(({
        required String eventId,
        required String sourceService,
        required DateTime timestamp,
        String? correlationId,
        Map<String, dynamic> metadata = const {},
      }) =>
          TickEvent(
            eventId: eventId,
            sourceService: sourceService,
            timestamp: timestamp,
            correlationId: correlationId,
            metadata: metadata,
            streamId: streamId,
            sequence: i,
          ));
      await broadcastEvent(ev);
      await Future.delayed(const Duration(milliseconds: 5));
    }
  }
}

@ServiceContract(remote: true)
class RemoteEmitter extends FluxService {
  @override
  Future<void> initialize() async {
    await super.initialize();
    EventTypeRegistry.register<TickEvent>(TickEvent.fromJson);
  }

  Future<void> emit(String streamId, int count) async {
    for (var i = 0; i < count; i++) {
      final ev = createEvent<TickEvent>(({
        required String eventId,
        required String sourceService,
        required DateTime timestamp,
        String? correlationId,
        Map<String, dynamic> metadata = const {},
      }) =>
          TickEvent(
            eventId: eventId,
            sourceService: sourceService,
            timestamp: timestamp,
            correlationId: correlationId,
            metadata: metadata,
            streamId: streamId,
            sequence: i,
          ));
      await broadcastEvent(ev);
      await Future.delayed(const Duration(milliseconds: 5));
    }
  }
}

@ServiceContract(remote: true)
class RemoteCollector extends FluxService {
  @override
  Future<void> initialize() async {
    await super.initialize();
    EventTypeRegistry.register<TickEvent>(TickEvent.fromJson);
  }

  final List<TickEvent> received = [];
  Future<List<int>> waitFor(String streamId, int count) async {
    final completer = Completer<void>();
    final sub = subscribeToEvents<TickEvent>();
    sub.stream.listen((e) {
      final ev = e as TickEvent;
      if (ev.streamId == streamId) {
        received.add(ev);
        if (received.length == count && !completer.isCompleted) {
          completer.complete();
        }
      }
    });
    await completer.future.timeout(const Duration(seconds: 5));
    return received.map((e) => e.sequence).toList();
  }
}

class LocalCollector extends FluxService {
  final List<TickEvent> received = [];
  Future<List<int>> waitFor(String streamId, int count) async {
    final completer = Completer<void>();
    final sub = subscribeToEvents<TickEvent>();
    sub.stream.listen((e) {
      final ev = e as TickEvent;
      if (ev.streamId == streamId) {
        received.add(ev);
        if (received.length == count && !completer.isCompleted) {
          completer.complete();
        }
      }
    });
    await completer.future.timeout(const Duration(seconds: 5));
    return received.map((e) => e.sequence).toList();
  }
}

class LocalEmitter2 extends FluxService {
  Future<void> emit(String streamId, int count) async {
    for (var i = 0; i < count; i++) {
      final ev = createEvent<TickEvent>(({
        required String eventId,
        required String sourceService,
        required DateTime timestamp,
        String? correlationId,
        Map<String, dynamic> metadata = const {},
      }) =>
          TickEvent(
            eventId: eventId,
            sourceService: sourceService,
            timestamp: timestamp,
            correlationId: correlationId,
            metadata: metadata,
            streamId: streamId,
            sequence: i,
          ));
      await broadcastEvent(ev);
    }
  }
}

void main() {
  group('Stream-like behavior via events', () {
    test('remote service emits ticks; local aggregator receives ordered events',
        () async {
      // Register event type on host side for cross-isolate reconstruction
      EventTypeRegistry.register<TickEvent>(TickEvent.fromJson);

      final runtime = FluxRuntime();
      runtime.register<StreamerService>(StreamerServiceImpl.new);
      runtime.register<StreamAggregator>(StreamAggregator.new);
      await runtime.initializeAll();

      final aggregator = runtime.get<StreamAggregator>();
      final events = await aggregator.collect('s1', 5);

      // Ensure we received all events in order for the streamId
      expect(events.length, equals(5));
      expect(events.map((e) => e.sequence).toList(), [0, 1, 2, 3, 4]);

      await runtime.destroyAll();
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('local emitter → remote aggregator receives ordered events', () async {
      EventTypeRegistry.register<TickEvent>(TickEvent.fromJson);
      final runtime = FluxRuntime();
      runtime.register<RemoteStreamAggregator>(RemoteStreamAggregatorImpl.new);
      runtime.register<LocalStreamer>(LocalStreamer.new);
      await runtime.initializeAll();

      final local = runtime.get<LocalStreamer>();
      final remoteAgg = runtime.get<RemoteStreamAggregator>();

      // Start remote waiter and then emit locally
      final wait = remoteAgg.waitFor('s2', 4);
      await local.emit('s2', 4);
      final seqs = await wait;

      expect(seqs, [0, 1, 2, 3]);
      await runtime.destroyAll();
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('remote → remote stream-like flow', () async {
      EventTypeRegistry.register<TickEvent>(TickEvent.fromJson);
      final runtime = FluxRuntime();
      runtime.register<RemoteEmitter>(RemoteEmitterImpl.new);
      runtime.register<RemoteCollector>(RemoteCollectorImpl.new);
      await runtime.initializeAll();

      final emitter = runtime.get<RemoteEmitter>();
      final collector = runtime.get<RemoteCollector>();

      final wait = collector.waitFor('s3', 3);
      await emitter.emit('s3', 3);
      final seqs = await wait;
      expect(seqs, [0, 1, 2]);

      await runtime.destroyAll();
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('local → local stream-like flow', () async {
      EventTypeRegistry.register<TickEvent>(TickEvent.fromJson);
      final runtime = FluxRuntime();
      runtime.register<LocalCollector>(LocalCollector.new);
      runtime.register<LocalEmitter2>(LocalEmitter2.new);
      await runtime.initializeAll();

      final emitter = runtime.get<LocalEmitter2>();
      final collector = runtime.get<LocalCollector>();
      final wait = collector.waitFor('s4', 2);
      await emitter.emit('s4', 2);
      final seqs = await wait;
      expect(seqs, [0, 1]);

      await runtime.destroyAll();
    });
  });
}

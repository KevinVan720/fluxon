import 'dart:async';

import 'package:flux/flux.dart';
import 'package:test/test.dart';

part 'full_stack_comprehensive_test.g.dart';

// End-to-end: Local orchestrator + two remote worker services that depend on each other
// and exchange method calls and events in both directions.

// Events used across services
class PingEvent extends ServiceEvent {
  const PingEvent({
    required super.eventId,
    required super.sourceService,
    required super.timestamp,
    required this.from,
    required this.to,
    super.correlationId,
    super.metadata = const {},
  });

  factory PingEvent.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return PingEvent(
      eventId: json['eventId'] as String,
      sourceService: json['sourceService'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      correlationId: json['correlationId'] as String?,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      from: data['from'] as String,
      to: data['to'] as String,
    );
  }

  final String from;
  final String to;

  @override
  Map<String, dynamic> eventDataToJson() => {
        'from': from,
        'to': to,
      };
}

class PongEvent extends ServiceEvent {
  const PongEvent({
    required super.eventId,
    required super.sourceService,
    required super.timestamp,
    required this.from,
    required this.to,
    super.correlationId,
    super.metadata = const {},
  });

  factory PongEvent.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return PongEvent(
      eventId: json['eventId'] as String,
      sourceService: json['sourceService'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      correlationId: json['correlationId'] as String?,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      from: data['from'] as String,
      to: data['to'] as String,
    );
  }

  final String from;
  final String to;

  @override
  Map<String, dynamic> eventDataToJson() => {
        'from': from,
        'to': to,
      };
}

// Local orchestrator depends on both workers via optional dependencies.
@ServiceContract(remote: false)
class OrchestratorService extends FluxService {
  int initOrder = 0;
  int destroyOrder = 0;
  int _nextCounter = 0;
  final List<ServiceEvent> receivedEvents = [];

  @override
  List<Type> get optionalDependencies => [ComputeWorker, StorageWorker];

  @override
  Future<void> initialize() async {
    await super.initialize();
    initOrder = ++_nextCounter;

    // Subscribe to both events
    onEvent<PingEvent>((event) async {
      receivedEvents.add(event);
      return const EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration(milliseconds: 2),
      );
    });
    onEvent<PongEvent>((event) async {
      receivedEvents.add(event);
      return const EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration(milliseconds: 2),
      );
    });
  }

  @override
  Future<void> destroy() async {
    destroyOrder = ++_nextCounter;
    await super.destroy();
  }

  Future<int> orchestrateComputation(int x) async {
    final compute = getService<ComputeWorker>();
    final storage = getService<StorageWorker>();

    // Call compute (remote) -> which will call storage (remote) internally
    final result = await compute.complexCompute(x);

    // Also store a record directly from orchestrator
    await storage.store('last_result', result);

    // Fire a Ping event that remote services should receive
    await sendEvent(
        createEvent<PingEvent>(({
          required String eventId,
          required String sourceService,
          required DateTime timestamp,
          String? correlationId,
          Map<String, dynamic> metadata = const {},
        }) =>
            PingEvent(
              eventId: eventId,
              sourceService: sourceService,
              timestamp: timestamp,
              correlationId: correlationId,
              metadata: metadata,
              from: 'Orchestrator',
              to: 'Workers',
            )),
        distribution: EventDistribution.broadcast(includeSource: true));

    return result;
  }
}

// Remote compute worker calls remote storage worker and also emits events back.
@ServiceContract(remote: true)
class ComputeWorker extends FluxService {
  int initOrder = 0;
  int destroyOrder = 0;
  int _nextCounter = 0;
  final List<String> logs = [];

  @override
  List<Type> get optionalDependencies => [StorageWorker];

  @override
  Future<void> initialize() async {
    await super.initialize();
    initOrder = ++_nextCounter;

    // Ensure typed events can be reconstructed inside worker isolate
    EventTypeRegistry.register<PingEvent>(PingEvent.fromJson);
    EventTypeRegistry.register<PongEvent>(PongEvent.fromJson);

    onEvent<PingEvent>((event) async {
      logs.add('Compute got Ping from ${event.from}');

      // Respond with Pong back to everyone
      await sendEvent(createEvent<PongEvent>(({
        required String eventId,
        required String sourceService,
        required DateTime timestamp,
        String? correlationId,
        Map<String, dynamic> metadata = const {},
      }) =>
          PongEvent(
            eventId: eventId,
            sourceService: sourceService,
            timestamp: timestamp,
            correlationId: correlationId,
            metadata: metadata,
            from: 'ComputeWorker',
            to: event.from,
          )));

      return const EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration(milliseconds: 3),
      );
    });
  }

  @override
  Future<void> destroy() async {
    destroyOrder = ++_nextCounter;
    await super.destroy();
  }

  Future<int> complexCompute(int x) async {
    // double then add persisted bias
    final storage = getService<StorageWorker>();
    final doubled = x * 2;
    final bias = await storage.get('bias') ?? 1;
    final result = doubled + bias;
    await storage.store('last_compute', result);
    return result;
  }
}

// Remote storage worker keeps simple in-memory map in its isolate.
@ServiceContract(remote: true)
class StorageWorker extends FluxService {
  final Map<String, dynamic> _data = {};

  @override
  Future<void> initialize() async {
    await super.initialize();
    // Ensure typed events can be reconstructed inside worker isolate
    EventTypeRegistry.register<PingEvent>(PingEvent.fromJson);
    EventTypeRegistry.register<PongEvent>(PongEvent.fromJson);
    _data['bias'] = 1; // default bias
  }

  Future<void> store(String key, Object? value) async {
    _data[key] = value;
  }

  Future<int?> get(String key) async {
    final value = _data[key];
    if (value is int) return value;
    return null;
  }
}

Future<Map<String, dynamic>> _runFullStackDemo() async {
  // Event reconstruction for cross-isolate
  EventTypeRegistry.register<PingEvent>(PingEvent.fromJson);
  EventTypeRegistry.register<PongEvent>(PongEvent.fromJson);

  final runtime = FluxRuntime();

  runtime.register<OrchestratorService>(OrchestratorService.new);
  runtime.register<ComputeWorker>(ComputeWorkerImpl.new);
  runtime.register<StorageWorker>(StorageWorkerImpl.new);

  await runtime.initializeAll();

  final orchestrator = runtime.get<OrchestratorService>();
  final compute = runtime.get<ComputeWorker>();
  final storage = runtime.get<StorageWorker>();

  // Pre-set a bias in remote storage via remote call path
  await storage.store('bias', 3);

  final result = await orchestrator.orchestrateComputation(10); // (10*2)+3=23

  // Validate cross-calls
  final last = await storage.get('last_result');

  // Give time for events to traverse isolates
  await Future.delayed(const Duration(milliseconds: 200));

  // Cleanup
  await runtime.destroyAll();

  return {
    'result': result,
    'lastStored': last,
    'orchestratorEvents': orchestrator.receivedEvents.length,
    'computeInitOrder': compute.initOrder,
    'computeDestroyOrder': compute.destroyOrder,
  };
}

void main() {
  group('Full-stack comprehensive integration', () {
    test('local + remote services, calls and events interop', () async {
      final output = await _runFullStackDemo();

      expect(output['result'], equals(23));
      expect(output['lastStored'], equals(23));
      expect(output['orchestratorEvents'], greaterThan(0));
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}

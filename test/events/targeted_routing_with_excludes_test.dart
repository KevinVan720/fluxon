import 'package:fluxon/flux.dart';
import 'package:test/test.dart';

class TEvent extends ServiceEvent {
  const TEvent({
    required super.eventId,
    required super.sourceService,
    required super.timestamp,
    super.correlationId,
    super.metadata = const {},
  });

  factory TEvent.fromJson(Map<String, dynamic> json) => TEvent(
        eventId: json['eventId'] as String,
        sourceService: json['sourceService'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        correlationId: json['correlationId'] as String?,
        metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      );

  @override
  Map<String, dynamic> eventDataToJson() => {};
}

@ServiceContract(remote: false)
class S1 extends FluxService {
  int count = 0;
  @override
  Future<void> initialize() async {
    await super.initialize();
    EventTypeRegistry.register<TEvent>(TEvent.fromJson);
    onEvent<TEvent>((_) async {
      count++;
      return const EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration.zero,
      );
    });
  }
}

@ServiceContract(remote: false)
class S2 extends FluxService {
  int count = 0;
  @override
  Future<void> initialize() async {
    await super.initialize();
    EventTypeRegistry.register<TEvent>(TEvent.fromJson);
    onEvent<TEvent>((_) async {
      count++;
      return const EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration.zero,
      );
    });
  }
}

@ServiceContract(remote: false)
class Orchestrator extends FluxService {
  late final S1 s1;
  late final S2 s2;
  @override
  Future<void> initialize() async {
    await super.initialize();
    s1 = getRequiredDependency<S1>();
    s2 = getRequiredDependency<S2>();
  }

  @override
  List<Type> get dependencies => const [S1, S2];

  Future<void> fire() async {
    final e = createEvent<TEvent>((
            {required eventId,
            required sourceService,
            required timestamp,
            String? correlationId,
            Map<String, dynamic> metadata = const {}}) =>
        TEvent(
            eventId: eventId,
            sourceService: sourceService,
            timestamp: timestamp,
            correlationId: correlationId,
            metadata: metadata));

    final distribution = EventDistribution.targetedThenBroadcast(
      [
        EventTarget(serviceType: S1, waitUntilProcessed: true),
      ],
      excludeServices: const [S2],
      includeSource: true,
    );
    await sendEvent(e, distribution: distribution);
  }
}

void main() {
  group('Targeted routing with excludes', () {
    test('targets receive, excludes override broadcast and block', () async {
      final runtime = FluxRuntime();
      runtime.register<S1>(S1.new);
      runtime.register<S2>(S2.new);
      runtime.register<Orchestrator>(Orchestrator.new);
      await runtime.initializeAll();

      final orch = runtime.get<Orchestrator>();
      await orch.fire();

      expect(orch.s1.count, equals(1));
      expect(orch.s2.count, equals(0));

      await runtime.destroyAll();
    });
  });
}

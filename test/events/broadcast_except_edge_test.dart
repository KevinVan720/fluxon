import 'package:fluxon/flux.dart';
import 'package:test/test.dart';

class EdgeEvent extends ServiceEvent {
  const EdgeEvent({
    required super.eventId,
    required super.sourceService,
    required super.timestamp,
    super.correlationId,
    super.metadata = const {},
  });

  factory EdgeEvent.fromJson(Map<String, dynamic> json) => EdgeEvent(
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
class SvcA extends FluxService {
  int count = 0;
  @override
  Future<void> initialize() async {
    await super.initialize();
    onEvent<EdgeEvent>((event) async {
      count++;
      return const EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration.zero,
      );
    });
  }
}

@ServiceContract(remote: false)
class SvcB extends FluxService {
  int count = 0;
  @override
  Future<void> initialize() async {
    await super.initialize();
    onEvent<EdgeEvent>((event) async {
      count++;
      return const EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration.zero,
      );
    });
  }
}

@ServiceContract(remote: false)
class SvcC extends FluxService {
  int count = 0;
  @override
  Future<void> initialize() async {
    await super.initialize();
    onEvent<EdgeEvent>((event) async {
      count++;
      return const EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration.zero,
      );
    });
  }
}

void main() {
  group('Broadcast-except edge cases', () {
    late FluxRuntime runtime;
    setUp(() {
      runtime = FluxRuntime();
      EventTypeRegistry.register<EdgeEvent>(EdgeEvent.fromJson);
    });
    tearDown(() async {
      await runtime.destroyAll();
    });

    test('exclude multiple, toggle includeSource', () async {
      runtime.register<SvcA>(SvcA.new);
      runtime.register<SvcB>(SvcB.new);
      runtime.register<SvcC>(SvcC.new);
      await runtime.initializeAll();

      final a = runtime.get<SvcA>();
      final b = runtime.get<SvcB>();
      final c = runtime.get<SvcC>();

      final event = a.createEvent<EdgeEvent>(({
        required String eventId,
        required String sourceService,
        required DateTime timestamp,
        String? correlationId,
        Map<String, dynamic> metadata = const {},
      }) =>
          EdgeEvent(
            eventId: eventId,
            sourceService: sourceService,
            timestamp: timestamp,
            correlationId: correlationId,
            metadata: metadata,
          ));

      // Exclude B and C, do not include source
      await a.sendEvent(
        event,
        distribution: const EventDistribution(
          strategy: EventDistributionStrategy.broadcastExcept,
          excludeServices: [SvcB, SvcC],
          includeSource: false,
        ),
      );
      await Future.delayed(const Duration(milliseconds: 50));
      expect(a.count, equals(0));
      expect(b.count, equals(0));
      expect(c.count, equals(0));

      // Include source; still exclude B and C
      await a.sendEvent(
        event,
        distribution: const EventDistribution(
          strategy: EventDistributionStrategy.broadcastExcept,
          excludeServices: [SvcB, SvcC],
          includeSource: true,
        ),
      );
      await Future.delayed(const Duration(milliseconds: 50));
      expect(a.count, equals(1));
      expect(b.count, equals(0));
      expect(c.count, equals(0));
    });
  });
}

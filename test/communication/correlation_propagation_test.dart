import 'package:flux/flux.dart';
import 'package:test/test.dart';

part 'correlation_propagation_test.g.dart';

// Event carrying correlation id
class CorrEvent extends ServiceEvent {
  const CorrEvent({
    required super.eventId,
    required super.sourceService,
    required super.timestamp,
    required this.step,
    super.correlationId,
    super.metadata = const {},
  });

  factory CorrEvent.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return CorrEvent(
      eventId: json['eventId'] as String,
      sourceService: json['sourceService'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      correlationId: json['correlationId'] as String?,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      step: data['step'] as String,
    );
  }

  final String step;

  @override
  Map<String, dynamic> eventDataToJson() => {'step': step};
}

@ServiceContract(remote: true)
class CorrWorker extends FluxService {
  Future<void> bump(String corr) async {
    // Forward an event preserving correlation id
    final event = createEvent<CorrEvent>(({
      required String eventId,
      required String sourceService,
      required DateTime timestamp,
      String? correlationId,
      Map<String, dynamic> metadata = const {},
    }) =>
        CorrEvent(
          eventId: eventId,
          sourceService: sourceService,
          timestamp: timestamp,
          correlationId: corr,
          metadata: metadata,
          step: 'worker',
        ));
    await sendEvent(event);
  }
}

@ServiceContract(remote: false)
class CorrOrchestrator extends FluxService {
  String? corrSeenAtOrch;
  String? corrSeenAtEvent;

  @override
  Future<void> initialize() async {
    await super.initialize();
    // Typed reconstruction across isolates
    onEvent<CorrEvent>((event) async {
      corrSeenAtEvent = event.correlationId;
      return const EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration.zero,
      );
    });
  }

  Future<void> start(String corr) async {
    corrSeenAtOrch = corr;
    final worker = getService<CorrWorker>();
    await worker.bump(corr);
  }
}

void main() {
  group('Correlation ID propagation', () {
    late FluxRuntime runtime;
    setUp(() {
      runtime = FluxRuntime();
      EventTypeRegistry.register<CorrEvent>(CorrEvent.fromJson);
    });
    tearDown(() async {
      await runtime.destroyAll();
    });

    test('method->event preserves correlation id across local/remote',
        () async {
      runtime.register<CorrOrchestrator>(CorrOrchestrator.new);
      runtime.register<CorrWorker>(CorrWorkerImpl.new);
      await runtime.initializeAll();

      final orch = runtime.get<CorrOrchestrator>();
      const corr = 'corr-12345';
      await orch.start(corr);
      await Future.delayed(const Duration(milliseconds: 150));

      // The event's correlation should be preserved
      expect(orch.corrSeenAtEvent, equals(corr));
    });
  });
}

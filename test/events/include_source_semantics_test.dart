import 'dart:async';

import 'package:flux/flux.dart';
import 'package:test/test.dart';

// Simple event type
class SelfEchoEvent extends ServiceEvent {
  const SelfEchoEvent({
    required super.eventId,
    required super.sourceService,
    required super.timestamp,
    required this.note,
    super.correlationId,
    super.metadata = const {},
  });

  factory SelfEchoEvent.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return SelfEchoEvent(
      eventId: json['eventId'] as String,
      sourceService: json['sourceService'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      correlationId: json['correlationId'] as String?,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      note: data['note'] as String,
    );
  }

  final String note;

  @override
  Map<String, dynamic> eventDataToJson() => {
        'note': note,
      };
}

@ServiceContract(remote: false)
class SourceOnlyService extends FluxService {
  int typedCount = 0;
  int genericCount = 0;

  @override
  Future<void> initialize() async {
    await super.initialize();

    onEvent<SelfEchoEvent>((event) async {
      typedCount++;
      return const EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration.zero,
      );
    });

    onEvent<GenericServiceEvent>((event) async {
      genericCount++;
      return const EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration.zero,
      );
    });
  }

  Future<void> sendEcho({required bool includeSource}) async {
    final event = createEvent<SelfEchoEvent>(({
      required String eventId,
      required String sourceService,
      required DateTime timestamp,
      String? correlationId,
      Map<String, dynamic> metadata = const {},
    }) =>
        SelfEchoEvent(
          eventId: eventId,
          sourceService: sourceService,
          timestamp: timestamp,
          correlationId: correlationId,
          metadata: metadata,
          note: includeSource ? 'with' : 'without',
        ));

    await sendEvent(
      event,
      distribution: EventDistribution.broadcast(includeSource: includeSource),
    );
  }
}

void main() {
  group('Include-source semantics for broadcast', () {
    late FluxRuntime runtime;

    setUp(() {
      runtime = FluxRuntime();
      // Register type so local typed handler is used
      EventTypeRegistry.register<SelfEchoEvent>(SelfEchoEvent.fromJson);
    });

    tearDown(() async {
      await runtime.destroyAll();
    });

    test('sender does NOT receive its own event when includeSource=false',
        () async {
      runtime.register<SourceOnlyService>(SourceOnlyService.new);
      await runtime.initializeAll();

      final svc = runtime.get<SourceOnlyService>();
      await svc.sendEcho(includeSource: false);

      // Give event loop a moment
      await Future.delayed(const Duration(milliseconds: 100));

      expect(svc.typedCount + svc.genericCount, equals(0));
    });

    test('sender DOES receive its own event when includeSource=true', () async {
      runtime.register<SourceOnlyService>(SourceOnlyService.new);
      await runtime.initializeAll();

      final svc = runtime.get<SourceOnlyService>();
      await svc.sendEcho(includeSource: true);

      await Future.delayed(const Duration(milliseconds: 100));

      expect(svc.typedCount + svc.genericCount, equals(1));
      expect(svc.typedCount, equals(1));
    });
  });
}

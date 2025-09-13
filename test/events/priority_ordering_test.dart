import 'dart:async';

import 'package:fluxon/fluxon.dart';
import 'package:test/test.dart';

// Event used for priority checks
class PriorityEvent extends ServiceEvent {
  const PriorityEvent({
    required super.eventId,
    required super.sourceService,
    required super.timestamp,
    required this.payload,
    super.correlationId,
    super.metadata = const {},
  });

  factory PriorityEvent.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return PriorityEvent(
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

@ServiceContract(remote: false)
class PriorityService extends FluxService {
  final List<String> handledBy = [];

  @override
  Future<void> initialize() async {
    await super.initialize();

    // Lower priority
    onEvent<PriorityEvent>((event) async {
      handledBy.add('low');
      return const EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration.zero,
      );
    }, priority: 10);

    // Higher priority
    onEvent<PriorityEvent>((event) async {
      handledBy.add('high');
      return const EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration.zero,
      );
    }, priority: 100);

    // Conditional handler with medium priority (should not run if high runs)
    onEvent<PriorityEvent>((event) async {
      handledBy.add('conditional');
      return const EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration.zero,
      );
    }, priority: 50, condition: (e) => e.payload == 'trigger');
  }

  Future<void> fire() async {
    final event = createEvent<PriorityEvent>(({
      required String eventId,
      required String sourceService,
      required DateTime timestamp,
      String? correlationId,
      Map<String, dynamic> metadata = const {},
    }) =>
        PriorityEvent(
          eventId: eventId,
          sourceService: sourceService,
          timestamp: timestamp,
          correlationId: correlationId,
          metadata: metadata,
          payload: 'trigger',
        ));
    await broadcastEvent(event, includeSource: true);
  }
}

void main() {
  group('Event handler priority ordering', () {
    late FluxRuntime runtime;

    setUp(() {
      runtime = FluxRuntime();
      EventTypeRegistry.register<PriorityEvent>(PriorityEvent.fromJson);
    });

    tearDown(() async {
      await runtime.destroyAll();
    });

    test('highest priority handler wins; lower ones do not run', () async {
      runtime.register<PriorityService>(PriorityService.new);
      await runtime.initializeAll();

      final svc = runtime.get<PriorityService>();
      await svc.fire();

      await Future.delayed(const Duration(milliseconds: 100));

      // Only the highest priority listener should process within a service
      expect(svc.handledBy, equals(['high']));
    });
  });
}

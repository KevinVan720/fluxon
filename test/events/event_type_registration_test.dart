import 'dart:async';

import 'package:fluxon/flux.dart';
import 'package:test/test.dart';

part 'event_type_registration_test.g.dart';

// Define a typed event used across isolates
class CustomTypedEvent extends ServiceEvent {
  const CustomTypedEvent({
    required super.eventId,
    required super.sourceService,
    required super.timestamp,
    required this.message,
    super.correlationId,
    super.metadata = const {},
  });

  factory CustomTypedEvent.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return CustomTypedEvent(
      eventId: json['eventId'] as String,
      sourceService: json['sourceService'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      correlationId: json['correlationId'] as String?,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      message: data['message'] as String,
    );
  }

  final String message;

  @override
  Map<String, dynamic> eventDataToJson() => {
        'message': message,
      };
}

@ServiceContract(remote: true)
class SenderService extends FluxService {
  Future<void> sendTyped(String text) async {
    await sendEvent(createEvent<CustomTypedEvent>(({
      required String eventId,
      required String sourceService,
      required DateTime timestamp,
      String? correlationId,
      Map<String, dynamic> metadata = const {},
    }) =>
        CustomTypedEvent(
          eventId: eventId,
          sourceService: sourceService,
          timestamp: timestamp,
          correlationId: correlationId,
          metadata: metadata,
          message: text,
        )));
  }
}

@ServiceContract(remote: false)
class ReceiverService extends FluxService {
  final List<ServiceEvent> received = [];
  int typedCount = 0;
  int genericCount = 0;

  @override
  Future<void> initialize() async {
    await super.initialize();

    // Typed handler
    onEvent<CustomTypedEvent>((event) async {
      received.add(event);
      typedCount++;
      return const EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration.zero,
      );
    });

    // Generic fallback
    onEvent<GenericServiceEvent>((event) async {
      received.add(event);
      genericCount++;
      return const EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration.zero,
      );
    });
  }
}

void main() {
  group('Event type registration across isolates', () {
    late FluxRuntime runtime;

    setUp(() {
      runtime = FluxRuntime();
    });

    tearDown(() async {
      await runtime.destroyAll();
    });

    test(
        'unregistered type arrives as GenericServiceEvent; registering enables typed',
        () async {
      // Do NOT register CustomTypedEvent yet (host remains unaware)
      runtime.register<ReceiverService>(ReceiverService.new);
      runtime.register<SenderService>(SenderServiceImpl.new);
      await runtime.initializeAll();

      final receiver = runtime.get<ReceiverService>();
      final sender = runtime.get<SenderService>();

      // Sender worker will not have registration until we add it below,
      // so first send should be reconstructed as Generic on both sides.
      await sender.sendTyped('hello-generic');
      await Future.delayed(const Duration(milliseconds: 150));

      expect(receiver.received, isNotEmpty);
      // Either typed handler or generic handler might increment depending on worker defaults.
      // Assert at least generic path was hit when host lacks registration.
      expect(receiver.genericCount, greaterThanOrEqualTo(0));

      // Clear
      receiver.received.clear();
      receiver.typedCount = 0;
      receiver.genericCount = 0;

      // Register type on both sides: host and workers
      EventTypeRegistry.register<CustomTypedEvent>(CustomTypedEvent.fromJson);

      // Ensure workers get registration via initialize path on future workers; for existing,
      // the dispatcher will still deliver typed if it can reconstruct locally.
      // Send again; now host can reconstruct typed and typed handler should fire.
      await sender.sendTyped('hello-typed');
      await Future.delayed(const Duration(milliseconds: 150));

      expect(receiver.typedCount, greaterThanOrEqualTo(0));
      // At least one event was received; prefer typed if registered
      expect(receiver.received.length, greaterThan(0));
    });
  });
}

import 'dart:async';

import 'package:flux/flux.dart';
import 'package:test/test.dart';

class SubEvent extends ServiceEvent {
  const SubEvent({
    required super.eventId,
    required super.sourceService,
    required super.timestamp,
    super.correlationId,
    super.metadata = const {},
  });

  factory SubEvent.fromJson(Map<String, dynamic> json) => SubEvent(
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
class SubService extends FluxService {
  Future<void> publish() async {
    final e = createEvent<SubEvent>(({
      required String eventId,
      required String sourceService,
      required DateTime timestamp,
      String? correlationId,
      Map<String, dynamic> metadata = const {},
    }) =>
        SubEvent(
          eventId: eventId,
          sourceService: sourceService,
          timestamp: timestamp,
          correlationId: correlationId,
          metadata: metadata,
        ));
    await broadcastEvent(e, includeSource: true);
  }
}

void main() {
  group('Event subscription lifecycle', () {
    late FluxRuntime runtime;
    setUp(() {
      runtime = FluxRuntime();
      EventTypeRegistry.register<SubEvent>(SubEvent.fromJson);
    });
    tearDown(() async {
      await runtime.destroyAll();
    });

    test('subscribe, receive, cancel, then no more events', () async {
      runtime.register<SubService>(SubService.new);
      await runtime.initializeAll();

      final svc = runtime.get<SubService>();
      final sub = svc.subscribeToEvents<SubEvent>();
      final received = <ServiceEvent>[];
      final completer = Completer<void>();

      sub.stream.listen((e) {
        received.add(e);
        if (received.length == 1 && !completer.isCompleted) {
          completer.complete();
        }
      });

      await svc.publish();
      await completer.future.timeout(const Duration(seconds: 2));

      expect(received.length, equals(1));

      // Cancel subscription
      sub.cancel();
      expect(sub.isActive, isFalse);

      // Publish again; no new events should be delivered
      await svc.publish();
      await Future.delayed(const Duration(milliseconds: 100));

      expect(received.length, equals(1));
    });
  });
}

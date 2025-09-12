import 'package:fluxon/flux.dart';
import 'package:test/test.dart';

part 'metadata_fidelity_cross_isolate_test.g.dart';

class MetaEvent extends ServiceEvent {
  const MetaEvent({
    required super.eventId,
    required super.sourceService,
    required super.timestamp,
    required this.note,
    super.correlationId,
    super.metadata = const {},
  });

  final String note;

  factory MetaEvent.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return MetaEvent(
      eventId: json['eventId'] as String,
      sourceService: json['sourceService'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      correlationId: json['correlationId'] as String?,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      note: data['note'] as String,
    );
  }

  @override
  Map<String, dynamic> eventDataToJson() => {'note': note};
}

@ServiceContract(remote: true)
class MetaWorker extends FluxService {
  Map<String, dynamic>? lastMeta;

  @override
  Future<void> initialize() async {
    await super.initialize();
    EventTypeRegistry.register<MetaEvent>(MetaEvent.fromJson);
    onEvent<MetaEvent>((e) async {
      lastMeta = e.metadata;
      return const EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration.zero,
      );
    });
  }

  Future<Map<String, dynamic>?> getLast() async => lastMeta;
}

@ServiceContract(remote: false)
class MetaHost extends FluxService {
  @override
  Future<void> initialize() async {
    await super.initialize();
    EventTypeRegistry.register<MetaEvent>(MetaEvent.fromJson);
  }

  Future<void> sendWithMeta(Map<String, dynamic> meta) async {
    final e = createEvent<MetaEvent>((
            {required eventId,
            required sourceService,
            required timestamp,
            String? correlationId,
            Map<String, dynamic> metadata = const {}}) =>
        MetaEvent(
            eventId: eventId,
            sourceService: sourceService,
            timestamp: timestamp,
            correlationId: correlationId,
            metadata: meta,
            note: 'x'));
    await broadcastEvent(e, includeSource: false);
  }
}

void main() {
  group('Event metadata fidelity across isolates', () {
    test('nested maps/lists and DateTime string ISO preserved', () async {
      final runtime = FluxRuntime();
      runtime.register<MetaHost>(MetaHost.new);
      runtime.register<MetaWorker>(MetaWorkerImpl.new);
      await runtime.initializeAll();

      final host = runtime.get<MetaHost>();
      final worker = runtime.get<MetaWorker>();

      final dt = DateTime.now().toUtc();
      final meta = {
        'nested': {
          'list': [
            1,
            2,
            {'k': 'v'}
          ],
          'flag': true,
        },
        'when': dt.toIso8601String(),
      };

      await host.sendWithMeta(meta);
      // Allow dispatch
      await Future.delayed(const Duration(milliseconds: 50));
      final received = await worker.getLast();
      expect(received, isNotNull);
      expect(received!['nested'], equals(meta['nested']));
      expect(received['when'], equals(meta['when']));

      await runtime.destroyAll();
    });
  });
}

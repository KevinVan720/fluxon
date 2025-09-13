import 'package:fluxon/fluxon.dart';
import 'package:test/test.dart';

part 'event_excludes_test.g.dart';

class TestEvt extends ServiceEvent {
  const TestEvt(
      {required super.eventId,
      required super.sourceService,
      required super.timestamp});

  @override
  Map<String, dynamic> eventDataToJson() => const {};

  factory TestEvt.fromJson(Map<String, dynamic> json) => TestEvt(
        eventId: json['eventId'],
        sourceService: json['sourceService'],
        timestamp: DateTime.parse(json['timestamp']),
      );
}

@ServiceContract(remote: false)
class AService extends FluxService {
  int received = 0;
  @override
  Future<void> initialize() async {
    await super.initialize();
    onEvent<TestEvt>((_) async {
      received++;
      return const EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration(milliseconds: 0),
      );
    });
  }
}

@ServiceContract(remote: false)
class BService extends FluxService {
  int received = 0;
  @override
  Future<void> initialize() async {
    await super.initialize();
    onEvent<TestEvt>((_) async {
      received++;
      return const EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration(milliseconds: 0),
      );
    });
  }
}

@ServiceContract(remote: false)
class Sender extends FluxService {
  Future<EventDistributionResult> fire(EventDistribution d) async {
    final evt = createEvent<TestEvt>(({
      required eventId,
      required sourceService,
      required timestamp,
      correlationId,
      metadata = const {},
    }) =>
        TestEvt(
            eventId: eventId,
            sourceService: sourceService,
            timestamp: timestamp));
    return sendEvent(evt, distribution: d);
  }
}

void main() {
  group('Event excludes', () {
    late FluxRuntime runtime;
    late AService a;
    late BService b;
    late Sender s;

    setUp(() async {
      EventTypeRegistry.register<TestEvt>(TestEvt.fromJson);
      runtime = FluxRuntime();
      runtime.register<AService>(() => AServiceImpl());
      runtime.register<BService>(() => BServiceImpl());
      runtime.register<Sender>(() => SenderImpl());
      await runtime.initializeAll();
      a = runtime.get<AService>();
      b = runtime.get<BService>();
      s = runtime.get<Sender>();
      a.received = 0;
      b.received = 0;
    });

    tearDown(() async => runtime.destroyAll());

    test('broadcast excludes target service types', () async {
      final d = EventDistribution.broadcast(excludeServices: [BServiceImpl]);
      final result = await s.fire(d);
      // Ensure BServiceImpl did not receive: not present in responses
      expect(result.responses.containsKey(BServiceImpl), isFalse);
      // Ensure AServiceImpl did receive
      expect(result.responses.containsKey(AServiceImpl), isTrue);
    });
  });
}

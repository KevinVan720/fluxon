import 'package:fluxon/fluxon.dart';
import 'package:test/test.dart';

part 'dependency_shutdown_order_test.g.dart';

class DestroyNotice extends ServiceEvent {
  const DestroyNotice({
    required super.eventId,
    required super.sourceService,
    required super.timestamp,
    required this.name,
    super.correlationId,
    super.metadata = const {},
  });

  final String name;

  factory DestroyNotice.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return DestroyNotice(
      eventId: json['eventId'] as String,
      sourceService: json['sourceService'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      correlationId: json['correlationId'] as String?,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      name: data['name'] as String,
    );
  }

  @override
  Map<String, dynamic> eventDataToJson() => {'name': name};
}

@ServiceContract(remote: false)
class ServiceA extends FluxService {
  @override
  List<Type> get dependencies => const [ServiceC];

  @override
  Future<void> destroy() async {
    final e = createEvent<DestroyNotice>((
            {required eventId,
            required sourceService,
            required timestamp,
            String? correlationId,
            Map<String, dynamic> metadata = const {}}) =>
        DestroyNotice(
            eventId: eventId,
            sourceService: sourceService,
            timestamp: timestamp,
            correlationId: correlationId,
            metadata: metadata,
            name: 'A'));
    await broadcastEvent(e, includeSource: true);
    await super.destroy();
  }
}

@ServiceContract(remote: true)
class ServiceB extends FluxService {
  Future<String> id() async => 'B';
  @override
  Future<void> destroy() async {
    final e = createEvent<DestroyNotice>((
            {required eventId,
            required sourceService,
            required timestamp,
            String? correlationId,
            Map<String, dynamic> metadata = const {}}) =>
        DestroyNotice(
            eventId: eventId,
            sourceService: sourceService,
            timestamp: timestamp,
            correlationId: correlationId,
            metadata: metadata,
            name: 'B'));
    await broadcastEvent(e, includeSource: true);
    await super.destroy();
  }
}

@ServiceContract(remote: false)
class ServiceC extends FluxService {
  // Keep local-only dependency chain for order verification
  @override
  List<Type> get dependencies => const [];

  @override
  Future<void> destroy() async {
    final e = createEvent<DestroyNotice>((
            {required eventId,
            required sourceService,
            required timestamp,
            String? correlationId,
            Map<String, dynamic> metadata = const {}}) =>
        DestroyNotice(
            eventId: eventId,
            sourceService: sourceService,
            timestamp: timestamp,
            correlationId: correlationId,
            metadata: metadata,
            name: 'C'));
    await broadcastEvent(e, includeSource: true);
    await super.destroy();
  }
}

@ServiceContract(remote: false)
class Collector extends FluxService {
  final List<String> destroyed = [];
  @override
  Future<void> initialize() async {
    await super.initialize();
    EventTypeRegistry.register<DestroyNotice>(DestroyNotice.fromJson);
    onEvent<DestroyNotice>((e) async {
      destroyed.add(e.name);
      return const EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration.zero,
      );
    });
  }
}

void main() {
  group('Dependency-aware shutdown order', () {
    test('destroy order is reverse topological across isolates', () async {
      final runtime = FluxRuntime();
      runtime.register<Collector>(Collector.new);
      runtime.register<ServiceA>(ServiceA.new);
      runtime.register<ServiceB>(ServiceBImpl.new);
      runtime.register<ServiceC>(ServiceC.new);
      await runtime.initializeAll();

      final collector = runtime.get<Collector>();
      final b = runtime.get<ServiceB>();
      expect(await b.id(), equals('B'));

      await runtime.destroyAll();

      // Expect local reverse order A then C
      expect(collector.destroyed, equals(['A', 'C']));

      // Remote should be torn down; proxy call should fail
      expect(() => b.id(), throwsA(isA<ServiceException>()));
    });
  });
}

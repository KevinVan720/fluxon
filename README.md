# Flux

Fast, typed, event-driven services for Dart with complete isolate transparency and zero boilerplate.

## Table of Contents
1. Overview
2. Quickstart
3. Core Concepts
4. Usage Guide
   - Service Registration
   - Transparent Calls
   - Events
   - Code Generation

## 1. Overview
- Same API for local and remote services
- Automatic runtime infrastructure (dispatcher, bridge, worker wiring)
- Unified event system (`sendEvent`) with cross‑isolate routing
- Strong typing and generated proxies

## 2. Core Concepts
- FluxRuntime: orchestrates service lifecycle and event infrastructure
- FluxService: base for services with client and event capabilities
- Worker Isolates: remote services run in dedicated isolates transparently
- Event Distribution: configure routing (broadcast, direct) and include/exclude rules

## 3. Usage Guide

### Service Registration
Always use `@ServiceContract` annotation. Register with auto-generated `Impl` classes.
```dart
// 1. Define your service with @ServiceContract
@ServiceContract(remote: false)  // or remote: true for worker isolates
abstract class OrderService extends FluxService {
  Future<Order> createOrder(String userId, List<String> productIds);
}

// 2. Register with auto-generated implementation
runtime.register<OrderService>(() => OrderServiceImpl());
await runtime.initializeAll();
```

Declare dependencies inside the service and use them after initialization.
```dart
@ServiceContract(remote: false)
abstract class OrderService extends FluxService {
  @override
  List<Type> get dependencies => [UserService, ProductService];

  @override
  Future<void> initialize() async {
    await super.initialize();
    // Access dependency clients here using getService<UserService>()
  }
}
```

### Transparent Calls
```dart
// Define services with @ServiceContract
@ServiceContract(remote: false)
abstract class UserService extends FluxService {
  Future<User> getUser(String id);
}

@ServiceContract(remote: true)
abstract class EmailService extends FluxService {
  Future<void> sendWelcomeEmail(String userId);
}

// Register generated implementations
final runtime = FluxRuntime();
runtime.register<UserService>(() => UserServiceImpl());   // local
runtime.register<EmailService>(() => EmailServiceImpl()); // remote (worker)
await runtime.initializeAll();

// Use transparently
final userService = runtime.get<UserService>();
final emailService = runtime.get<EmailService>(); // could be remote
await emailService.sendWelcomeEmail('user_1');
```

### Events
Register event types and listen/send events in any service. Use `includeSource: true` if a service must receive its own broadcasts.
```dart
// 1. Register event types for cross-isolate communication
EventTypeRegistry.register<UserCreatedEvent>((json) => UserCreatedEvent.fromJson(json));
EventTypeRegistry.register<EmailSentEvent>((json) => EmailSentEvent.fromJson(json));

@ServiceContract(remote: true)
abstract class EmailService extends FluxService {
  @override
  Future<void> initialize() async {
    onEvent<UserCreatedEvent>((event) async {
      await sendWelcomeEmail(event.userId);
      return const EventProcessingResponse(result: EventProcessingResult.success);
    });
    await super.initialize();
  }
}

// 2. Sending events with explicit distribution
await sendEvent(
  createEvent(({required eventId, required sourceService, required timestamp})
    => EmailSentEvent(userId: id, eventId: eventId, sourceService: sourceService, timestamp: timestamp)),
  distribution: EventDistribution.broadcast(includeSource: true),
);
```

#### Alternative listening patterns

You can consume events in multiple ways depending on your needs.

1) Priority/conditional handlers (deterministic order)
```dart
onEvent<UserCreatedEvent>(
  (event) async {
    // High-priority processing
  },
  priority: 10, // higher runs first
  condition: (e) => e.userId.startsWith('vip_'),
);
```

2) Stream-based consumption with backpressure control
```dart
late final StreamSubscription<UserCreatedEvent> _userCreatedSub;

@override
Future<void> initialize() async {
  _userCreatedSub = listenToEvents<UserCreatedEvent>(
    (event) {
      // Stream-friendly processing
    },
    where: (e) => DateTime.now().difference(e.timestamp).inMinutes < 5,
  );
  await super.initialize();
}

@override
Future<void> destroy() async {
  await _userCreatedSub.cancel();
  await super.destroy();
}
```

3) Subscribe to events from remote isolates explicitly
```dart
late String _remoteSubId;

@override
Future<void> initialize() async {
  // Ensure event types are registered in this isolate
  EventTypeRegistry.register<UserCreatedEvent>(UserCreatedEvent.fromJson);

  _remoteSubId = await subscribeToRemoteEvents<UserCreatedEvent>(
    (event) async {
      // Handle events originating from other isolates
      return const EventProcessingResponse(result: EventProcessingResult.success);
    },
  );
  await super.initialize();
}

@override
Future<void> destroy() async {
  await unsubscribeFromRemoteEvents(_remoteSubId);
  await super.destroy();
}
```

Note: Event factories must be registered (via `EventTypeRegistry.register`) in every isolate that needs to reconstruct those events (e.g., call this early in `main()` and at the start of each worker service's `initialize()`).

#### Defining a typed event
```dart
class UserCreatedEvent extends ServiceEvent {
  const UserCreatedEvent({
    required this.userId,
    required super.eventId,
    required super.sourceService,
    required super.timestamp,
    super.metadata = const {},
    super.correlationId,
  });

  final String userId;

  @override
  Map<String, dynamic> eventDataToJson() => {'userId': userId};

  factory UserCreatedEvent.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return UserCreatedEvent(
      userId: data['userId'],
      eventId: json['eventId'],
      sourceService: json['sourceService'],
      timestamp: DateTime.parse(json['timestamp']),
      correlationId: json['correlationId'],
      metadata: json['metadata'] ?? {},
    );
  }
}
```

### Local ↔ Remote Calls (cross-isolate)
```dart
// Define two services that call each other
@ServiceContract(remote: false)
abstract class UserService extends FluxService {
  Future<User> getUser(String id);
}

@ServiceContract(remote: true)
abstract class EmailService extends FluxService {
  Future<void> sendWelcomeEmail(String userId);
}

// EmailServiceImpl (remote): calls local UserService transparently
class EmailServiceImpl extends EmailService {
  @override
  Future<void> sendWelcomeEmail(String userId) async {
    final userService = getService<UserService>(); // local or remote
    final user = await userService.getUser(userId);
    // ... send email using user details
    await sendEvent(EmailSentEvent(userId: user.id, eventId: 'e', sourceService: serviceName, timestamp: DateTime.now()));
  }
}

// Registration
final runtime = FluxRuntime();
runtime.register<UserService>(() => UserServiceImpl());   // local
runtime.register<EmailService>(() => EmailServiceImpl()); // remote (worker)
await runtime.initializeAll();

// UI or other service
await runtime.get<EmailService>().sendWelcomeEmail('user_1');
```

### Orchestrating multiple services (fan-out and events)
```dart
@ServiceContract(remote: true)
abstract class AnalyticsService extends FluxService {
  Future<void> record(String action, Map<String, dynamic> props);
}

class OrderServiceImpl extends OrderService {
  @override
  Future<Order> createOrder(String userId, List<String> products) async {
    final analytics = getService<AnalyticsService>(); // remote worker
    final order = await _create(userId, products);
    await analytics.record('order_created', {'orderId': order.id});
    await sendEvent(OrderCreatedEvent(orderId: order.id, eventId: 'e', sourceService: serviceName, timestamp: DateTime.now()));
    return order;
  }
}
```

### Code Generation
Add to `pubspec.yaml` and run:
```yaml
dependencies:
  flux:
dev_dependencies:
  flux_method_generator:
  build_runner: ^2.4.0
```
```bash
# Generate service implementations and client proxies
dart run build_runner build

# Or watch for changes
dart run build_runner watch
```

This generates:
- `ServiceNameImpl` classes for service registration
- Client proxy classes for transparent remote calls
- Method ID mappings for efficient communication

### Event distribution strategies
```dart
// Target specific services and wait for completion
await sendEvent(
  OrderCreatedEvent(...),
  distribution: EventDistribution.targeted([
    EventTarget(serviceType: InventoryService, waitUntilProcessed: true),
    EventTarget(serviceType: BillingService, waitUntilProcessed: true),
  ]),
);

// Broadcast to everyone except a few
await broadcastEvent(
  NotificationEvent(...),
  excludeServices: const [AuditService],
);

// Prioritize a few targets then broadcast to the rest
await sendEventTargetedThenBroadcast(
  AnalyticsEvent(...),
  [EventTarget(serviceType: RealtimeDashboardService, waitUntilProcessed: false)],
  excludeServices: const [DebugService],
);
```

### Health checks & observability
```dart
// Service-side: override healthCheck for custom diagnostics
@override
Future<ServiceHealthCheck> healthCheck() async => ServiceHealthCheck(
  status: ServiceHealthStatus.healthy,
  timestamp: DateTime.now(),
  message: 'OK',
  details: {'uptime': upTime.inSeconds},
);

// Runtime-side: aggregate checks
final results = await runtime.performHealthChecks();

// Event statistics (per isolate)
final stats = runtime.dependencyResolver; // see Dependency Graph & Stats below
```

### Dependency graph & stats
```dart
// Visualize the dependency graph
final dot = runtime.visualizeDependencyGraph();
// You can render this with Graphviz or tooling of your choice

// Statistics
final depStats = runtime.getDependencyStatistics();
```

### Service configuration & timeouts
You can control timeouts/retries via `ServiceConfig` or annotation parameters.
```dart
@ServiceContract(remote: true, timeoutMs: 15000, retryAttempts: 2, retryDelayMs: 200)
abstract class BillingService extends FluxService {}

class MyService extends FluxService {
  MyService(): super(config: const ServiceConfig(timeout: Duration(seconds: 20)));
}
```

---

Flux — where services flow seamlessly across isolates. 🌊



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
5. Best Practices & Pitfalls
6. Testing Guide
7. Architecture
8. Why Flux

## 1. Overview
- Same API for local and remote services
- Automatic runtime infrastructure (dispatcher, bridge, worker wiring)
- Unified event system (`sendEvent`) with cross‑isolate routing
- Strong typing and generated proxies

## 2. Quickstart
```dart
final runtime = FluxRuntime();

runtime.register<UserService>(UserService.new);          // Local
runtime.register<EmailService>(EmailServiceWorker.new);  // Remote (auto)

await runtime.initializeAll();

final userService = runtime.get<UserService>();
final user = await userService.createUser('alice');

await runtime.destroyAll();
```

## 3. Core Concepts
- FluxRuntime: orchestrates service lifecycle and event infrastructure
- FluxService: base for services with client and event capabilities
- Worker Isolates: remote services run in dedicated isolates transparently
- Event Distribution: configure routing (broadcast, direct) and include/exclude rules

## 4. Usage Guide

### Service Registration
Use zero‑argument factories. Avoid resolving dependencies during registration.
```dart
runtime.register<UserService>(UserService.new);
runtime.register<ProductService>(ProductService.new);
runtime.register<OrderService>(OrderService.new);
await runtime.initializeAll();
```

Declare dependencies inside the service and use them after initialization.
```dart
@ServiceContract(remote: false)
class OrderService extends FluxService {
  @override
  List<Type> get dependencies => [UserService, ProductService];

  @override
  Future<void> initialize() async {
    await super.initialize();
    // Access dependency clients here using client capabilities of FluxService
  }
}
```

### Transparent Calls
```dart
final userService = runtime.get<UserService>();
final emailService = runtime.get<EmailService>(); // could be remote
await emailService.sendWelcomeEmail('user_1');
```

### Events
Listen and send events in any service. Use `includeSource: true` if a service must receive its own broadcasts.
```dart
@ServiceContract(remote: true)
class EmailService extends FluxService {
  @override
  Future<void> initialize() async {
    onEvent<UserCreatedEvent>((event) async {
      await sendWelcomeEmail(event.userId);
      return const EventProcessingResponse(result: EventProcessingResult.success);
    });
    await super.initialize();
  }
}

// Sending with explicit distribution
await sendEvent(
  createEvent(({required eventId, required sourceService, required timestamp})
    => EmailSentEvent(userId: id, eventId: eventId, sourceService: sourceService, timestamp: timestamp)),
  distribution: EventDistribution.broadcast(includeSource: true),
);
```

### Code Generation
Add to `pubspec.yaml` and run:
```yaml
dev_dependencies:
  build_runner: ^2.4.0
```
```bash
dart run build_runner build
```

## 5. Best Practices & Pitfalls
1) Broadcasting to self
- Broadcast excludes the source by default. Use `EventDistribution.broadcast(includeSource: true)` when a service must observe its own events.

2) Registration & DI
- Do not call `runtime.get<T>()` inside `register(...)`. Use zero‑arg factories and declare `dependencies` in the service. Resolve after `super.initialize()`.

3) Async event assertions
- When testing event outcomes, either assert on `sendEvent` responses or allow a brief delay to process handlers before assertions.

## 6. Testing Guide
Isolate tests; create/destroy a runtime per test.
```dart
late FluxRuntime runtime;

setUp(() {
  runtime = FluxRuntime();
});

tearDown(() async {
  if (runtime.isInitialized) await runtime.destroyAll();
});
```
- Avoid global/static mutable state in services unless reset in `tearDown`.
- Ensure services that must observe their own events set `includeSource: true`.

## 7. Architecture
```
Main Isolate                Worker Isolate 1              Worker Isolate 2
┌─────────────┐            ┌──────────────┐              ┌──────────────┐
│ Service A   │◄──events──►│ Service B    │◄──events────►│ Service C    │
│ + EventDisp │            │ + EventDisp  │              │ + EventDisp  │
│ + EventBridge│            │ + EventBridge│              │ + EventBridge│
└─────────────┘            └──────────────┘              └──────────────┘
       ▲                           ▲                             ▲
       │                           │                             │
   FluxRuntime ◄──────────────────┼─────────────────────────────┘
   (Automatic routing & infrastructure)
```

## 8. Why Flux
- Zero configuration and boilerplate
- Local/remote transparency for services and events
- Strong typing and generated proxies
- True parallelism with worker isolates
- Seamless scalability (move services between isolates without code changes)

---

Flux — where services flow seamlessly across isolates. 🌊



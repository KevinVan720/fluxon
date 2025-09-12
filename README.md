# Fluxon

Fast, typed, event-driven services for Dart with complete isolate transparency and zero boilerplate.

## Table of Contents

1. [Overview](#overview)
2. [Installation](#installation)
3. [Quickstart](#quickstart)
4. [Core Concepts](#core-concepts)
5. [Usage Guide](#usage-guide)
   - [Service Registration](#service-registration)
   - [Transparent Calls](#transparent-calls)
   - [Events](#events)
   - [Code Generation](#code-generation)
6. [Advanced Features](#advanced-features)
   - [Event Distribution Strategies](#event-distribution-strategies)
   - [Health Checks & Observability](#health-checks--observability)
   - [Service Configuration & Timeouts](#service-configuration--timeouts)

## Overview

Fluxon is a powerful service framework for Dart that enables seamless communication between services running in different isolates. It provides:

- **🔄 Isolate Transparency**: Same API for local and remote services - no need to know where a service runs
- **🚀 Zero Boilerplate**: Automatic code generation for service implementations and client proxies  
- **📡 Unified Events**: Cross-isolate event system with flexible routing and distribution
- **💪 Strong Typing**: Full type safety with generated proxies and method mappings
- **🏗️ Auto Infrastructure**: Automatic runtime setup for dispatchers, bridges, and worker wiring

## Installation

Add Fluxon to your `pubspec.yaml`:

```yaml
dependencies:
  fluxon: ^0.0.1

dev_dependencies:
  flux_method_generator: ^0.0.1
  build_runner: ^2.4.0
```

Then run:

```bash
dart pub get
```

## Quickstart

Here's a minimal example to get you started:

```dart
import 'package:fluxon/flux.dart';

part 'main.g.dart'; // Required for code generation

// 1. Define and implement your service with @ServiceContract
@ServiceContract(remote: false)
class GreetingService extends FluxService {
  Future<String> greet(String name) async {
    return 'Hello, $name!';
  }
}

// 2. Set up and use (after running code generation)
void main() async {
  final runtime = FluxRuntime();
  
  // Register service using auto-generated Impl class
  runtime.register<GreetingService>(() => GreetingServiceImpl());
  await runtime.initializeAll();
  
  // Use service
  final greeting = runtime.get<GreetingService>();
  final message = await greeting.greet('World');
  print(message); // Hello, World!
}
```

Generate the required code:

```bash
dart run build_runner build
```

## Core Concepts

- **FluxRuntime**: Orchestrates service lifecycle and event infrastructure across isolates
- **FluxService**: Base class for services with built-in client and event capabilities  
- **@ServiceContract**: Annotation that defines service interfaces and generates implementation code
- **Worker Isolates**: Remote services run in dedicated isolates with complete transparency
- **Event Distribution**: Configurable routing system (broadcast, targeted, direct) with include/exclude rules

## Usage Guide

### Service Registration
Always use `@ServiceContract` annotation. Define concrete service classes.
```dart
// 1. Define your service with @ServiceContract
@ServiceContract(remote: false)  // or remote: true for worker isolates
class OrderService extends FluxService {
  Future<Order> createOrder(String userId, List<String> productIds) async {
    // Your business logic here
    final order = Order(id: generateId(), userId: userId, productIds: productIds);
    return order;
  }
}

// 2. Register your service using auto-generated Impl class
runtime.register<OrderService>(() => OrderServiceImpl());
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
    // Access dependency clients here using getService<UserService>()
  }

  Future<Order> createOrder(String userId, List<String> productIds) async {
    final userService = getService<UserService>();
    final productService = getService<ProductService>();
    
    // Use dependencies in your business logic
    final user = await userService.getUser(userId);
    final products = await productService.getProducts(productIds);
    
    return Order(id: generateId(), userId: userId, productIds: productIds);
  }
}
```

### Transparent Calls
```dart
// Define services with @ServiceContract
@ServiceContract(remote: false)
class UserService extends FluxService {
  Future<User> getUser(String id) async {
    // Local service implementation
    return User(id: id, name: 'User $id');
  }
}

@ServiceContract(remote: true)
class EmailService extends FluxService {
  Future<void> sendWelcomeEmail(String userId) async {
    // This runs in a worker isolate
    final userService = getService<UserService>(); // Transparently calls local service
    final user = await userService.getUser(userId);
    
    // Send email logic here
    print('Sending welcome email to ${user.name}');
  }
}

// Register services using auto-generated Impl classes
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
class EmailService extends FluxService {
  @override
  Future<void> initialize() async {
    onEvent<UserCreatedEvent>((event) async {
      await sendWelcomeEmail(event.userId);
      return const EventProcessingResponse(result: EventProcessingResult.success);
    });
    await super.initialize();
  }

  Future<void> sendWelcomeEmail(String userId) async {
    // Email sending logic
    print('Sending welcome email to user $userId');
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


### Code Generation

Generate service implementations and client proxies automatically.

Add to `pubspec.yaml` and run:
```yaml
dependencies:
  fluxon:
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
- Method dispatchers for worker isolates
- Method ID mappings for efficient communication

## Advanced Features

### Event Distribution Strategies

Control how events are distributed across your services:

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

### Health Checks & Observability

Monitor your services and get insights into system health:

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

// Visualize the dependency graph
final dot = runtime.visualizeDependencyGraph();
// You can render this with Graphviz or tooling of your choice

// Get dependency statistics
final depStats = runtime.getDependencyStatistics();
print('Total services: ${depStats.totalServices}');
print('Root services: ${depStats.rootServices}');
print('Average dependencies: ${depStats.averageDependencies}');
```

### Service Configuration & Timeouts

Control service behavior with configuration options:

```dart
// Configure per-method timeouts and retries using @ServiceMethod
@ServiceContract(remote: true)
class BillingService extends FluxService {
  @ServiceMethod(timeoutMs: 15000, retryAttempts: 2, retryDelayMs: 200)
  Future<PaymentResult> processPayment(String orderId, double amount) async {
    // This method will timeout after 15s and retry up to 2 times with 200ms delay
    return PaymentResult(success: true);
  }

  @ServiceMethod(timeoutMs: 5000)
  Future<bool> validateCard(String cardNumber) async {
    // This method has a shorter 5s timeout
    return true;
  }
}

// Or configure service-wide defaults via ServiceConfig
class MyService extends FluxService {
  MyService(): super(
    config: const ServiceConfig(
      timeout: Duration(seconds: 30),
      retryAttempts: 3,
      retryDelay: Duration(seconds: 1),
      enableLogging: true,
      logLevel: ServiceLogLevel.info,
    )
  );
}

// You can also override timeouts at runtime using ServiceCallOptions
final proxy = runtime.proxyRegistry.getProxy<BillingService>();
await proxy.callMethod<PaymentResult>(
  'processPayment',
  ['order_123', 99.99],
  options: const ServiceCallOptions(
    timeout: Duration(seconds: 60),
    retryAttempts: 5,
    retryDelay: Duration(milliseconds: 100),
  ),
);
```



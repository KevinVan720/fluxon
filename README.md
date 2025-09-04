# Flux

A comprehensive service framework for Dart applications with **complete isolate transparency** and **automatic event-driven communication**.

## 🚀 Key Features

### ✅ **Complete Isolate Transparency**
- **Identical APIs** for local and remote services
- **Automatic infrastructure setup** - zero boilerplate
- **Transparent method calls** - no difference between local/remote
- **Seamless event communication** across isolate boundaries

### 🎯 **Unified Event System**
- **Single API** for all event communication (`sendEvent()`)
- **Automatic routing** to local AND remote services
- **Cross-isolate event bridging** with full serialization support
- **Event type registry** for proper reconstruction across isolates

### 🔧 **Automatic Service Management**
- **FluxRuntime** automatically sets up all infrastructure
- **EventDispatcher** and **EventBridge** created automatically
- **Worker isolates** get full event infrastructure automatically
- **Service discovery** works transparently for local and remote services

## 📊 **Architecture Overview**

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

## 🎯 **Simple Usage**

### **Unified Registration**
```dart
final runtime = FluxRuntime();

// 🚀 Same API for local and remote services!
runtime.register<UserService>(() => UserService());           // Local
runtime.register<EmailService>(() => EmailServiceWorker());   // Remote (auto-detected)
runtime.register<PaymentService>(() => PaymentServiceWorker()); // Remote (auto-detected)

await runtime.initializeAll();
```

### **Transparent Service Calls**
```dart
// 🚀 Works identically for local OR remote services
final userService = runtime.get<UserService>();
final emailService = runtime.get<EmailService>();    // Could be remote!
final paymentService = runtime.get<PaymentService>(); // Could be remote!

// All calls look the same regardless of location
final user = await userService.createUser('alice');
await emailService.sendWelcomeEmail(user.id);
await paymentService.setupBilling(user.id);
```

### **Automatic Event Communication**
```dart
@ServiceContract(remote: true)
class EmailService extends FluxService {
  @override
  Future<void> initialize() async {
    // 🚀 Events work automatically across isolates
    onEvent<UserCreatedEvent>((event) async {
      await sendWelcomeEmail(event.userId);
      
      // Send completion event to ALL services (local + remote)
      await sendEvent(createEvent(
        ({required String eventId, required String sourceService, required DateTime timestamp}) =>
          EmailSentEvent(userId: event.userId, type: 'welcome', eventId: eventId, sourceService: sourceService, timestamp: timestamp)
      ));
      
      return EventProcessingResponse(result: EventProcessingResult.success);
    });
    
    await super.initialize();
  }
}
```

## 🔥 **Zero Boilerplate**

### **Before (Complex Setup)**
```dart
// 😰 Manual setup required
final eventDispatcher = EventDispatcher();
final eventBridge = EventBridge();
final service = MyService();
service.setEventDispatcher(eventDispatcher);
service.setEventBridge(eventBridge);

await locator.registerWorkerServiceProxy<MyService>(
  serviceName: 'MyService',
  serviceFactory: () => MyServiceWorker(),
  registerGenerated: registerMyServiceGenerated,
);

_registerMyServiceDispatcher();
_registerMyServiceClientFactory();
```

### **After (Zero Boilerplate)**
```dart
// 🚀 Automatic everything!
final runtime = FluxRuntime();
runtime.register<MyService>(() => MyServiceWorker());
await runtime.initializeAll();
```

## 📱 **Complete Example**

```dart
import 'package:dart_service_framework/dart_service_framework.dart';

part 'main.g.dart'; // Generated code

// Event types
class UserCreatedEvent extends ServiceEvent {
  const UserCreatedEvent({
    required this.userId,
    required super.eventId,
    required super.sourceService,
    required super.timestamp,
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
    );
  }
}

// Local service
@ServiceContract(remote: false)
class UserService extends FluxService {
  Future<Map<String, dynamic>> createUser(String name) async {
    final user = {'id': 'user_${DateTime.now().millisecondsSinceEpoch}', 'name': name};
    
    // Send event to ALL services automatically
    await sendEvent(createEvent(
      ({required String eventId, required String sourceService, required DateTime timestamp}) =>
        UserCreatedEvent(userId: user['id']!, eventId: eventId, sourceService: sourceService, timestamp: timestamp)
    ));
    
    return user;
  }
}

// Remote service (runs in isolate)
@ServiceContract(remote: true)
class EmailService extends FluxService {
  @override
  Future<void> initialize() async {
    // Listen for events from any service
    onEvent<UserCreatedEvent>((event) async {
      await sendWelcomeEmail(event.userId);
      return EventProcessingResponse(result: EventProcessingResult.success);
    });
    
    await super.initialize();
  }

  Future<void> sendWelcomeEmail(String userId) async {
    logger.info('Sending welcome email', metadata: {'userId': userId});
    // Email logic here...
  }
}

void main() async {
  // Register event types
  EventTypeRegistry.register<UserCreatedEvent>((json) => UserCreatedEvent.fromJson(json));

  // Create runtime and register services
  final runtime = FluxRuntime();
  
  // 🚀 Same registration API for local and remote!
  runtime.register<UserService>(() => UserService());
  runtime.register<EmailService>(() => EmailServiceWorker()); // Auto-detected as remote
  
  await runtime.initializeAll();

  // Use services transparently
  final userService = runtime.get<UserService>();
  final user = await userService.createUser('Alice');
  
  // Events automatically flow to EmailService in its isolate!
  
  await runtime.destroyAll();
}
```

## 🏗️ **Code Generation**

Add to your `pubspec.yaml`:

```yaml
dev_dependencies:
  build_runner: ^2.4.0

dependencies:
  dart_service_framework:
    path: ../dart-service-framework  # or pub version when published
```

Run code generation:

```bash
dart run build_runner build
```

## 🎯 **Key Benefits**

1. **Zero Configuration**: FluxRuntime sets up everything automatically
2. **Isolate Transparency**: Local and remote services have identical APIs
3. **Automatic Events**: Cross-isolate event communication works out of the box
4. **Type Safety**: Full compile-time type checking with generics
5. **Performance**: True parallelism with Squadron worker isolates
6. **Scalability**: Services can be moved between local/remote without code changes

## 📚 **Documentation**

- See `USAGE.md` for detailed examples
- Check `test/` directory for comprehensive usage patterns
- Generated code provides transparent proxy classes

---

**Flux** - Where services flow seamlessly across isolates! 🌊
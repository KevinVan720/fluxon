# Squadron-First Service Framework Example

This example demonstrates the **magic** of the Squadron-first service framework - transparent cross-service method calls without any manual setup!

## The Magic ✨

In your service code, you simply write:

```dart
@SquadronService()
class UserService extends SquadronService with SquadronServiceHandler {
  @override
  List<Type> get dependencies => [DatabaseService, CacheService];

  Future<Map<String, dynamic>> createUser({required String name, required String email}) async {
    // Get dependencies - no manual setup needed!
    final database = getRequiredDependency<DatabaseService>();
    final cache = getDependency<CacheService>();

    // Call methods as if they were local - but they're in different isolates!
    final user = await database.create('users', {'name': name, 'email': email});
    await cache.set('user:${user['id']}', user);

    return user;
  }
}
```

**That's it!** The framework automatically:
- ✅ Starts Squadron workers for each service
- ✅ Resolves dependencies and injection order
- ✅ Creates transparent proxies for cross-isolate calls
- ✅ Handles all message passing and serialization
- ✅ Provides type-safe method calls
- ✅ Manages service lifecycle and health monitoring

## Key Features

### 🚀 **Zero Setup Cross-Service Calls**
```dart
// This looks like a local call but goes across isolates!
final user = await database.create('users', userData);
await cache.set('user:${user['id']}', user);
```

### 🔗 **Automatic Dependency Injection**
```dart
@override
List<Type> get dependencies => [DatabaseService, CacheService];

// Framework automatically injects these when available
final database = getRequiredDependency<DatabaseService>();
final cache = getDependency<CacheService>(); // Optional dependency
```

### 🏗️ **Squadron Worker Management (Compiled Binary Ready!)**
```dart
// Register services - framework handles Squadron workers
locator.register<DatabaseService>(
  factory: () => DatabaseService(),
  isolateEntryPoint: databaseServiceEntryPoint, // Direct function reference!
);

// Initialize all - starts workers and sets up communication
await locator.initializeAll();
```

**✅ Works in compiled binaries!** No separate files needed - all entry points are embedded as function references.

### 📡 **Event Broadcasting**
```dart
// Send typed events across all services
final event = createEvent<UserCreatedEvent>(...);
await broadcastEvent(event);
```

## Running the Example

```bash
cd example/squadron_first_example
dart pub get
dart run lib/main.dart
```

## Service Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   UserService   │    │ DatabaseService │    │  CacheService   │
│   (Worker)      │    │    (Worker)     │    │    (Worker)     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │ Service Locator │
                    │ (Main Isolate)  │
                    └─────────────────┘
```

Each service runs in its own Squadron worker isolate, but you can call methods between them as if they were local objects!

## The "Magic" Explained

1. **Service Registration**: You register services with function references (not file paths!)
2. **Automatic Workers**: Framework uses `Isolate.spawn()` with embedded functions
3. **Proxy Generation**: Framework creates transparent proxies using Dart's `noSuchMethod`
4. **Dependency Injection**: Framework resolves dependencies and injects proxies
5. **Method Interception**: When you call `database.create()`, the proxy intercepts it
6. **Cross-Isolate Call**: Proxy sends the call to the DatabaseService worker
7. **Response Handling**: Result is returned as if it was a local call

## 🚀 **Compiled Binary Support**

**The framework is designed to work perfectly with compiled binaries!**

✅ **Function References**: Entry points use direct function references, not file paths
✅ **Embedded Code**: All service logic is embedded in the main binary
✅ **Isolate.spawn()**: Uses Dart's built-in `Isolate.spawn()` with function references
✅ **No External Files**: No need to distribute separate `.dart` files
✅ **Single Binary**: Everything compiles into one executable

### How It Works in Compiled Binaries:

```dart
// This function is embedded in your compiled binary
void databaseServiceEntryPoint(SendPort sendPort) async {
  // Service logic runs in isolate
}

// Register with direct function reference (works in compiled binary!)
locator.register<DatabaseService>(
  isolateEntryPoint: databaseServiceEntryPoint, // Function reference
);
```

When you compile your app with `dart compile exe`, all the entry point functions are embedded in the binary and can be referenced directly by `Isolate.spawn()`.

## No More Manual Work!

❌ **Before** (manual Squadron setup):
```dart
// Create worker
final worker = await Worker.create('database_service.dart');

// Send message
final result = await worker.send({'method': 'create', 'args': [...]});

// Handle response
if (result['success']) {
  return result['data'];
} else {
  throw Exception(result['error']);
}
```

✅ **Now** (automatic magic):
```dart
// Just call the method!
final user = await database.create('users', userData);
```

The framework handles everything else automatically! 🎉
# Dart Service Framework Usage Guide

This guide demonstrates how to use the Dart Service Framework to build scalable, maintainable applications with proper service architecture.

## Quick Start

### 1. Add Dependency

Add the framework to your `pubspec.yaml`:

```yaml
dependencies:
  dart_service_framework: ^1.0.0
```

### 2. Import the Framework

```dart
import 'package:dart_service_framework/dart_service_framework.dart';
```

### 3. Create Your First Service

```dart
class DatabaseService extends BaseService {
  @override
  List<Type> get dependencies => const [];

  @override
  Future<void> initialize() async {
    logger.info('Connecting to database');
    // Your initialization logic here
  }

  @override
  Future<void> destroy() async {
    logger.info('Disconnecting from database');
    // Your cleanup logic here
  }

  Future<User> getUser(String id) async {
    ensureInitialized();
    // Your business logic here
  }
}
```

### 4. Register and Use Services

```dart
void main() async {
  final locator = ServiceLocator();
  
  // Register services
  locator.register<DatabaseService>(() => DatabaseService());
  
  // Initialize all services
  await locator.initializeAll();
  
  // Use services
  final dbService = locator.get<DatabaseService>();
  final user = await dbService.getUser('123');
  
  // Cleanup
  await locator.destroyAll();
}
```

## Core Concepts

### Services

All services must extend `BaseService` and implement:
- `dependencies`: List of required service types
- `initialize()`: Service initialization logic
- `destroy()`: Service cleanup logic

```dart
class MyService extends BaseService {
  @override
  List<Type> get dependencies => [DatabaseService, CacheService];

  @override
  List<Type> get optionalDependencies => [MetricsService];

  @override
  Future<void> initialize() async {
    logger.info('Initializing MyService');
    // Initialization logic
  }

  @override
  Future<void> destroy() async {
    logger.info('Destroying MyService');
    // Cleanup logic
  }
}
```

### Service Locator

The `ServiceLocator` manages service registration, dependency resolution, and lifecycle:

```dart
final locator = ServiceLocator();

// Register services
locator.register<DatabaseService>(() => DatabaseService());
locator.register<CacheService>(() => CacheService());
locator.register<UserService>(() => UserService());

// Initialize all services (automatic dependency order)
await locator.initializeAll();

// Get service instances
final userService = locator.get<UserService>();

// Check service status
if (locator.isServiceInitialized<UserService>()) {
  // Service is ready
}

// Destroy all services (reverse dependency order)
await locator.destroyAll();
```

### Dependency Management

Services declare dependencies that determine initialization order:

```dart
class UserService extends BaseService {
  @override
  List<Type> get dependencies => [DatabaseService]; // Required

  @override
  List<Type> get optionalDependencies => [CacheService]; // Optional
}
```

The framework automatically:
- Validates dependencies (detects circular dependencies)
- Calculates initialization order using topological sort
- Initializes services in correct order
- Destroys services in reverse order

### Logging

Each service gets an automatic logger with service-specific prefixes:

```dart
class MyService extends BaseService {
  @override
  Future<void> initialize() async {
    logger.info('Service starting'); // [MyService] Service starting
    logger.debug('Debug info', metadata: {'key': 'value'});
    logger.error('Error occurred', error: exception, stackTrace: stack);
  }

  Future<void> doWork() async {
    // Time operations automatically
    await logger.timeAsync('database_query', () async {
      // Your async operation
    });
  }
}
```

## Advanced Features

### Service Mixins

#### Periodic Tasks

```dart
class NotificationService extends BaseService with PeriodicServiceMixin {
  @override
  Duration get periodicInterval => const Duration(minutes: 5);

  @override
  Future<void> performPeriodicTask() async {
    // This runs every 5 minutes
    await processNotifications();
  }
}
```

#### Configuration Validation

```dart
class ApiService extends BaseService with ConfigurableServiceMixin {
  @override
  void validateConfiguration() {
    if (config.metadata['apiKey'] == null) {
      throw Exception('API key is required');
    }
  }
}
```

#### Resource Management

```dart
class StreamService extends BaseService with ResourceManagedServiceMixin {
  @override
  Future<void> initialize() async {
    final subscription = someStream.listen(handleData);
    registerSubscription(subscription); // Auto-cleanup on destroy
    
    final timer = Timer.periodic(Duration(seconds: 1), handleTimer);
    registerTimer(timer); // Auto-cleanup on destroy
  }
}
```

### Health Checks

Services can implement custom health checks:

```dart
class DatabaseService extends BaseService {
  @override
  Future<ServiceHealthCheck> healthCheck() async {
    try {
      await ping();
      return ServiceHealthCheck(
        status: ServiceHealthStatus.healthy,
        timestamp: DateTime.now(),
        message: 'Database responding normally',
        details: {'latency_ms': 50},
      );
    } catch (e) {
      return ServiceHealthCheck(
        status: ServiceHealthStatus.unhealthy,
        timestamp: DateTime.now(),
        message: 'Database connection failed',
        details: {'error': e.toString()},
      );
    }
  }
}

// Check all service health
final healthChecks = await locator.performHealthChecks();
for (final entry in healthChecks.entries) {
  print('${entry.key}: ${entry.value.status}');
}
```

### Service Information and Analytics

```dart
// Get dependency statistics
final stats = locator.getDependencyStatistics();
print('Total services: ${stats.totalServices}');
print('Longest dependency chain: ${stats.longestChainLength}');

// Visualize dependency graph
print(locator.visualizeDependencyGraph());

// Get detailed service info
final info = locator.getServiceInfo<UserService>();
print('Service: ${info.name}');
print('State: ${info.state}');
print('Dependencies: ${info.dependencies}');
```

### Custom Logging

```dart
// Memory logger for testing
final memoryWriter = MemoryLogWriter();
final logger = ServiceLogger(
  serviceName: 'TestService',
  writer: memoryWriter,
);

// Multi-output logging
final multiWriter = MultiLogWriter([
  ConsoleLogWriter(colorize: true),
  FileLogWriter('app.log'),
  MemoryLogWriter(),
]);

// Filtered logging
final filteredWriter = FilteredLogWriter(
  writer: ConsoleLogWriter(),
  minLevel: ServiceLogLevel.warning,
  serviceNameFilter: r'Database.*',
);
```

## Best Practices

### 1. Service Design

- Keep services focused on a single responsibility
- Use dependency injection rather than service locator pattern within services
- Implement proper error handling and recovery
- Use health checks for monitoring

### 2. Dependency Management

- Minimize dependencies between services
- Use optional dependencies when appropriate
- Avoid circular dependencies
- Group related services into modules

### 3. Logging

- Use structured logging with metadata
- Log important state changes and operations
- Use appropriate log levels
- Include timing information for performance monitoring

### 4. Testing

```dart
// Test with memory logger
final memoryWriter = MemoryLogWriter();
final service = MyService(
  logger: ServiceLogger(serviceName: 'Test', writer: memoryWriter)
);

await service.internalInitialize();

// Verify logs
final logs = memoryWriter.entries;
expect(logs.any((log) => log.message.contains('initialized')), isTrue);
```

### 5. Error Handling

```dart
class RobustService extends BaseService {
  @override
  Future<void> initialize() async {
    await withRetry('database_connection', () async {
      await connectToDatabase();
    }, maxAttempts: 3);
  }

  Future<void> performOperation() async {
    try {
      ensureInitialized();
      ensureNotDestroyed();
      // Your operation
    } on ServiceStateException {
      logger.error('Service not in correct state');
      rethrow;
    }
  }
}
```

## Squadron Integration (Advanced)

For CPU-intensive or IO-heavy services, you can run them in isolates using Squadron:

```dart
// Note: Squadron integration is provided but requires additional setup
// See the service_worker.dart implementation for details

final workerFactory = ServiceWorkerFactory();
final worker = workerFactory.createWorker<MyService>(
  serviceName: 'MyService',
  serviceFactory: () => MyService(),
);

await worker.start();
await worker.initializeService();

// Service now runs in its own isolate
final result = await worker.callServiceMethod('someMethod', ['arg1', 'arg2']);
```

## Migration and Deployment

### Graceful Shutdown

```dart
// Handle shutdown signals
ProcessSignal.sigint.watch().listen((_) async {
  print('Shutting down gracefully...');
  await locator.destroyAll();
  exit(0);
});
```

### Service Versioning

```dart
class DatabaseServiceV2 extends BaseService {
  @override
  String get serviceName => 'DatabaseService'; // Same name for replacement
  
  // New implementation
}

// Register new version
locator.register<DatabaseService>(() => DatabaseServiceV2());
```

This framework provides a solid foundation for building scalable Dart applications with proper service architecture, dependency management, and observability.
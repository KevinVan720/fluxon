# Squadron Service Framework Example

This example demonstrates advanced usage of the Dart Service Framework with Squadron worker isolates, showing:

- **Typed Service Methods**: Services with strongly-typed method signatures
- **Data Classes**: Rich data models with JSON serialization
- **Inter-Service Communication**: Services calling other services with dependency injection
- **Squadron Workers**: Services running in isolates for true parallelism
- **Cache-Aside Pattern**: Intelligent caching with automatic invalidation
- **Performance Monitoring**: Cross-service metrics and health checks

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Main Isolate  │    │ Database Worker  │    │  Cache Worker   │
│                 │    │    Isolate       │    │    Isolate      │
├─────────────────┤    ├──────────────────┤    ├─────────────────┤
│  UserService    │◄──►│ DatabaseService  │    │  CacheService   │
│  (Orchestrator) │    │  (CPU-intensive) │    │  (Fast access)  │
│                 │    │                  │    │                 │
│ • createUser()  │    │ • createUser()   │    │ • cacheUser()   │
│ • getUserById() │    │ • searchUsers()  │    │ • getCached()   │
│ • searchUsers() │    │ • getAnalytics() │    │ • getStats()    │
│ • getAnalytics()│    │ • healthCheck()  │    │ • healthCheck() │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

## Data Models

### User
```dart
class User {
  final String id;
  final String name;
  final String email;
  final DateTime createdAt;
  final bool isActive;
  final Map<String, dynamic> metadata;
  
  // JSON serialization methods
  factory User.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
}
```

### UserSearchCriteria
```dart
class UserSearchCriteria {
  final String? namePattern;
  final String? emailPattern;
  final bool? isActive;
  final DateTime? createdAfter;
  final DateTime? createdBefore;
  final List<String> tags;
  final int limit;
  final int offset;
}
```

### UserSearchResult
```dart
class UserSearchResult {
  final List<User> users;
  final int totalCount;
  final bool hasMore;
  final Duration searchTime;
}
```

## Service Methods

### DatabaseService (Squadron Worker)

```dart
@SquadronService()
class DatabaseService extends BaseService {
  @SquadronMethod()
  Future<User> createUser({
    required String name,
    required String email,
    Map<String, dynamic> metadata = const {},
  });

  @SquadronMethod()
  Future<User?> getUserById(String id);

  @SquadronMethod()
  Future<List<User>> getUsersByIds(List<String> ids);

  @SquadronMethod()
  Future<UserSearchResult> searchUsers(UserSearchCriteria criteria);

  @SquadronMethod()
  Future<UserAnalytics> getAnalytics();
}
```

### CacheService (Squadron Worker)

```dart
@SquadronService()
class CacheService extends BaseService {
  @SquadronMethod()
  Future<void> cacheUser(User user, {Duration? ttl});

  @SquadronMethod()
  Future<User?> getCachedUser(String userId);

  @SquadronMethod()
  Future<List<User>> getCachedUsers(List<String> userIds);

  @SquadronMethod()
  Future<CacheStats> getStats();
}
```

### UserService (Main Isolate)

```dart
class UserService extends BaseService {
  // Orchestrates database and cache operations
  Future<User> createUser({required String name, required String email});
  Future<User?> getUserById(String id); // Cache-aside pattern
  Future<UserSearchResult> searchUsers(UserSearchCriteria criteria);
  Future<UserAnalytics> getAnalytics(); // Cached analytics
}
```

## Running the Example

### Prerequisites

```yaml
dependencies:
  squadron: ^6.2.0
  dart_service_framework:
    path: ../../

dev_dependencies:
  build_runner: ^2.4.0
  squadron_builder: ^6.0.0  # For generating workers
```

### Generate Squadron Workers

```bash
cd example/squadron_example
dart pub get
dart run build_runner build
```

This generates:
- `database_service.worker.dart`
- `cache_service.worker.dart`

### Run the Example

```bash
dart run lib/main.dart
```

## Key Features Demonstrated

### 1. Typed Method Calls Across Isolates

```dart
// This call serializes UserSearchCriteria to JSON,
// sends it to the database worker isolate,
// executes the search, and deserializes the result
final result = await databaseService.searchUsers(
  UserSearchCriteria(
    namePattern: 'alice',
    isActive: true,
    limit: 10,
  )
);
```

### 2. Cache-Aside Pattern

```dart
Future<User?> getUserById(String id) async {
  // Try cache first
  final cached = await cacheService.getCachedUser(id);
  if (cached != null) return cached;
  
  // Fallback to database
  final user = await databaseService.getUserById(id);
  if (user != null) {
    await cacheService.cacheUser(user); // Cache for next time
  }
  return user;
}
```

### 3. Service-to-Service Communication

```dart
class UserService extends BaseService {
  DatabaseService? _databaseService;
  CacheService? _cacheService;
  
  // Dependencies injected by service locator
  void setDatabaseService(DatabaseService service) {
    _databaseService = service;
  }
  
  void setCacheService(CacheService service) {
    _cacheService = service;
  }
}
```

### 4. Performance Monitoring

```dart
Future<Map<String, dynamic>> getPerformanceMetrics() async {
  return {
    'database': await _databaseService.healthCheck(),
    'cache': await _cacheService.getStats(),
    'userService': {'state': state.name},
  };
}
```

### 5. Comprehensive Error Handling

```dart
try {
  final user = await databaseService.getUserById(id);
  await cacheService.cacheUser(user);
} catch (e) {
  logger.warning('Cache operation failed', metadata: {
    'userId': id,
    'error': e.toString(),
  });
  // Continue without cache - graceful degradation
}
```

## Expected Output

```
=== Squadron Service Framework Example ===

1. Setting up services with Squadron workers...
   Services registered

2. Initializing services and Squadron workers...
   All services and workers initialized

3. Demonstrating typed service methods...
   Creating users...
   Created users: Alice Johnson, Bob Smith, Carol Davis

4. Demonstrating cache-aside pattern...
   First call (database + cache):
     Retrieved: Alice Johnson
   Second call (cache hit):
     Retrieved: Alice Johnson

5. Demonstrating typed search with caching...
   First search (database + cache):
     Found 2 users in 87ms
       - Alice Johnson (alice@example.com)
       - Carol Davis (carol@example.com)
   Second search (cache hit):
     Found 2 users in 2ms (cached)

6. Performance metrics across services...
   User Service: initialized
   Database: healthy - Database is healthy
   Cache: healthy
     Cache hit rate: 85.7%
     Cache entries: 8
     Memory usage: 2.3KB

=== Squadron Example completed successfully! ===

Key features demonstrated:
✓ Typed data classes with JSON serialization
✓ Squadron worker services
✓ Inter-service communication with dependency injection
✓ Cache-aside pattern with automatic invalidation
✓ Typed service methods with complex parameters
✓ Performance monitoring across service boundaries
✓ Comprehensive error handling and logging
✓ Health checks for distributed services
```

## Production Considerations

### 1. Real Squadron Workers

In production, replace the simulated workers with real Squadron workers:

```dart
// Generated by squadron_builder
final databaseWorker = DatabaseServiceWorker();
await databaseWorker.start();

final cacheWorker = CacheServiceWorker();  
await cacheWorker.start();
```

### 2. Error Recovery

```dart
class ResilientUserService extends UserService {
  @override
  Future<User?> getUserById(String id) async {
    return await withRetry('getUserById', () async {
      return await super.getUserById(id);
    }, maxAttempts: 3);
  }
}
```

### 3. Circuit Breaker Pattern

```dart
class CircuitBreakerCacheService {
  bool _isOpen = false;
  int _failureCount = 0;
  
  Future<T?> withCircuitBreaker<T>(Future<T> Function() operation) async {
    if (_isOpen) return null; // Fail fast
    
    try {
      final result = await operation();
      _failureCount = 0; // Reset on success
      return result;
    } catch (e) {
      _failureCount++;
      if (_failureCount >= 5) {
        _isOpen = true; // Open circuit
        Timer(Duration(seconds: 30), () => _isOpen = false); // Auto-reset
      }
      rethrow;
    }
  }
}
```

### 4. Monitoring Integration

```dart
class MonitoredUserService extends UserService {
  final MetricsCollector _metrics;
  
  @override
  Future<User?> getUserById(String id) async {
    return await _metrics.time('user_service.get_user', () async {
      final result = await super.getUserById(id);
      _metrics.increment(result != null ? 'user.found' : 'user.not_found');
      return result;
    });
  }
}
```

This example showcases the full power of the Dart Service Framework with Squadron, demonstrating how to build scalable, maintainable applications with proper service architecture and isolate-based parallelism.
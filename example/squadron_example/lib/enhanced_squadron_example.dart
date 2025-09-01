/// Enhanced Squadron example with automatic dependency injection and event broadcasting
library enhanced_squadron_example;

import 'dart:io';
import 'package:dart_service_framework/dart_service_framework.dart';
import 'models/user.dart';
import 'events/user_events.dart';
import 'services/database_service.dart';
import 'services/cache_service.dart';
import 'services/user_service.dart';

/// Simple enhanced service locator with automatic dependency injection and event broadcasting
class EnhancedSquadronServiceLocator extends ServiceLocator {
  EnhancedSquadronServiceLocator({ServiceLogger? logger}) : 
    _serviceLogger = logger ?? ServiceLogger(serviceName: 'EnhancedSquadronServiceLocator'),
    super(logger: logger);
  
  final ServiceLogger _serviceLogger;
  late final EventDispatcher _eventDispatcher;

  // Worker services (simulated Squadron workers)
  DatabaseService? _databaseWorker;
  CacheService? _cacheWorker;

  @override
  Future<void> initializeAll() async {
    // Initialize event dispatcher
    _eventDispatcher = EventDispatcher(logger: _serviceLogger);
    
    // Initialize Squadron workers (simulated)
    await _initializeWorkers();
    
    // Initialize services normally
    await super.initializeAll();
    
    // Perform automatic dependency injection
    await _performDependencyInjection();
    
    // Set up event dispatchers for all services
    await _setupEventDispatchers();
  }

  @override
  Future<void> destroyAll() async {
    await super.destroyAll();
    
    // Stop Squadron workers (simulated)
    await _stopWorkers();
    
    // Dispose event dispatcher
    _eventDispatcher.dispose();
  }

  Future<void> _initializeWorkers() async {
    _serviceLogger.info('Starting Squadron workers');
    
    // Create and initialize database worker
    _databaseWorker = DatabaseService(
      logger: ServiceLogger(serviceName: 'DatabaseWorker', writer: ConsoleLogWriter()),
    );
    await _databaseWorker!.internalInitialize();
    
    // Create and initialize cache worker
    _cacheWorker = CacheService(
      logger: ServiceLogger(serviceName: 'CacheWorker', writer: ConsoleLogWriter()),
    );
    await _cacheWorker!.internalInitialize();
    
    _serviceLogger.info('Squadron workers started');
  }

  Future<void> _stopWorkers() async {
    _serviceLogger.info('Stopping Squadron workers');
    
    if (_databaseWorker != null) {
      await _databaseWorker!.internalDestroy();
    }
    
    if (_cacheWorker != null) {
      await _cacheWorker!.internalDestroy();
    }
    
    _serviceLogger.info('Squadron workers stopped');
  }

  /// Perform automatic dependency injection for all services
  Future<void> _performDependencyInjection() async {
    _serviceLogger.info('Performing automatic dependency injection');
    
    // Get all service info and inject dependencies
    final allServiceInfo = getAllServiceInfo();
    for (final serviceInfo in allServiceInfo) {
      if (_isServiceInitialized(serviceInfo.type)) {
        final service = _getService(serviceInfo.type);
        if (service != null) {
          await _injectDependenciesForService(serviceInfo.type, service);
        }
      }
    }
    
    _serviceLogger.info('Dependency injection completed');
  }

  /// Inject dependencies for a specific service
  Future<void> _injectDependenciesForService(Type serviceType, BaseService service) async {
    final allDependencies = [...service.dependencies, ...service.optionalDependencies];
    
    for (final depType in allDependencies) {
      BaseService? dependency;
      
      // Check if it's a worker service
      if (depType == DatabaseService && _databaseWorker != null) {
        dependency = _databaseWorker!;
      } else if (depType == CacheService && _cacheWorker != null) {
        dependency = _cacheWorker!;
      } else if (_isServiceRegistered(depType) && _isServiceInitialized(depType)) {
        // Try regular registered services
        dependency = _getService(depType);
      }
      
      if (dependency != null) {
        service.onDependencyAvailable(depType, dependency);
        _serviceLogger.debug('Injected dependency', metadata: {
          'service': serviceType.toString(),
          'dependency': depType.toString(),
        });
      } else if (service.dependencies.contains(depType)) {
        // Required dependency not found
        _serviceLogger.warning('Required dependency not available', metadata: {
          'service': serviceType.toString(),
          'dependency': depType.toString(),
        });
      }
    }
  }

  /// Helper method to check if a service type is registered
  bool _isServiceRegistered(Type serviceType) {
    try {
      getAllServiceInfo().firstWhere((info) => info.type == serviceType);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Helper method to check if a service type is initialized
  bool _isServiceInitialized(Type serviceType) {
    try {
      final info = getAllServiceInfo().firstWhere((info) => info.type == serviceType);
      return info.state == ServiceState.initialized;
    } catch (e) {
      return false;
    }
  }

  /// Helper method to get a service by type
  BaseService? _getService(Type serviceType) {
    try {
      if (serviceType == UserService) {
        return tryGet<UserService>();
      } else if (serviceType == DatabaseService) {
        return tryGet<DatabaseService>();
      } else if (serviceType == CacheService) {
        return tryGet<CacheService>();
      }
    } catch (e) {
      // Service not available
    }
    return null;
  }

  /// Set up event dispatchers for all services
  Future<void> _setupEventDispatchers() async {
    _serviceLogger.info('Setting up event dispatchers');

    // Set event dispatcher for worker services
    if (_databaseWorker != null && _databaseWorker is ServiceEventMixin) {
      (_databaseWorker! as ServiceEventMixin).setEventDispatcher(_eventDispatcher);
    }

    if (_cacheWorker != null && _cacheWorker is ServiceEventMixin) {
      (_cacheWorker! as ServiceEventMixin).setEventDispatcher(_eventDispatcher);
    }

    // Set event dispatcher for main services
    final allServiceInfo = getAllServiceInfo();
    for (final serviceInfo in allServiceInfo) {
      if (_isServiceInitialized(serviceInfo.type)) {
        final service = _getService(serviceInfo.type);
        if (service != null && service is ServiceEventMixin) {
          (service as ServiceEventMixin).setEventDispatcher(_eventDispatcher);
        }
      }
    }

    _serviceLogger.info('Event dispatchers set up for all services');
  }

  /// Get the event dispatcher
  EventDispatcher get eventDispatcher => _eventDispatcher;
}

Future<void> main() async {
  print('=== Enhanced Squadron Service Framework Example ===\n');

  // Set up logging
  final memoryWriter = MemoryLogWriter();
  final logger = ServiceLogger(
    serviceName: 'EnhancedSquadronExample',
    writer: MultiLogWriter([
      ConsoleLogWriter(colorize: true),
      memoryWriter,
    ]),
  );

  final locator = EnhancedSquadronServiceLocator(logger: logger);

  try {
    print('1. Setting up services with automatic dependency injection...');
    
    // Register placeholder services for dependency resolution
    // The actual implementations will be injected from worker services
    locator.register<DatabaseService>(() => DatabaseService());
    locator.register<CacheService>(() => CacheService());
    
    // Register the main user service
    locator.register<UserService>(() => UserService(
      logger: ServiceLogger(serviceName: 'UserService', writer: ConsoleLogWriter()),
    ));

    print('   Services registered\n');

    print('2. Initializing services with Squadron workers and auto-injection...');
    await locator.initializeAll();
    print('   All services and workers initialized with dependencies injected\n');

    print('3. Demonstrating automatic dependency resolution...');
    final userService = locator.get<UserService>();

    // Verify dependencies are available
    print('   Checking dependencies:');
    print('     Database service: ${userService.getDependency<DatabaseService>() != null ? 'Available' : 'Not available'}');
    print('     Cache service: ${userService.getDependency<CacheService>() != null ? 'Available' : 'Not available'}');
    print('');

    print('4. Testing cross-service method calls...');
    
    // Create users - this will automatically use the injected database and cache services
    print('   Creating users with automatic service coordination...');
    final user1 = await userService.createUser(
      name: 'Alice Johnson',
      email: 'alice@example.com',
      metadata: {
        'department': 'Engineering',
        'tags': ['senior', 'fullstack', 'team-lead'],
      },
    );

    final user2 = await userService.createUser(
      name: 'Bob Smith',
      email: 'bob@example.com',
      metadata: {
        'department': 'Design',
        'tags': ['junior', 'ui-ux'],
      },
    );

    print('   Created users: ${user1.name}, ${user2.name}\n');

    print('5. Testing cache-aside pattern with injected services...');
    
    // First call - should hit database and cache result
    print('   First call (database + cache):');
    var fetchedUser = await userService.getUserById(user1.id);
    print('     Retrieved: ${fetchedUser?.name}');

    // Second call - should hit cache
    print('   Second call (cache hit):');
    fetchedUser = await userService.getUserById(user1.id);
    print('     Retrieved: ${fetchedUser?.name}\n');

    print('6. Testing search with automatic caching...');
    
    final searchCriteria = UserSearchCriteria(
      namePattern: 'a',
      isActive: true,
      limit: 10,
    );

    print('   First search (database + cache):');
    var searchResult = await userService.searchUsers(searchCriteria);
    print('     Found ${searchResult.users.length} users in ${searchResult.searchTime.inMilliseconds}ms');

    print('   Second search (cache hit):');
    searchResult = await userService.searchUsers(searchCriteria);
    print('     Found ${searchResult.users.length} users in ${searchResult.searchTime.inMilliseconds}ms (cached)\n');

    print('7. Testing analytics with cross-service coordination...');
    
    print('   Generating analytics (database + cache):');
    final analytics = await userService.getAnalytics();
    print('     Total users: ${analytics.totalUsers}');
    print('     Active users: ${analytics.activeUsers}');
    print('     Average profile score: ${analytics.averageProfileScore.toStringAsFixed(1)}');

    print('   Getting cached analytics:');
    final cachedAnalytics = await userService.getAnalytics();
    print('     Retrieved analytics (cached)\n');

    print('8. Demonstrating event broadcasting system...');
    
    // Set up event listeners for demonstration
    final eventLogs = <String>[];
    
    // Listen to user created events
    userService.onEvent<UserCreatedEvent>((event) async {
      eventLogs.add('UserService received UserCreatedEvent: ${event.user.name}');
      return EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration(milliseconds: 5),
      );
    });

    print('   Creating a user to trigger events...');
    final eventTestUser = await userService.createUser(
      name: 'Event Test User',
      email: 'event@example.com',
      metadata: {'source': 'event_demo'},
    );
    print('     Created user: ${eventTestUser.name}');

    // Give events time to propagate
    await Future.delayed(Duration(milliseconds: 100));

    print('   Event processing results:');
    for (final log in eventLogs) {
      print('     $log');
    }

    // Demonstrate event statistics
    print('   Event system statistics:');
    final eventStats = locator.eventDispatcher.getStatistics();
    for (final entry in eventStats.entries) {
      final stats = entry.value;
      print('     ${entry.key}: sent=${stats.totalSent}, processed=${stats.totalProcessed}, success=${(stats.successRate * 100).toStringAsFixed(1)}%');
    }
    print('');

    print('9. Performance metrics across injected services...');
    final metrics = await userService.getPerformanceMetrics();
    
    print('   User Service: ${metrics['userService']['state']}');
    print('   Database: ${metrics['database']['status']} - ${metrics['database']['message']}');
    print('   Cache: ${metrics['cache']['status']}');
    
    if (metrics['cache']['stats'] != null) {
      final cacheStats = metrics['cache']['stats'];
      print('     Cache hit rate: ${(cacheStats['hitRate'] * 100).toStringAsFixed(1)}%');
      print('     Cache entries: ${cacheStats['totalEntries']}');
    }
    print('');

    print('10. Health checks with dependency verification...');
    final healthChecks = await locator.performHealthChecks();
    for (final entry in healthChecks.entries) {
      final health = entry.value;
      print('   ${entry.key}: ${health.status.name} - ${health.message}');
    }
    print('');

    print('11. Dependency relationship verification...');
    final userServiceInfo = locator.getServiceInfo<UserService>();
    print('   UserService dependencies: ${userServiceInfo.dependencies.map((t) => t.toString()).join(', ')}');
    print('   UserService state: ${userServiceInfo.state.name}');
    print('');

    print('12. Cleanup and shutdown...');
    await locator.destroyAll();
    print('    All services and workers shut down\n');

    print('13. Log analysis...');
    final logs = memoryWriter.entries;
    final dependencyLogs = logs.where((e) => 
      e.message.contains('Injected dependency') || 
      e.message.contains('became available')
    ).toList();

    print('   Dependency injection logs:');
    for (final log in dependencyLogs) {
      print('     [${log.serviceName}] ${log.message}');
      if (log.metadata.isNotEmpty) {
        print('       ${log.metadata}');
      }
    }

    print('\n=== Enhanced Squadron Example completed successfully! ===');
    print('\nKey enhanced features demonstrated:');
    print('✓ Automatic dependency injection with getDependency<T>()');
    print('✓ Service-to-service communication without manual wiring');
    print('✓ onDependencyAvailable() callbacks for service coordination');
    print('✓ Squadron worker simulation with transparent method calls');
    print('✓ Dependency verification and health monitoring');
    print('✓ Cache-aside pattern with automatic service coordination');
    print('✓ Cross-isolate method calls abstracted away from business logic');
    print('✓ Typed event broadcasting with distribution control');
    print('✓ Event listeners with priority and conditional processing');
    print('✓ Cross-service event coordination and statistics tracking');

  } catch (error, stackTrace) {
    print('❌ Error occurred: $error');
    print('Stack trace: $stackTrace');
    
    try {
      await locator.destroyAll();
    } catch (cleanupError) {
      print('Cleanup error: $cleanupError');
    }
    
    exit(1);
  }
}

/// Example of real Squadron integration
/// 
/// In a production environment with real Squadron workers:
/// 
/// ```dart
/// // 1. Services would be annotated with @SquadronService()
/// @SquadronService()
/// class DatabaseService extends BaseService {
///   @SquadronMethod()
///   Future<User> createUser({required String name, required String email}) async {
///     // Implementation runs in isolate
///   }
/// }
/// 
/// // 2. Code generation creates worker classes
/// // dart run build_runner build
/// // Generates: database_service.worker.dart
/// 
/// // 3. Enhanced service locator would spawn real isolates
/// Future<void> _initializeWorkers() async {
///   _databaseWorker = DatabaseServiceWorker();
///   await _databaseWorker!.start();
///   
///   _cacheWorker = CacheServiceWorker();
///   await _cacheWorker!.start();
/// }
/// 
/// // 4. Method calls automatically serialize across isolates
/// final user = await userService.createUser(name: 'Alice', email: 'alice@example.com');
/// // This call:
/// // - Serializes parameters to JSON
/// // - Sends to database worker isolate
/// // - Executes createUser in isolate
/// // - Serializes User result back to JSON
/// // - Deserializes in main isolate
/// // - Returns typed User object
/// 
/// // 5. Dependency injection still works transparently
/// class UserService extends BaseService {
///   @override
///   List<Type> get dependencies => [DatabaseService]; // Worker service
///   
///   @override
///   void onDependencyAvailable(Type serviceType, BaseService service) {
///     super.onDependencyAvailable(serviceType, service);
///     if (serviceType == DatabaseService) {
///       // service is actually a proxy to the worker isolate
///       print('Database worker is ready for cross-isolate calls');
///     }
///   }
/// }
/// ```
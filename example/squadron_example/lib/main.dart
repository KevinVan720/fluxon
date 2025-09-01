/// Squadron example demonstrating typed service methods and inter-service communication
library squadron_example;

import 'dart:io';
import 'package:dart_service_framework/dart_service_framework.dart';
import 'models/user.dart';
import 'services/database_service.dart';
import 'services/cache_service.dart';
import 'services/user_service.dart';

/// Enhanced service locator with Squadron worker support and automatic dependency injection
class SquadronServiceLocator extends ServiceLocator {
  SquadronServiceLocator({ServiceLogger? logger}) : 
    _serviceLogger = logger ?? ServiceLogger(serviceName: 'SquadronServiceLocator'),
    super(logger: logger);
  
  final ServiceLogger _serviceLogger;

  // In a real implementation, these would be Squadron workers
  // For this example, we'll simulate the worker pattern
  DatabaseService? _databaseWorker;
  CacheService? _cacheWorker;

  @override
  Future<void> initializeAll() async {
    // Initialize Squadron workers (simulated)
    await _initializeWorkers();
    
    // Initialize services normally
    await super.initializeAll();
    
    // Perform automatic dependency injection
    await _performDependencyInjection();
  }

  @override
  Future<void> destroyAll() async {
    await super.destroyAll();
    
    // Stop Squadron workers (simulated)
    await _stopWorkers();
  }

  Future<void> _initializeWorkers() async {
    _serviceLogger.info('Starting Squadron workers');
    
    // In a real implementation, these would be:
    // _databaseWorker = DatabaseServiceWorker();
    // await _databaseWorker!.start();
    // await _databaseWorker!.initialize();
    
    // For this example, we create the services directly
    _databaseWorker = DatabaseService(
      logger: ServiceLogger(serviceName: 'DatabaseWorker', writer: ConsoleLogWriter()),
    );
    await _databaseWorker!.internalInitialize();
    
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
      // In real implementation: await _databaseWorker!.stop();
    }
    
    if (_cacheWorker != null) {
      await _cacheWorker!.internalDestroy();
      // In real implementation: await _cacheWorker!.stop();
    }
    
    _serviceLogger.info('Squadron workers stopped');
  }

  /// Perform automatic dependency injection for all services
  Future<void> _performDependencyInjection() async {
    _serviceLogger.info('Performing automatic dependency injection');
    
    // Inject dependencies for all registered services
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
    // Use the service info to check registration
    try {
      final info = getAllServiceInfo().firstWhere((info) => info.type == serviceType);
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
      // Use tryGet with dynamic typing
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
}

Future<void> main() async {
  print('=== Squadron Service Framework Example ===\n');

  // Set up logging
  final memoryWriter = MemoryLogWriter();
  final logger = ServiceLogger(
    serviceName: 'SquadronExample',
    writer: MultiLogWriter([
      ConsoleLogWriter(colorize: true),
      memoryWriter,
    ]),
  );

  final locator = SquadronServiceLocator(logger: logger);

  try {
    print('1. Setting up services with Squadron workers...');
    
    // Register placeholder services for dependency resolution
    // The actual services run as Squadron workers
    locator.register<DatabaseService>(() => DatabaseService());
    locator.register<CacheService>(() => CacheService());
    
    // Register the main user service (runs in main isolate)
    locator.register<UserService>(() => UserService(
      logger: ServiceLogger(serviceName: 'UserService', writer: ConsoleLogWriter()),
    ));

    print('   Services registered\n');

    print('2. Initializing services and Squadron workers...');
    await locator.initializeAll();
    print('   All services and workers initialized\n');

    print('3. Demonstrating typed service methods...');
    final userService = locator.get<UserService>();

    // Create users with typed data classes
    print('   Creating users...');
    final user1 = await userService.createUser(
      name: 'Alice Johnson',
      email: 'alice@example.com',
      metadata: {
        'department': 'Engineering',
        'tags': ['senior', 'fullstack', 'team-lead'],
        'joinDate': DateTime.now().subtract(const Duration(days: 365)).toIso8601String(),
      },
    );

    final user2 = await userService.createUser(
      name: 'Bob Smith',
      email: 'bob@example.com',
      metadata: {
        'department': 'Design',
        'tags': ['junior', 'ui-ux'],
        'joinDate': DateTime.now().subtract(const Duration(days: 180)).toIso8601String(),
      },
    );

    final user3 = await userService.createUser(
      name: 'Carol Davis',
      email: 'carol@example.com',
      metadata: {
        'department': 'Engineering',
        'tags': ['senior', 'backend', 'architect'],
        'joinDate': DateTime.now().subtract(const Duration(days: 730)).toIso8601String(),
      },
    );

    print('   Created users: ${user1.name}, ${user2.name}, ${user3.name}\n');

    print('4. Demonstrating cache-aside pattern...');
    
    // First call - should hit database and cache result
    print('   First call (database + cache):');
    var fetchedUser = await userService.getUserById(user1.id);
    print('     Retrieved: ${fetchedUser?.name}');

    // Second call - should hit cache
    print('   Second call (cache hit):');
    fetchedUser = await userService.getUserById(user1.id);
    print('     Retrieved: ${fetchedUser?.name}');

    // Batch retrieval
    print('   Batch retrieval:');
    final users = await userService.getUsersByIds([user1.id, user2.id, user3.id]);
    print('     Retrieved ${users.length} users: ${users.map((u) => u.name).join(', ')}\n');

    print('5. Demonstrating typed search with caching...');
    
    // Search with typed criteria
    final searchCriteria = UserSearchCriteria(
      namePattern: 'a', // Users with 'a' in name
      isActive: true,
      limit: 10,
    );

    print('   First search (database + cache):');
    var searchResult = await userService.searchUsers(searchCriteria);
    print('     Found ${searchResult.users.length} users in ${searchResult.searchTime.inMilliseconds}ms');
    for (final user in searchResult.users) {
      print('       - ${user.name} (${user.email})');
    }

    print('   Second search (cache hit):');
    searchResult = await userService.searchUsers(searchCriteria);
    print('     Found ${searchResult.users.length} users in ${searchResult.searchTime.inMilliseconds}ms (cached)\n');

    print('6. Demonstrating service-to-service communication...');
    
    // Update user (demonstrates cache invalidation)
    print('   Updating user...');
    final updatedUser = await userService.updateUser(user2.id, {
      'name': 'Robert Smith',
      'metadata': {
        ...user2.metadata,
        'tags': ['senior', 'ui-ux', 'team-lead'], // Promotion!
      },
    });
    print('     Updated: ${updatedUser?.name}');

    // Get analytics (demonstrates complex cross-service operation)
    print('   Generating analytics...');
    final analytics = await userService.getAnalytics();
    print('     Total users: ${analytics.totalUsers}');
    print('     Active users: ${analytics.activeUsers}');
    print('     Average profile score: ${analytics.averageProfileScore.toStringAsFixed(1)}');
    print('     Top tags: ${analytics.topTags}');

    // Second analytics call (should be cached)
    print('   Getting cached analytics...');
    final cachedAnalytics = await userService.getAnalytics();
    print('     Retrieved in ${DateTime.now().difference(cachedAnalytics.generatedAt).inMilliseconds}ms (cached)\n');

    print('7. Performance metrics across services...');
    final metrics = await userService.getPerformanceMetrics();
    
    print('   User Service: ${metrics['userService']['state']}');
    print('   Database: ${metrics['database']['status']} - ${metrics['database']['message']}');
    print('   Cache: ${metrics['cache']['status']}');
    
    if (metrics['cache']['stats'] != null) {
      final cacheStats = metrics['cache']['stats'];
      print('     Cache hit rate: ${(cacheStats['hitRate'] * 100).toStringAsFixed(1)}%');
      print('     Cache entries: ${cacheStats['totalEntries']}');
      print('     Memory usage: ${(cacheStats['memoryUsageBytes'] / 1024).toStringAsFixed(1)}KB');
    }
    print('');

    print('8. Health checks across all services...');
    final healthChecks = await locator.performHealthChecks();
    for (final entry in healthChecks.entries) {
      final health = entry.value;
      print('   ${entry.key}: ${health.status.name} - ${health.message}');
      if (health.details.isNotEmpty) {
        print('     Details: ${health.details}');
      }
    }
    print('');

    print('9. Demonstrating error handling...');
    
    // Try to get non-existent user
    print('   Getting non-existent user...');
    final nonExistentUser = await userService.getUserById('non-existent-id');
    print('     Result: ${nonExistentUser ?? 'null (not found)'}');

    // Try to update non-existent user
    print('   Updating non-existent user...');
    final updateResult = await userService.updateUser('non-existent-id', {'name': 'New Name'});
    print('     Result: ${updateResult ?? 'null (not found)'}\n');

    print('10. Cleanup and shutdown...');
    await locator.destroyAll();
    print('    All services and workers shut down\n');

    print('11. Log analysis...');
    final logs = memoryWriter.entries;
    final errorLogs = logs.where((e) => e.level == ServiceLogLevel.error).length;
    final warningLogs = logs.where((e) => e.level == ServiceLogLevel.warning).length;
    final infoLogs = logs.where((e) => e.level == ServiceLogLevel.info).length;
    final debugLogs = logs.where((e) => e.level == ServiceLogLevel.debug).length;

    print('   Total log entries: ${logs.length}');
    print('   Errors: $errorLogs');
    print('   Warnings: $warningLogs');
    print('   Info: $infoLogs');
    print('   Debug: $debugLogs');

    // Show some interesting log entries
    print('\n   Recent service operations:');
    final recentLogs = logs.where((e) => 
      e.level == ServiceLogLevel.info && 
      (e.message.contains('Creating user') || 
       e.message.contains('Search') || 
       e.message.contains('Analytics'))
    ).take(5);
    
    for (final log in recentLogs) {
      print('     [${log.serviceName}] ${log.message}');
      if (log.metadata.isNotEmpty) {
        print('       ${log.metadata}');
      }
    }

    print('\n=== Squadron Example completed successfully! ===');
    print('\nKey features demonstrated:');
    print('✓ Typed data classes with JSON serialization');
    print('✓ Squadron worker services (simulated)');
    print('✓ Inter-service communication with dependency injection');
    print('✓ Cache-aside pattern with automatic invalidation');
    print('✓ Typed service methods with complex parameters');
    print('✓ Performance monitoring across service boundaries');
    print('✓ Comprehensive error handling and logging');
    print('✓ Health checks for distributed services');

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

/// Example of how to run this with real Squadron workers
/// 
/// To use real Squadron workers, you would:
/// 
/// 1. Add squadron_builder to dev_dependencies
/// 2. Run: dart run build_runner build
/// 3. This generates DatabaseServiceWorker and CacheServiceWorker classes
/// 4. Replace the simulated workers in _initializeWorkers() with:
/// 
/// ```dart
/// _databaseWorker = DatabaseServiceWorker();
/// await _databaseWorker!.start();
/// await _databaseWorker!.initialize();
/// 
/// _cacheWorker = CacheServiceWorker();
/// await _cacheWorker!.start();
/// await _cacheWorker!.initialize();
/// ```
/// 
/// 5. The typed method calls would then automatically serialize/deserialize
///    data across isolate boundaries:
/// 
/// ```dart
/// // This call would serialize UserSearchCriteria to JSON,
/// // send it to the worker isolate, execute the search,
/// // and deserialize UserSearchResult back to the main isolate
/// final result = await _databaseWorker!.searchUsers(criteria);
/// ```
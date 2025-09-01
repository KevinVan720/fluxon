/// Squadron-first example demonstrating transparent cross-service method calls
library main;

import 'dart:io';
import 'package:dart_service_framework/dart_service_framework.dart';
import 'services/database_service.dart';
import 'services/cache_service.dart';
import 'services/user_service.dart';

Future<void> main() async {
  print('=== Squadron-First Service Framework Example ===\n');
  print('Demonstrating transparent cross-service method calls!\n');

  // Create the Squadron-first service locator
  final locator = SquadronServiceLocator();

  try {
    // Register services with their Squadron entry points (function references)
    print('1. Registering Squadron services...');
    
    locator.register<DatabaseService>(
      factory: () => DatabaseService(),
      isolateEntryPoint: databaseServiceEntryPoint, // Direct function reference!
      dependencies: [],
    );

    locator.register<CacheService>(
      factory: () => CacheService(),
      isolateEntryPoint: cacheServiceEntryPoint, // Direct function reference!
      dependencies: [],
    );

    locator.register<UserService>(
      factory: () => UserService(),
      isolateEntryPoint: userServiceEntryPoint, // Direct function reference!
      dependencies: [DatabaseService, CacheService],
    );

    print('   ✓ DatabaseService registered');
    print('   ✓ CacheService registered');
    print('   ✓ UserService registered (depends on Database + Cache)');
    print('');

    // Initialize all services - this starts Squadron workers automatically!
    print('2. Initializing Squadron workers...');
    await locator.initializeAll();
    print('   ✓ All Squadron workers started and dependencies injected');
    print('');

    // Now the magic happens - transparent method calls across isolates!
    print('3. Demonstrating transparent cross-service method calls...');
    
    // Get the user service proxy
    final userService = locator.get<UserService>();
    
    print('   Creating users (UserService -> DatabaseService -> CacheService)...');
    
    // This looks like a normal method call, but it's actually:
    // 1. Sent to UserService worker isolate
    // 2. UserService calls DatabaseService (another isolate)
    // 3. UserService calls CacheService (another isolate)
    // 4. All automatically handled by the framework!
    final user1 = await userService.createUser(
      name: 'Alice Johnson',
      email: 'alice@example.com',
      metadata: {'role': 'admin', 'department': 'engineering'},
    );
    print('     ✓ Created user: ${user1['name']} (ID: ${user1['id']})');

    final user2 = await userService.createUser(
      name: 'Bob Wilson',
      email: 'bob@example.com',
      metadata: {'role': 'user', 'department': 'marketing'},
    );
    print('     ✓ Created user: ${user2['name']} (ID: ${user2['id']})');

    print('');

    // Demonstrate cache-aside pattern with transparent calls
    print('4. Testing cache-aside pattern...');
    
    print('   First lookup (cache miss -> database -> cache)...');
    final fetchedUser1 = await userService.getUserById(user1['id']);
    print('     ✓ Retrieved user: ${fetchedUser1!['name']}');

    print('   Second lookup (cache hit)...');
    final cachedUser1 = await userService.getUserById(user1['id']);
    print('     ✓ Retrieved user from cache: ${cachedUser1!['name']}');
    print('');

    // Demonstrate search with caching
    print('5. Testing search with result caching...');
    
    final searchResults = await userService.searchUsers({'role': 'admin'});
    print('     ✓ Found ${searchResults.length} admin users');
    
    // Second search should hit cache
    final cachedResults = await userService.searchUsers({'role': 'admin'});
    print('     ✓ Retrieved ${cachedResults.length} results from cache');
    print('');

    // Demonstrate update with cache invalidation
    print('6. Testing update with cache invalidation...');
    
    final updatedUser = await userService.updateUser(user1['id'], {
      'name': 'Alice Johnson-Smith',
      'metadata': {'role': 'admin', 'department': 'engineering', 'married': true},
    });
    print('     ✓ Updated user: ${updatedUser!['name']}');

    // Verify cache was invalidated
    final freshUser = await userService.getUserById(user1['id']);
    print('     ✓ Fresh lookup shows updated name: ${freshUser!['name']}');
    print('');

    // Demonstrate cross-service statistics
    print('7. Getting statistics from multiple services...');
    
    final stats = await userService.getUserStats();
    print('     Database stats: ${stats['database']['recordCount']} users');
    print('     Cache stats: ${stats['cache']['totalEntries']} entries');
    print('');

    // Demonstrate service health checks
    print('8. Performing health checks on all Squadron workers...');
    
    final healthChecks = await locator.performHealthChecks();
    for (final entry in healthChecks.entries) {
      final health = entry.value;
      print('     ${entry.key}: ${health.status.name} - ${health.message}');
    }
    print('');

    // Show the magic - direct access to other services through dependencies
    print('9. Demonstrating direct service access (the real magic!)...');
    print('   Note: In UserService code, we simply call:');
    print('   - final database = getRequiredDependency<DatabaseService>();');
    print('   - await database.create(...) // This goes across isolates!');
    print('   - final cache = getDependency<CacheService>();');
    print('   - await cache.set(...) // This also goes across isolates!');
    print('');
    print('   No manual setup, no message passing, no complex wiring!');
    print('   Just call methods as if they were local objects!');
    print('');

    // Demonstrate event broadcasting
    print('10. Event broadcasting across all services...');
    
    // Delete a user to trigger events
    final deleted = await userService.deleteUser(user2['id']);
    print('     ✓ Deleted user (sent events to all services): $deleted');
    print('');

    // Show final statistics
    print('11. Final service statistics...');
    final finalStats = await userService.getUserStats();
    print('     Remaining users: ${finalStats['database']['recordCount']}');
    print('     Cache entries: ${finalStats['cache']['totalEntries']}');
    print('');

    print('12. Cleanup and shutdown...');
    await locator.destroyAll();
    print('     ✓ All Squadron workers stopped');
    print('');

    print('🎉 Squadron-First Framework Demo Complete!');
    print('');
    print('Key Features Demonstrated:');
    print('✓ Automatic Squadron worker management');
    print('✓ Transparent cross-isolate method calls');
    print('✓ Automatic dependency injection');
    print('✓ No manual message passing or setup');
    print('✓ Type-safe service communication');
    print('✓ Event broadcasting across services');
    print('✓ Health monitoring and statistics');
    print('✓ Just call methods - framework handles the rest!');

  } catch (error, stackTrace) {
    print('❌ Error occurred: $error');
    print('Stack trace: $stackTrace');
    
    // Cleanup on error
    try {
      await locator.destroyAll();
    } catch (cleanupError) {
      print('❌ Cleanup error: $cleanupError');
    }
    
    exit(1);
  }
}
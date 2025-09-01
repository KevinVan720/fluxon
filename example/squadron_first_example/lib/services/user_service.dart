/// Squadron-first user service with transparent cross-service method calls
library user_service;

import 'dart:async';
import 'package:dart_service_framework/dart_service_framework.dart';
import 'database_service.dart';
import 'cache_service.dart';

/// User service that demonstrates transparent cross-service method calls
@SquadronService()
class UserService extends SquadronService with SquadronServiceHandler {
  UserService() : super(serviceName: 'UserService');

  @override
  List<Type> get dependencies => [DatabaseService, CacheService];

  @override
  Future<void> initialize() async {
    await super.initialize();
    logger.info('User service initialized');
  }

  /// Create a new user - demonstrates transparent method calls
  @ServiceMethod(description: 'Create a new user with automatic caching')
  Future<Map<String, dynamic>> createUser({
    required String name,
    required String email,
    Map<String, dynamic> metadata = const {},
  }) async {
    logger.info('Creating user', metadata: {
      'name': name,
      'email': email,
    });

    // Get database service - this is the magic! No manual setup needed
    final database = getRequiredDependency<DatabaseService>();
    final cache = getDependency<CacheService>();

    // Create user in database - transparent method call across isolates!
    final user = await database.create('users', {
      'name': name,
      'email': email,
      'createdAt': DateTime.now().toIso8601String(),
      'metadata': metadata,
    });

    // Cache the user - another transparent method call!
    if (cache != null) {
      await cache.set('user:${user['id']}', user, ttl: const Duration(hours: 1));
      logger.debug('User cached', metadata: {'userId': user['id']});
    }

    // Send event about user creation
    final event = createEvent<UserCreatedEvent>(
      ({required eventId, required sourceService, required timestamp, correlationId, metadata = const {}}) =>
          UserCreatedEvent(
            eventId: eventId,
            sourceService: sourceService,
            timestamp: timestamp,
            correlationId: correlationId,
            metadata: metadata,
            userId: user['id'],
            userName: user['name'],
            userEmail: user['email'],
          ),
    );

    await broadcastEvent(event);

    logger.info('User created successfully', metadata: {'userId': user['id']});
    return user;
  }

  /// Get user by ID with cache-aside pattern
  @ServiceMethod(description: 'Get user by ID with automatic caching')
  Future<Map<String, dynamic>?> getUserById(String id) async {
    logger.debug('Getting user by ID', metadata: {'userId': id});

    final cache = getDependency<CacheService>();
    final database = getRequiredDependency<DatabaseService>();

    // Try cache first - transparent method call!
    if (cache != null) {
      final cached = await cache.get('user:$id');
      if (cached != null) {
        logger.debug('User found in cache', metadata: {'userId': id});
        return cached as Map<String, dynamic>;
      }
    }

    // Fallback to database - another transparent method call!
    final user = await database.findById('users', id);
    
    if (user != null && cache != null) {
      // Cache for next time - transparent method call!
      await cache.set('user:$id', user, ttl: const Duration(hours: 1));
      logger.debug('User cached from database', metadata: {'userId': id});
    }

    return user;
  }

  /// Search users by criteria
  @ServiceMethod(description: 'Search users with caching of results')
  Future<List<Map<String, dynamic>>> searchUsers(Map<String, dynamic> criteria) async {
    logger.debug('Searching users', metadata: {'criteria': criteria});

    final database = getRequiredDependency<DatabaseService>();
    final cache = getDependency<CacheService>();

    // Create cache key from criteria
    final cacheKey = 'search:users:${criteria.toString()}';

    // Try cache first
    if (cache != null) {
      final cached = await cache.get(cacheKey);
      if (cached != null) {
        logger.debug('Search results found in cache');
        return List<Map<String, dynamic>>.from(cached as List);
      }
    }

    // Search database - transparent method call!
    final results = await database.findWhere('users', criteria);

    // Cache results
    if (cache != null && results.isNotEmpty) {
      await cache.set(cacheKey, results, ttl: const Duration(minutes: 15));
      logger.debug('Search results cached', metadata: {'resultCount': results.length});
    }

    return results;
  }

  /// Update user with cache invalidation
  @ServiceMethod(description: 'Update user with automatic cache invalidation')
  Future<Map<String, dynamic>?> updateUser(String id, Map<String, dynamic> updates) async {
    logger.info('Updating user', metadata: {
      'userId': id,
      'updates': updates.keys.toList(),
    });

    final database = getRequiredDependency<DatabaseService>();
    final cache = getDependency<CacheService>();

    // Update in database - transparent method call!
    final updatedUser = await database.update('users', id, updates);

    if (updatedUser != null) {
      // Invalidate cache - transparent method call!
      if (cache != null) {
        await cache.remove('user:$id');
        logger.debug('User cache invalidated', metadata: {'userId': id});
      }

      // Send update event
      final event = createEvent<UserUpdatedEvent>(
        ({required eventId, required sourceService, required timestamp, correlationId, metadata = const {}}) =>
            UserUpdatedEvent(
              eventId: eventId,
              sourceService: sourceService,
              timestamp: timestamp,
              correlationId: correlationId,
              metadata: metadata,
              userId: id,
              updates: updates,
            ),
      );

      await broadcastEvent(event);
    }

    return updatedUser;
  }

  /// Delete user with cleanup
  @ServiceMethod(description: 'Delete user with cache cleanup')
  Future<bool> deleteUser(String id) async {
    logger.info('Deleting user', metadata: {'userId': id});

    final database = getRequiredDependency<DatabaseService>();
    final cache = getDependency<CacheService>();

    // Delete from database - transparent method call!
    final deleted = await database.delete('users', id);

    if (deleted) {
      // Clean up cache - transparent method call!
      if (cache != null) {
        await cache.remove('user:$id');
        logger.debug('User cache cleaned up', metadata: {'userId': id});
      }

      // Send deletion event
      final event = createEvent<UserDeletedEvent>(
        ({required eventId, required sourceService, required timestamp, correlationId, metadata = const {}}) =>
            UserDeletedEvent(
              eventId: eventId,
              sourceService: sourceService,
              timestamp: timestamp,
              correlationId: correlationId,
              metadata: metadata,
              userId: id,
            ),
      );

      await broadcastEvent(event);
    }

    return deleted;
  }

  /// Get user statistics - demonstrates multiple service coordination
  @ServiceMethod(description: 'Get user statistics from database and cache')
  Future<Map<String, dynamic>> getUserStats() async {
    logger.debug('Getting user statistics');

    final database = getRequiredDependency<DatabaseService>();
    final cache = getDependency<CacheService>();

    // Get database stats - transparent method call!
    final dbStats = await database.getTableStats('users');
    
    // Get cache stats - transparent method call!
    Map<String, dynamic> cacheStats = {};
    if (cache != null) {
      cacheStats = await cache.getStats();
    }

    return {
      'database': dbStats,
      'cache': cacheStats,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  @override
  Future<dynamic> handleWorkerRequest(WorkerRequest request) async {
    switch (request.name) {
      case 'createUser':
        final args = request.args[0] as Map<String, dynamic>;
        return await createUser(
          name: args['name'],
          email: args['email'],
          metadata: args['metadata'] ?? {},
        );
      case 'getUserById':
        return await getUserById(request.args[0]);
      case 'searchUsers':
        return await searchUsers(request.args[0]);
      case 'updateUser':
        return await updateUser(request.args[0], request.args[1]);
      case 'deleteUser':
        return await deleteUser(request.args[0]);
      case 'getUserStats':
        return await getUserStats();
      case 'healthCheck':
        return (await healthCheck()).toJson();
      default:
        return await super.handleWorkerRequest(request);
    }
  }
}

/// User-related events
class UserCreatedEvent extends ServiceEvent {
  const UserCreatedEvent({
    required super.eventId,
    required super.sourceService,
    required super.timestamp,
    super.correlationId,
    super.metadata = const {},
    required this.userId,
    required this.userName,
    required this.userEmail,
  });

  final String userId;
  final String userName;
  final String userEmail;

  @override
  Map<String, dynamic> eventDataToJson() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
    };
  }
}

class UserUpdatedEvent extends ServiceEvent {
  const UserUpdatedEvent({
    required super.eventId,
    required super.sourceService,
    required super.timestamp,
    super.correlationId,
    super.metadata = const {},
    required this.userId,
    required this.updates,
  });

  final String userId;
  final Map<String, dynamic> updates;

  @override
  Map<String, dynamic> eventDataToJson() {
    return {
      'userId': userId,
      'updates': updates,
    };
  }
}

class UserDeletedEvent extends ServiceEvent {
  const UserDeletedEvent({
    required super.eventId,
    required super.sourceService,
    required super.timestamp,
    super.correlationId,
    super.metadata = const {},
    required this.userId,
  });

  final String userId;

  @override
  Map<String, dynamic> eventDataToJson() {
    return {
      'userId': userId,
    };
  }
}

/// Entry point for the UserService Squadron worker
/// This function is embedded in the compiled binary and can be referenced directly
void userServiceEntryPoint(SendPort sendPort) async {
  final receivePort = ReceivePort();
  sendPort.send(receivePort.sendPort);

  UserService? service;
  final logger = ServiceLogger(serviceName: 'UserServiceWorker');

  try {
    // Initialize the service
    service = UserService();
    await service.initialize();
    
    logger.info('UserService worker started');

    await for (final message in receivePort) {
      try {
        if (message is Map<String, dynamic>) {
          final request = WorkerRequest.fromJson(message);
          final result = await service.handleWorkerRequest(request);
          sendPort.send({'success': true, 'result': result});
        } else {
          sendPort.send({'success': false, 'error': 'Invalid message format'});
        }
      } catch (error, stackTrace) {
        logger.error('Worker request failed', error: error, stackTrace: stackTrace);
        sendPort.send({'success': false, 'error': error.toString()});
      }
    }
  } catch (error, stackTrace) {
    logger.error('UserService worker failed to start', error: error, stackTrace: stackTrace);
    sendPort.send({'success': false, 'error': error.toString()});
  } finally {
    if (service != null) {
      try {
        await service.destroy();
      } catch (error) {
        logger.error('UserService cleanup failed', error: error);
      }
    }
  }
}
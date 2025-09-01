/// User service that orchestrates database and cache operations
library user_service;

import 'dart:async';
import 'package:dart_service_framework/dart_service_framework.dart';
import '../models/user.dart';
import '../events/user_events.dart';
import 'database_service.dart';
import 'cache_service.dart';

/// High-level user service that coordinates between database and cache
/// This service runs in the main isolate and communicates with worker services
class UserService extends BaseService with ServiceEventMixin {
  UserService({ServiceLogger? logger}) : super(logger: logger);

  @override
  List<Type> get dependencies => [DatabaseService];

  @override
  List<Type> get optionalDependencies => [CacheService];

  @override
  Future<void> initialize() async {
    logger.info('Initializing user service');
    // Dependencies will be injected automatically by the enhanced service locator
  }

  @override
  void onDependencyAvailable(Type serviceType, BaseService service) {
    super.onDependencyAvailable(serviceType, service);
    
    if (serviceType == DatabaseService) {
      logger.info('Database service became available');
    } else if (serviceType == CacheService) {
      logger.info('Cache service became available');
    }
  }

  /// Get the database service dependency
  DatabaseService get databaseService => getRequiredDependency<DatabaseService>();

  /// Get the cache service dependency (optional)
  CacheService? get cacheService => getDependency<CacheService>();

  /// Creates a new user with caching
  Future<User> createUser({
    required String name,
    required String email,
    Map<String, dynamic> metadata = const {},
  }) async {
    ensureInitialized();

    logger.info('Creating user', metadata: {'name': name, 'email': email});

    // Create user in database
    final user = await databaseService.createUser(
      name: name,
      email: email,
      metadata: metadata,
    );

    // Cache the new user if cache is available
    final cache = cacheService;
    if (cache != null) {
      try {
        await cache.cacheUser(user);
        logger.debug('New user cached', metadata: {'userId': user.id});
      } catch (e) {
        logger.warning('Failed to cache new user', metadata: {
          'userId': user.id,
          'error': e.toString(),
        });
      }
    }

    logger.info('User created successfully', metadata: {'userId': user.id});

    // Broadcast user created event
    final event = createEvent<UserCreatedEvent>(
      (
        {required eventId,
        required sourceService,
        required timestamp,
        correlationId,
        metadata = const {}}) => UserCreatedEvent(
        eventId: eventId,
        sourceService: sourceService,
        timestamp: timestamp,
        correlationId: correlationId,
        metadata: metadata,
        user: user,
        creationContext: {
          'method': 'createUser',
          'cached': cache != null,
        },
      ),
    );

    // Send to cache service first (if available), then broadcast to others
    final targets = cache != null 
        ? [EventTarget(serviceType: CacheService, waitUntilProcessed: false)]
        : <EventTarget>[];

    await sendEventTargetedThenBroadcast(
      event,
      targets,
      excludeServices: [DatabaseService], // Database already knows about the user
    );

    return user;
  }

  /// Gets a user by ID with cache-aside pattern
  Future<User?> getUserById(String id) async {
    ensureInitialized();

    logger.debug('Getting user by ID', metadata: {'userId': id});

    // Try cache first if available
    final cache = cacheService;
    if (cache != null) {
      try {
        final cachedUser = await cache.getCachedUser(id);
        if (cachedUser != null) {
          logger.debug('User found in cache', metadata: {'userId': id});
          return cachedUser;
        }
      } catch (e) {
        logger.warning('Cache lookup failed', metadata: {
          'userId': id,
          'error': e.toString(),
        });
      }
    }

    // Get from database
    final user = await databaseService.getUserById(id);
    
    if (user != null) {
      // Cache the user if cache is available
      if (cache != null) {
        try {
          await cache.cacheUser(user);
          logger.debug('User cached from database', metadata: {'userId': id});
        } catch (e) {
          logger.warning('Failed to cache user from database', metadata: {
            'userId': id,
            'error': e.toString(),
          });
        }
      }
      
      logger.debug('User found in database', metadata: {'userId': id});
    } else {
      logger.debug('User not found', metadata: {'userId': id});
    }

    return user;
  }

  /// Gets multiple users with batch caching
  Future<List<User>> getUsersByIds(List<String> ids) async {
    ensureInitialized();


    if (ids.isEmpty) return [];

    logger.debug('Getting users by IDs', metadata: {'count': ids.length});

    final users = <User>[];
    final uncachedIds = <String>[];

    // Try to get from cache first if available
    final cache = cacheService;
    if (cache != null) {
      try {
        final cachedUsers = await cache!.getCachedUsers(ids);
        final cachedUserIds = cachedUsers.map((u) => u.id).toSet();
        
        users.addAll(cachedUsers);
        uncachedIds.addAll(ids.where((id) => !cachedUserIds.contains(id)));
        
        logger.debug('Cache lookup completed', metadata: {
          'requested': ids.length,
          'cached': cachedUsers.length,
          'uncached': uncachedIds.length,
        });
      } catch (e) {
        logger.warning('Batch cache lookup failed', metadata: {
          'error': e.toString(),
        });
        uncachedIds.addAll(ids);
      }
    } else {
      uncachedIds.addAll(ids);
    }

    // Get remaining users from database
    if (uncachedIds.isNotEmpty) {
      final dbUsers = await databaseService.getUsersByIds(uncachedIds);
      users.addAll(dbUsers);

      // Cache the users from database if cache is available
      if (cache != null && dbUsers.isNotEmpty) {
        try {
          await cache!.cacheUsers(dbUsers);
          logger.debug('Batch cached users from database', metadata: {
            'count': dbUsers.length,
          });
        } catch (e) {
          logger.warning('Failed to batch cache users', metadata: {
            'error': e.toString(),
          });
        }
      }
    }

    logger.debug('Users retrieval completed', metadata: {
      'requested': ids.length,
      'found': users.length,
    });

    return users;
  }

  /// Searches for users with result caching
  Future<UserSearchResult> searchUsers(UserSearchCriteria criteria) async {
    ensureInitialized();


    logger.info('Searching users', metadata: criteria.toJson());

    // Create cache key from search criteria
    final searchKey = _createSearchKey(criteria);

    // Try cache first if available
    final cache = cacheService;
    if (cache != null) {
      try {
        final cachedResult = await cache!.getCachedSearchResult(searchKey);
        if (cachedResult != null) {
          logger.info('Search result found in cache', metadata: {
            'searchKey': searchKey,
            'resultCount': cachedResult.users.length,
          });
          return cachedResult;
        }
      } catch (e) {
        logger.warning('Search cache lookup failed', metadata: {
          'searchKey': searchKey,
          'error': e.toString(),
        });
      }
    }

    // Perform search in database
    final result = await databaseService.searchUsers(criteria);

    // Cache the search result if cache is available
    if (cache != null) {
      try {
        // Cache search results for shorter time since they can become stale
        await cache!.cacheSearchResult(
          searchKey, 
          result, 
          ttl: const Duration(minutes: 10),
        );
        logger.debug('Search result cached', metadata: {
          'searchKey': searchKey,
          'resultCount': result.users.length,
        });
      } catch (e) {
        logger.warning('Failed to cache search result', metadata: {
          'searchKey': searchKey,
          'error': e.toString(),
        });
      }
    }

    logger.info('User search completed', metadata: {
      'totalFound': result.totalCount,
      'returned': result.users.length,
      'searchTimeMs': result.searchTime.inMilliseconds,
    });

    // Broadcast search performed event
    final searchEvent = createEvent<UserSearchPerformedEvent>(
      ({required eventId,
        required sourceService,
        required timestamp,
        correlationId,
        metadata = const {}}) => UserSearchPerformedEvent(
        eventId: eventId,
        sourceService: sourceService,
        timestamp: timestamp,
        correlationId: correlationId,
        metadata: metadata,
        searchCriteria: criteria,
        resultCount: result.users.length,
        searchTime: result.searchTime,
        cacheHit: cache != null, // Simplified - would track actual cache hits
      ),
    );

    // Send notification to all services (fire-and-forget)
    await sendNotification(searchEvent);

    return result;
  }

  /// Updates a user with cache invalidation
  Future<User?> updateUser(String id, Map<String, dynamic> updates) async {
    ensureInitialized();


    logger.info('Updating user', metadata: {'userId': id, 'updates': updates});

    // Update in database
    final updatedUser = await databaseService.updateUser(id, updates);

    if (updatedUser != null) {
      // Update cache if available
      final cache = cacheService;
    if (cache != null) {
        try {
          await cache!.cacheUser(updatedUser);
          logger.debug('Updated user cached', metadata: {'userId': id});
        } catch (e) {
          logger.warning('Failed to update user cache', metadata: {
            'userId': id,
            'error': e.toString(),
          });
        }
      }

      logger.info('User updated successfully', metadata: {'userId': id});
    } else {
      logger.warning('User not found for update', metadata: {'userId': id});
    }

    return updatedUser;
  }

  /// Deletes a user with cache invalidation
  Future<bool> deleteUser(String id) async {
    ensureInitialized();


    logger.info('Deleting user', metadata: {'userId': id});

    // Delete from database
    final success = await databaseService.deleteUser(id);

    if (success) {
      // Remove from cache if available
      final cache = cacheService;
    if (cache != null) {
        try {
          await cache!.remove('user:$id');
          logger.debug('User removed from cache', metadata: {'userId': id});
        } catch (e) {
          logger.warning('Failed to remove user from cache', metadata: {
            'userId': id,
            'error': e.toString(),
          });
        }
      }

      logger.info('User deleted successfully', metadata: {'userId': id});
    } else {
      logger.warning('User not found for deletion', metadata: {'userId': id});
    }

    return success;
  }

  /// Gets user count
  Future<int> getUserCount() async {
    ensureInitialized();


    return await databaseService.getUserCount();
  }

  /// Gets user analytics
  Future<UserAnalytics> getAnalytics() async {
    ensureInitialized();


    logger.info('Generating user analytics');

    // Analytics are expensive, so cache them
    const cacheKey = 'analytics:users';
    
    final cache = cacheService;
    if (cache != null) {
      try {
        final cached = await cache!.get(cacheKey);
        if (cached != null) {
          final analytics = UserAnalytics.fromJson(cached);
          logger.info('Analytics found in cache');
          return analytics;
        }
      } catch (e) {
        logger.warning('Analytics cache lookup failed', metadata: {
          'error': e.toString(),
        });
      }
    }

    // Generate analytics from database
    final analytics = await databaseService.getAnalytics();

    // Cache analytics for 1 hour
    if (cache != null) {
      try {
        await cache!.set(
          cacheKey, 
          analytics.toJson(),
          ttl: const Duration(hours: 1),
        );
        logger.debug('Analytics cached');
      } catch (e) {
        logger.warning('Failed to cache analytics', metadata: {
          'error': e.toString(),
        });
      }
    }

    logger.info('Analytics generated', metadata: {
      'totalUsers': analytics.totalUsers,
      'activeUsers': analytics.activeUsers,
    });

    return analytics;
  }

  /// Gets service performance metrics
  Future<Map<String, dynamic>> getPerformanceMetrics() async {
    ensureInitialized();

    final metrics = <String, dynamic>{
      'userService': {
        'state': state.name,
        'initialized': isInitialized,
      },
    };

    // Get database health
    final dbService = getDependency<DatabaseService>();
    if (dbService != null) {
      try {
        final dbHealth = await dbService.healthCheck();
        metrics['database'] = {
          'status': dbHealth.status.name,
          'message': dbHealth.message,
          'details': dbHealth.details,
        };
      } catch (e) {
        metrics['database'] = {
          'status': 'error',
          'error': e.toString(),
        };
      }
    }

    // Get cache stats if available
    final cache = cacheService;
    if (cache != null) {
      try {
        final cacheStats = await cache!.getStats();
        final cacheHealth = await cache!.healthCheck();
        
        metrics['cache'] = {
          'status': cacheHealth.status.name,
          'stats': cacheStats.toJson(),
        };
      } catch (e) {
        metrics['cache'] = {
          'status': 'error',
          'error': e.toString(),
        };
      }
    } else {
      metrics['cache'] = {
        'status': 'not_available',
      };
    }

    return metrics;
  }

  @override
  Future<ServiceHealthCheck> healthCheck() async {
    if (!isInitialized) {
      return ServiceHealthCheck(
        status: ServiceHealthStatus.unhealthy,
        timestamp: DateTime.now(),
        message: 'User service not initialized',
      );
    }



    try {
      // Check database health
      final dbHealth = await databaseService.healthCheck();
      
      ServiceHealthStatus overallStatus;
      String message;
      
      if (dbHealth.status == ServiceHealthStatus.healthy) {
        overallStatus = ServiceHealthStatus.healthy;
        message = 'User service is healthy';
      } else if (dbHealth.status == ServiceHealthStatus.degraded) {
        overallStatus = ServiceHealthStatus.degraded;
        message = 'User service degraded due to database issues';
      } else {
        overallStatus = ServiceHealthStatus.unhealthy;
        message = 'User service unhealthy due to database issues';
      }

      return ServiceHealthCheck(
        status: overallStatus,
        timestamp: DateTime.now(),
        message: message,
        details: {
          'database': dbHealth.toJson(),
          'cache': cacheService != null ? 'available' : 'not_available',
        },
      );
    } catch (e) {
      return ServiceHealthCheck(
        status: ServiceHealthStatus.unhealthy,
        timestamp: DateTime.now(),
        message: 'Health check failed: $e',
      );
    }
  }

  // Private helper methods

  String _createSearchKey(UserSearchCriteria criteria) {
    // Create a deterministic cache key from search criteria
    final parts = <String>[];
    
    if (criteria.namePattern != null) {
      parts.add('name:${criteria.namePattern}');
    }
    if (criteria.emailPattern != null) {
      parts.add('email:${criteria.emailPattern}');
    }
    if (criteria.isActive != null) {
      parts.add('active:${criteria.isActive}');
    }
    if (criteria.createdAfter != null) {
      parts.add('after:${criteria.createdAfter!.millisecondsSinceEpoch}');
    }
    if (criteria.createdBefore != null) {
      parts.add('before:${criteria.createdBefore!.millisecondsSinceEpoch}');
    }
    if (criteria.tags.isNotEmpty) {
      parts.add('tags:${criteria.tags.join(',')}');
    }
    
    parts.add('limit:${criteria.limit}');
    parts.add('offset:${criteria.offset}');
    
    return parts.join('|');
  }
}
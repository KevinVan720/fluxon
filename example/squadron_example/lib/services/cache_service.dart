/// Cache service that runs in a Squadron worker isolate
library cache_service;

import 'dart:async';
import 'dart:convert';
import 'package:squadron/squadron.dart';
import 'package:dart_service_framework/dart_service_framework.dart';
import '../models/user.dart';
import '../events/user_events.dart';

/// Cache entry with expiration
class CacheEntry {
  const CacheEntry({
    required this.data,
    required this.createdAt,
    required this.expiresAt,
  });

  final Map<String, dynamic> data;
  final DateTime createdAt;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
    };
  }

  factory CacheEntry.fromJson(Map<String, dynamic> json) {
    return CacheEntry(
      data: Map<String, dynamic>.from(json['data'] as Map),
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }
}

/// Cache statistics
class CacheStats {
  const CacheStats({
    required this.totalEntries,
    required this.hits,
    required this.misses,
    required this.evictions,
    required this.memoryUsageBytes,
    required this.averageAccessTime,
  });

  final int totalEntries;
  final int hits;
  final int misses;
  final int evictions;
  final int memoryUsageBytes;
  final Duration averageAccessTime;

  double get hitRate => (hits + misses) > 0 ? hits / (hits + misses) : 0.0;

  Map<String, dynamic> toJson() {
    return {
      'totalEntries': totalEntries,
      'hits': hits,
      'misses': misses,
      'evictions': evictions,
      'memoryUsageBytes': memoryUsageBytes,
      'averageAccessTimeMicros': averageAccessTime.inMicroseconds,
      'hitRate': hitRate,
    };
  }

  factory CacheStats.fromJson(Map<String, dynamic> json) {
    return CacheStats(
      totalEntries: json['totalEntries'] as int,
      hits: json['hits'] as int,
      misses: json['misses'] as int,
      evictions: json['evictions'] as int,
      memoryUsageBytes: json['memoryUsageBytes'] as int,
      averageAccessTime: Duration(microseconds: json['averageAccessTimeMicros'] as int),
    );
  }

  @override
  String toString() {
    return 'CacheStats(entries: $totalEntries, hitRate: ${(hitRate * 100).toStringAsFixed(1)}%, memory: ${(memoryUsageBytes / 1024).toStringAsFixed(1)}KB)';
  }
}

/// Squadron cache service that runs in its own isolate
@SquadronService()
class CacheService extends BaseService with ServiceEventMixin {
  CacheService({ServiceLogger? logger}) : super(logger: logger);

  // Cache storage
  final Map<String, CacheEntry> _cache = {};
  
  // Statistics
  int _hits = 0;
  int _misses = 0;
  int _evictions = 0;
  final List<Duration> _accessTimes = [];
  
  // Configuration
  static const int maxEntries = 1000;
  static const Duration defaultTtl = Duration(minutes: 30);

  @override
  List<Type> get dependencies => const [];

  @override
  Future<void> initialize() async {
    logger.info('Initializing cache service in isolate');
    
    // Start cleanup timer
    Timer.periodic(const Duration(minutes: 5), (_) => _cleanupExpiredEntries());
    
    // Set up event listeners
    _setupEventListeners();
    
    logger.info('Cache service initialized');
  }

  /// Set up event listeners for cache management
  void _setupEventListeners() {
    // Listen for user created events to pre-cache users
    onEvent<UserCreatedEvent>((event) async {
      logger.debug('Received user created event', metadata: {
        'userId': event.user.id,
        'userName': event.user.name,
      });

      // Pre-cache the new user
      await cacheUser(event.user);

      return EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration(milliseconds: 10),
        data: {'cached': true, 'userId': event.user.id},
      );
    }, priority: 10); // High priority for caching

    // Listen for user updated events to invalidate cache
    onEvent<UserUpdatedEvent>((event) async {
      logger.debug('Received user updated event', metadata: {
        'userId': event.userId,
        'changes': event.changes,
      });

      // Remove old cached version
      await remove('user:${event.userId}');

      return EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration(milliseconds: 5),
        data: {'invalidated': true, 'userId': event.userId},
      );
    });

    // Listen for user deleted events to clean up cache
    onEvent<UserDeletedEvent>((event) async {
      logger.debug('Received user deleted event', metadata: {
        'userId': event.userId,
        'reason': event.deletionReason,
      });

      // Remove from cache
      await remove('user:${event.userId}');

      return EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration(milliseconds: 5),
        data: {'removed': true, 'userId': event.userId},
      );
    });

    // Listen for search events to track popular searches
    onEvent<UserSearchPerformedEvent>((event) async {
      logger.debug('Received search performed event', metadata: {
        'resultCount': event.resultCount,
        'searchTime': event.searchTime.inMilliseconds,
        'cacheHit': event.cacheHit,
      });

      // Could implement search result caching logic here
      // For now, just acknowledge the event

      return EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration(milliseconds: 1),
        data: {'tracked': true},
      );
    });

    logger.debug('Event listeners set up for cache service');
  }

  @override
  Future<void> destroy() async {
    logger.info('Destroying cache service');
    _cache.clear();
    _accessTimes.clear();
    logger.info('Cache service destroyed');
  }

  /// Sets a value in the cache
  @SquadronMethod()
  Future<void> set(String key, Map<String, dynamic> value, {Duration? ttl}) async {
    ensureInitialized();
    
    final stopwatch = Stopwatch()..start();
    
    final expiresAt = DateTime.now().add(ttl ?? defaultTtl);
    final entry = CacheEntry(
      data: Map<String, dynamic>.from(value),
      createdAt: DateTime.now(),
      expiresAt: expiresAt,
    );

    // Evict if at capacity
    if (_cache.length >= maxEntries && !_cache.containsKey(key)) {
      _evictLeastRecentlyUsed();
    }

    _cache[key] = entry;
    
    stopwatch.stop();
    _recordAccessTime(stopwatch.elapsed);

    logger.debug('Cache set', metadata: {
      'key': key,
      'ttlSeconds': (ttl ?? defaultTtl).inSeconds,
      'size': _estimateSize(value),
    });
  }

  /// Gets a value from the cache
  @SquadronMethod()
  Future<Map<String, dynamic>?> get(String key) async {
    ensureInitialized();
    
    final stopwatch = Stopwatch()..start();
    
    final entry = _cache[key];
    
    if (entry == null) {
      _misses++;
      stopwatch.stop();
      _recordAccessTime(stopwatch.elapsed);
      
      logger.debug('Cache miss', metadata: {'key': key});
      return null;
    }

    if (entry.isExpired) {
      _cache.remove(key);
      _misses++;
      stopwatch.stop();
      _recordAccessTime(stopwatch.elapsed);
      
      logger.debug('Cache expired', metadata: {'key': key});
      return null;
    }

    _hits++;
    stopwatch.stop();
    _recordAccessTime(stopwatch.elapsed);

    logger.debug('Cache hit', metadata: {'key': key});
    return Map<String, dynamic>.from(entry.data);
  }

  /// Gets multiple values from the cache
  @SquadronMethod()
  Future<Map<String, Map<String, dynamic>>> getMultiple(List<String> keys) async {
    ensureInitialized();
    
    final stopwatch = Stopwatch()..start();
    final result = <String, Map<String, dynamic>>{};
    
    for (final key in keys) {
      final entry = _cache[key];
      
      if (entry != null && !entry.isExpired) {
        result[key] = Map<String, dynamic>.from(entry.data);
        _hits++;
      } else {
        if (entry?.isExpired == true) {
          _cache.remove(key);
        }
        _misses++;
      }
    }
    
    stopwatch.stop();
    _recordAccessTime(stopwatch.elapsed);

    logger.debug('Cache multi-get', metadata: {
      'requested': keys.length,
      'found': result.length,
    });

    return result;
  }

  /// Removes a value from the cache
  @SquadronMethod()
  Future<bool> remove(String key) async {
    ensureInitialized();
    
    final removed = _cache.remove(key) != null;
    
    logger.debug('Cache remove', metadata: {'key': key, 'found': removed});
    return removed;
  }

  /// Removes multiple values from the cache
  @SquadronMethod()
  Future<int> removeMultiple(List<String> keys) async {
    ensureInitialized();
    
    int removedCount = 0;
    for (final key in keys) {
      if (_cache.remove(key) != null) {
        removedCount++;
      }
    }
    
    logger.debug('Cache multi-remove', metadata: {
      'requested': keys.length,
      'removed': removedCount,
    });

    return removedCount;
  }

  /// Checks if a key exists in the cache
  @SquadronMethod()
  Future<bool> exists(String key) async {
    ensureInitialized();
    
    final entry = _cache[key];
    if (entry == null) return false;
    
    if (entry.isExpired) {
      _cache.remove(key);
      return false;
    }
    
    return true;
  }

  /// Clears all cache entries
  @SquadronMethod()
  Future<void> clear() async {
    ensureInitialized();
    
    final count = _cache.length;
    _cache.clear();
    
    logger.info('Cache cleared', metadata: {'entriesRemoved': count});
  }

  /// Gets cache statistics
  @SquadronMethod()
  Future<CacheStats> getStats() async {
    ensureInitialized();
    
    final memoryUsage = _estimateMemoryUsage();
    final avgAccessTime = _accessTimes.isEmpty 
        ? Duration.zero 
        : Duration(microseconds: 
            _accessTimes.map((d) => d.inMicroseconds).reduce((a, b) => a + b) ~/ _accessTimes.length);

    final stats = CacheStats(
      totalEntries: _cache.length,
      hits: _hits,
      misses: _misses,
      evictions: _evictions,
      memoryUsageBytes: memoryUsage,
      averageAccessTime: avgAccessTime,
    );

    logger.debug('Cache stats requested', metadata: stats.toJson());
    return stats;
  }

  /// Performs cache cleanup
  @SquadronMethod()
  Future<int> cleanup() async {
    ensureInitialized();
    
    return _cleanupExpiredEntries();
  }

  /// Cache-specific user methods

  /// Caches a user object
  @SquadronMethod()
  Future<void> cacheUser(User user, {Duration? ttl}) async {
    await set('user:${user.id}', user.toJson(), ttl: ttl);
  }

  /// Gets a cached user
  @SquadronMethod()
  Future<User?> getCachedUser(String userId) async {
    final data = await get('user:$userId');
    if (data == null) return null;
    
    try {
      return User.fromJson(data);
    } catch (e) {
      logger.warning('Failed to deserialize cached user', metadata: {
        'userId': userId,
        'error': e.toString(),
      });
      await remove('user:$userId'); // Remove corrupted entry
      return null;
    }
  }

  /// Caches multiple users
  @SquadronMethod()
  Future<void> cacheUsers(List<User> users, {Duration? ttl}) async {
    for (final user in users) {
      await cacheUser(user, ttl: ttl);
    }
    
    logger.debug('Cached multiple users', metadata: {'count': users.length});
  }

  /// Gets multiple cached users
  @SquadronMethod()
  Future<List<User>> getCachedUsers(List<String> userIds) async {
    final keys = userIds.map((id) => 'user:$id').toList();
    final cached = await getMultiple(keys);
    
    final users = <User>[];
    for (final entry in cached.entries) {
      try {
        final user = User.fromJson(entry.value);
        users.add(user);
      } catch (e) {
        logger.warning('Failed to deserialize cached user', metadata: {
          'key': entry.key,
          'error': e.toString(),
        });
        await remove(entry.key); // Remove corrupted entry
      }
    }
    
    return users;
  }

  /// Caches user search results
  @SquadronMethod()
  Future<void> cacheSearchResult(String searchKey, UserSearchResult result, {Duration? ttl}) async {
    await set('search:$searchKey', result.toJson(), ttl: ttl);
  }

  /// Gets cached search results
  @SquadronMethod()
  Future<UserSearchResult?> getCachedSearchResult(String searchKey) async {
    final data = await get('search:$searchKey');
    if (data == null) return null;
    
    try {
      return UserSearchResult.fromJson(data);
    } catch (e) {
      logger.warning('Failed to deserialize cached search result', metadata: {
        'searchKey': searchKey,
        'error': e.toString(),
      });
      await remove('search:$searchKey');
      return null;
    }
  }

  @SquadronMethod()
  @override
  Future<ServiceHealthCheck> healthCheck() async {
    final stats = await getStats();
    
    // Determine health based on cache performance
    ServiceHealthStatus status;
    String message;
    
    if (stats.hitRate > 0.8) {
      status = ServiceHealthStatus.healthy;
      message = 'Cache performing well';
    } else if (stats.hitRate > 0.5) {
      status = ServiceHealthStatus.degraded;
      message = 'Cache hit rate below optimal';
    } else {
      status = ServiceHealthStatus.unhealthy;
      message = 'Poor cache performance';
    }

    return ServiceHealthCheck(
      status: status,
      timestamp: DateTime.now(),
      message: message,
      details: {
        'stats': stats.toJson(),
        'isolateId': 'cache_worker',
      },
    );
  }

  // Private helper methods

  void _evictLeastRecentlyUsed() {
    if (_cache.isEmpty) return;
    
    // Simple LRU: remove oldest entry by creation time
    String? oldestKey;
    DateTime? oldestTime;
    
    for (final entry in _cache.entries) {
      if (oldestTime == null || entry.value.createdAt.isBefore(oldestTime)) {
        oldestTime = entry.value.createdAt;
        oldestKey = entry.key;
      }
    }
    
    if (oldestKey != null) {
      _cache.remove(oldestKey);
      _evictions++;
      
      logger.debug('Cache eviction', metadata: {'key': oldestKey});
    }
  }

  int _cleanupExpiredEntries() {
    final now = DateTime.now();
    final expiredKeys = <String>[];
    
    for (final entry in _cache.entries) {
      if (entry.value.expiresAt.isBefore(now)) {
        expiredKeys.add(entry.key);
      }
    }
    
    for (final key in expiredKeys) {
      _cache.remove(key);
    }
    
    if (expiredKeys.isNotEmpty) {
      logger.debug('Cleaned up expired entries', metadata: {'count': expiredKeys.length});
    }
    
    return expiredKeys.length;
  }

  int _estimateSize(Map<String, dynamic> data) {
    // Simple size estimation based on JSON string length
    try {
      return jsonEncode(data).length;
    } catch (e) {
      return 0;
    }
  }

  int _estimateMemoryUsage() {
    int totalSize = 0;
    for (final entry in _cache.values) {
      totalSize += _estimateSize(entry.data);
      totalSize += 100; // Overhead for CacheEntry object
    }
    return totalSize;
  }

  void _recordAccessTime(Duration duration) {
    _accessTimes.add(duration);
    
    // Keep only recent access times to prevent memory growth
    if (_accessTimes.length > 1000) {
      _accessTimes.removeRange(0, 500);
    }
  }
}
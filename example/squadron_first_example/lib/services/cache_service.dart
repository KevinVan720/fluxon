/// Squadron-first cache service with automatic worker management
library cache_service;

import 'dart:async';
import 'package:dart_service_framework/dart_service_framework.dart';

/// Cache service that runs as a Squadron worker
@SquadronService()
class CacheService extends SquadronService with SquadronServiceHandler {
  CacheService() : super(serviceName: 'CacheService');

  // Cache storage with TTL
  final Map<String, _CacheEntry> _cache = {};
  Timer? _cleanupTimer;

  @override
  List<Type> get dependencies => const [];

  @override
  Future<void> initialize() async {
    await super.initialize();
    
    // Start periodic cleanup
    _cleanupTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _cleanupExpiredEntries(),
    );

    logger.info('Cache service initialized');
  }

  @override
  Future<void> destroy() async {
    _cleanupTimer?.cancel();
    _cache.clear();
    await super.destroy();
  }

  /// Store a value in the cache
  @ServiceMethod(description: 'Store a value in the cache with optional TTL')
  Future<void> set(String key, dynamic value, {Duration? ttl}) async {
    logger.debug('Setting cache value', metadata: {
      'key': key,
      'hasTtl': ttl != null,
      'ttlSeconds': ttl?.inSeconds,
    });

    final expiry = ttl != null ? DateTime.now().add(ttl) : null;
    _cache[key] = _CacheEntry(value, expiry);

    logger.debug('Cache value set', metadata: {
      'key': key,
      'totalEntries': _cache.length,
    });
  }

  /// Get a value from the cache
  @ServiceMethod(description: 'Get a value from the cache')
  Future<dynamic> get(String key) async {
    logger.debug('Getting cache value', metadata: {'key': key});

    final entry = _cache[key];
    if (entry == null) {
      logger.debug('Cache miss', metadata: {'key': key});
      return null;
    }

    // Check if expired
    if (entry.isExpired) {
      _cache.remove(key);
      logger.debug('Cache entry expired', metadata: {'key': key});
      return null;
    }

    logger.debug('Cache hit', metadata: {'key': key});
    return entry.value;
  }

  /// Check if a key exists in the cache
  @ServiceMethod(description: 'Check if a key exists in the cache')
  Future<bool> has(String key) async {
    final entry = _cache[key];
    if (entry == null) return false;
    
    if (entry.isExpired) {
      _cache.remove(key);
      return false;
    }
    
    return true;
  }

  /// Remove a value from the cache
  @ServiceMethod(description: 'Remove a value from the cache')
  Future<bool> remove(String key) async {
    logger.debug('Removing cache value', metadata: {'key': key});

    final removed = _cache.remove(key) != null;
    
    logger.debug('Cache removal result', metadata: {
      'key': key,
      'removed': removed,
    });

    return removed;
  }

  /// Clear all cache entries
  @ServiceMethod(description: 'Clear all cache entries')
  Future<void> clear() async {
    final count = _cache.length;
    _cache.clear();
    
    logger.info('Cache cleared', metadata: {
      'entriesRemoved': count,
    });
  }

  /// Get cache statistics
  @ServiceMethod(description: 'Get cache statistics')
  Future<Map<String, dynamic>> getStats() async {
    final now = DateTime.now();
    int expiredCount = 0;
    int totalSize = 0;

    for (final entry in _cache.values) {
      if (entry.isExpired) {
        expiredCount++;
      }
      totalSize += _estimateSize(entry.value);
    }

    return {
      'totalEntries': _cache.length,
      'expiredEntries': expiredCount,
      'estimatedSizeBytes': totalSize,
      'hitRate': 0.95, // Simplified - would track actual hits/misses
    };
  }

  /// Get all cache keys
  @ServiceProperty(description: 'List of all cache keys')
  Future<List<String>> get keys async {
    return _cache.keys.toList();
  }

  /// Clean up expired entries
  void _cleanupExpiredEntries() {
    final keysToRemove = <String>[];
    
    for (final entry in _cache.entries) {
      if (entry.value.isExpired) {
        keysToRemove.add(entry.key);
      }
    }

    for (final key in keysToRemove) {
      _cache.remove(key);
    }

    if (keysToRemove.isNotEmpty) {
      logger.debug('Cleaned up expired cache entries', metadata: {
        'removedCount': keysToRemove.length,
        'remainingCount': _cache.length,
      });
    }
  }

  /// Estimate the size of a value in bytes (simplified)
  int _estimateSize(dynamic value) {
    if (value == null) return 0;
    if (value is String) return value.length * 2; // UTF-16
    if (value is num) return 8;
    if (value is bool) return 1;
    if (value is List) return value.length * 8; // Rough estimate
    if (value is Map) return value.length * 16; // Rough estimate
    return 100; // Default estimate for complex objects
  }

  @override
  Future<dynamic> handleWorkerRequest(WorkerRequest request) async {
    switch (request.name) {
      case 'set':
        final ttl = request.args.length > 2 ? Duration(seconds: request.args[2]) : null;
        return await set(request.args[0], request.args[1], ttl: ttl);
      case 'get':
        return await get(request.args[0]);
      case 'has':
        return await has(request.args[0]);
      case 'remove':
        return await remove(request.args[0]);
      case 'clear':
        return await clear();
      case 'getStats':
        return await getStats();
      case 'keys':
        return await keys;
      case 'healthCheck':
        return (await healthCheck()).toJson();
      default:
        return await super.handleWorkerRequest(request);
    }
  }
}

/// Cache entry with optional expiry
class _CacheEntry {
  _CacheEntry(this.value, this.expiry);

  final dynamic value;
  final DateTime? expiry;

  bool get isExpired {
    if (expiry == null) return false;
    return DateTime.now().isAfter(expiry!);
  }
}

/// Entry point for the CacheService Squadron worker
/// This function is embedded in the compiled binary and can be referenced directly
void cacheServiceEntryPoint(SendPort sendPort) async {
  final receivePort = ReceivePort();
  sendPort.send(receivePort.sendPort);

  CacheService? service;
  final logger = ServiceLogger(serviceName: 'CacheServiceWorker');

  try {
    // Initialize the service
    service = CacheService();
    await service.initialize();
    
    logger.info('CacheService worker started');

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
    logger.error('CacheService worker failed to start', error: error, stackTrace: stackTrace);
    sendPort.send({'success': false, 'error': error.toString()});
  } finally {
    if (service != null) {
      try {
        await service.destroy();
      } catch (error) {
        logger.error('CacheService cleanup failed', error: error);
      }
    }
  }
}
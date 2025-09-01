/// Database service that runs in a Squadron worker isolate
library database_service;

import 'dart:async';
import 'dart:math';
import 'package:squadron/squadron.dart';
import 'package:dart_service_framework/dart_service_framework.dart';
import '../models/user.dart';

/// Squadron service for database operations
/// This service runs in its own isolate for CPU-intensive operations
@SquadronService()
class DatabaseService extends BaseService {
  DatabaseService({ServiceLogger? logger}) : super(logger: logger);

  // In-memory database simulation
  final Map<String, User> _users = {};
  final Random _random = Random();
  bool _isConnected = false;

  @override
  List<Type> get dependencies => const [];

  @override
  Future<void> initialize() async {
    logger.info('Initializing database service in isolate');
    await _simulateConnection();
    await _seedDatabase();
    _isConnected = true;
    logger.info('Database service initialized with ${_users.length} users');
  }

  @override
  Future<void> destroy() async {
    logger.info('Destroying database service');
    _users.clear();
    _isConnected = false;
    logger.info('Database service destroyed');
  }

  /// Creates a new user
  @SquadronMethod()
  Future<User> createUser({
    required String name,
    required String email,
    Map<String, dynamic> metadata = const {},
  }) async {
    ensureInitialized();
    logger.info('Creating user', metadata: {'name': name, 'email': email});

    // Simulate some processing time
    await Future.delayed(Duration(milliseconds: _random.nextInt(50) + 10));

    final user = User(
      id: _generateId(),
      name: name,
      email: email,
      createdAt: DateTime.now(),
      metadata: metadata,
    );

    _users[user.id] = user;
    
    logger.info('User created successfully', metadata: {'userId': user.id});
    return user;
  }

  /// Gets a user by ID
  @SquadronMethod()
  Future<User?> getUserById(String id) async {
    ensureInitialized();
    logger.debug('Fetching user by ID', metadata: {'userId': id});

    // Simulate database query time
    await Future.delayed(Duration(milliseconds: _random.nextInt(20) + 5));

    final user = _users[id];
    if (user != null) {
      logger.debug('User found', metadata: {'userId': id});
    } else {
      logger.debug('User not found', metadata: {'userId': id});
    }

    return user;
  }

  /// Gets multiple users by IDs
  @SquadronMethod()
  Future<List<User>> getUsersByIds(List<String> ids) async {
    ensureInitialized();
    logger.debug('Fetching users by IDs', metadata: {'count': ids.length});

    // Simulate batch query time
    await Future.delayed(Duration(milliseconds: ids.length * 2 + 10));

    final users = <User>[];
    for (final id in ids) {
      final user = _users[id];
      if (user != null) {
        users.add(user);
      }
    }

    logger.debug('Users fetched', metadata: {
      'requested': ids.length,
      'found': users.length,
    });

    return users;
  }

  /// Searches for users based on criteria
  @SquadronMethod()
  Future<UserSearchResult> searchUsers(UserSearchCriteria criteria) async {
    ensureInitialized();
    logger.info('Searching users', metadata: criteria.toJson());

    final stopwatch = Stopwatch()..start();

    // Simulate complex search operation
    await Future.delayed(Duration(milliseconds: _random.nextInt(100) + 50));

    var filteredUsers = _users.values.where((user) {
      // Name pattern matching
      if (criteria.namePattern != null) {
        if (!user.name.toLowerCase().contains(criteria.namePattern!.toLowerCase())) {
          return false;
        }
      }

      // Email pattern matching
      if (criteria.emailPattern != null) {
        if (!user.email.toLowerCase().contains(criteria.emailPattern!.toLowerCase())) {
          return false;
        }
      }

      // Active status filter
      if (criteria.isActive != null && user.isActive != criteria.isActive) {
        return false;
      }

      // Date range filters
      if (criteria.createdAfter != null && user.createdAt.isBefore(criteria.createdAfter!)) {
        return false;
      }

      if (criteria.createdBefore != null && user.createdAt.isAfter(criteria.createdBefore!)) {
        return false;
      }

      return true;
    }).toList();

    // Sort by creation date (newest first)
    filteredUsers.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final totalCount = filteredUsers.length;
    final hasMore = criteria.offset + criteria.limit < totalCount;

    // Apply pagination
    final startIndex = criteria.offset;
    final endIndex = (startIndex + criteria.limit).clamp(0, filteredUsers.length);
    final paginatedUsers = filteredUsers.sublist(startIndex, endIndex);

    stopwatch.stop();

    final result = UserSearchResult(
      users: paginatedUsers,
      totalCount: totalCount,
      hasMore: hasMore,
      searchTime: stopwatch.elapsed,
    );

    logger.info('User search completed', metadata: {
      'totalFound': totalCount,
      'returned': paginatedUsers.length,
      'searchTimeMs': stopwatch.elapsedMilliseconds,
    });

    return result;
  }

  /// Updates a user
  @SquadronMethod()
  Future<User?> updateUser(String id, Map<String, dynamic> updates) async {
    ensureInitialized();
    logger.info('Updating user', metadata: {'userId': id, 'updates': updates});

    // Simulate update operation
    await Future.delayed(Duration(milliseconds: _random.nextInt(30) + 10));

    final existingUser = _users[id];
    if (existingUser == null) {
      logger.warning('User not found for update', metadata: {'userId': id});
      return null;
    }

    final updatedUser = existingUser.copyWith(
      name: updates['name'] as String? ?? existingUser.name,
      email: updates['email'] as String? ?? existingUser.email,
      isActive: updates['isActive'] as bool? ?? existingUser.isActive,
      metadata: updates['metadata'] as Map<String, dynamic>? ?? existingUser.metadata,
    );

    _users[id] = updatedUser;
    
    logger.info('User updated successfully', metadata: {'userId': id});
    return updatedUser;
  }

  /// Deletes a user
  @SquadronMethod()
  Future<bool> deleteUser(String id) async {
    ensureInitialized();
    logger.info('Deleting user', metadata: {'userId': id});

    // Simulate delete operation
    await Future.delayed(Duration(milliseconds: _random.nextInt(20) + 5));

    final removed = _users.remove(id);
    final success = removed != null;

    if (success) {
      logger.info('User deleted successfully', metadata: {'userId': id});
    } else {
      logger.warning('User not found for deletion', metadata: {'userId': id});
    }

    return success;
  }

  /// Gets user count
  @SquadronMethod()
  Future<int> getUserCount() async {
    ensureInitialized();
    logger.debug('Getting user count');

    // Simulate count query
    await Future.delayed(Duration(milliseconds: 5));

    return _users.length;
  }

  /// Gets analytics data
  @SquadronMethod()
  Future<UserAnalytics> getAnalytics() async {
    ensureInitialized();
    logger.info('Generating user analytics');

    // Simulate complex analytics computation
    await Future.delayed(Duration(milliseconds: _random.nextInt(200) + 100));

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final totalUsers = _users.length;
    final activeUsers = _users.values.where((user) => user.isActive).length;
    final newUsersToday = _users.values
        .where((user) => user.createdAt.isAfter(today))
        .length;

    // Calculate average profile score (simulated)
    final averageProfileScore = _users.isEmpty 
        ? 0.0 
        : _users.values
            .map((user) => _calculateProfileScore(user))
            .reduce((a, b) => a + b) / _users.length;

    // Calculate top tags from metadata
    final tagCounts = <String, int>{};
    for (final user in _users.values) {
      final tags = user.metadata['tags'] as List<String>? ?? [];
      for (final tag in tags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }

    // Get top 10 tags
    final topTags = Map.fromEntries(
      tagCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value))
        ..take(10)
    );

    final analytics = UserAnalytics(
      totalUsers: totalUsers,
      activeUsers: activeUsers,
      newUsersToday: newUsersToday,
      averageProfileScore: averageProfileScore,
      topTags: topTags,
      generatedAt: DateTime.now(),
    );

    logger.info('Analytics generated', metadata: {
      'totalUsers': totalUsers,
      'activeUsers': activeUsers,
      'newUsersToday': newUsersToday,
    });

    return analytics;
  }

  /// Performs a health check
  @SquadronMethod()
  @override
  Future<ServiceHealthCheck> healthCheck() async {
    if (!_isConnected) {
      return ServiceHealthCheck(
        status: ServiceHealthStatus.unhealthy,
        timestamp: DateTime.now(),
        message: 'Database not connected',
        details: {'connected': false},
      );
    }

    // Simulate health check query
    await Future.delayed(Duration(milliseconds: 10));

    return ServiceHealthCheck(
      status: ServiceHealthStatus.healthy,
      timestamp: DateTime.now(),
      message: 'Database is healthy',
      details: {
        'connected': true,
        'userCount': _users.length,
        'isolateId': 'database_worker',
      },
    );
  }

  // Private helper methods

  Future<void> _simulateConnection() async {
    logger.debug('Connecting to database...');
    // Simulate connection time
    await Future.delayed(Duration(milliseconds: _random.nextInt(100) + 50));
    logger.debug('Database connection established');
  }

  Future<void> _seedDatabase() async {
    logger.debug('Seeding database with sample data');

    final sampleUsers = [
      {'name': 'Alice Johnson', 'email': 'alice@example.com', 'tags': ['developer', 'senior']},
      {'name': 'Bob Smith', 'email': 'bob@example.com', 'tags': ['designer', 'junior']},
      {'name': 'Carol Davis', 'email': 'carol@example.com', 'tags': ['manager', 'senior']},
      {'name': 'David Wilson', 'email': 'david@example.com', 'tags': ['developer', 'junior']},
      {'name': 'Eve Brown', 'email': 'eve@example.com', 'tags': ['analyst', 'senior']},
    ];

    for (final userData in sampleUsers) {
      final user = User(
        id: _generateId(),
        name: userData['name'] as String,
        email: userData['email'] as String,
        createdAt: DateTime.now().subtract(Duration(days: _random.nextInt(30))),
        metadata: {'tags': userData['tags']},
      );
      _users[user.id] = user;
    }

    logger.debug('Database seeded with ${_users.length} sample users');
  }

  String _generateId() {
    return 'user_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(1000)}';
  }

  double _calculateProfileScore(User user) {
    // Simulate profile score calculation
    double score = 50.0; // Base score

    // Age factor (newer users get bonus)
    final daysSinceCreation = DateTime.now().difference(user.createdAt).inDays;
    if (daysSinceCreation < 7) score += 20;
    else if (daysSinceCreation < 30) score += 10;

    // Activity factor
    if (user.isActive) score += 15;

    // Tags factor
    final tags = user.metadata['tags'] as List<String>? ?? [];
    score += tags.length * 5;

    return score.clamp(0.0, 100.0);
  }
}
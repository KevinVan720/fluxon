import 'package:dart_service_framework/dart_service_framework.dart';

/// Example database service
class DatabaseService extends BaseService {
  bool _connected = false;

  @override
  List<Type> get dependencies => const [];

  @override
  Future<void> initialize() async {
    logger.info('Connecting to database');
    await Future.delayed(
        const Duration(milliseconds: 100)); // Simulate connection
    _connected = true;
    logger.info('Database connected successfully');
  }

  @override
  Future<void> destroy() async {
    logger.info('Disconnecting from database');
    _connected = false;
    logger.info('Database disconnected');
  }

  bool get isConnected => _connected;

  Future<Map<String, dynamic>> getUser(String id) async {
    ensureInitialized();
    logger.debug('Fetching user', metadata: {'userId': id});

    if (!_connected) {
      throw Exception('Database not connected');
    }

    // Simulate database query
    await Future.delayed(const Duration(milliseconds: 10));

    return {
      'id': id,
      'name': 'User $id',
      'email': 'user$id@example.com',
    };
  }

  @override
  Future<ServiceHealthCheck> healthCheck() async {
    if (_connected) {
      return ServiceHealthCheck(
        status: ServiceHealthStatus.healthy,
        timestamp: DateTime.now(),
        message: 'Database connection is healthy',
        details: {'connected': true},
      );
    } else {
      return ServiceHealthCheck(
        status: ServiceHealthStatus.unhealthy,
        timestamp: DateTime.now(),
        message: 'Database not connected',
        details: {'connected': false},
      );
    }
  }
}

/// Example cache service
class CacheService extends BaseService {
  final Map<String, dynamic> _cache = {};

  @override
  List<Type> get dependencies => const [];

  @override
  Future<void> initialize() async {
    logger.info('Initializing cache service');
    _cache.clear();
  }

  @override
  Future<void> destroy() async {
    logger.info('Clearing cache');
    _cache.clear();
  }

  void set(String key, dynamic value) {
    ensureInitialized();
    _cache[key] = value;
    logger.debug('Cache set', metadata: {'key': key});
  }

  T? get<T>(String key) {
    ensureInitialized();
    final value = _cache[key];
    logger.debug('Cache get', metadata: {'key': key, 'hit': value != null});
    return value as T?;
  }

  void remove(String key) {
    ensureInitialized();
    _cache.remove(key);
    logger.debug('Cache remove', metadata: {'key': key});
  }
}

/// Example user service that depends on database and optionally cache
class UserService extends BaseService {
  DatabaseService? _dbService;
  CacheService? _cacheService;

  @override
  List<Type> get dependencies => [DatabaseService];

  @override
  List<Type> get optionalDependencies => [CacheService];

  @override
  Future<void> initialize() async {
    logger.info('Initializing user service');
    // Dependencies will be injected by the service locator
  }

  /// Sets the database service dependency
  void setDatabaseService(DatabaseService dbService) {
    _dbService = dbService;
  }

  /// Sets the cache service dependency (optional)
  void setCacheService(CacheService? cacheService) {
    _cacheService = cacheService;
  }

  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    ensureInitialized();

    if (_dbService == null) {
      throw Exception('Database service not available');
    }

    logger.info('Getting user profile', metadata: {'userId': userId});

    // Try cache first if available
    if (_cacheService != null) {
      final cached = _cacheService!.get<Map<String, dynamic>>('user:$userId');
      if (cached != null) {
        logger
            .info('User profile found in cache', metadata: {'userId': userId});
        return cached;
      }
    }

    // Get from database
    final user = await _dbService!.getUser(userId);

    // Cache the result if cache service is available
    if (_cacheService != null) {
      _cacheService!.set('user:$userId', user);
    }

    logger.info('User profile retrieved', metadata: {'userId': userId});
    return user;
  }
}

/// Example notification service with periodic tasks
class NotificationService extends BaseService with PeriodicServiceMixin {
  final List<String> _notifications = [];
  int _processedCount = 0;

  @override
  List<Type> get dependencies => [UserService];

  @override
  Duration get periodicInterval => const Duration(seconds: 2);

  @override
  Future<void> initialize() async {
    await super.initialize(); // Important: call super to start periodic tasks
    logger.info('Initializing notification service');
  }

  @override
  Future<void> performPeriodicTask() async {
    if (_notifications.isNotEmpty) {
      final notification = _notifications.removeAt(0);
      logger.info('Processing notification',
          metadata: {'notification': notification});
      _processedCount++;
    }
  }

  void sendNotification(String userId, String message) {
    ensureInitialized();

    final notification = 'User $userId: $message';
    _notifications.add(notification);

    logger.info('Notification queued', metadata: {
      'userId': userId,
      'message': message,
      'queueSize': _notifications.length,
    });
  }

  int get processedCount => _processedCount;
  int get queueSize => _notifications.length;
}

/// Enhanced service locator that handles dependency injection
class EnhancedServiceLocator extends ServiceLocator {
  EnhancedServiceLocator({ServiceLogger? logger}) : super(logger: logger);

  @override
  Future<void> initializeAll() async {
    await super.initializeAll();

    // Perform dependency injection after all services are initialized
    _injectDependencies();
  }

  void _injectDependencies() {
    // Inject database service into user service
    if (isServiceInitialized<UserService>() &&
        isServiceInitialized<DatabaseService>()) {
      final userService = get<UserService>();
      final dbService = get<DatabaseService>();
      userService.setDatabaseService(dbService);
    }

    // Inject cache service into user service if available
    if (isServiceInitialized<UserService>() &&
        isServiceInitialized<CacheService>()) {
      final userService = get<UserService>();
      final cacheService = get<CacheService>();
      userService.setCacheService(cacheService);
    }
  }
}

Future<void> main() async {
  print('=== Dart Service Framework Example ===\n');

  // Create service locator with custom logger
  final memoryWriter = MemoryLogWriter();
  final logger = ServiceLogger(
    serviceName: 'ExampleApp',
    writer: MultiLogWriter([
      ConsoleLogWriter(colorize: true),
      memoryWriter,
    ]),
  );

  final locator = EnhancedServiceLocator(logger: logger);

  try {
    print('1. Registering services...');

    // Register services in any order - dependency resolver will handle initialization order
    locator.register<NotificationService>(() => NotificationService());
    locator.register<UserService>(() => UserService());
    locator.register<CacheService>(() => CacheService());
    locator.register<DatabaseService>(() => DatabaseService());

    print('   Registered ${locator.serviceCount} services\n');

    print('2. Analyzing dependencies...');
    final stats = locator.getDependencyStatistics();
    print('   Total services: ${stats.totalServices}');
    print('   Root services: ${stats.rootServices}');
    print('   Leaf services: ${stats.leafServices}');
    print('   Longest chain: ${stats.longestChainLength}\n');

    print('3. Initializing all services...');
    await locator.initializeAll();
    print('   All services initialized successfully!\n');

    print('4. Using services...');
    final userService = locator.get<UserService>();
    final notificationService = locator.get<NotificationService>();

    // Get user profiles
    final user1 = await userService.getUserProfile('123');
    final user2 = await userService.getUserProfile('456');
    final user1Cached =
        await userService.getUserProfile('123'); // Should come from cache

    print('   Retrieved user: ${user1['name']}');
    print('   Retrieved user: ${user2['name']}');
    print('   Retrieved cached user: ${user1Cached['name']}\n');

    // Send notifications
    notificationService.sendNotification('123', 'Welcome!');
    notificationService.sendNotification('456', 'Hello World!');

    print(
        '   Sent 2 notifications (queue size: ${notificationService.queueSize})');

    // Wait for periodic processing
    print('   Waiting for periodic processing...');
    await Future.delayed(const Duration(seconds: 5));
    print('   Processed ${notificationService.processedCount} notifications\n');

    print('5. Health checks...');
    final healthChecks = await locator.performHealthChecks();
    for (final entry in healthChecks.entries) {
      final serviceName = entry.key;
      final health = entry.value;
      print('   $serviceName: ${health.status.name} - ${health.message}');
    }
    print('');

    print('6. Service information...');
    final allInfo = locator.getAllServiceInfo();
    for (final info in allInfo) {
      print(
          '   ${info.name}: ${info.state.name} (${info.dependencies.length} deps)');
    }
    print('');

    print('7. Dependency visualization:');
    print(locator.visualizeDependencyGraph());

    print('8. Destroying all services...');
    await locator.destroyAll();
    print('   All services destroyed successfully!\n');

    print('9. Log summary:');
    final logEntries = memoryWriter.entries;
    final errorLogs = logEntries.where((e) => e.level == ServiceLogLevel.error);
    final warningLogs =
        logEntries.where((e) => e.level == ServiceLogLevel.warning);
    final infoLogs = logEntries.where((e) => e.level == ServiceLogLevel.info);

    print('   Total log entries: ${logEntries.length}');
    print('   Errors: ${errorLogs.length}');
    print('   Warnings: ${warningLogs.length}');
    print('   Info: ${infoLogs.length}');

    print('\n=== Example completed successfully! ===');
  } catch (error, stackTrace) {
    print('Error: $error');
    print('Stack trace: $stackTrace');

    // Try to clean up
    try {
      await locator.destroyAll();
    } catch (cleanupError) {
      print('Cleanup error: $cleanupError');
    }
  }
}

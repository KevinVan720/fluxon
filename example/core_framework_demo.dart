/// Core Framework Demo
///
/// This example demonstrates the fully implemented Phase 1 and Phase 2 functionality
/// of the Dart Service Framework.

import '../lib/dart_service_framework.dart';
part 'core_framework_demo.service.client.g.dart';

/// Simple database service (no dependencies)
class DatabaseService extends BaseService {
  @override
  List<Type> get dependencies => const [];

  bool _connected = false;

  @override
  Future<void> initialize() async {
    logger.info('Connecting to database...');
    await Future.delayed(Duration(milliseconds: 100));
    _connected = true;
    logger.info('Database connected successfully');
  }

  @override
  Future<void> destroy() async {
    logger.info('Disconnecting from database...');
    _connected = false;
    logger.info('Database disconnected');
  }

  Future<Map<String, dynamic>> getUser(String id) async {
    ensureInitialized();
    logger.debug('Fetching user', metadata: {'userId': id});

    await Future.delayed(Duration(milliseconds: 50));
    return {
      'id': id,
      'name': 'User $id',
      'email': 'user$id@example.com',
    };
  }

  bool get isConnected => _connected;
}

/// Cache service that depends on database
class CacheService extends BaseService {
  @override
  List<Type> get dependencies => [DatabaseService];

  late DatabaseService _database;
  final Map<String, Map<String, dynamic>> _cache = {};

  @override
  Future<void> initialize() async {
    _database = getRequiredDependency<DatabaseService>();
    logger.info('Cache service initialized with database dependency');
  }

  @override
  Future<void> destroy() async {
    _cache.clear();
    logger.info('Cache cleared');
  }

  Future<Map<String, dynamic>> getUser(String id) async {
    ensureInitialized();

    if (_cache.containsKey(id)) {
      logger.debug('Cache hit', metadata: {'userId': id});
      return _cache[id]!;
    }

    logger
        .debug('Cache miss, fetching from database', metadata: {'userId': id});
    final user = await _database.getUser(id);
    _cache[id] = user;

    return user;
  }

  int get cacheSize => _cache.length;
}

void main() async {
  print('🚀 Dart Service Framework - Core Demo\n');

  final locator = ServiceLocator();

  try {
    // Phase 1 & 2: Service Registration with Dependency Management
    print('📝 Registering services...');
    locator.register<DatabaseService>(() => DatabaseService());
    locator.register<CacheService>(() => CacheService());

    // Show dependency resolution
    final stats = locator.getDependencyStatistics();
    print('📊 Dependency Analysis:');
    print('   Total Services: ${stats.totalServices}');
    print('   Root Services: ${stats.rootServices}');
    print('   Dependency Chain Length: ${stats.longestChainLength}');
    print('');

    print('🔗 Dependency Graph:');
    print(locator.visualizeDependencyGraph());

    // Phase 1 & 2: Automatic Dependency-Aware Initialization
    print('🔄 Initializing services in dependency order...');
    await locator.initializeAll();
    print('✅ All services initialized successfully\n');

    // Phase 1: Type-Safe Service Retrieval
    print('💼 Using services...');
    final cacheService = locator.get<CacheService>();

    final user1 = await cacheService.getUser('123');
    final user2 = await cacheService.getUser('456');
    final user1Again = await cacheService.getUser('123'); // Cache hit

    print('👤 ${user1['name']} (${user1['email']})');
    print('👤 ${user2['name']} (${user2['email']})');
    print('📈 Cache size: ${cacheService.cacheSize}');
    print('');

    // Phase 1: Health Monitoring
    print('🏥 Health checks...');
    final healthResults = await locator.performHealthChecks();
    for (final entry in healthResults.entries) {
      final health = entry.value;
      print(
          '   ${entry.key}: ${health.status.name.toUpperCase()} - ${health.message}');
    }
    print('');

    // Phase 1: Service Information
    print('📋 Service Information:');
    final allServices = locator.getAllServiceInfo();
    for (final serviceInfo in allServices) {
      print(
          '   ${serviceInfo.name}: ${serviceInfo.state.name} (deps: ${serviceInfo.dependencies.length})');
    }
  } catch (error, stackTrace) {
    print('❌ Error: $error');
  } finally {
    print('\n🧹 Cleanup...');
    await locator.destroyAll();
    print('✅ All services destroyed');
  }

  print('\n🎉 Demo completed - Core framework is fully functional!');
}

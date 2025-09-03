import 'package:test/test.dart';
import 'package:dart_service_framework/dart_service_framework.dart';

/// Core Framework Demo
///
/// This example demonstrates the fully implemented Phase 1 and Phase 2 functionality
/// of the Dart Service Framework.

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

Future<void> _runCoreFeaturesDemo() async {
  final locator = ServiceLocator();

  // Phase 1 & 2: Service Registration with Dependency Management
  locator.register<DatabaseService>(() => DatabaseService());
  locator.register<CacheService>(() => CacheService());

  // Show dependency resolution
  final stats = locator.getDependencyStatistics();
  expect(stats.totalServices, equals(2));
  expect(stats.rootServices, equals(1)); // DatabaseService has no dependencies
  expect(stats.longestChainLength, equals(2));

  // Phase 1 & 2: Automatic Dependency-Aware Initialization
  await locator.initializeAll();

  // Phase 1: Type-Safe Service Retrieval
  final cacheService = locator.get<CacheService>();

  final user1 = await cacheService.getUser('123');
  final user2 = await cacheService.getUser('456');
  final user1Again = await cacheService.getUser('123'); // Cache hit

  expect(user1['name'], equals('User 123'));
  expect(user2['name'], equals('User 456'));
  expect(user1Again['name'], equals('User 123'));
  expect(cacheService.cacheSize, equals(2));

  // Phase 1: Health Monitoring
  final healthResults = await locator.performHealthChecks();
  expect(healthResults.length, equals(2));
  for (final health in healthResults.values) {
    expect(health.status, equals(ServiceHealthStatus.healthy));
  }

  // Phase 1: Service Information
  final allServices = locator.getAllServiceInfo();
  expect(allServices.length, equals(2));
  for (final serviceInfo in allServices) {
    expect(serviceInfo.state, equals(ServiceState.initialized));
  }

  // Cleanup
  await locator.destroyAll();
}

void main() {
  group('Core Features Demo', () {
    test('runs core features demo successfully', () async {
      await _runCoreFeaturesDemo();
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}

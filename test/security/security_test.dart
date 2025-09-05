import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flux/flux.dart';
import 'package:test/test.dart';

// Security roles and permissions
enum SecurityRole {
  admin,
  user,
  guest,
  moderator,
  service,
}

enum Permission {
  read,
  write,
  delete,
  execute,
  manage,
  audit,
}

class SecurityContext {
  const SecurityContext({
    required this.userId,
    required this.sessionId,
    required this.roles,
    required this.permissions,
    required this.attributes,
    required this.expiresAt,
  });

  factory SecurityContext.fromJson(Map<String, dynamic> json) =>
      SecurityContext(
        userId: json['userId'] as String,
        sessionId: json['sessionId'] as String,
        roles: (json['roles'] as List)
            .map(
                (r) => SecurityRole.values.firstWhere((e) => e.toString() == r))
            .toList(),
        permissions: (json['permissions'] as List)
            .map((p) => Permission.values.firstWhere((e) => e.toString() == p))
            .toList(),
        attributes: Map<String, dynamic>.from(json['attributes'] as Map),
        expiresAt: DateTime.parse(json['expiresAt'] as String),
      );
  final String userId;
  final String sessionId;
  final List<SecurityRole> roles;
  final List<Permission> permissions;
  final Map<String, dynamic> attributes;
  final DateTime expiresAt;

  bool hasRole(SecurityRole role) => roles.contains(role);
  bool hasPermission(Permission permission) => permissions.contains(permission);
  bool isExpired() => DateTime.now().isAfter(expiresAt);
  bool hasAttribute(String key, value) => attributes[key] == value;

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'sessionId': sessionId,
        'roles': roles.map((r) => r.toString()).toList(),
        'permissions': permissions.map((p) => p.toString()).toList(),
        'attributes': attributes,
        'expiresAt': expiresAt.toIso8601String(),
      };
}

// Security service for authentication and authorization
@ServiceContract(remote: false)
class SecurityService extends FluxService {
  SecurityService();
  final Map<String, SecurityContext> _activeSessions = {};
  final Map<String, String> _userPasswords = {};
  final Map<String, List<SecurityRole>> _userRoles = {};
  final Map<String, List<Permission>> _rolePermissions = {};
  final List<Map<String, dynamic>> _auditLog = [];

  @override
  Future<void> initialize() async {
    await super.initialize();

    // Initialize role permissions
    _rolePermissions[SecurityRole.admin.toString()] = Permission.values;
    _rolePermissions[SecurityRole.user.toString()] = [
      Permission.read,
      Permission.write,
      Permission.delete
    ];
    _rolePermissions[SecurityRole.guest.toString()] = [Permission.read];
    _rolePermissions[SecurityRole.moderator.toString()] = [
      Permission.read,
      Permission.write,
      Permission.manage
    ];
    _rolePermissions[SecurityRole.service.toString()] = [
      Permission.execute,
      Permission.audit
    ];

    logger.info('Security service initialized');
  }

  Future<String> authenticate(String username, String password) async {
    if (!_userPasswords.containsKey(username)) {
      throw SecurityException('User not found: $username');
    }

    if (_userPasswords[username] != password) {
      _auditLog.add({
        'action': 'authentication_failed',
        'username': username,
        'timestamp': DateTime.now().toIso8601String(),
        'ip': '127.0.0.1',
      });
      throw SecurityException('Invalid password for user: $username');
    }

    final sessionId = _generateSessionId();
    final roles = _userRoles[username] ?? [SecurityRole.user];
    final permissions = _getPermissionsForRoles(roles);

    final context = SecurityContext(
      userId: username,
      sessionId: sessionId,
      roles: roles,
      permissions: permissions,
      attributes: {'ip': '127.0.0.1', 'userAgent': 'test'},
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
    );

    _activeSessions[sessionId] = context;

    _auditLog.add({
      'action': 'authentication_success',
      'username': username,
      'sessionId': sessionId,
      'timestamp': DateTime.now().toIso8601String(),
    });

    logger.info('User authenticated: $username');
    return sessionId;
  }

  Future<SecurityContext?> getSecurityContext(String sessionId) async {
    final context = _activeSessions[sessionId];
    if (context == null || context.isExpired()) {
      if (context != null) {
        _activeSessions.remove(sessionId);
        _auditLog.add({
          'action': 'session_expired',
          'sessionId': sessionId,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
      return null;
    }
    return context;
  }

  Future<bool> authorize(String sessionId, Permission permission) async {
    final context = await getSecurityContext(sessionId);
    if (context == null) {
      return false;
    }

    final hasPermission = context.hasPermission(permission);

    _auditLog.add({
      'action': 'authorization_check',
      'sessionId': sessionId,
      'permission': permission.toString(),
      'result': hasPermission,
      'timestamp': DateTime.now().toIso8601String(),
    });

    return hasPermission;
  }

  Future<bool> authorizeRole(String sessionId, SecurityRole role) async {
    final context = await getSecurityContext(sessionId);
    if (context == null) {
      return false;
    }

    final hasRole = context.hasRole(role);

    _auditLog.add({
      'action': 'role_check',
      'sessionId': sessionId,
      'role': role.toString(),
      'result': hasRole,
      'timestamp': DateTime.now().toIso8601String(),
    });

    return hasRole;
  }

  Future<void> logout(String sessionId) async {
    if (_activeSessions.containsKey(sessionId)) {
      _activeSessions.remove(sessionId);
      _auditLog.add({
        'action': 'logout',
        'sessionId': sessionId,
        'timestamp': DateTime.now().toIso8601String(),
      });
      logger.info('User logged out: $sessionId');
    }
  }

  Future<void> createUser(
      String username, String password, List<SecurityRole> roles) async {
    if (_userPasswords.containsKey(username)) {
      throw SecurityException('User already exists: $username');
    }

    _userPasswords[username] = password;
    _userRoles[username] = roles;

    _auditLog.add({
      'action': 'user_created',
      'username': username,
      'roles': roles.map((r) => r.toString()).toList(),
      'timestamp': DateTime.now().toIso8601String(),
    });

    logger.info(
        'User created: $username with roles: ${roles.map((r) => r.toString()).join(', ')}');
  }

  List<Permission> _getPermissionsForRoles(List<SecurityRole> roles) {
    final permissions = <Permission>{};
    for (final role in roles) {
      final rolePermissions = _rolePermissions[role.toString()] ?? [];
      permissions.addAll(rolePermissions);
    }
    return permissions.toList();
  }

  String _generateSessionId() {
    final random = Random();
    final bytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Encode(bytes);
  }

  List<Map<String, dynamic>> getAuditLog() => List.from(_auditLog);

  Map<String, dynamic> getSecurityStats() => {
        'activeSessions': _activeSessions.length,
        'totalUsers': _userPasswords.length,
        'auditLogEntries': _auditLog.length,
      };
}

// Exception for security violations
class SecurityException implements Exception {
  SecurityException(this.message);
  final String message;

  @override
  String toString() => 'SecurityException: $message';
}

// Secure data service with access control
@ServiceContract(remote: false)
class SecureDataService extends FluxService {
  SecureDataService(this._securityService);
  final SecurityService _securityService;
  final Map<String, Map<String, dynamic>> _data = {};
  final Map<String, String> _dataOwners = {};

  @override
  Future<void> initialize() async {
    await super.initialize();
    logger.info('Secure data service initialized');
  }

  Future<Map<String, dynamic>?> getData(String sessionId, String dataId) async {
    if (!await _securityService.authorize(sessionId, Permission.read)) {
      throw SecurityException('Insufficient permissions to read data');
    }

    final context = await _securityService.getSecurityContext(sessionId);
    if (context == null) {
      throw SecurityException('Invalid session');
    }

    final data = _data[dataId];
    if (data == null) {
      return null;
    }

    // Check if user owns the data or is admin
    if (_dataOwners[dataId] != context.userId &&
        !context.hasRole(SecurityRole.admin)) {
      throw SecurityException('Access denied: user does not own this data');
    }

    logger.info('Data accessed: $dataId by ${context.userId}');
    return Map.from(data);
  }

  Future<void> setData(
      String sessionId, String dataId, Map<String, dynamic> data) async {
    if (!await _securityService.authorize(sessionId, Permission.write)) {
      throw SecurityException('Insufficient permissions to write data');
    }

    final context = await _securityService.getSecurityContext(sessionId);
    if (context == null) {
      throw SecurityException('Invalid session');
    }

    // Check if user owns the data or is admin
    if (_dataOwners.containsKey(dataId) &&
        _dataOwners[dataId] != context.userId &&
        !context.hasRole(SecurityRole.admin)) {
      throw SecurityException('Access denied: user does not own this data');
    }

    _data[dataId] = Map.from(data);
    _dataOwners[dataId] = context.userId;

    logger.info('Data updated: $dataId by ${context.userId}');
  }

  Future<void> deleteData(String sessionId, String dataId) async {
    if (!await _securityService.authorize(sessionId, Permission.delete)) {
      throw SecurityException('Insufficient permissions to delete data');
    }

    final context = await _securityService.getSecurityContext(sessionId);
    if (context == null) {
      throw SecurityException('Invalid session');
    }

    // Check if user owns the data or is admin
    if (_dataOwners[dataId] != context.userId &&
        !context.hasRole(SecurityRole.admin)) {
      throw SecurityException('Access denied: user does not own this data');
    }

    _data.remove(dataId);
    _dataOwners.remove(dataId);

    logger.info('Data deleted: $dataId by ${context.userId}');
  }

  Future<List<String>> listData(String sessionId) async {
    if (!await _securityService.authorize(sessionId, Permission.read)) {
      throw SecurityException('Insufficient permissions to list data');
    }

    final context = await _securityService.getSecurityContext(sessionId);
    if (context == null) {
      throw SecurityException('Invalid session');
    }

    if (context.hasRole(SecurityRole.admin)) {
      return _data.keys.toList();
    } else {
      return _dataOwners.entries
          .where((e) => e.value == context.userId)
          .map((e) => e.key)
          .toList();
    }
  }
}

// Secure API service with rate limiting
@ServiceContract(remote: false)
class SecureApiService extends FluxService {
  SecureApiService(this._securityService);
  final SecurityService _securityService;
  final Map<String, List<DateTime>> _requestHistory = {};
  final Map<String, int> _rateLimits = {};
  final Map<String, int> _requestCounts = {};

  @override
  Future<void> initialize() async {
    await super.initialize();

    // Set default rate limits
    _rateLimits['default'] = 100; // 100 requests per minute
    _rateLimits['admin'] = 1000; // 1000 requests per minute
    _rateLimits['user'] = 50; // 50 requests per minute

    logger.info('Secure API service initialized');
  }

  Future<String> makeApiCall(
      String sessionId, String endpoint, Map<String, dynamic> data) async {
    final context = await _securityService.getSecurityContext(sessionId);
    if (context == null) {
      throw SecurityException('Invalid session');
    }

    // Check rate limiting
    if (!await _checkRateLimit(context.userId, context.roles)) {
      throw SecurityException('Rate limit exceeded');
    }

    // Check endpoint permissions
    if (!await _checkEndpointPermission(context, endpoint)) {
      throw SecurityException(
          'Insufficient permissions for endpoint: $endpoint');
    }

    // Record request
    _recordRequest(context.userId);

    // Simulate API processing
    await Future.delayed(const Duration(milliseconds: 10));

    logger.info('API call made: $endpoint by ${context.userId}');
    return 'API call to $endpoint successful';
  }

  Future<bool> _checkRateLimit(String userId, List<SecurityRole> roles) async {
    final now = DateTime.now();
    final oneMinuteAgo = now.subtract(const Duration(minutes: 1));

    // Get user's rate limit
    var rateLimit = _rateLimits['default'] ?? 10;
    if (roles.contains(SecurityRole.admin)) {
      rateLimit = _rateLimits['admin'] ?? 100;
    } else if (roles.contains(SecurityRole.user)) {
      rateLimit = _rateLimits['user'] ?? 50;
    }

    // Clean old requests
    _requestHistory[userId] = _requestHistory[userId]
            ?.where((time) => time.isAfter(oneMinuteAgo))
            .toList() ??
        [];

    // Check if limit exceeded
    if (_requestHistory[userId]!.length >= rateLimit) {
      return false;
    }

    // Add current request
    _requestHistory[userId]!.add(now);
    return true;
  }

  Future<bool> _checkEndpointPermission(
      SecurityContext context, String endpoint) async {
    // Admin can access all endpoints
    if (context.hasRole(SecurityRole.admin)) {
      return true;
    }

    // Check specific endpoint permissions
    switch (endpoint) {
      case '/api/public':
        return true;
      case '/api/user':
        return context.hasRole(SecurityRole.user) ||
            context.hasRole(SecurityRole.admin);
      case '/api/admin':
        return context.hasRole(SecurityRole.admin);
      case '/api/service':
        return context.hasRole(SecurityRole.service);
      default:
        return false;
    }
  }

  void _recordRequest(String userId) {
    _requestCounts[userId] = (_requestCounts[userId] ?? 0) + 1;
  }

  Map<String, dynamic> getApiStats() => {
        'requestCounts': Map.from(_requestCounts),
        'rateLimits': Map.from(_rateLimits),
      };
}

// Encryption service for sensitive data
@ServiceContract(remote: false)
class EncryptionService extends FluxService {
  EncryptionService();
  final String _encryptionKey = 'test_encryption_key_12345';

  @override
  Future<void> initialize() async {
    await super.initialize();
    logger.info('Encryption service initialized');
  }

  Future<String> encrypt(String data) async {
    // Simple XOR encryption for testing (not secure for production)
    final bytes = data.codeUnits;
    final keyBytes = _encryptionKey.codeUnits;
    final encrypted = <int>[];

    for (var i = 0; i < bytes.length; i++) {
      encrypted.add(bytes[i] ^ keyBytes[i % keyBytes.length]);
    }

    return base64Encode(encrypted);
  }

  Future<String> decrypt(String encryptedData) async {
    // Simple XOR decryption for testing
    final encrypted = base64Decode(encryptedData);
    final keyBytes = _encryptionKey.codeUnits;
    final decrypted = <int>[];

    for (var i = 0; i < encrypted.length; i++) {
      decrypted.add(encrypted[i] ^ keyBytes[i % keyBytes.length]);
    }

    return String.fromCharCodes(decrypted);
  }

  Future<Map<String, dynamic>> encryptMap(Map<String, dynamic> data) async {
    final encrypted = <String, dynamic>{};

    for (final entry in data.entries) {
      if (entry.value is String) {
        encrypted[entry.key] = await encrypt(entry.value as String);
      } else {
        encrypted[entry.key] = entry.value;
      }
    }

    return encrypted;
  }

  Future<Map<String, dynamic>> decryptMap(
      Map<String, dynamic> encryptedData) async {
    final decrypted = <String, dynamic>{};

    for (final entry in encryptedData.entries) {
      if (entry.value is String) {
        try {
          decrypted[entry.key] = await decrypt(entry.value as String);
        } catch (e) {
          decrypted[entry.key] =
              entry.value; // Keep original if decryption fails
        }
      } else {
        decrypted[entry.key] = entry.value;
      }
    }

    return decrypted;
  }
}

void main() {
  group('Security Tests', () {
    late FluxRuntime runtime;
    late SecurityService securityService;
    late SecureDataService dataService;
    late SecureApiService apiService;
    late EncryptionService encryptionService;

    setUp(() async {
      runtime = FluxRuntime();

      runtime.register<SecurityService>(SecurityService.new);
      runtime.register<EncryptionService>(EncryptionService.new);

      await runtime.initializeAll();

      securityService = runtime.get<SecurityService>();
      // Create dependent services after SecurityService is available
      dataService = SecureDataService(securityService);
      apiService = SecureApiService(securityService);
      encryptionService = runtime.get<EncryptionService>();

      // Create test users
      await securityService
          .createUser('admin', 'admin123', [SecurityRole.admin]);
      await securityService.createUser('user1', 'user123', [SecurityRole.user]);
      await securityService
          .createUser('guest', 'guest123', [SecurityRole.guest]);
      await securityService
          .createUser('moderator', 'mod123', [SecurityRole.moderator]);
    });

    tearDown(() async {
      if (runtime.isInitialized) {
        await runtime.destroyAll();
      }
    });

    group('Authentication', () {
      test('should authenticate valid users', () async {
        final sessionId =
            await securityService.authenticate('admin', 'admin123');
        expect(sessionId, isNotEmpty);

        final context = await securityService.getSecurityContext(sessionId);
        expect(context, isNotNull);
        expect(context!.userId, equals('admin'));
        expect(context.hasRole(SecurityRole.admin), isTrue);
      });

      test('should reject invalid credentials', () async {
        expect(
          () => securityService.authenticate('admin', 'wrongpassword'),
          throwsA(isA<SecurityException>()),
        );

        expect(
          () => securityService.authenticate('nonexistent', 'password'),
          throwsA(isA<SecurityException>()),
        );
      });

      test('should handle session expiration', () async {
        final sessionId =
            await securityService.authenticate('user1', 'user123');

        // Simulate session expiration by manually removing it
        await securityService.logout(sessionId);

        final context = await securityService.getSecurityContext(sessionId);
        expect(context, isNull);
      });
    });

    group('Authorization', () {
      test('should authorize based on permissions', () async {
        final adminSession =
            await securityService.authenticate('admin', 'admin123');
        final userSession =
            await securityService.authenticate('user1', 'user123');
        final guestSession =
            await securityService.authenticate('guest', 'guest123');

        // Admin should have all permissions
        expect(await securityService.authorize(adminSession, Permission.read),
            isTrue);
        expect(await securityService.authorize(adminSession, Permission.write),
            isTrue);
        expect(await securityService.authorize(adminSession, Permission.delete),
            isTrue);
        expect(await securityService.authorize(adminSession, Permission.manage),
            isTrue);

        // User should have read, write, and delete permissions
        expect(await securityService.authorize(userSession, Permission.read),
            isTrue);
        expect(await securityService.authorize(userSession, Permission.write),
            isTrue);
        expect(await securityService.authorize(userSession, Permission.delete),
            isTrue);
        expect(await securityService.authorize(userSession, Permission.manage),
            isFalse);

        // Guest should only have read permission
        expect(await securityService.authorize(guestSession, Permission.read),
            isTrue);
        expect(await securityService.authorize(guestSession, Permission.write),
            isFalse);
        expect(await securityService.authorize(guestSession, Permission.delete),
            isFalse);
      });

      test('should authorize based on roles', () async {
        final adminSession =
            await securityService.authenticate('admin', 'admin123');
        final userSession =
            await securityService.authenticate('user1', 'user123');
        final moderatorSession =
            await securityService.authenticate('moderator', 'mod123');

        expect(
            await securityService.authorizeRole(
                adminSession, SecurityRole.admin),
            isTrue);
        expect(
            await securityService.authorizeRole(userSession, SecurityRole.user),
            isTrue);
        expect(
            await securityService.authorizeRole(
                moderatorSession, SecurityRole.moderator),
            isTrue);
        expect(
            await securityService.authorizeRole(
                userSession, SecurityRole.admin),
            isFalse);
      });
    });

    group('Secure Data Access', () {
      test('should allow data access based on ownership', () async {
        final userSession =
            await securityService.authenticate('user1', 'user123');
        final adminSession =
            await securityService.authenticate('admin', 'admin123');

        // User creates data
        await dataService
            .setData(userSession, 'data1', {'content': 'user1 data'});

        // User can read their own data
        final data = await dataService.getData(userSession, 'data1');
        expect(data, isNotNull);
        expect(data!['content'], equals('user1 data'));

        // Admin can read any data
        final adminData = await dataService.getData(adminSession, 'data1');
        expect(adminData, isNotNull);
        expect(adminData!['content'], equals('user1 data'));
      });

      test('should deny access to other users data', () async {
        final user1Session =
            await securityService.authenticate('user1', 'user123');
        final user2Session =
            await securityService.authenticate('guest', 'guest123');

        // User1 creates data
        await dataService
            .setData(user1Session, 'data1', {'content': 'user1 data'});

        // User2 should not be able to read user1's data
        expect(
          () => dataService.getData(user2Session, 'data1'),
          throwsA(isA<SecurityException>()),
        );
      });

      test('should handle data deletion permissions', () async {
        final userSession =
            await securityService.authenticate('user1', 'user123');
        final guestSession =
            await securityService.authenticate('guest', 'guest123');

        // User creates data
        await dataService
            .setData(userSession, 'data1', {'content': 'user1 data'});

        // Guest should not be able to delete data (no delete permission)
        expect(
          dataService.deleteData(guestSession, 'data1'),
          throwsA(isA<SecurityException>()),
        );

        // User should be able to delete their own data
        await dataService.deleteData(userSession, 'data1');

        final data = await dataService.getData(userSession, 'data1');
        expect(data, isNull);
      });
    });

    group('API Security', () {
      test('should enforce endpoint permissions', () async {
        final adminSession =
            await securityService.authenticate('admin', 'admin123');
        final userSession =
            await securityService.authenticate('user1', 'user123');
        final guestSession =
            await securityService.authenticate('guest', 'guest123');

        // Admin can access all endpoints
        expect(await apiService.makeApiCall(adminSession, '/api/admin', {}),
            contains('successful'));
        expect(await apiService.makeApiCall(adminSession, '/api/user', {}),
            contains('successful'));
        expect(await apiService.makeApiCall(adminSession, '/api/public', {}),
            contains('successful'));

        // User can access user and public endpoints
        expect(await apiService.makeApiCall(userSession, '/api/user', {}),
            contains('successful'));
        expect(await apiService.makeApiCall(userSession, '/api/public', {}),
            contains('successful'));

        // User cannot access admin endpoint
        expect(
          () => apiService.makeApiCall(userSession, '/api/admin', {}),
          throwsA(isA<SecurityException>()),
        );

        // Guest can only access public endpoint
        expect(await apiService.makeApiCall(guestSession, '/api/public', {}),
            contains('successful'));
        expect(
          () => apiService.makeApiCall(guestSession, '/api/user', {}),
          throwsA(isA<SecurityException>()),
        );
      });

      test('should enforce rate limiting', () async {
        final userSession =
            await securityService.authenticate('user1', 'user123');

        // Make many API calls to trigger rate limiting
        for (var i = 0; i < 60; i++) {
          try {
            await apiService.makeApiCall(userSession, '/api/public', {});
          } catch (e) {
            if (e is SecurityException &&
                e.message.contains('Rate limit exceeded')) {
              // Expected after hitting rate limit
              break;
            }
          }
        }

        // Should eventually hit rate limit
        expect(
          () => apiService.makeApiCall(userSession, '/api/public', {}),
          throwsA(isA<SecurityException>()),
        );
      });
    });

    group('Data Encryption', () {
      test('should encrypt and decrypt data', () async {
        const originalData = 'sensitive information';

        final encrypted = await encryptionService.encrypt(originalData);
        expect(encrypted, isNot(equals(originalData)));

        final decrypted = await encryptionService.decrypt(encrypted);
        expect(decrypted, equals(originalData));
      });

      test('should encrypt and decrypt maps', () async {
        final originalData = {
          'username': 'testuser',
          'password': 'secret123',
          'email': 'test@example.com',
          'age': 25,
        };

        final encrypted = await encryptionService.encryptMap(originalData);
        expect(encrypted['username'], isNot(equals('testuser')));
        expect(encrypted['password'], isNot(equals('secret123')));
        expect(encrypted['age'], equals(25)); // Non-string values unchanged

        final decrypted = await encryptionService.decryptMap(encrypted);
        expect(decrypted['username'], equals('testuser'));
        expect(decrypted['password'], equals('secret123'));
        expect(decrypted['email'], equals('test@example.com'));
        expect(decrypted['age'], equals(25));
      });
    });

    group('Audit Logging', () {
      test('should log security events', () async {
        final adminSession =
            await securityService.authenticate('admin', 'admin123');
        final userSession =
            await securityService.authenticate('user1', 'user123');

        // Perform various operations
        await dataService.setData(userSession, 'data1', {'content': 'test'});
        await dataService.getData(userSession, 'data1');
        await apiService.makeApiCall(adminSession, '/api/admin', {});

        final auditLog = securityService.getAuditLog();
        expect(auditLog.length, greaterThan(0));

        // Check for specific events
        final authEvents = auditLog
            .where((e) => e['action'] == 'authentication_success')
            .toList();
        expect(authEvents.length, greaterThanOrEqualTo(2));

        final authzEvents = auditLog
            .where((e) => e['action'] == 'authorization_check')
            .toList();
        expect(authzEvents.length, greaterThan(0));
      });

      test('should track failed authentication attempts', () async {
        // Try to authenticate with wrong password
        try {
          await securityService.authenticate('admin', 'wrongpassword');
        } catch (e) {
          // Expected to fail
        }

        final auditLog = securityService.getAuditLog();
        final failedAuthEvents = auditLog
            .where((e) => e['action'] == 'authentication_failed')
            .toList();
        expect(failedAuthEvents.length, greaterThan(0));
        expect(failedAuthEvents.first['username'], equals('admin'));
      });
    });

    group('Security Edge Cases', () {
      test('should handle concurrent security operations', () async {
        final futures = <Future>[];

        // Create multiple sessions concurrently
        for (var i = 0; i < 10; i++) {
          futures.add(securityService.authenticate('user1', 'user123'));
        }

        final sessions = await Future.wait(futures);
        expect(sessions.length, equals(10));

        // All sessions should be valid
        for (final session in sessions) {
          final context = await securityService.getSecurityContext(session);
          expect(context, isNotNull);
        }
      });

      test('should handle invalid session operations', () async {
        const invalidSession = 'invalid_session_id';

        expect(
          () => dataService.getData(invalidSession, 'data1'),
          throwsA(isA<SecurityException>()),
        );

        expect(
          () => apiService.makeApiCall(invalidSession, '/api/public', {}),
          throwsA(isA<SecurityException>()),
        );
      });

      test('should handle session expiration during operation', () async {
        final sessionId =
            await securityService.authenticate('user1', 'user123');

        // Logout the session
        await securityService.logout(sessionId);

        // Try to use the expired session
        expect(
          () => dataService.getData(sessionId, 'data1'),
          throwsA(isA<SecurityException>()),
        );
      });
    });
  });
}

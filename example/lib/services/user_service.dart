import 'package:flux/flux.dart';
import '../models/task.dart';
import 'storage_service.dart';

part 'user_service.g.dart';

/// User management service
/// This service runs locally for fast user lookups
@ServiceContract(remote: false)
class UserService extends FluxService {
  final List<User> _users = [];

  // 🔗 DEPENDENCY SYSTEM: Depends on storage
  @override
  List<Type> get dependencies => [StorageService];

  @override
  Future<void> initialize() async {
    // Load users from storage
    final storage = getService<StorageService>();
    _users.addAll(await storage.loadUsers());

    logger.info('User service initialized with ${_users.length} users');
    await super.initialize();
  }

  /// Get all users
  Future<List<User>> getAllUsers() async => List.from(_users);

  /// Get user by ID
  Future<User> getUserById(String userId) async {
    final user = _users.firstWhere(
      (u) => u.id == userId,
      orElse: () => throw ServiceException('User not found: $userId'),
    );
    return user;
  }

  /// Get users by role
  Future<List<User>> getUsersByRole(UserRole role) async =>
      _users.where((user) => user.role == role).toList();

  /// Create a new user
  Future<User> createUser({
    required String name,
    required String email,
    UserRole role = UserRole.member,
    String? avatar,
  }) async {
    // Generate ID based on name for demo purposes
    final id = (_users.length + 1).toString();

    final user = User(
      id: id,
      name: name,
      email: email,
      role: role,
      avatar: avatar,
    );

    _users.add(user);

    // 🔄 SERVICE PROXY SYSTEM: Save to storage
    final storage = getService<StorageService>();
    await storage.saveUsers(_users);

    logger.info(
      'Created user: ${user.name}',
      metadata: {
        'userId': user.id,
        'email': user.email,
        'role': user.role.name,
      },
    );

    return user;
  }

  /// Update user
  Future<User> updateUser(
    String userId, {
    String? name,
    String? email,
    UserRole? role,
    String? avatar,
  }) async {
    final userIndex = _users.indexWhere((u) => u.id == userId);
    if (userIndex == -1) {
      throw ServiceException('User not found: $userId');
    }

    final oldUser = _users[userIndex];
    final updatedUser = User(
      id: oldUser.id,
      name: name ?? oldUser.name,
      email: email ?? oldUser.email,
      role: role ?? oldUser.role,
      avatar: avatar ?? oldUser.avatar,
    );

    _users[userIndex] = updatedUser;

    // Save to storage
    final storage = getService<StorageService>();
    await storage.saveUsers(_users);

    logger.info(
      'Updated user: ${updatedUser.name}',
      metadata: {'userId': updatedUser.id},
    );

    return updatedUser;
  }

  /// Search users by name or email
  Future<List<User>> searchUsers(String query) async {
    final lowercaseQuery = query.toLowerCase();
    return _users
        .where(
          (user) =>
              user.name.toLowerCase().contains(lowercaseQuery) ||
              user.email.toLowerCase().contains(lowercaseQuery),
        )
        .toList();
  }

  /// Get current user (for demo, return first admin)
  Future<User> getCurrentUser() async {
    return _users.firstWhere(
      (user) => user.role == UserRole.admin,
      orElse: () => _users.first,
    );
  }
}

import 'package:dart_service_framework/dart_service_framework.dart';
import '../models/task.dart';

part 'simple_user_service.g.dart';

/// Simplified user service without dependencies
@ServiceContract(remote: false)
class SimpleUserService extends FluxService {
  final List<User> _users = [
    const User(
      id: '1',
      name: 'Alice Johnson',
      email: 'alice@example.com',
      role: UserRole.admin,
    ),
    const User(
      id: '2',
      name: 'Bob Smith',
      email: 'bob@example.com',
      role: UserRole.manager,
    ),
    const User(
      id: '3',
      name: 'Carol Davis',
      email: 'carol@example.com',
      role: UserRole.member,
    ),
  ];

  @override
  Future<void> initialize() async {
    logger.info('Simple user service initialized with ${_users.length} users');
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

  /// Get current user (for demo, return first admin)
  Future<User> getCurrentUser() async {
    return _users.firstWhere(
      (user) => user.role == UserRole.admin,
      orElse: () => _users.first,
    );
  }
}

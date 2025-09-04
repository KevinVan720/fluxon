import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dart_service_framework/dart_service_framework.dart';
import '../models/task.dart';

part 'storage_service.g.dart';

/// Local storage service for persisting data
/// This service runs locally for fast data access
@ServiceContract(remote: false)
class StorageService extends FluxService {
  SharedPreferences? _prefs;

  @override
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    logger.info('Storage service initialized');
    await super.initialize();
  }

  /// Save tasks to local storage
  Future<void> saveTasks(List<Task> tasks) async {
    final tasksJson = tasks.map((t) => t.toJson()).toList();
    await _prefs?.setString('tasks', jsonEncode(tasksJson));
    logger.info('Saved ${tasks.length} tasks to storage');
  }

  /// Load tasks from local storage
  Future<List<Task>> loadTasks() async {
    final tasksString = _prefs?.getString('tasks');
    if (tasksString == null) return [];

    final tasksList = jsonDecode(tasksString) as List;
    final tasks = tasksList.map((json) => Task.fromJson(json)).toList();
    logger.info('Loaded ${tasks.length} tasks from storage');
    return tasks;
  }

  /// Save users to local storage
  Future<void> saveUsers(List<User> users) async {
    final usersJson = users.map((u) => u.toJson()).toList();
    await _prefs?.setString('users', jsonEncode(usersJson));
    logger.info('Saved ${users.length} users to storage');
  }

  /// Load users from local storage
  Future<List<User>> loadUsers() async {
    final usersString = _prefs?.getString('users');
    if (usersString == null) {
      // Create default users
      const defaultUsers = [
        User(
          id: '1',
          name: 'Alice Johnson',
          email: 'alice@example.com',
          role: UserRole.admin,
        ),
        User(
          id: '2',
          name: 'Bob Smith',
          email: 'bob@example.com',
          role: UserRole.manager,
        ),
        User(
          id: '3',
          name: 'Carol Davis',
          email: 'carol@example.com',
          role: UserRole.member,
        ),
      ];
      await saveUsers(defaultUsers);
      return defaultUsers;
    }

    final usersList = jsonDecode(usersString) as List;
    final users = usersList.map((json) => User.fromJson(json)).toList();
    logger.info('Loaded ${users.length} users from storage');
    return users;
  }

  /// Clear all data (for testing)
  Future<void> clearAll() async {
    await _prefs?.clear();
    logger.info('Cleared all storage data');
  }
}

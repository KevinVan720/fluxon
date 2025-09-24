import 'package:fluxon/fluxon.dart';
import 'package:test/test.dart';

part 'complex_marshalling_test.g.dart';

/// Enum for testing enum marshalling
enum Priority { low, medium, high, critical }

/// Nested address object
class Address {
  const Address({
    required this.street,
    required this.city,
    required this.zipCode,
    this.country = 'USA',
  });

  final String street;
  final String city;
  final String zipCode;
  final String country;

  Map<String, dynamic> toJson() => {
        'street': street,
        'city': city,
        'zipCode': zipCode,
        'country': country,
      };

  static Address fromJson(Map<String, dynamic> json) => Address(
        street: json['street'] as String,
        city: json['city'] as String,
        zipCode: json['zipCode'] as String,
        country: json['country'] as String? ?? 'USA',
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Address &&
          other.street == street &&
          other.city == city &&
          other.zipCode == zipCode &&
          other.country == country;

  @override
  int get hashCode => Object.hash(street, city, zipCode, country);

  @override
  String toString() => 'Address($street, $city, $zipCode, $country)';
}

/// Complex user object with nested data, lists, maps, and enums
class ComplexUser {
  const ComplexUser({
    required this.id,
    required this.name,
    required this.email,
    required this.address,
    required this.priority,
    required this.tags,
    required this.metadata,
    required this.scores,
    this.manager,
    this.projects = const [],
  });

  final int id;
  final String name;
  final String email;
  final Address address;
  final Priority priority;
  final List<String> tags;
  final Map<String, dynamic> metadata;
  final Map<String, double> scores;
  final ComplexUser? manager; // Recursive reference!
  final List<Project> projects;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'address': address.toJson(),
        'priority': priority.name,
        'tags': tags,
        'metadata': metadata,
        'scores': scores,
        'manager': manager?.toJson(),
        'projects': projects.map((p) => p.toJson()).toList(),
      };

  static ComplexUser fromJson(Map<String, dynamic> json) => ComplexUser(
        id: json['id'] as int,
        name: json['name'] as String,
        email: json['email'] as String,
        address: Address.fromJson(json['address'] as Map<String, dynamic>),
        priority: Priority.values.byName(json['priority'] as String),
        tags: (json['tags'] as List).cast<String>(),
        metadata: Map<String, dynamic>.from(json['metadata'] as Map),
        scores: Map<String, double>.from(json['scores'] as Map),
        manager: json['manager'] != null
            ? ComplexUser.fromJson(json['manager'] as Map<String, dynamic>)
            : null,
        projects: (json['projects'] as List)
            .map((p) => Project.fromJson(p as Map<String, dynamic>))
            .toList(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ComplexUser &&
          other.id == id &&
          other.name == name &&
          other.email == email &&
          other.address == address &&
          other.priority == priority;

  @override
  int get hashCode => Object.hash(id, name, email, address, priority);

  @override
  String toString() => 'ComplexUser(id: $id, name: $name, priority: $priority)';
}

/// Project object for nested collections
class Project {
  const Project({
    required this.id,
    required this.name,
    required this.deadline,
    required this.status,
  });

  final String id;
  final String name;
  final DateTime deadline;
  final String status;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'deadline': deadline.toIso8601String(),
        'status': status,
      };

  static Project fromJson(Map<String, dynamic> json) => Project(
        id: json['id'] as String,
        name: json['name'] as String,
        deadline: DateTime.parse(json['deadline'] as String),
        status: json['status'] as String,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Project &&
          other.id == id &&
          other.name == name &&
          other.deadline == deadline &&
          other.status == status;

  @override
  int get hashCode => Object.hash(id, name, deadline, status);

  @override
  String toString() => 'Project($id: $name, deadline: $deadline)';
}

/// Service that handles complex objects
@ServiceContract(remote: true)
class ComplexMarshallingService extends FluxonService {
  /// Process a complex user object
  Future<ComplexUser> processUser(ComplexUser user) async {
    // Create a processed version with modifications
    return ComplexUser(
      id: user.id + 1000,
      name: '${user.name} (Processed)',
      email: 'processed_${user.email}',
      address: Address(
        street: '${user.address.street} Suite B',
        city: user.address.city,
        zipCode: user.address.zipCode,
        country: user.address.country,
      ),
      priority: Priority.high, // Always upgrade to high
      tags: [...user.tags, 'processed'],
      metadata: {
        ...user.metadata,
        'processedAt': DateTime.now().toIso8601String(),
        'originalId': user.id,
      },
      scores: user.scores.map((k, v) => MapEntry(k, v * 1.5)),
      manager: user.manager, // Keep manager as-is
      projects: user.projects
          .map((p) => Project(
                id: p.id,
                name: '${p.name} (Updated)',
                deadline: p.deadline.add(const Duration(days: 7)),
                status: 'updated',
              ))
          .toList(),
    );
  }

  /// Process multiple users in a complex structure
  Future<Map<Priority, List<ComplexUser>>> groupUsersByPriority(
      List<ComplexUser> users) async {
    final grouped = <Priority, List<ComplexUser>>{};

    for (final user in users) {
      grouped.putIfAbsent(user.priority, () => []).add(user);
    }

    return grouped;
  }

  /// Return deeply nested data structure
  Future<Map<String, Map<Priority, List<Project>>>> getProjectMatrix(
      List<ComplexUser> users) async {
    final matrix = <String, Map<Priority, List<Project>>>{};

    for (final user in users) {
      matrix[user.name] = {
        user.priority: user.projects,
      };
    }

    return matrix;
  }

  /// Test recursive object handling
  Future<ComplexUser> createUserWithManager() async {
    final manager = ComplexUser(
      id: 1,
      name: 'Manager Bob',
      email: 'bob@example.com',
      address: const Address(
        street: '123 Boss St',
        city: 'Corporate City',
        zipCode: '12345',
      ),
      priority: Priority.critical,
      tags: ['manager', 'senior'],
      metadata: {'level': 'executive'},
      scores: {'performance': 95.0, 'leadership': 90.0},
      projects: [
        Project(
          id: 'proj1',
          name: 'Strategic Initiative',
          deadline: DateTime(2025, 12, 31),
          status: 'active',
        ),
      ],
    );

    return ComplexUser(
      id: 2,
      name: 'Employee Alice',
      email: 'alice@example.com',
      address: const Address(
        street: '456 Worker Ave',
        city: 'Employee Town',
        zipCode: '67890',
      ),
      priority: Priority.medium,
      tags: ['developer', 'junior'],
      metadata: {'level': 'junior', 'department': 'engineering'},
      scores: {'performance': 85.0, 'technical': 88.0},
      manager: manager, // Recursive reference!
      projects: [
        Project(
          id: 'proj2',
          name: 'Feature Development',
          deadline: DateTime(2025, 10, 15),
          status: 'in_progress',
        ),
        Project(
          id: 'proj3',
          name: 'Bug Fixes',
          deadline: DateTime(2025, 9, 30),
          status: 'pending',
        ),
      ],
    );
  }
}

void main() {
  group('Complex Object Marshalling Tests', () {
    late FluxonRuntime runtime;

    setUp(() {
      runtime = FluxonRuntime();
    });

    tearDown(() async {
      await runtime.destroyAll();
    });

    test('should handle complex nested objects with all data types', () async {
      runtime.register<ComplexMarshallingService>(
          ComplexMarshallingServiceImpl.new);
      await runtime.initializeAll();

      final service = runtime.get<ComplexMarshallingService>();

      final user = ComplexUser(
        id: 42,
        name: 'John Doe',
        email: 'john@example.com',
        address: const Address(
          street: '123 Main St',
          city: 'Anytown',
          zipCode: '12345',
        ),
        priority: Priority.medium,
        tags: ['developer', 'backend', 'senior'],
        metadata: {
          'department': 'engineering',
          'startDate': '2023-01-15',
          'salary': 100000,
          'remote': true,
        },
        scores: {
          'performance': 92.5,
          'teamwork': 88.0,
          'technical': 95.5,
        },
        projects: [
          Project(
            id: 'proj1',
            name: 'API Redesign',
            deadline: DateTime(2025, 12, 1),
            status: 'active',
          ),
        ],
      );

      final result = await service.processUser(user);

      // Verify transformations
      expect(result.id, equals(1042));
      expect(result.name, equals('John Doe (Processed)'));
      expect(result.email, equals('processed_john@example.com'));
      expect(result.address.street, equals('123 Main St Suite B'));
      expect(result.priority, equals(Priority.high));
      expect(result.tags, contains('processed'));
      expect(result.metadata['originalId'], equals(42));
      expect(result.scores['performance'], equals(138.75)); // 92.5 * 1.5
      expect(result.projects[0].name, equals('API Redesign (Updated)'));
      expect(result.projects[0].status, equals('updated'));
    });

    test('should handle complex collections and grouping', () async {
      runtime.register<ComplexMarshallingService>(
          ComplexMarshallingServiceImpl.new);
      await runtime.initializeAll();

      final service = runtime.get<ComplexMarshallingService>();

      final users = [
        ComplexUser(
          id: 1,
          name: 'Low Priority User',
          email: 'low@example.com',
          address:
              const Address(street: '1 Low St', city: 'Town', zipCode: '11111'),
          priority: Priority.low,
          tags: ['user'],
          metadata: {},
          scores: {},
        ),
        ComplexUser(
          id: 2,
          name: 'High Priority User',
          email: 'high@example.com',
          address: const Address(
              street: '2 High St', city: 'Town', zipCode: '22222'),
          priority: Priority.high,
          tags: ['vip'],
          metadata: {},
          scores: {},
        ),
        ComplexUser(
          id: 3,
          name: 'Critical User',
          email: 'critical@example.com',
          address: const Address(
              street: '3 Critical St', city: 'Town', zipCode: '33333'),
          priority: Priority.critical,
          tags: ['admin'],
          metadata: {},
          scores: {},
        ),
      ];

      final grouped = await service.groupUsersByPriority(users);

      expect(grouped.keys, hasLength(3));
      expect(grouped[Priority.low], hasLength(1));
      expect(grouped[Priority.high], hasLength(1));
      expect(grouped[Priority.critical], hasLength(1));
      expect(grouped[Priority.low]![0].name, equals('Low Priority User'));
      expect(grouped[Priority.critical]![0].name, equals('Critical User'));
    });

    test('should handle deeply nested data structures', () async {
      runtime.register<ComplexMarshallingService>(
          ComplexMarshallingServiceImpl.new);
      await runtime.initializeAll();

      final service = runtime.get<ComplexMarshallingService>();

      final users = [
        ComplexUser(
          id: 1,
          name: 'Project Manager',
          email: 'pm@example.com',
          address:
              const Address(street: '1 PM St', city: 'Town', zipCode: '11111'),
          priority: Priority.high,
          tags: ['manager'],
          metadata: {},
          scores: {},
          projects: [
            Project(
              id: 'alpha',
              name: 'Alpha Project',
              deadline: DateTime(2025, 11, 1),
              status: 'active',
            ),
            Project(
              id: 'beta',
              name: 'Beta Project',
              deadline: DateTime(2025, 12, 1),
              status: 'planning',
            ),
          ],
        ),
      ];

      final matrix = await service.getProjectMatrix(users);

      expect(matrix.keys, contains('Project Manager'));
      expect(matrix['Project Manager']!.keys, contains(Priority.high));
      expect(matrix['Project Manager']![Priority.high], hasLength(2));
      expect(matrix['Project Manager']![Priority.high]![0].name,
          equals('Alpha Project'));
      expect(matrix['Project Manager']![Priority.high]![1].name,
          equals('Beta Project'));
    });

    test('should handle recursive object references', () async {
      runtime.register<ComplexMarshallingService>(
          ComplexMarshallingServiceImpl.new);
      await runtime.initializeAll();

      final service = runtime.get<ComplexMarshallingService>();

      final userWithManager = await service.createUserWithManager();

      // Verify main user
      expect(userWithManager.id, equals(2));
      expect(userWithManager.name, equals('Employee Alice'));
      expect(userWithManager.manager, isNotNull);

      // Verify manager (recursive reference)
      expect(userWithManager.manager!.id, equals(1));
      expect(userWithManager.manager!.name, equals('Manager Bob'));
      expect(userWithManager.manager!.priority, equals(Priority.critical));
      expect(userWithManager.manager!.projects, hasLength(1));
      expect(userWithManager.manager!.projects[0].name,
          equals('Strategic Initiative'));

      // Verify employee projects
      expect(userWithManager.projects, hasLength(2));
      expect(userWithManager.projects[0].name, equals('Feature Development'));
      expect(userWithManager.projects[1].name, equals('Bug Fixes'));
    });

    test('should handle edge cases and null values', () async {
      runtime.register<ComplexMarshallingService>(
          ComplexMarshallingServiceImpl.new);
      await runtime.initializeAll();

      final service = runtime.get<ComplexMarshallingService>();

      // User with minimal data and null manager
      final minimalUser = ComplexUser(
        id: 999,
        name: 'Minimal User',
        email: 'minimal@example.com',
        address: const Address(
          street: '',
          city: 'Empty',
          zipCode: '00000',
        ),
        priority: Priority.low,
        tags: [], // Empty list
        metadata: {}, // Empty map
        scores: {}, // Empty scores
        manager: null, // Null reference
        projects: [], // Empty projects
      );

      final result = await service.processUser(minimalUser);

      expect(result.id, equals(1999));
      expect(result.name, equals('Minimal User (Processed)'));
      expect(result.manager, isNull);
      expect(result.tags, contains('processed'));
      expect(result.projects, isEmpty);
      expect(result.metadata['originalId'], equals(999));
    });
  });
}

/// Data models for the Squadron example
library models;

/// User data class with JSON serialization
class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
    this.isActive = true,
    this.metadata = const {},
  });

  final String id;
  final String name;
  final String email;
  final DateTime createdAt;
  final bool isActive;
  final Map<String, dynamic> metadata;

  /// Creates a User from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
    );
  }

  /// Converts User to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
      'metadata': metadata,
    };
  }

  /// Creates a copy with updated fields
  User copyWith({
    String? id,
    String? name,
    String? email,
    DateTime? createdAt,
    bool? isActive,
    Map<String, dynamic>? metadata,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.id == id &&
        other.name == name &&
        other.email == email &&
        other.createdAt == createdAt &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return Object.hash(id, name, email, createdAt, isActive);
  }

  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email, isActive: $isActive)';
  }
}

/// User profile with additional computed fields
class UserProfile {
  const UserProfile({
    required this.user,
    required this.profileScore,
    required this.lastLoginAt,
    this.preferences = const {},
    this.tags = const [],
  });

  final User user;
  final double profileScore;
  final DateTime? lastLoginAt;
  final Map<String, dynamic> preferences;
  final List<String> tags;

  /// Creates a UserProfile from JSON
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      profileScore: (json['profileScore'] as num).toDouble(),
      lastLoginAt: json['lastLoginAt'] != null 
          ? DateTime.parse(json['lastLoginAt'] as String)
          : null,
      preferences: Map<String, dynamic>.from(json['preferences'] as Map? ?? {}),
      tags: List<String>.from(json['tags'] as List? ?? []),
    );
  }

  /// Converts UserProfile to JSON
  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'profileScore': profileScore,
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'preferences': preferences,
      'tags': tags,
    };
  }

  @override
  String toString() {
    return 'UserProfile(user: ${user.name}, score: $profileScore, tags: $tags)';
  }
}

/// Search criteria for finding users
class UserSearchCriteria {
  const UserSearchCriteria({
    this.namePattern,
    this.emailPattern,
    this.isActive,
    this.createdAfter,
    this.createdBefore,
    this.tags = const [],
    this.limit = 50,
    this.offset = 0,
  });

  final String? namePattern;
  final String? emailPattern;
  final bool? isActive;
  final DateTime? createdAfter;
  final DateTime? createdBefore;
  final List<String> tags;
  final int limit;
  final int offset;

  /// Creates UserSearchCriteria from JSON
  factory UserSearchCriteria.fromJson(Map<String, dynamic> json) {
    return UserSearchCriteria(
      namePattern: json['namePattern'] as String?,
      emailPattern: json['emailPattern'] as String?,
      isActive: json['isActive'] as bool?,
      createdAfter: json['createdAfter'] != null 
          ? DateTime.parse(json['createdAfter'] as String)
          : null,
      createdBefore: json['createdBefore'] != null 
          ? DateTime.parse(json['createdBefore'] as String)
          : null,
      tags: List<String>.from(json['tags'] as List? ?? []),
      limit: json['limit'] as int? ?? 50,
      offset: json['offset'] as int? ?? 0,
    );
  }

  /// Converts UserSearchCriteria to JSON
  Map<String, dynamic> toJson() {
    return {
      'namePattern': namePattern,
      'emailPattern': emailPattern,
      'isActive': isActive,
      'createdAfter': createdAfter?.toIso8601String(),
      'createdBefore': createdBefore?.toIso8601String(),
      'tags': tags,
      'limit': limit,
      'offset': offset,
    };
  }
}

/// Result of a user search operation
class UserSearchResult {
  const UserSearchResult({
    required this.users,
    required this.totalCount,
    required this.hasMore,
    required this.searchTime,
  });

  final List<User> users;
  final int totalCount;
  final bool hasMore;
  final Duration searchTime;

  /// Creates UserSearchResult from JSON
  factory UserSearchResult.fromJson(Map<String, dynamic> json) {
    return UserSearchResult(
      users: (json['users'] as List)
          .map((userJson) => User.fromJson(userJson as Map<String, dynamic>))
          .toList(),
      totalCount: json['totalCount'] as int,
      hasMore: json['hasMore'] as bool,
      searchTime: Duration(microseconds: json['searchTimeMicros'] as int),
    );
  }

  /// Converts UserSearchResult to JSON
  Map<String, dynamic> toJson() {
    return {
      'users': users.map((user) => user.toJson()).toList(),
      'totalCount': totalCount,
      'hasMore': hasMore,
      'searchTimeMicros': searchTime.inMicroseconds,
    };
  }

  @override
  String toString() {
    return 'UserSearchResult(count: ${users.length}/$totalCount, hasMore: $hasMore)';
  }
}

/// Analytics data for users
class UserAnalytics {
  const UserAnalytics({
    required this.totalUsers,
    required this.activeUsers,
    required this.newUsersToday,
    required this.averageProfileScore,
    required this.topTags,
    required this.generatedAt,
  });

  final int totalUsers;
  final int activeUsers;
  final int newUsersToday;
  final double averageProfileScore;
  final Map<String, int> topTags;
  final DateTime generatedAt;

  /// Creates UserAnalytics from JSON
  factory UserAnalytics.fromJson(Map<String, dynamic> json) {
    return UserAnalytics(
      totalUsers: json['totalUsers'] as int,
      activeUsers: json['activeUsers'] as int,
      newUsersToday: json['newUsersToday'] as int,
      averageProfileScore: (json['averageProfileScore'] as num).toDouble(),
      topTags: Map<String, int>.from(json['topTags'] as Map),
      generatedAt: DateTime.parse(json['generatedAt'] as String),
    );
  }

  /// Converts UserAnalytics to JSON
  Map<String, dynamic> toJson() {
    return {
      'totalUsers': totalUsers,
      'activeUsers': activeUsers,
      'newUsersToday': newUsersToday,
      'averageProfileScore': averageProfileScore,
      'topTags': topTags,
      'generatedAt': generatedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'UserAnalytics(total: $totalUsers, active: $activeUsers, new: $newUsersToday)';
  }
}
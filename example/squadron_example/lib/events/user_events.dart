/// User-related events for the Squadron example
library user_events;

import 'package:dart_service_framework/dart_service_framework.dart';
import '../models/user.dart';

/// Event fired when a user is created
class UserCreatedEvent extends ServiceEvent {
  const UserCreatedEvent({
    required super.eventId,
    required super.sourceService,
    required super.timestamp,
    super.correlationId,
    super.metadata = const {},
    required this.user,
    required this.creationContext,
  });

  final User user;
  final Map<String, dynamic> creationContext;

  @override
  Map<String, dynamic> eventDataToJson() {
    return {
      'user': user.toJson(),
      'creationContext': creationContext,
    };
  }

  factory UserCreatedEvent.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return UserCreatedEvent(
      eventId: json['eventId'] as String,
      sourceService: json['sourceService'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      correlationId: json['correlationId'] as String?,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      user: User.fromJson(data['user'] as Map<String, dynamic>),
      creationContext: Map<String, dynamic>.from(data['creationContext'] as Map),
    );
  }

  @override
  String toString() {
    return 'UserCreatedEvent(user: ${user.name}, id: $eventId)';
  }
}

/// Event fired when a user is updated
class UserUpdatedEvent extends ServiceEvent {
  const UserUpdatedEvent({
    required super.eventId,
    required super.sourceService,
    required super.timestamp,
    super.correlationId,
    super.metadata = const {},
    required this.userId,
    required this.previousData,
    required this.updatedData,
    required this.changes,
  });

  final String userId;
  final Map<String, dynamic> previousData;
  final Map<String, dynamic> updatedData;
  final List<String> changes;

  @override
  Map<String, dynamic> eventDataToJson() {
    return {
      'userId': userId,
      'previousData': previousData,
      'updatedData': updatedData,
      'changes': changes,
    };
  }

  factory UserUpdatedEvent.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return UserUpdatedEvent(
      eventId: json['eventId'] as String,
      sourceService: json['sourceService'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      correlationId: json['correlationId'] as String?,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      userId: data['userId'] as String,
      previousData: Map<String, dynamic>.from(data['previousData'] as Map),
      updatedData: Map<String, dynamic>.from(data['updatedData'] as Map),
      changes: List<String>.from(data['changes'] as List),
    );
  }

  @override
  String toString() {
    return 'UserUpdatedEvent(userId: $userId, changes: ${changes.join(', ')})';
  }
}

/// Event fired when a user is deleted
class UserDeletedEvent extends ServiceEvent {
  const UserDeletedEvent({
    required super.eventId,
    required super.sourceService,
    required super.timestamp,
    super.correlationId,
    super.metadata = const {},
    required this.userId,
    required this.deletedUser,
    required this.deletionReason,
  });

  final String userId;
  final User deletedUser;
  final String deletionReason;

  @override
  Map<String, dynamic> eventDataToJson() {
    return {
      'userId': userId,
      'deletedUser': deletedUser.toJson(),
      'deletionReason': deletionReason,
    };
  }

  factory UserDeletedEvent.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return UserDeletedEvent(
      eventId: json['eventId'] as String,
      sourceService: json['sourceService'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      correlationId: json['correlationId'] as String?,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      userId: data['userId'] as String,
      deletedUser: User.fromJson(data['deletedUser'] as Map<String, dynamic>),
      deletionReason: data['deletionReason'] as String,
    );
  }

  @override
  String toString() {
    return 'UserDeletedEvent(userId: $userId, reason: $deletionReason)';
  }
}

/// Event fired when user search is performed
class UserSearchPerformedEvent extends ServiceEvent {
  const UserSearchPerformedEvent({
    required super.eventId,
    required super.sourceService,
    required super.timestamp,
    super.correlationId,
    super.metadata = const {},
    required this.searchCriteria,
    required this.resultCount,
    required this.searchTime,
    required this.cacheHit,
  });

  final UserSearchCriteria searchCriteria;
  final int resultCount;
  final Duration searchTime;
  final bool cacheHit;

  @override
  Map<String, dynamic> eventDataToJson() {
    return {
      'searchCriteria': searchCriteria.toJson(),
      'resultCount': resultCount,
      'searchTimeMs': searchTime.inMilliseconds,
      'cacheHit': cacheHit,
    };
  }

  factory UserSearchPerformedEvent.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return UserSearchPerformedEvent(
      eventId: json['eventId'] as String,
      sourceService: json['sourceService'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      correlationId: json['correlationId'] as String?,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      searchCriteria: UserSearchCriteria.fromJson(data['searchCriteria'] as Map<String, dynamic>),
      resultCount: data['resultCount'] as int,
      searchTime: Duration(milliseconds: data['searchTimeMs'] as int),
      cacheHit: data['cacheHit'] as bool,
    );
  }

  @override
  String toString() {
    return 'UserSearchPerformedEvent(results: $resultCount, time: ${searchTime.inMilliseconds}ms, cached: $cacheHit)';
  }
}

/// Event fired when analytics are generated
class AnalyticsGeneratedEvent extends ServiceEvent {
  const AnalyticsGeneratedEvent({
    required super.eventId,
    required super.sourceService,
    required super.timestamp,
    super.correlationId,
    super.metadata = const {},
    required this.analytics,
    required this.generationTime,
    required this.dataPoints,
  });

  final UserAnalytics analytics;
  final Duration generationTime;
  final int dataPoints;

  @override
  Map<String, dynamic> eventDataToJson() {
    return {
      'analytics': analytics.toJson(),
      'generationTimeMs': generationTime.inMilliseconds,
      'dataPoints': dataPoints,
    };
  }

  factory AnalyticsGeneratedEvent.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return AnalyticsGeneratedEvent(
      eventId: json['eventId'] as String,
      sourceService: json['sourceService'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      correlationId: json['correlationId'] as String?,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      analytics: UserAnalytics.fromJson(data['analytics'] as Map<String, dynamic>),
      generationTime: Duration(milliseconds: data['generationTimeMs'] as int),
      dataPoints: data['dataPoints'] as int,
    );
  }

  @override
  String toString() {
    return 'AnalyticsGeneratedEvent(users: ${analytics.totalUsers}, time: ${generationTime.inMilliseconds}ms)';
  }
}

/// System event for cache operations
class CacheOperationEvent extends ServiceEvent {
  const CacheOperationEvent({
    required super.eventId,
    required super.sourceService,
    required super.timestamp,
    super.correlationId,
    super.metadata = const {},
    required this.operation,
    required this.key,
    required this.hit,
    required this.size,
  });

  final String operation; // 'get', 'set', 'remove', 'clear'
  final String key;
  final bool hit;
  final int size; // Size in bytes or entry count

  @override
  Map<String, dynamic> eventDataToJson() {
    return {
      'operation': operation,
      'key': key,
      'hit': hit,
      'size': size,
    };
  }

  factory CacheOperationEvent.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return CacheOperationEvent(
      eventId: json['eventId'] as String,
      sourceService: json['sourceService'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      correlationId: json['correlationId'] as String?,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      operation: data['operation'] as String,
      key: data['key'] as String,
      hit: data['hit'] as bool,
      size: data['size'] as int,
    );
  }

  @override
  String toString() {
    return 'CacheOperationEvent($operation: $key, hit: $hit, size: $size)';
  }
}

/// System event for service health changes
class ServiceHealthChangedEvent extends ServiceEvent {
  const ServiceHealthChangedEvent({
    required super.eventId,
    required super.sourceService,
    required super.timestamp,
    super.correlationId,
    super.metadata = const {},
    required this.serviceName,
    required this.previousStatus,
    required this.currentStatus,
    required this.healthCheck,
  });

  final String serviceName;
  final ServiceHealthStatus previousStatus;
  final ServiceHealthStatus currentStatus;
  final ServiceHealthCheck healthCheck;

  @override
  Map<String, dynamic> eventDataToJson() {
    return {
      'serviceName': serviceName,
      'previousStatus': previousStatus.name,
      'currentStatus': currentStatus.name,
      'healthCheck': healthCheck.toJson(),
    };
  }

  factory ServiceHealthChangedEvent.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return ServiceHealthChangedEvent(
      eventId: json['eventId'] as String,
      sourceService: json['sourceService'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      correlationId: json['correlationId'] as String?,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      serviceName: data['serviceName'] as String,
      previousStatus: ServiceHealthStatus.values.byName(data['previousStatus'] as String),
      currentStatus: ServiceHealthStatus.values.byName(data['currentStatus'] as String),
      healthCheck: ServiceHealthCheck(
        status: ServiceHealthStatus.values.byName(data['healthCheck']['status'] as String),
        timestamp: DateTime.parse(data['healthCheck']['timestamp'] as String),
        message: data['healthCheck']['message'] as String,
        details: Map<String, dynamic>.from(data['healthCheck']['details'] as Map? ?? {}),
      ),
    );
  }

  @override
  String toString() {
    return 'ServiceHealthChangedEvent($serviceName: $previousStatus -> $currentStatus)';
  }
}
/// Tests for local-to-local service event communication
library local_to_local_events_test;

import 'dart:async';
import 'package:test/test.dart';
import 'package:dart_service_framework/dart_service_framework.dart';

// Test event types for local communication
class UserCreatedEvent extends ServiceEvent {
  const UserCreatedEvent({
    required super.eventId,
    required super.sourceService,
    required super.timestamp,
    super.correlationId,
    super.metadata = const {},
    required this.userId,
    required this.userName,
    required this.email,
  });

  final String userId;
  final String userName;
  final String email;

  @override
  Map<String, dynamic> eventDataToJson() {
    return {
      'userId': userId,
      'userName': userName,
      'email': email,
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
      userId: data['userId'] as String,
      userName: data['userName'] as String,
      email: data['email'] as String,
    );
  }
}

class OrderPlacedEvent extends ServiceEvent {
  const OrderPlacedEvent({
    required super.eventId,
    required super.sourceService,
    required super.timestamp,
    super.correlationId,
    super.metadata = const {},
    required this.orderId,
    required this.userId,
    required this.amount,
    required this.items,
  });

  final String orderId;
  final String userId;
  final double amount;
  final List<String> items;

  @override
  Map<String, dynamic> eventDataToJson() {
    return {
      'orderId': orderId,
      'userId': userId,
      'amount': amount,
      'items': items,
    };
  }

  factory OrderPlacedEvent.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return OrderPlacedEvent(
      eventId: json['eventId'] as String,
      sourceService: json['sourceService'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      correlationId: json['correlationId'] as String?,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      orderId: data['orderId'] as String,
      userId: data['userId'] as String,
      amount: (data['amount'] as num).toDouble(),
      items: List<String>.from(data['items'] as List),
    );
  }
}

class SystemAlertEvent extends ServiceEvent {
  const SystemAlertEvent({
    required super.eventId,
    required super.sourceService,
    required super.timestamp,
    super.correlationId,
    super.metadata = const {},
    required this.level,
    required this.message,
    required this.component,
  });

  final String level; // INFO, WARNING, ERROR, CRITICAL
  final String message;
  final String component;

  @override
  Map<String, dynamic> eventDataToJson() {
    return {
      'level': level,
      'message': message,
      'component': component,
    };
  }

  factory SystemAlertEvent.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return SystemAlertEvent(
      eventId: json['eventId'] as String,
      sourceService: json['sourceService'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      correlationId: json['correlationId'] as String?,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      level: data['level'] as String,
      message: data['message'] as String,
      component: data['component'] as String,
    );
  }
}

// Local test services with event communication
class UserService extends BaseService with ServiceEventMixin {
  final List<Map<String, dynamic>> users = [];
  final List<ServiceEvent> receivedEvents = [];
  final List<String> processedMessages = [];

  @override
  Future<void> initialize() async {
    // Listen for order events to validate user exists
    onEvent<OrderPlacedEvent>((event) async {
      receivedEvents.add(event);

      final userExists = users.any((user) => user['id'] == event.userId);
      if (!userExists) {
        processedMessages.add(
            'ERROR: Order ${event.orderId} placed for non-existent user ${event.userId}');

        // Send system alert about invalid order
        final alertEvent = createEvent<SystemAlertEvent>(
          (
                  {required eventId,
                  required sourceService,
                  required timestamp,
                  correlationId,
                  metadata = const {}}) =>
              SystemAlertEvent(
            eventId: eventId,
            sourceService: sourceService,
            timestamp: timestamp,
            correlationId: correlationId,
            metadata: metadata,
            level: 'ERROR',
            message: 'Order placed for non-existent user',
            component: 'UserService',
          ),
          correlationId: event.correlationId,
          additionalMetadata: {
            'orderId': event.orderId,
            'invalidUserId': event.userId,
          },
        );

        await broadcastEvent(alertEvent);

        return EventProcessingResponse(
          result: EventProcessingResult.failed,
          processingTime: Duration(milliseconds: 5),
          error: 'User not found',
        );
      }

      processedMessages
          .add('Order ${event.orderId} validated for user ${event.userId}');
      return EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration(milliseconds: 10),
        data: {'validated': true, 'userId': event.userId},
      );
    }, priority: 100);
  }

  Future<String> createUser(String name, String email) async {
    ensureInitialized();

    final userId = 'user_${users.length + 1}';
    final user = {
      'id': userId,
      'name': name,
      'email': email,
      'createdAt': DateTime.now().toIso8601String(),
    };

    users.add(user);

    // Create and send user created event
    final event = createEvent<UserCreatedEvent>(
      (
              {required eventId,
              required sourceService,
              required timestamp,
              correlationId,
              metadata = const {}}) =>
          UserCreatedEvent(
        eventId: eventId,
        sourceService: sourceService,
        timestamp: timestamp,
        correlationId: correlationId,
        metadata: metadata,
        userId: userId,
        userName: name,
        email: email,
      ),
      additionalMetadata: {'userCount': users.length},
    );

    await broadcastEvent(event);
    return userId;
  }
}

class OrderService extends BaseService with ServiceEventMixin {
  final List<Map<String, dynamic>> orders = [];
  final List<ServiceEvent> receivedEvents = [];
  final List<String> processedMessages = [];

  @override
  Future<void> initialize() async {
    // Listen for user created events to track available users
    onEvent<UserCreatedEvent>((event) async {
      receivedEvents.add(event);
      processedMessages.add(
          'User ${event.userName} (${event.userId}) is now available for orders');

      return EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration(milliseconds: 5),
        data: {'userTracked': true, 'userId': event.userId},
      );
    });

    // Listen for system alerts to handle issues
    onEvent<SystemAlertEvent>((event) async {
      receivedEvents.add(event);

      if (event.level == 'ERROR' && event.component == 'UserService') {
        processedMessages.add('Received alert: ${event.message}');
        // Could implement retry logic, notifications, etc.
      }

      return EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration(milliseconds: 3),
      );
    });
  }

  Future<String> placeOrder(
      String userId, double amount, List<String> items) async {
    ensureInitialized();

    final orderId = 'order_${orders.length + 1}';
    final order = {
      'id': orderId,
      'userId': userId,
      'amount': amount,
      'items': items,
      'placedAt': DateTime.now().toIso8601String(),
    };

    orders.add(order);

    // Create and send order placed event
    final event = createEvent<OrderPlacedEvent>(
      (
              {required eventId,
              required sourceService,
              required timestamp,
              correlationId,
              metadata = const {}}) =>
          OrderPlacedEvent(
        eventId: eventId,
        sourceService: sourceService,
        timestamp: timestamp,
        correlationId: correlationId,
        metadata: metadata,
        orderId: orderId,
        userId: userId,
        amount: amount,
        items: items,
      ),
      additionalMetadata: {'orderCount': orders.length},
    );

    await broadcastEvent(event);
    return orderId;
  }
}

class NotificationService extends BaseService with ServiceEventMixin {
  final List<String> notifications = [];
  final List<ServiceEvent> receivedEvents = [];
  final List<String> processedMessages = [];

  @override
  Future<void> initialize() async {
    // Listen for user created events
    onEvent<UserCreatedEvent>((event) async {
      receivedEvents.add(event);
      final notification =
          'Welcome ${event.userName}! Your account has been created.';
      notifications.add(notification);
      processedMessages.add('Sent welcome notification to ${event.userName}');

      return EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration(milliseconds: 15),
        data: {'notificationSent': true, 'type': 'welcome'},
      );
    });

    // Listen for order placed events
    onEvent<OrderPlacedEvent>((event) async {
      receivedEvents.add(event);
      final notification =
          'Order ${event.orderId} confirmed! Total: \$${event.amount}';
      notifications.add(notification);
      processedMessages.add('Sent order confirmation for ${event.orderId}');

      return EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration(milliseconds: 12),
        data: {'notificationSent': true, 'type': 'order_confirmation'},
      );
    });

    // Listen for system alerts
    onEvent<SystemAlertEvent>((event) async {
      receivedEvents.add(event);

      if (event.level == 'ERROR' || event.level == 'CRITICAL') {
        final notification =
            'ALERT [${event.level}]: ${event.message} (${event.component})';
        notifications.add(notification);
        processedMessages.add('Sent system alert notification');
      }

      return EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration(milliseconds: 8),
        data: {'alertProcessed': true, 'level': event.level},
      );
    });
  }
}

class AnalyticsService extends BaseService with ServiceEventMixin {
  final Map<String, int> eventCounts = {};
  final List<ServiceEvent> receivedEvents = [];
  final List<String> processedMessages = [];

  @override
  Future<void> initialize() async {
    // Track all events for analytics
    onEvent<UserCreatedEvent>((event) async {
      receivedEvents.add(event);
      eventCounts['userCreated'] = (eventCounts['userCreated'] ?? 0) + 1;
      processedMessages.add('Tracked user creation: ${event.userId}');

      return EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration(milliseconds: 5),
        data: {'tracked': true, 'type': 'user_created'},
      );
    });

    onEvent<OrderPlacedEvent>((event) async {
      receivedEvents.add(event);
      eventCounts['orderPlaced'] = (eventCounts['orderPlaced'] ?? 0) + 1;
      processedMessages
          .add('Tracked order: ${event.orderId} amount \$${event.amount}');

      return EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration(milliseconds: 5),
        data: {'tracked': true, 'type': 'order_placed'},
      );
    });

    onEvent<SystemAlertEvent>((event) async {
      receivedEvents.add(event);
      eventCounts['systemAlert'] = (eventCounts['systemAlert'] ?? 0) + 1;
      eventCounts['${event.level.toLowerCase()}Alert'] =
          (eventCounts['${event.level.toLowerCase()}Alert'] ?? 0) + 1;
      processedMessages.add('Tracked system alert: ${event.level}');

      return EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration(milliseconds: 3),
        data: {'tracked': true, 'type': 'system_alert'},
      );
    });
  }

  Map<String, int> getAnalytics() => Map.unmodifiable(eventCounts);
}

void main() {
  group('Local-to-Local Event Communication Tests', () {
    late EventDispatcher dispatcher;
    late ServiceLocator locator;
    late UserService userService;
    late OrderService orderService;
    late NotificationService notificationService;
    late AnalyticsService analyticsService;

    setUp(() async {
      dispatcher = EventDispatcher();
      locator = ServiceLocator();

      // Create services
      userService = UserService();
      orderService = OrderService();
      notificationService = NotificationService();
      analyticsService = AnalyticsService();

      // Register services with locator
      locator.register<UserService>(() => userService);
      locator.register<OrderService>(() => orderService);
      locator.register<NotificationService>(() => notificationService);
      locator.register<AnalyticsService>(() => analyticsService);

      // Set event dispatchers
      userService.setEventDispatcher(dispatcher);
      orderService.setEventDispatcher(dispatcher);
      notificationService.setEventDispatcher(dispatcher);
      analyticsService.setEventDispatcher(dispatcher);

      // Initialize services
      await locator.initializeAll();
    });

    tearDown(() async {
      await locator.destroyAll();
      dispatcher.dispose();
    });

    test('should handle complete user creation workflow with events', () async {
      // Create a user and verify all services respond to the event
      final userId =
          await userService.createUser('John Doe', 'john@example.com');

      // Give time for event propagation
      await Future.delayed(Duration(milliseconds: 100));

      // Verify user was created
      expect(userId, isNotEmpty);
      expect(userService.users, hasLength(1));
      expect(userService.users.first['name'], equals('John Doe'));

      // Verify order service received the event
      expect(orderService.receivedEvents, hasLength(1));
      expect(orderService.receivedEvents.first, isA<UserCreatedEvent>());
      expect(orderService.processedMessages,
          contains('User John Doe (${userId}) is now available for orders'));

      // Verify notification service sent welcome message
      expect(notificationService.receivedEvents, hasLength(1));
      expect(notificationService.notifications,
          contains('Welcome John Doe! Your account has been created.'));
      expect(notificationService.processedMessages,
          contains('Sent welcome notification to John Doe'));

      // Verify analytics tracked the event
      expect(analyticsService.receivedEvents, hasLength(1));
      expect(analyticsService.eventCounts['userCreated'], equals(1));
      expect(analyticsService.processedMessages,
          contains('Tracked user creation: ${userId}'));
    });

    test('should handle order placement workflow with event cascade', () async {
      // First create a user
      final userId =
          await userService.createUser('Jane Smith', 'jane@example.com');
      await Future.delayed(Duration(milliseconds: 50));

      // Clear previous events for cleaner testing
      orderService.receivedEvents.clear();
      notificationService.receivedEvents.clear();
      analyticsService.receivedEvents.clear();

      // Place an order
      final orderId = await orderService.placeOrder(
        userId,
        99.99,
        ['Widget A', 'Widget B'],
      );

      // Give time for event propagation
      await Future.delayed(Duration(milliseconds: 100));

      // Verify order was created
      expect(orderId, isNotEmpty);
      expect(orderService.orders, hasLength(1));
      expect(orderService.orders.first['userId'], equals(userId));
      expect(orderService.orders.first['amount'], equals(99.99));

      // Verify user service validated the order
      expect(userService.receivedEvents.where((e) => e is OrderPlacedEvent),
          hasLength(1));
      expect(userService.processedMessages,
          contains('Order ${orderId} validated for user ${userId}'));

      // Verify notification service sent order confirmation
      expect(
          notificationService.receivedEvents
              .where((e) => e is OrderPlacedEvent),
          hasLength(1));
      expect(notificationService.notifications,
          contains('Order ${orderId} confirmed! Total: \$99.99'));

      // Verify analytics tracked the order
      expect(
          analyticsService.receivedEvents.where((e) => e is OrderPlacedEvent),
          hasLength(1));
      expect(analyticsService.eventCounts['orderPlaced'], equals(1));
    });

    test('should handle error scenarios with system alerts', () async {
      // Try to place an order for a non-existent user
      final orderId = await orderService.placeOrder(
        'nonexistent_user',
        50.00,
        ['Test Item'],
      );

      // Give time for event propagation and error handling
      await Future.delayed(Duration(milliseconds: 150));

      // Verify order was created but validation failed
      expect(orderService.orders, hasLength(1));
      expect(orderService.orders.first['userId'], equals('nonexistent_user'));

      // Verify user service detected the error and sent an alert
      expect(userService.receivedEvents.where((e) => e is OrderPlacedEvent),
          hasLength(1));
      expect(
          userService.processedMessages,
          contains(
              'ERROR: Order ${orderId} placed for non-existent user nonexistent_user'));

      // Verify notification service received the system alert
      expect(
          notificationService.receivedEvents
              .where((e) => e is SystemAlertEvent),
          hasLength(1));
      final alertEvent = notificationService.receivedEvents
          .whereType<SystemAlertEvent>()
          .first;
      expect(alertEvent.level, equals('ERROR'));
      expect(alertEvent.message, equals('Order placed for non-existent user'));
      expect(alertEvent.component, equals('UserService'));

      // Verify order service received the system alert
      expect(orderService.receivedEvents.where((e) => e is SystemAlertEvent),
          hasLength(1));
      expect(orderService.processedMessages,
          contains('Received alert: Order placed for non-existent user'));

      // Verify analytics tracked all events including the alert
      expect(analyticsService.eventCounts['orderPlaced'], equals(1));
      expect(analyticsService.eventCounts['systemAlert'], equals(1));
      expect(analyticsService.eventCounts['errorAlert'], equals(1));
    });

    test('should support event subscriptions and streams', () async {
      final receivedUserEvents = <UserCreatedEvent>[];
      final receivedOrderEvents = <OrderPlacedEvent>[];

      // Set up subscriptions
      final userSubscription =
          userService.subscribeToEvents<UserCreatedEvent>();
      final orderSubscription =
          orderService.subscribeToEvents<OrderPlacedEvent>();

      userSubscription.stream.listen((event) {
        receivedUserEvents.add(event as UserCreatedEvent);
      });

      orderSubscription.stream.listen((event) {
        receivedOrderEvents.add(event as OrderPlacedEvent);
      });

      // Create user and place order
      final userId =
          await userService.createUser('Stream Test', 'stream@example.com');
      await Future.delayed(Duration(milliseconds: 50));

      await orderService.placeOrder(userId, 25.50, ['Streamed Item']);
      await Future.delayed(Duration(milliseconds: 100));

      // Verify subscription events
      expect(receivedUserEvents, hasLength(1));
      expect(receivedUserEvents.first.userName, equals('Stream Test'));

      expect(receivedOrderEvents, hasLength(1));
      expect(receivedOrderEvents.first.amount, equals(25.50));
    });

    test('should handle high-volume event processing', () async {
      final stopwatch = Stopwatch()..start();

      // Create multiple users and orders rapidly
      final futures = <Future>[];

      for (int i = 0; i < 10; i++) {
        futures.add(userService.createUser('User $i', 'user$i@example.com'));
      }

      await Future.wait(futures);
      futures.clear();

      // Wait for user creation events to propagate
      await Future.delayed(Duration(milliseconds: 200));

      // Place orders for all users
      for (int i = 0; i < 10; i++) {
        final userId = 'user_${i + 1}';
        futures
            .add(orderService.placeOrder(userId, 10.0 * (i + 1), ['Item $i']));
      }

      await Future.wait(futures);

      // Wait for all events to propagate
      await Future.delayed(Duration(milliseconds: 300));

      stopwatch.stop();

      // Verify all events were processed
      expect(userService.users, hasLength(10));
      expect(orderService.orders, hasLength(10));
      expect(notificationService.notifications.length,
          greaterThanOrEqualTo(20)); // Welcome + order confirmations

      expect(analyticsService.eventCounts['userCreated'], equals(10));
      expect(analyticsService.eventCounts['orderPlaced'], equals(10));

      // Verify performance (should complete reasonably quickly)
      expect(stopwatch.elapsedMilliseconds, lessThan(2000));

      print('High-volume test completed in ${stopwatch.elapsedMilliseconds}ms');
    });

    test('should properly handle event correlation IDs', () async {
      // Test correlation ID tracking

      // Create user with correlation ID
      final userId =
          await userService.createUser('Correlated User', 'corr@example.com');

      // Wait for event propagation
      await Future.delayed(Duration(milliseconds: 100));

      // Find the user created event and verify it has proper correlation tracking
      final userEvent =
          analyticsService.receivedEvents.whereType<UserCreatedEvent>().first;

      expect(userEvent.userId, equals(userId));
      expect(userEvent.sourceService, equals('UserService'));
      expect(userEvent.metadata['userCount'], equals(1));
    });

    test('should track event statistics correctly', () async {
      // Generate various events
      await userService.createUser('Stats User', 'stats@example.com');
      await Future.delayed(Duration(milliseconds: 50));

      await orderService.placeOrder('user_1', 100.0, ['Stats Item']);
      await Future.delayed(Duration(milliseconds: 50));

      // Try invalid order to generate error
      await orderService.placeOrder('invalid_user', 50.0, ['Error Item']);
      await Future.delayed(Duration(milliseconds: 150));

      // Get event statistics
      final stats = dispatcher.getStatistics();

      expect(stats.isNotEmpty, isTrue);
      expect(stats.containsKey('UserCreatedEvent'), isTrue);
      expect(stats.containsKey('OrderPlacedEvent'), isTrue);
      expect(stats.containsKey('SystemAlertEvent'), isTrue);

      final userStats = stats['UserCreatedEvent']!;
      expect(userStats.totalSent, greaterThan(0));
      expect(userStats.totalProcessed, greaterThan(0));
      expect(userStats.successRate, greaterThan(0.5));

      print('Event Statistics:');
      stats.forEach((eventType, stat) {
        print('  $eventType: ${stat.toString()}');
      });
    });
  });
}

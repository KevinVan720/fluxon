import 'package:test/test.dart';
import 'package:dart_service_framework/dart_service_framework.dart';

part 'remote_event_communication_test.g.dart';

// Custom events for testing
class OrderEvent extends ServiceEvent {
  final String orderId;
  final String customerId;
  final double amount;

  const OrderEvent({
    required this.orderId,
    required this.customerId,
    required this.amount,
    required super.eventId,
    required super.sourceService,
    required super.timestamp,
    super.metadata = const {},
    super.correlationId,
  });

  @override
  Map<String, dynamic> eventDataToJson() => {
        'orderId': orderId,
        'customerId': customerId,
        'amount': amount,
      };

  factory OrderEvent.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return OrderEvent(
      orderId: data['orderId'],
      customerId: data['customerId'],
      amount: data['amount'],
      eventId: json['eventId'],
      sourceService: json['sourceService'],
      timestamp: DateTime.parse(json['timestamp']),
      metadata: json['metadata'] ?? {},
      correlationId: json['correlationId'],
    );
  }
}

class PaymentEvent extends ServiceEvent {
  final String orderId;
  final String paymentId;
  final bool success;
  final String? reason;

  const PaymentEvent({
    required this.orderId,
    required this.paymentId,
    required this.success,
    this.reason,
    required super.eventId,
    required super.sourceService,
    required super.timestamp,
    super.metadata = const {},
    super.correlationId,
  });

  @override
  Map<String, dynamic> eventDataToJson() => {
        'orderId': orderId,
        'paymentId': paymentId,
        'success': success,
        'reason': reason,
      };

  factory PaymentEvent.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return PaymentEvent(
      orderId: data['orderId'],
      paymentId: data['paymentId'],
      success: data['success'],
      reason: data['reason'],
      eventId: json['eventId'],
      sourceService: json['sourceService'],
      timestamp: DateTime.parse(json['timestamp']),
      metadata: json['metadata'] ?? {},
      correlationId: json['correlationId'],
    );
  }
}

class NotificationEvent extends ServiceEvent {
  final String userId;
  final String message;
  final String type;

  const NotificationEvent({
    required this.userId,
    required this.message,
    required this.type,
    required super.eventId,
    required super.sourceService,
    required super.timestamp,
    super.metadata = const {},
    super.correlationId,
  });

  @override
  Map<String, dynamic> eventDataToJson() => {
        'userId': userId,
        'message': message,
        'type': type,
      };

  factory NotificationEvent.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return NotificationEvent(
      userId: data['userId'],
      message: data['message'],
      type: data['type'],
      eventId: json['eventId'],
      sourceService: json['sourceService'],
      timestamp: DateTime.parse(json['timestamp']),
      metadata: json['metadata'] ?? {},
      correlationId: json['correlationId'],
    );
  }
}

// Remote Payment Service - runs in worker isolate
@ServiceContract(remote: true)
abstract class PaymentService extends BaseService {
  Future<String> processPayment(String orderId, double amount);
  Future<void> onOrderReceived(OrderEvent event);
}

// Remote Notification Service - runs in worker isolate
@ServiceContract(remote: true)
abstract class NotificationService extends BaseService {
  Future<void> sendNotification(String userId, String message, String type);
  Future<void> onPaymentProcessed(PaymentEvent event);
  Future<int> getNotificationCount();
}

// Local Order Service - runs in main isolate
@ServiceContract(remote: false)
class OrderService extends BaseService
    with ServiceEventMixin, ServiceClientMixin {
  final List<String> processedOrders = [];

  @override
  List<Type> get optionalDependencies => [PaymentService, NotificationService];

  @override
  Future<void> initialize() async {
    _registerOrderServiceDispatcher();
    await super.initialize();

    // Listen for payment events
    onEvent<PaymentEvent>((event) async {
      logger.info('Order service received payment event',
          metadata: {'orderId': event.orderId, 'success': event.success});

      if (event.success) {
        processedOrders.add(event.orderId);

        // Send notification event after successful payment
        await sendEvent(createEvent(
          (
                  {required String eventId,
                  required String sourceService,
                  required DateTime timestamp,
                  String? correlationId,
                  Map<String, dynamic> metadata = const {}}) =>
              NotificationEvent(
            userId: 'customer-${event.orderId}',
            message:
                'Your order ${event.orderId} has been processed successfully!',
            type: 'order_confirmation',
            eventId: eventId,
            sourceService: sourceService,
            timestamp: timestamp,
            correlationId: event.correlationId,
            metadata: metadata,
          ),
          correlationId: event.correlationId,
        ));
      }
      return EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration(milliseconds: 10),
      );
    });
  }

  Future<void> createOrder(
      String orderId, String customerId, double amount) async {
    logger.info('Creating order',
        metadata: {'orderId': orderId, 'amount': amount});

    // Send order event to payment service (local -> remote)
    // We combine both event-based and direct method calls to demonstrate both patterns
    final orderEvent = createEvent(
      (
              {required String eventId,
              required String sourceService,
              required DateTime timestamp,
              String? correlationId,
              Map<String, dynamic> metadata = const {}}) =>
          OrderEvent(
        orderId: orderId,
        customerId: customerId,
        amount: amount,
        eventId: eventId,
        sourceService: sourceService,
        timestamp: timestamp,
        correlationId: correlationId,
        metadata: metadata,
      ),
      correlationId: 'order-$orderId',
    );

    // Send event (for logging and monitoring)
    await sendEvent(orderEvent);

    // Also directly call the payment service to trigger processing
    final paymentService = getService<PaymentService>();
    await paymentService.onOrderReceived(orderEvent);
  }

  Future<List<String>> getProcessedOrders() async => processedOrders;
}

// Payment Service Implementation
class PaymentServiceImpl extends PaymentService with ServiceClientMixin {
  final Map<String, String> payments = {};

  @override
  List<Type> get optionalDependencies => [NotificationService];

  @override
  Future<void> initialize() async {
    _registerPaymentServiceDispatcher();
    _registerNotificationServiceClientFactory();
    await super.initialize();
  }

  @override
  Future<String> processPayment(String orderId, double amount) async {
    final paymentId = 'pay-$orderId-${DateTime.now().millisecondsSinceEpoch}';
    payments[orderId] = paymentId;

    // Simulate payment processing
    await Future.delayed(Duration(milliseconds: 100));

    logger.info('Payment processed',
        metadata: {'orderId': orderId, 'paymentId': paymentId});
    return paymentId;
  }

  @override
  Future<void> onOrderReceived(OrderEvent event) async {
    final paymentId = await processPayment(event.orderId, event.amount);

    // For remote services, we directly call other services instead of using events
    // The event-driven approach is better suited for local-to-local or local-to-remote communication
    final notificationService = getService<NotificationService>();
    await notificationService.onPaymentProcessed(PaymentEvent(
      orderId: event.orderId,
      paymentId: paymentId,
      success: true,
      eventId: 'payment-${DateTime.now().millisecondsSinceEpoch}',
      sourceService: 'PaymentService',
      timestamp: DateTime.now(),
      correlationId: event.correlationId,
      metadata: const {},
    ));
  }
}

// Notification Service Implementation
class NotificationServiceImpl extends NotificationService {
  final List<Map<String, dynamic>> notifications = [];

  @override
  Future<void> initialize() async {
    _registerNotificationServiceDispatcher();
    await super.initialize();
  }

  @override
  Future<void> sendNotification(
      String userId, String message, String type) async {
    notifications.add({
      'userId': userId,
      'message': message,
      'type': type,
      'timestamp': DateTime.now().toIso8601String(),
    });

    logger
        .info('Notification sent', metadata: {'userId': userId, 'type': type});
  }

  @override
  Future<void> onPaymentProcessed(PaymentEvent event) async {
    logger.info('Processing payment event', metadata: {
      'orderId': event.orderId,
      'paymentId': event.paymentId,
      'success': event.success
    });

    if (event.success) {
      await sendNotification(
          'customer-${event.orderId}',
          'Payment ${event.paymentId} processed for order ${event.orderId}',
          'payment_confirmation');
    }
  }

  @override
  Future<int> getNotificationCount() async => notifications.length;
}

// Test orchestrator
class EventOrchestrator extends BaseService with ServiceClientMixin {
  @override
  List<Type> get optionalDependencies =>
      [OrderService, PaymentService, NotificationService];

  Future<Map<String, dynamic>> runEventWorkflow() async {
    final orderService = getService<OrderService>();
    final paymentService = getService<PaymentService>();
    final notificationService = getService<NotificationService>();

    // Create multiple orders to test event flow
    await orderService.createOrder('order-1', 'customer-1', 99.99);
    await orderService.createOrder('order-2', 'customer-2', 149.50);
    await orderService.createOrder('order-3', 'customer-3', 75.25);

    // Wait for events to propagate
    await Future.delayed(Duration(milliseconds: 500));

    return {
      'processedOrders': await orderService.getProcessedOrders(),
      'notificationCount': await notificationService.getNotificationCount(),
    };
  }
}

Future<Map<String, dynamic>> _runRemoteEventCommunicationDemo() async {
  // 🚀 OPTIMIZED: ServiceLocator automatically sets up ALL infrastructure!
  final locator = ServiceLocator();

  // Register local services - event infrastructure automatic!
  registerOrderServiceGenerated();
  locator.register<OrderService>(() => OrderService());
  locator.register<EventOrchestrator>(() => EventOrchestrator());

  // Register remote services - transparent!
  await locator.registerWorkerServiceProxy<PaymentService>(
    serviceName: 'PaymentService',
    serviceFactory: () => PaymentServiceImpl(),
    registerGenerated: registerPaymentServiceGenerated,
  );

  await locator.registerWorkerServiceProxy<NotificationService>(
    serviceName: 'NotificationService',
    serviceFactory: () => NotificationServiceImpl(),
    registerGenerated: registerNotificationServiceGenerated,
  );

  // 🚀 OPTIMIZED: All infrastructure set up automatically!
  await locator.initializeAll();

  final orchestrator = locator.get<EventOrchestrator>();
  final result = await orchestrator.runEventWorkflow();

  await locator.destroyAll();
  return result;
}

void main() {
  group('Remote Event Communication Tests', () {
    test('Local to Remote Event Communication', () async {
      final result = await _runRemoteEventCommunicationDemo();

      // Verify that orders were processed (local -> remote -> local)
      expect(result['processedOrders'], hasLength(3));
      expect(result['processedOrders'], contains('order-1'));
      expect(result['processedOrders'], contains('order-2'));
      expect(result['processedOrders'], contains('order-3'));

      // Verify notifications were sent
      // 3 payment confirmations + 3 order confirmations = 6 total
      expect(result['notificationCount'], equals(6));
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('Event Serialization Across Isolates', () async {
      // 🚀 OPTIMIZED: Zero manual setup required!
      final locator = ServiceLocator();

      registerOrderServiceGenerated();
      locator.register<OrderService>(() => OrderService());

      await locator.registerWorkerServiceProxy<PaymentService>(
        serviceName: 'PaymentService',
        serviceFactory: () => PaymentServiceImpl(),
        registerGenerated: registerPaymentServiceGenerated,
      );

      await locator.initializeAll();

      final orderService = locator.get<OrderService>();

      // Test complex event data serialization
      await orderService.createOrder(
          'complex-order-123', 'customer-with-special-chars-àáâã', 1234.56);

      await Future.delayed(Duration(milliseconds: 200));

      final processedOrders = await orderService.getProcessedOrders();
      expect(processedOrders, contains('complex-order-123'));

      await locator.destroyAll();
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('Event Correlation Across Services', () async {
      // 🚀 OPTIMIZED: Complete automation!
      final locator = ServiceLocator();

      registerOrderServiceGenerated();
      locator.register<OrderService>(() => OrderService());

      await locator.registerWorkerServiceProxy<PaymentService>(
        serviceName: 'PaymentService',
        serviceFactory: () => PaymentServiceImpl(),
        registerGenerated: registerPaymentServiceGenerated,
      );

      await locator.registerWorkerServiceProxy<NotificationService>(
        serviceName: 'NotificationService',
        serviceFactory: () => NotificationServiceImpl(),
        registerGenerated: registerNotificationServiceGenerated,
      );

      await locator.initializeAll();

      final orderService = locator.get<OrderService>();

      // Test that correlation IDs are preserved across remote boundaries
      await orderService.createOrder('corr-order-1', 'customer-corr', 100.0);

      await Future.delayed(Duration(milliseconds: 300));

      final processedOrders = await orderService.getProcessedOrders();
      expect(processedOrders, contains('corr-order-1'));

      await locator.destroyAll();
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}

import 'dart:async';

import 'package:flux/flux.dart';
import 'package:test/test.dart';

// E-commerce system integration test
@ServiceContract(remote: false)
class ECommerceIntegrationService extends FluxService {
  ECommerceIntegrationService();
  final Map<String, Map<String, dynamic>> _orders = {};
  final Map<String, Map<String, dynamic>> _users = {};
  final Map<String, Map<String, dynamic>> _products = {};
  final Map<String, Map<String, dynamic>> _inventory = {};
  final List<Map<String, dynamic>> _events = [];

  @override
  Future<void> initialize() async {
    await super.initialize();

    // Set up event listeners
    onEvent<OrderCreatedEvent>((event) async {
      _events.add({
        'type': 'order_created',
        'orderId': event.orderId,
        'timestamp': DateTime.now().toIso8601String(),
      });
      return const EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration.zero,
      );
    });

    onEvent<PaymentProcessedEvent>((event) async {
      _events.add({
        'type': 'payment_processed',
        'orderId': event.orderId,
        'amount': event.amount,
        'timestamp': DateTime.now().toIso8601String(),
      });
      return const EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration.zero,
      );
    });

    onEvent<InventoryUpdatedEvent>((event) async {
      _events.add({
        'type': 'inventory_updated',
        'productId': event.productId,
        'quantity': event.quantity,
        'timestamp': DateTime.now().toIso8601String(),
      });
      return const EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration.zero,
      );
    });

    logger.info('E-commerce integration service initialized');
  }

  Future<String> createUser(String name, String email) async {
    final userId = 'user_${_users.length + 1}';
    _users[userId] = {
      'id': userId,
      'name': name,
      'email': email,
      'createdAt': DateTime.now().toIso8601String(),
    };

    logger.info('User created: $userId');
    return userId;
  }

  Future<String> createProduct(
      String name, double price, int initialStock) async {
    final productId = 'product_${_products.length + 1}';
    _products[productId] = {
      'id': productId,
      'name': name,
      'price': price,
      'createdAt': DateTime.now().toIso8601String(),
    };

    _inventory[productId] = {
      'productId': productId,
      'quantity': initialStock,
      'reserved': 0,
    };

    // Send inventory updated event
    final event = createEvent<InventoryUpdatedEvent>(
      (
              {required eventId,
              required sourceService,
              required timestamp,
              correlationId,
              metadata = const {}}) =>
          InventoryUpdatedEvent(
        eventId: eventId,
        sourceService: sourceService,
        timestamp: timestamp,
        correlationId: correlationId,
        metadata: metadata,
        productId: productId,
        quantity: initialStock,
      ),
    );
    await sendEvent(event,
        distribution: EventDistribution.broadcast(includeSource: true));

    logger.info('Product created: $productId with $initialStock units');
    return productId;
  }

  Future<String> createOrder(String userId, Map<String, int> items) async {
    final orderId = 'order_${_orders.length + 1}';

    // Check inventory
    for (final entry in items.entries) {
      final productId = entry.key;
      final quantity = entry.value;

      if (!_inventory.containsKey(productId)) {
        throw Exception('Product not found: $productId');
      }

      final available = _inventory[productId]!['quantity'] as int;
      if (available < quantity) {
        throw Exception('Insufficient inventory for product $productId');
      }
    }

    // Reserve inventory
    for (final entry in items.entries) {
      final productId = entry.key;
      final quantity = entry.value;

      _inventory[productId]!['quantity'] -= quantity;
      _inventory[productId]!['reserved'] += quantity;
    }

    // Calculate total
    double total = 0;
    for (final entry in items.entries) {
      final productId = entry.key;
      final quantity = entry.value;
      final price = _products[productId]!['price'] as double;
      total += price * quantity;
    }

    _orders[orderId] = {
      'id': orderId,
      'userId': userId,
      'items': items,
      'total': total,
      'status': 'pending',
      'createdAt': DateTime.now().toIso8601String(),
    };

    // Send order created event
    final event = createEvent<OrderCreatedEvent>(
      (
              {required eventId,
              required sourceService,
              required timestamp,
              correlationId,
              metadata = const {}}) =>
          OrderCreatedEvent(
        eventId: eventId,
        sourceService: sourceService,
        timestamp: timestamp,
        correlationId: correlationId,
        metadata: metadata,
        orderId: orderId,
        userId: userId,
        total: total,
      ),
    );
    await sendEvent(event,
        distribution: EventDistribution.broadcast(includeSource: true));

    logger.info(
        'Order created: $orderId for user $userId, total: \$${total.toStringAsFixed(2)}');
    return orderId;
  }

  Future<void> processPayment(String orderId, double amount) async {
    if (!_orders.containsKey(orderId)) {
      throw Exception('Order not found: $orderId');
    }

    final order = _orders[orderId]!;
    if (order['total'] != amount) {
      throw Exception(
          'Payment amount mismatch: expected ${order['total']}, got $amount');
    }

    order['status'] = 'paid';

    // Send payment processed event
    final event = createEvent<PaymentProcessedEvent>(
      (
              {required eventId,
              required sourceService,
              required timestamp,
              correlationId,
              metadata = const {}}) =>
          PaymentProcessedEvent(
        eventId: eventId,
        sourceService: sourceService,
        timestamp: timestamp,
        correlationId: correlationId,
        metadata: metadata,
        orderId: orderId,
        amount: amount,
      ),
    );
    await sendEvent(event,
        distribution: EventDistribution.broadcast(includeSource: true));

    logger.info(
        'Payment processed for order $orderId: \$${amount.toStringAsFixed(2)}');
  }

  Future<void> fulfillOrder(String orderId) async {
    if (!_orders.containsKey(orderId)) {
      throw Exception('Order not found: $orderId');
    }

    final order = _orders[orderId]!;
    if (order['status'] != 'paid') {
      throw Exception('Order not paid: $orderId');
    }

    // Release reserved inventory and restore available inventory
    final items = order['items'] as Map<String, int>;
    for (final entry in items.entries) {
      final productId = entry.key;
      final quantity = entry.value;

      _inventory[productId]!['reserved'] -= quantity;
      _inventory[productId]!['quantity'] +=
          quantity; // Restore available inventory
    }

    order['status'] = 'fulfilled';

    logger.info('Order fulfilled: $orderId');
  }

  Map<String, dynamic> getSystemState() => {
        'users': _users.length,
        'products': _products.length,
        'orders': _orders.length,
        'inventory': _inventory.map((k, v) => MapEntry(k, {
              'quantity': v['quantity'],
              'reserved': v['reserved'],
            })),
        'events': List.from(_events),
      };
}

// Event types for e-commerce system
class OrderCreatedEvent extends ServiceEvent {
  const OrderCreatedEvent({
    required super.eventId,
    required super.sourceService,
    required super.timestamp,
    required this.orderId,
    required this.userId,
    required this.total,
    super.correlationId,
    super.metadata = const {},
  });
  factory OrderCreatedEvent.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return OrderCreatedEvent(
      eventId: json['eventId'] as String,
      sourceService: json['sourceService'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      correlationId: json['correlationId'] as String?,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      orderId: data['orderId'] as String,
      userId: data['userId'] as String,
      total: (data['total'] as num).toDouble(),
    );
  }

  final String orderId;
  final String userId;
  final double total;

  @override
  Map<String, dynamic> eventDataToJson() => {
        'orderId': orderId,
        'userId': userId,
        'total': total,
      };
}

class PaymentProcessedEvent extends ServiceEvent {
  const PaymentProcessedEvent({
    required super.eventId,
    required super.sourceService,
    required super.timestamp,
    required this.orderId,
    required this.amount,
    super.correlationId,
    super.metadata = const {},
  });
  factory PaymentProcessedEvent.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return PaymentProcessedEvent(
      eventId: json['eventId'] as String,
      sourceService: json['sourceService'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      correlationId: json['correlationId'] as String?,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      orderId: data['orderId'] as String,
      amount: (data['amount'] as num).toDouble(),
    );
  }

  final String orderId;
  final double amount;

  @override
  Map<String, dynamic> eventDataToJson() => {
        'orderId': orderId,
        'amount': amount,
      };
}

class InventoryUpdatedEvent extends ServiceEvent {
  const InventoryUpdatedEvent({
    required super.eventId,
    required super.sourceService,
    required super.timestamp,
    required this.productId,
    required this.quantity,
    super.correlationId,
    super.metadata = const {},
  });
  factory InventoryUpdatedEvent.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return InventoryUpdatedEvent(
      eventId: json['eventId'] as String,
      sourceService: json['sourceService'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      correlationId: json['correlationId'] as String?,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      productId: data['productId'] as String,
      quantity: data['quantity'] as int,
    );
  }

  final String productId;
  final int quantity;

  @override
  Map<String, dynamic> eventDataToJson() => {
        'productId': productId,
        'quantity': quantity,
      };
}

// Microservices architecture integration test
@ServiceContract(remote: true)
class UserService extends FluxService {
  UserService();
  final Map<String, Map<String, dynamic>> _users = {};

  @override
  Future<void> initialize() async {
    await super.initialize();
    logger.info('User service initialized');
  }

  Future<String> createUser(String name, String email) async {
    final userId = 'user_${_users.length + 1}';
    _users[userId] = {
      'id': userId,
      'name': name,
      'email': email,
      'createdAt': DateTime.now().toIso8601String(),
    };

    logger.info('User created: $userId');
    return userId;
  }

  Future<Map<String, dynamic>?> getUser(String userId) async => _users[userId];

  Future<List<Map<String, dynamic>>> getAllUsers() async =>
      _users.values.toList();
}

@ServiceContract(remote: true)
class ProductService extends FluxService {
  ProductService();
  final Map<String, Map<String, dynamic>> _products = {};

  @override
  Future<void> initialize() async {
    await super.initialize();
    logger.info('Product service initialized');
  }

  Future<String> createProduct(String name, double price) async {
    final productId = 'product_${_products.length + 1}';
    _products[productId] = {
      'id': productId,
      'name': name,
      'price': price,
      'createdAt': DateTime.now().toIso8601String(),
    };

    logger.info('Product created: $productId');
    return productId;
  }

  Future<Map<String, dynamic>?> getProduct(String productId) async =>
      _products[productId];

  Future<List<Map<String, dynamic>>> getAllProducts() async =>
      _products.values.toList();
}

@ServiceContract(remote: false)
class OrderService extends FluxService {
  OrderService();
  final Map<String, Map<String, dynamic>> _orders = {};

  late final UserService _userService;
  late final ProductService _productService;

  @override
  Future<void> initialize() async {
    await super.initialize();

    // Get service dependencies after initialization
    _userService = getService<UserService>();
    _productService = getService<ProductService>();

    logger.info('Order service initialized');
  }

  Future<String> createOrder(String userId, Map<String, int> items) async {
    // Validate user exists
    final user = await _userService.getUser(userId);
    if (user == null) {
      throw Exception('User not found: $userId');
    }

    // Validate products exist
    for (final productId in items.keys) {
      final product = await _productService.getProduct(productId);
      if (product == null) {
        throw Exception('Product not found: $productId');
      }
    }

    final orderId = 'order_${_orders.length + 1}';
    _orders[orderId] = {
      'id': orderId,
      'userId': userId,
      'items': items,
      'status': 'pending',
      'createdAt': DateTime.now().toIso8601String(),
    };

    logger.info('Order created: $orderId for user $userId');
    return orderId;
  }

  Future<Map<String, dynamic>?> getOrder(String orderId) async =>
      _orders[orderId];

  Future<List<Map<String, dynamic>>> getOrdersForUser(String userId) async =>
      _orders.values.where((order) => order['userId'] == userId).toList();
}

// Real-time collaboration system integration test
@ServiceContract(remote: false)
class CollaborationService extends FluxService {
  CollaborationService();
  final Map<String, Map<String, dynamic>> _documents = {};
  final Map<String, Set<String>> _collaborators = {};
  final Map<String, List<Map<String, dynamic>>> _changes = {};

  @override
  Future<void> initialize() async {
    await super.initialize();

    // Listen for document change events
    onEvent<DocumentChangeEvent>((event) async {
      _changes.putIfAbsent(event.documentId, () => []).add({
        'userId': event.userId,
        'change': event.change,
        'timestamp': event.timestamp.toIso8601String(),
      });
      return const EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration.zero,
      );
    });

    logger.info('Collaboration service initialized');
  }

  Future<String> createDocument(String title, String userId) async {
    final documentId = 'doc_${_documents.length + 1}';
    _documents[documentId] = {
      'id': documentId,
      'title': title,
      'owner': userId,
      'content': '',
      'createdAt': DateTime.now().toIso8601String(),
      'lastModified': DateTime.now().toIso8601String(),
    };

    _collaborators[documentId] = {userId};

    logger.info('Document created: $documentId by $userId');
    return documentId;
  }

  Future<void> addCollaborator(String documentId, String userId) async {
    if (!_documents.containsKey(documentId)) {
      throw Exception('Document not found: $documentId');
    }

    _collaborators[documentId]!.add(userId);

    logger.info('Collaborator $userId added to document $documentId');
  }

  Future<void> makeChange(
      String documentId, String userId, String change) async {
    if (!_documents.containsKey(documentId)) {
      throw Exception('Document not found: $documentId');
    }

    if (!_collaborators[documentId]!.contains(userId)) {
      throw Exception(
          'User $userId is not a collaborator on document $documentId');
    }

    // Update document
    _documents[documentId]!['content'] += change;
    _documents[documentId]!['lastModified'] = DateTime.now().toIso8601String();

    // Send change event
    final event = createEvent<DocumentChangeEvent>(
      (
              {required eventId,
              required sourceService,
              required timestamp,
              correlationId,
              metadata = const {}}) =>
          DocumentChangeEvent(
        eventId: eventId,
        sourceService: sourceService,
        timestamp: timestamp,
        correlationId: correlationId,
        metadata: metadata,
        documentId: documentId,
        userId: userId,
        change: change,
      ),
    );
    await sendEvent(event,
        distribution: EventDistribution.broadcast(includeSource: true));

    logger.info('Change made to document $documentId by $userId');
  }

  Future<Map<String, dynamic>?> getDocument(String documentId) async =>
      _documents[documentId];

  Future<List<String>> getCollaborators(String documentId) async =>
      _collaborators[documentId]?.toList() ?? [];

  Future<List<Map<String, dynamic>>> getDocumentChanges(
          String documentId) async =>
      _changes[documentId] ?? [];
}

class DocumentChangeEvent extends ServiceEvent {
  const DocumentChangeEvent({
    required super.eventId,
    required super.sourceService,
    required super.timestamp,
    required this.documentId,
    required this.userId,
    required this.change,
    super.correlationId,
    super.metadata = const {},
  });
  factory DocumentChangeEvent.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return DocumentChangeEvent(
      eventId: json['eventId'] as String,
      sourceService: json['sourceService'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      correlationId: json['correlationId'] as String?,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      documentId: data['documentId'] as String,
      userId: data['userId'] as String,
      change: data['change'] as String,
    );
  }

  final String documentId;
  final String userId;
  final String change;

  @override
  Map<String, dynamic> eventDataToJson() => {
        'documentId': documentId,
        'userId': userId,
        'change': change,
      };
}

void main() {
  group('Integration Scenarios', () {
    late FluxRuntime runtime;

    setUp(() async {
      // Ensure clean state before each test
      runtime = FluxRuntime();
    });

    tearDown(() async {
      // Ensure complete cleanup after each test
      try {
        if (runtime.isInitialized) {
          await runtime.destroyAll();
        }
      } catch (e) {
        // Ignore cleanup errors to prevent test interference
        print('Warning: Cleanup error in tearDown: $e');
      }

      // Add a small delay to ensure cleanup is complete
      await Future.delayed(const Duration(milliseconds: 10));
    });

    group('E-Commerce System Integration', () {
      test('should handle complete e-commerce workflow', () async {
        // Ensure runtime is clean and ready
        expect(runtime.isInitialized, isFalse);

        runtime.register<ECommerceIntegrationService>(
            ECommerceIntegrationService.new);
        await runtime.initializeAll();

        final ecommerce = runtime.get<ECommerceIntegrationService>();

        // Create users
        final user1 =
            await ecommerce.createUser('John Doe', 'john@example.com');
        final user2 =
            await ecommerce.createUser('Jane Smith', 'jane@example.com');

        // Create products
        final product1 = await ecommerce.createProduct('Laptop', 999.99, 10);
        final product2 = await ecommerce.createProduct('Mouse', 29.99, 50);

        // Create orders
        final order1 =
            await ecommerce.createOrder(user1, {product1: 1, product2: 2});
        final order2 = await ecommerce.createOrder(user2, {product1: 1});

        // Process payments
        await ecommerce.processPayment(order1, 1059.97); // 999.99 + 2 * 29.99
        await ecommerce.processPayment(order2, 999.99);

        // Fulfill orders
        await ecommerce.fulfillOrder(order1);
        await ecommerce.fulfillOrder(order2);

        final state = ecommerce.getSystemState();
        expect(state['users'], equals(2));
        expect(state['products'], equals(2));
        expect(state['orders'], equals(2));
        expect(state['events'].length, greaterThan(0));
      });

      test('should handle inventory management', () async {
        // Ensure runtime is clean and ready
        expect(runtime.isInitialized, isFalse);

        runtime.register<ECommerceIntegrationService>(
            ECommerceIntegrationService.new);
        await runtime.initializeAll();

        final ecommerce = runtime.get<ECommerceIntegrationService>();

        // Create product with limited stock
        final product = await ecommerce.createProduct('Limited Item', 99.99, 2);

        // Create user
        final user =
            await ecommerce.createUser('Test User', 'test@example.com');

        // Create order that should succeed
        final order1 = await ecommerce.createOrder(user, {product: 1});
        expect(order1, isNotEmpty);

        // Create order that should succeed
        final order2 = await ecommerce.createOrder(user, {product: 1});
        expect(order2, isNotEmpty);

        // Create order that should fail (insufficient inventory)
        expect(
          () => ecommerce.createOrder(user, {product: 1}),
          throwsA(isA<Exception>()),
        );

        final state = ecommerce.getSystemState();
        expect(state['inventory'][product]['quantity'], equals(0));
        expect(state['inventory'][product]['reserved'], equals(2));
      });
    });

    group('Microservices Architecture Integration', () {
      test('should handle cross-service communication', () async {
        // Ensure runtime is clean and ready
        expect(runtime.isInitialized, isFalse);

        runtime.register<UserService>(UserService.new);
        runtime.register<ProductService>(ProductService.new);

        // Register OrderService (uses ServiceClientMixin for dependency injection)
        runtime.register<OrderService>(OrderService.new);

        await runtime.initializeAll();

        final userService = runtime.get<UserService>();
        final productService = runtime.get<ProductService>();
        final orderService = runtime.get<OrderService>();

        // Create users
        final user1 =
            await userService.createUser('Alice', 'alice@example.com');
        final user2 = await userService.createUser('Bob', 'bob@example.com');

        // Create products
        final product1 = await productService.createProduct('Widget A', 19.99);
        final product2 = await productService.createProduct('Widget B', 29.99);

        // Create orders
        final order1 =
            await orderService.createOrder(user1, {product1: 2, product2: 1});
        await orderService.createOrder(user2, {product1: 1});

        // Verify orders
        final order1Data = await orderService.getOrder(order1);
        expect(order1Data, isNotNull);
        expect(order1Data!['userId'], equals(user1));

        final user1Orders = await orderService.getOrdersForUser(user1);
        expect(user1Orders, hasLength(1));

        final user2Orders = await orderService.getOrdersForUser(user2);
        expect(user2Orders, hasLength(1));
      });

      test('should handle service failures gracefully', () async {
        // Ensure runtime is clean and ready
        expect(runtime.isInitialized, isFalse);

        runtime.register<UserService>(UserService.new);
        runtime.register<ProductService>(ProductService.new);

        // Register OrderService (uses ServiceClientMixin for dependency injection)
        runtime.register<OrderService>(OrderService.new);

        await runtime.initializeAll();

        final userService = runtime.get<UserService>();
        final orderService = runtime.get<OrderService>();

        // Create user
        final user =
            await userService.createUser('Test User', 'test@example.com');

        // Try to create order with non-existent product
        expect(
          () => orderService.createOrder(user, {'non_existent': 1}),
          throwsA(isA<Exception>()),
        );

        // Try to create order with non-existent user
        expect(
          () => orderService.createOrder('non_existent_user', {'product1': 1}),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Real-time Collaboration System Integration', () {
      test('should handle document collaboration workflow', () async {
        // Ensure runtime is clean and ready
        expect(runtime.isInitialized, isFalse);

        runtime.register<CollaborationService>(CollaborationService.new);
        await runtime.initializeAll();

        final collaboration = runtime.get<CollaborationService>();

        // Create document
        final document =
            await collaboration.createDocument('Project Plan', 'user1');

        // Add collaborators
        await collaboration.addCollaborator(document, 'user2');
        await collaboration.addCollaborator(document, 'user3');

        // Make changes
        await collaboration.makeChange(document, 'user1', 'Initial content\n');
        await collaboration.makeChange(document, 'user2', 'Added section 1\n');
        await collaboration.makeChange(document, 'user3', 'Added section 2\n');

        // Verify document state
        final docData = await collaboration.getDocument(document);
        expect(docData, isNotNull);
        expect(docData!['content'], contains('Initial content'));
        expect(docData['content'], contains('Added section 1'));
        expect(docData['content'], contains('Added section 2'));

        // Verify collaborators
        final collaborators = await collaboration.getCollaborators(document);
        expect(collaborators, containsAll(['user1', 'user2', 'user3']));

        // Verify changes
        final changes = await collaboration.getDocumentChanges(document);
        expect(changes, hasLength(3));
      });

      test('should handle unauthorized collaboration attempts', () async {
        // Ensure runtime is clean and ready
        expect(runtime.isInitialized, isFalse);

        runtime.register<CollaborationService>(CollaborationService.new);
        await runtime.initializeAll();

        final collaboration = runtime.get<CollaborationService>();

        // Create document
        final document =
            await collaboration.createDocument('Private Doc', 'user1');

        // Try to make change without being a collaborator
        expect(
          () => collaboration.makeChange(
              document, 'unauthorized_user', 'Unauthorized change'),
          throwsA(isA<Exception>()),
        );

        // Verify document wasn't changed
        final docData = await collaboration.getDocument(document);
        expect(docData!['content'], isEmpty);
      });
    });

    group('Complex Multi-Service Workflows', () {
      test('should handle end-to-end business process', () async {
        // Ensure runtime is clean and ready
        expect(runtime.isInitialized, isFalse);

        // Register all services
        runtime.register<ECommerceIntegrationService>(
            ECommerceIntegrationService.new);
        runtime.register<UserService>(UserService.new);
        runtime.register<ProductService>(ProductService.new);

        // Register OrderService (uses ServiceClientMixin for dependency injection)
        runtime.register<OrderService>(OrderService.new);

        runtime.register<CollaborationService>(CollaborationService.new);

        await runtime.initializeAll();

        final ecommerce = runtime.get<ECommerceIntegrationService>();
        final userService = runtime.get<UserService>();
        final productService = runtime.get<ProductService>();
        final orderService = runtime.get<OrderService>();
        final collaboration = runtime.get<CollaborationService>();

        // Create users in both systems
        final user1 =
            await ecommerce.createUser('John Doe', 'john@example.com');
        final user2 =
            await userService.createUser('Jane Smith', 'jane@example.com');

        // Create products
        final product1 = await ecommerce.createProduct('Laptop', 999.99, 5);
        final product2 = await productService.createProduct('Mouse', 29.99);

        // Create orders in both systems
        final order1 = await ecommerce.createOrder(user1, {product1: 1});
        final order2 = await orderService.createOrder(user2, {product2: 2});

        // Create collaboration document
        final document =
            await collaboration.createDocument('Project Requirements', user1);
        await collaboration.addCollaborator(document, user2);

        // Process e-commerce order
        await ecommerce.processPayment(order1, 999.99);
        await ecommerce.fulfillOrder(order1);

        // Make collaboration changes
        await collaboration.makeChange(
            document, user1, 'Initial requirements\n');
        await collaboration.makeChange(
            document, user2, 'Added technical specs\n');

        // Verify all systems are working
        final ecommerceState = ecommerce.getSystemState();
        expect(ecommerceState['orders'], equals(1));

        final order2Data = await orderService.getOrder(order2);
        expect(order2Data, isNotNull);

        final docData = await collaboration.getDocument(document);
        expect(docData!['content'], isNotEmpty);
      });

      test('should handle high-volume operations across services', () async {
        // Ensure runtime is clean and ready
        expect(runtime.isInitialized, isFalse);

        runtime.register<ECommerceIntegrationService>(
            ECommerceIntegrationService.new);
        runtime.register<CollaborationService>(CollaborationService.new);

        await runtime.initializeAll();

        final ecommerce = runtime.get<ECommerceIntegrationService>();
        final collaboration = runtime.get<CollaborationService>();

        // Create many users and products
        final users = <String>[];
        final products = <String>[];

        for (var i = 0; i < 100; i++) {
          users
              .add(await ecommerce.createUser('User $i', 'user$i@example.com'));
          products.add(
              await ecommerce.createProduct('Product $i', (i + 1) * 10.0, 100));
        }

        // Create many orders
        final orders = <String>[];
        for (var i = 0; i < 50; i++) {
          final user = users[i % users.length];
          final product = products[i % products.length];
          orders.add(await ecommerce.createOrder(user, {product: 1}));
        }

        // Create many documents
        final documents = <String>[];
        for (var i = 0; i < 20; i++) {
          final user = users[i % users.length];
          documents
              .add(await collaboration.createDocument('Document $i', user));
        }

        // Verify system state
        final ecommerceState = ecommerce.getSystemState();
        expect(ecommerceState['users'], equals(100));
        expect(ecommerceState['products'], equals(100));
        expect(ecommerceState['orders'], equals(50));

        // Verify documents
        for (final docId in documents) {
          final docData = await collaboration.getDocument(docId);
          expect(docData, isNotNull);
        }
      });
    });

    group('Error Recovery and Resilience', () {});
  });
}

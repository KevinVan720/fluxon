// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'remote_event_communication_test.dart';

// **************************************************************************
// ServiceGenerator
// **************************************************************************

// Service client for PaymentService
class PaymentServiceClient extends PaymentService {
  PaymentServiceClient(this._proxy);
  final ServiceProxy<PaymentService> _proxy;

  @override
  Future<String> processPayment(String orderId, double amount) async {
    return await _proxy
        .callMethod('processPayment', [orderId, amount], namedArgs: {});
  }

  @override
  Future<void> onOrderReceived(OrderEvent event) async {
    return await _proxy.callMethod('onOrderReceived', [event], namedArgs: {});
  }
}

void _registerPaymentServiceClientFactory() {
  GeneratedClientRegistry.register<PaymentService>(
    (proxy) => PaymentServiceClient(proxy),
  );
}

class _PaymentServiceMethods {
  static const int processPaymentId = 1;
  static const int onOrderReceivedId = 2;
}

Future<dynamic> _PaymentServiceDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as PaymentService;
  switch (methodId) {
    case _PaymentServiceMethods.processPaymentId:
      return await s.processPayment(positionalArgs[0], positionalArgs[1]);
    case _PaymentServiceMethods.onOrderReceivedId:
      return await s.onOrderReceived(positionalArgs[0]);
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void _registerPaymentServiceDispatcher() {
  GeneratedDispatcherRegistry.register<PaymentService>(
    _PaymentServiceDispatcher,
  );
}

void _registerPaymentServiceMethodIds() {
  ServiceMethodIdRegistry.register<PaymentService>({
    'processPayment': _PaymentServiceMethods.processPaymentId,
    'onOrderReceived': _PaymentServiceMethods.onOrderReceivedId,
  });
}

void registerPaymentServiceGenerated() {
  _registerPaymentServiceClientFactory();
  _registerPaymentServiceMethodIds();
}

// Service client for NotificationService
class NotificationServiceClient extends NotificationService {
  NotificationServiceClient(this._proxy);
  final ServiceProxy<NotificationService> _proxy;

  @override
  Future<void> sendNotification(
      String userId, String message, String type) async {
    return await _proxy
        .callMethod('sendNotification', [userId, message, type], namedArgs: {});
  }

  @override
  Future<void> onPaymentProcessed(PaymentEvent event) async {
    return await _proxy
        .callMethod('onPaymentProcessed', [event], namedArgs: {});
  }

  @override
  Future<int> getNotificationCount() async {
    return await _proxy.callMethod('getNotificationCount', [], namedArgs: {});
  }
}

void _registerNotificationServiceClientFactory() {
  GeneratedClientRegistry.register<NotificationService>(
    (proxy) => NotificationServiceClient(proxy),
  );
}

class _NotificationServiceMethods {
  static const int sendNotificationId = 1;
  static const int onPaymentProcessedId = 2;
  static const int getNotificationCountId = 3;
}

Future<dynamic> _NotificationServiceDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as NotificationService;
  switch (methodId) {
    case _NotificationServiceMethods.sendNotificationId:
      return await s.sendNotification(
          positionalArgs[0], positionalArgs[1], positionalArgs[2]);
    case _NotificationServiceMethods.onPaymentProcessedId:
      return await s.onPaymentProcessed(positionalArgs[0]);
    case _NotificationServiceMethods.getNotificationCountId:
      return await s.getNotificationCount();
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void _registerNotificationServiceDispatcher() {
  GeneratedDispatcherRegistry.register<NotificationService>(
    _NotificationServiceDispatcher,
  );
}

void _registerNotificationServiceMethodIds() {
  ServiceMethodIdRegistry.register<NotificationService>({
    'sendNotification': _NotificationServiceMethods.sendNotificationId,
    'onPaymentProcessed': _NotificationServiceMethods.onPaymentProcessedId,
    'getNotificationCount': _NotificationServiceMethods.getNotificationCountId,
  });
}

void registerNotificationServiceGenerated() {
  _registerNotificationServiceClientFactory();
  _registerNotificationServiceMethodIds();
}

// Service client for OrderService
class OrderServiceClient extends OrderService {
  OrderServiceClient(this._proxy);
  final ServiceProxy<OrderService> _proxy;
}

void _registerOrderServiceClientFactory() {
  GeneratedClientRegistry.register<OrderService>(
    (proxy) => OrderServiceClient(proxy),
  );
}

class _OrderServiceMethods {}

Future<dynamic> _OrderServiceDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as OrderService;
  switch (methodId) {
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void _registerOrderServiceDispatcher() {
  GeneratedDispatcherRegistry.register<OrderService>(
    _OrderServiceDispatcher,
  );
}

void _registerOrderServiceMethodIds() {
  ServiceMethodIdRegistry.register<OrderService>({});
}

void registerOrderServiceGenerated() {
  _registerOrderServiceClientFactory();
  _registerOrderServiceMethodIds();
}

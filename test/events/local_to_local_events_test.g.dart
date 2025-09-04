// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_to_local_events_test.dart';

// **************************************************************************
// ServiceGenerator
// **************************************************************************

// Service client for UserService
class UserServiceClient extends UserService {
  UserServiceClient(this._proxy);
  final ServiceProxy<UserService> _proxy;

  @override
  Future<String> createUser(String name, String email) async {
    return await _proxy.callMethod('createUser', [name, email], namedArgs: {});
  }
}

void _registerUserServiceClientFactory() {
  GeneratedClientRegistry.register<UserService>(
    (proxy) => UserServiceClient(proxy),
  );
}

class _UserServiceMethods {
  static const int createUserId = 1;
}

Future<dynamic> _UserServiceDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as UserService;
  switch (methodId) {
    case _UserServiceMethods.createUserId:
      return await s.createUser(positionalArgs[0], positionalArgs[1]);
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void _registerUserServiceDispatcher() {
  GeneratedDispatcherRegistry.register<UserService>(
    _UserServiceDispatcher,
  );
}

void _registerUserServiceMethodIds() {
  ServiceMethodIdRegistry.register<UserService>({
    'createUser': _UserServiceMethods.createUserId,
  });
}

void registerUserServiceGenerated() {
  _registerUserServiceClientFactory();
  _registerUserServiceMethodIds();
}

void _registerUserServiceLocalSide() {
  _registerUserServiceDispatcher();
  _registerUserServiceClientFactory();
  _registerUserServiceMethodIds();
}

// Service client for OrderService
class OrderServiceClient extends OrderService {
  OrderServiceClient(this._proxy);
  final ServiceProxy<OrderService> _proxy;

  @override
  Future<String> placeOrder(
      String userId, double amount, List<String> items) async {
    return await _proxy
        .callMethod('placeOrder', [userId, amount, items], namedArgs: {});
  }
}

void _registerOrderServiceClientFactory() {
  GeneratedClientRegistry.register<OrderService>(
    (proxy) => OrderServiceClient(proxy),
  );
}

class _OrderServiceMethods {
  static const int placeOrderId = 1;
}

Future<dynamic> _OrderServiceDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as OrderService;
  switch (methodId) {
    case _OrderServiceMethods.placeOrderId:
      return await s.placeOrder(
          positionalArgs[0], positionalArgs[1], positionalArgs[2]);
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
  ServiceMethodIdRegistry.register<OrderService>({
    'placeOrder': _OrderServiceMethods.placeOrderId,
  });
}

void registerOrderServiceGenerated() {
  _registerOrderServiceClientFactory();
  _registerOrderServiceMethodIds();
}

void _registerOrderServiceLocalSide() {
  _registerOrderServiceDispatcher();
  _registerOrderServiceClientFactory();
  _registerOrderServiceMethodIds();
}

// Service client for NotificationService
class NotificationServiceClient extends NotificationService {
  NotificationServiceClient(this._proxy);
  final ServiceProxy<NotificationService> _proxy;
}

void _registerNotificationServiceClientFactory() {
  GeneratedClientRegistry.register<NotificationService>(
    (proxy) => NotificationServiceClient(proxy),
  );
}

class _NotificationServiceMethods {}

Future<dynamic> _NotificationServiceDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as NotificationService;
  switch (methodId) {
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
  ServiceMethodIdRegistry.register<NotificationService>({});
}

void registerNotificationServiceGenerated() {
  _registerNotificationServiceClientFactory();
  _registerNotificationServiceMethodIds();
}

void _registerNotificationServiceLocalSide() {
  _registerNotificationServiceDispatcher();
  _registerNotificationServiceClientFactory();
  _registerNotificationServiceMethodIds();
}

// Service client for AnalyticsService
class AnalyticsServiceClient extends AnalyticsService {
  AnalyticsServiceClient(this._proxy);
  final ServiceProxy<AnalyticsService> _proxy;

  @override
  Future<Map<String, int>> getAnalytics() async {
    return await _proxy.callMethod('getAnalytics', [], namedArgs: {});
  }
}

void _registerAnalyticsServiceClientFactory() {
  GeneratedClientRegistry.register<AnalyticsService>(
    (proxy) => AnalyticsServiceClient(proxy),
  );
}

class _AnalyticsServiceMethods {
  static const int getAnalyticsId = 1;
}

Future<dynamic> _AnalyticsServiceDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as AnalyticsService;
  switch (methodId) {
    case _AnalyticsServiceMethods.getAnalyticsId:
      return await s.getAnalytics();
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void _registerAnalyticsServiceDispatcher() {
  GeneratedDispatcherRegistry.register<AnalyticsService>(
    _AnalyticsServiceDispatcher,
  );
}

void _registerAnalyticsServiceMethodIds() {
  ServiceMethodIdRegistry.register<AnalyticsService>({
    'getAnalytics': _AnalyticsServiceMethods.getAnalyticsId,
  });
}

void registerAnalyticsServiceGenerated() {
  _registerAnalyticsServiceClientFactory();
  _registerAnalyticsServiceMethodIds();
}

void _registerAnalyticsServiceLocalSide() {
  _registerAnalyticsServiceDispatcher();
  _registerAnalyticsServiceClientFactory();
  _registerAnalyticsServiceMethodIds();
}

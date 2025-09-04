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

void $registerUserServiceClientFactory() {
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

void $registerUserServiceDispatcher() {
  GeneratedDispatcherRegistry.register<UserService>(
    _UserServiceDispatcher,
  );
}

void $registerUserServiceMethodIds() {
  ServiceMethodIdRegistry.register<UserService>({
    'createUser': _UserServiceMethods.createUserId,
  });
}

void registerUserServiceGenerated() {
  $registerUserServiceClientFactory();
  $registerUserServiceMethodIds();
}

// Local worker implementation that auto-registers local side
class UserServiceLocalWorker extends UserService {
  UserServiceLocalWorker() {
    // 🚀 AUTO-REGISTRATION: Register local side when instance is created
    $registerUserServiceLocalSide();
  }
}

void $registerUserServiceLocalSide() {
  $registerUserServiceDispatcher();
  $registerUserServiceClientFactory();
  $registerUserServiceMethodIds();
}

void $autoRegisterUserServiceLocalSide() {
  LocalSideRegistry.register<UserService>($registerUserServiceLocalSide);
}

final $_UserServiceLocalSideRegistered = (() {
  $autoRegisterUserServiceLocalSide();
  return true;
})();

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

void $registerOrderServiceClientFactory() {
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

void $registerOrderServiceDispatcher() {
  GeneratedDispatcherRegistry.register<OrderService>(
    _OrderServiceDispatcher,
  );
}

void $registerOrderServiceMethodIds() {
  ServiceMethodIdRegistry.register<OrderService>({
    'placeOrder': _OrderServiceMethods.placeOrderId,
  });
}

void registerOrderServiceGenerated() {
  $registerOrderServiceClientFactory();
  $registerOrderServiceMethodIds();
}

// Local worker implementation that auto-registers local side
class OrderServiceLocalWorker extends OrderService {
  OrderServiceLocalWorker() {
    // 🚀 AUTO-REGISTRATION: Register local side when instance is created
    $registerOrderServiceLocalSide();
  }
}

void $registerOrderServiceLocalSide() {
  $registerOrderServiceDispatcher();
  $registerOrderServiceClientFactory();
  $registerOrderServiceMethodIds();
}

void $autoRegisterOrderServiceLocalSide() {
  LocalSideRegistry.register<OrderService>($registerOrderServiceLocalSide);
}

final $_OrderServiceLocalSideRegistered = (() {
  $autoRegisterOrderServiceLocalSide();
  return true;
})();

// Service client for NotificationService
class NotificationServiceClient extends NotificationService {
  NotificationServiceClient(this._proxy);
  final ServiceProxy<NotificationService> _proxy;
}

void $registerNotificationServiceClientFactory() {
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

void $registerNotificationServiceDispatcher() {
  GeneratedDispatcherRegistry.register<NotificationService>(
    _NotificationServiceDispatcher,
  );
}

void $registerNotificationServiceMethodIds() {
  ServiceMethodIdRegistry.register<NotificationService>({});
}

void registerNotificationServiceGenerated() {
  $registerNotificationServiceClientFactory();
  $registerNotificationServiceMethodIds();
}

// Local worker implementation that auto-registers local side
class NotificationServiceLocalWorker extends NotificationService {
  NotificationServiceLocalWorker() {
    // 🚀 AUTO-REGISTRATION: Register local side when instance is created
    $registerNotificationServiceLocalSide();
  }
}

void $registerNotificationServiceLocalSide() {
  $registerNotificationServiceDispatcher();
  $registerNotificationServiceClientFactory();
  $registerNotificationServiceMethodIds();
}

void $autoRegisterNotificationServiceLocalSide() {
  LocalSideRegistry.register<NotificationService>(
      $registerNotificationServiceLocalSide);
}

final $_NotificationServiceLocalSideRegistered = (() {
  $autoRegisterNotificationServiceLocalSide();
  return true;
})();

// Service client for AnalyticsService
class AnalyticsServiceClient extends AnalyticsService {
  AnalyticsServiceClient(this._proxy);
  final ServiceProxy<AnalyticsService> _proxy;

  @override
  Future<Map<String, int>> getAnalytics() async {
    return await _proxy.callMethod('getAnalytics', [], namedArgs: {});
  }
}

void $registerAnalyticsServiceClientFactory() {
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

void $registerAnalyticsServiceDispatcher() {
  GeneratedDispatcherRegistry.register<AnalyticsService>(
    _AnalyticsServiceDispatcher,
  );
}

void $registerAnalyticsServiceMethodIds() {
  ServiceMethodIdRegistry.register<AnalyticsService>({
    'getAnalytics': _AnalyticsServiceMethods.getAnalyticsId,
  });
}

void registerAnalyticsServiceGenerated() {
  $registerAnalyticsServiceClientFactory();
  $registerAnalyticsServiceMethodIds();
}

// Local worker implementation that auto-registers local side
class AnalyticsServiceLocalWorker extends AnalyticsService {
  AnalyticsServiceLocalWorker() {
    // 🚀 AUTO-REGISTRATION: Register local side when instance is created
    $registerAnalyticsServiceLocalSide();
  }
}

void $registerAnalyticsServiceLocalSide() {
  $registerAnalyticsServiceDispatcher();
  $registerAnalyticsServiceClientFactory();
  $registerAnalyticsServiceMethodIds();
}

void $autoRegisterAnalyticsServiceLocalSide() {
  LocalSideRegistry.register<AnalyticsService>(
      $registerAnalyticsServiceLocalSide);
}

final $_AnalyticsServiceLocalSideRegistered = (() {
  $autoRegisterAnalyticsServiceLocalSide();
  return true;
})();

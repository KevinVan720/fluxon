// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_service.dart';

// **************************************************************************
// ServiceGenerator
// **************************************************************************

// Service client for NotificationService
class NotificationServiceClient extends NotificationService {
  NotificationServiceClient(this._proxy);
  final ServiceProxy<NotificationService> _proxy;

  @override
  Future<void> sendNotification(
      {required String userId,
      required String title,
      required String message,
      String type = 'info'}) async {
    return await _proxy.callMethod('sendNotification', [], namedArgs: {
      'userId': userId,
      'title': title,
      'message': message,
      'type': type
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getNotificationsForUser(
      String userId) async {
    return await _proxy
        .callMethod('getNotificationsForUser', [userId], namedArgs: {});
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    return await _proxy
        .callMethod('markAsRead', [notificationId], namedArgs: {});
  }

  @override
  Future<int> getUnreadCount(String userId) async {
    return await _proxy.callMethod('getUnreadCount', [userId], namedArgs: {});
  }
}

void $registerNotificationServiceClientFactory() {
  GeneratedClientRegistry.register<NotificationService>(
    (proxy) => NotificationServiceClient(proxy),
  );
}

class _NotificationServiceMethods {
  static const int sendNotificationId = 1;
  static const int getNotificationsForUserId = 2;
  static const int markAsReadId = 3;
  static const int getUnreadCountId = 4;
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
          userId: namedArgs['userId'],
          title: namedArgs['title'],
          message: namedArgs['message'],
          type: namedArgs['type']);
    case _NotificationServiceMethods.getNotificationsForUserId:
      return await s.getNotificationsForUser(positionalArgs[0]);
    case _NotificationServiceMethods.markAsReadId:
      return await s.markAsRead(positionalArgs[0]);
    case _NotificationServiceMethods.getUnreadCountId:
      return await s.getUnreadCount(positionalArgs[0]);
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
  ServiceMethodIdRegistry.register<NotificationService>({
    'sendNotification': _NotificationServiceMethods.sendNotificationId,
    'getNotificationsForUser':
        _NotificationServiceMethods.getNotificationsForUserId,
    'markAsRead': _NotificationServiceMethods.markAsReadId,
    'getUnreadCount': _NotificationServiceMethods.getUnreadCountId,
  });
}

void registerNotificationServiceGenerated() {
  $registerNotificationServiceClientFactory();
  $registerNotificationServiceMethodIds();
}

// Remote service implementation that auto-registers the dispatcher
class NotificationServiceImpl extends NotificationService {
  @override
  bool get isRemote => true;
  @override
  Type get clientBaseType => NotificationService;
  @override
  Future<void> registerHostSide() async {
    $registerNotificationServiceClientFactory();
    $registerNotificationServiceMethodIds();
    // Auto-registered from dependencies/optionalDependencies
    try {
      $registerUserServiceClientFactory();
    } catch (_) {}
    try {
      $registerUserServiceMethodIds();
    } catch (_) {}
  }

  @override
  Future<void> initialize() async {
    $registerNotificationServiceDispatcher();
    // Ensure worker isolate can create clients for dependencies
    try {
      $registerUserServiceClientFactory();
    } catch (_) {}
    try {
      $registerUserServiceMethodIds();
    } catch (_) {}
    await super.initialize();
  }
}

void $registerNotificationServiceLocalSide() {
  $registerNotificationServiceDispatcher();
  $registerNotificationServiceClientFactory();
  $registerNotificationServiceMethodIds();
  try {
    $registerUserServiceClientFactory();
  } catch (_) {}
  try {
    $registerUserServiceMethodIds();
  } catch (_) {}
}

void $autoRegisterNotificationServiceLocalSide() {
  LocalSideRegistry.register<NotificationService>(
      $registerNotificationServiceLocalSide);
}

final $_NotificationServiceLocalSideRegistered = (() {
  $autoRegisterNotificationServiceLocalSide();
  return true;
})();

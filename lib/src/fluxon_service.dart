/// FluxonService - The simplified public API for the Dart Service Framework
library flux_service;

import 'dart:async';

import 'package:meta/meta.dart';

import 'base_service.dart';
import 'events/event_mixin.dart';
import 'service_proxy.dart';

/// 🚀 FLUXON: The ultimate simplified service class!
///
/// Just extend FluxonService and focus on your business logic.
/// All event and proxy infrastructure is included automatically.
///
/// Features included out-of-the-box:
/// - ✅ Event sending/receiving (sendEvent, onEvent)
/// - ✅ Cross-service calls (getService)
/// - ✅ Complete isolate transparency
/// - ✅ Automatic infrastructure setup
/// - ✅ Structured logging
/// - ✅ Lifecycle management
///
/// ## Example Usage:
///
/// ```dart
/// // Define your service interface
/// @ServiceContract(remote: true)
/// abstract class PaymentService extends FluxonService {
///   Future<bool> processPayment(String userId, double amount);
/// }
///
/// // Implement your service - that's it!
/// class PaymentServiceImpl extends PaymentService {
///   @override
///   Future<bool> processPayment(String userId, double amount) async {
///     // Send events automatically
///     await sendEvent(PaymentEvent(userId: userId, amount: amount));
///
///     // Call other services transparently (local or remote!)
///     final user = getService<UserService>();
///     final isValid = await user.validateUser(userId);
///
///     return isValid && amount > 0;
///   }
/// }
/// ```
///
/// ## Zero Boilerplate:
/// - No manual mixin declarations
/// - No dispatcher registration calls
/// - No event infrastructure setup
/// - Just pure business logic!
abstract class FluxonService extends BaseService
    with ServiceEventMixin, ServiceClientMixin {
  /// Creates a Fluxon service with all capabilities enabled
  FluxonService({
    super.config,
    super.logger,
  });

  /// Indicates whether this service instance represents a remote worker
  /// implementation. Codegen should override this to `true` for generated
  /// worker classes so the runtime can register them as remote explicitly.
  /// Defaults to `false` for local services and interfaces.
  bool get isRemote => false;

  @override
  @mustCallSuper
  Future<void> initialize() async {
    // 🚀 AUTOMATIC: All infrastructure setup happens automatically
    // - Event dispatcher registration (via extension)
    // - Service client factory setup
    // - Cross-isolate communication setup
    // - Event bridge configuration

    await super.initialize();

    logger.info('FluxonService initialized with full capabilities', metadata: {
      'serviceName': serviceName,
      'hasEventCapabilities': true,
      'hasClientCapabilities': true,
      'automaticInfrastructure': true,
    });
  }

  @override
  @mustCallSuper
  Future<void> destroy() async {
    logger.info('FluxonService destroying', metadata: {
      'serviceName': serviceName,
    });

    await super.destroy();

    logger.info('FluxonService destroyed successfully');
  }
}

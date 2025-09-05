part of 'base_service.dart';

/// Mixin for services that need periodic tasks.
mixin PeriodicServiceMixin on BaseService {
  Timer? _periodicTimer;

  /// The interval for periodic tasks.
  Duration get periodicInterval => const Duration(minutes: 1);

  /// Whether periodic tasks are enabled.
  bool get periodicTasksEnabled => true;

  /// Performs periodic tasks.
  Future<void> performPeriodicTask() async {}

  @override
  Future<void> initialize() async {
    await super.initialize();
    if (periodicTasksEnabled) {
      _startPeriodicTasks();
    }
  }

  @override
  Future<void> destroy() async {
    _stopPeriodicTasks();
    await super.destroy();
  }

  void _startPeriodicTasks() {
    _periodicTimer = Timer.periodic(periodicInterval, (_) async {
      try {
        await performPeriodicTask();
      } catch (error, stackTrace) {
        logger.error('Periodic task failed',
            error: error, stackTrace: stackTrace);
      }
    });
    logger.debug('Started periodic tasks with interval: $periodicInterval');
  }

  void _stopPeriodicTasks() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
    logger.debug('Stopped periodic tasks');
  }
}

/// Mixin for services that need configuration validation.
mixin ConfigurableServiceMixin on BaseService {
  /// Validates the service configuration.
  void validateConfiguration() {}

  @override
  Future<void> initialize() async {
    try {
      validateConfiguration();
    } catch (error) {
      throw ServiceConfigurationException(
        'Configuration validation failed for $serviceName: $error',
        error,
      );
    }
    await super.initialize();
  }
}

/// Mixin for services that need resource management.
mixin ResourceManagedServiceMixin on BaseService {
  final List<StreamSubscription> _subscriptions = [];
  final List<Timer> _timers = [];

  /// Registers a stream subscription for automatic cleanup.
  void registerSubscription(StreamSubscription subscription) {
    _subscriptions.add(subscription);
  }

  /// Registers a timer for automatic cleanup.
  void registerTimer(Timer timer) {
    _timers.add(timer);
  }

  @override
  Future<void> destroy() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();

    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();

    await super.destroy();
  }
}

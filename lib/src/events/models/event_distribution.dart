import '../service_event.dart'
    show EventTarget; // temporary import for EventTarget

/// Distribution strategy for events
enum EventDistributionStrategy {
  /// Send to specified targets only
  targeted,

  /// Send to specified targets first, then to all other services
  targetedThenBroadcast,

  /// Send to all services except those specified
  broadcastExcept,

  /// Send to all services
  broadcast,
}

/// Event distribution configuration
class EventDistribution {
  const EventDistribution({
    this.targets = const [],
    this.strategy = EventDistributionStrategy.targeted,
    this.excludeServices = const [],
    this.includeSource = false,
    this.parallelProcessing = true,
    this.globalTimeout,
    this.deliverToRuntimeSubscriptions = false,
  });

  /// Create a targeted distribution
  factory EventDistribution.targeted(
    List<EventTarget> targets, {
    bool deliverToRuntimeSubscriptions = false,
  }) =>
      EventDistribution(
        targets: targets,
        deliverToRuntimeSubscriptions: deliverToRuntimeSubscriptions,
      );

  /// Create a broadcast distribution
  factory EventDistribution.broadcast({
    List<Type> excludeServices = const [],
    bool includeSource = false,
    bool deliverToRuntimeSubscriptions = false,
  }) =>
      EventDistribution(
        strategy: EventDistributionStrategy.broadcast,
        excludeServices: excludeServices,
        includeSource: includeSource,
        deliverToRuntimeSubscriptions: deliverToRuntimeSubscriptions,
      );

  /// Create a targeted then broadcast distribution
  factory EventDistribution.targetedThenBroadcast(
    List<EventTarget> targets, {
    List<Type> excludeServices = const [],
    bool includeSource = false,
    bool deliverToRuntimeSubscriptions = false,
  }) =>
      EventDistribution(
        targets: targets,
        strategy: EventDistributionStrategy.targetedThenBroadcast,
        excludeServices: excludeServices,
        includeSource: includeSource,
        deliverToRuntimeSubscriptions: deliverToRuntimeSubscriptions,
      );

  /// Specific targets for the event
  final List<EventTarget> targets;

  /// Distribution strategy
  final EventDistributionStrategy strategy;

  /// Services to exclude from broadcast
  final List<Type> excludeServices;

  /// Whether to include the source service in distribution
  final bool includeSource;

  /// Whether to process targets in parallel or sequentially
  final bool parallelProcessing;

  /// Global timeout for the entire distribution
  final Duration? globalTimeout;

  /// Whether runtime-level subscriptions should receive this event
  final bool deliverToRuntimeSubscriptions;

  @override
  String toString() =>
      'EventDistribution(strategy: $strategy, targets: ${targets.length}, excludes: ${excludeServices.length}, deliverRuntime: $deliverToRuntimeSubscriptions)';
}

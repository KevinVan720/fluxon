part of 'event_dispatcher.dart';

/// Determine target services based on distribution strategy
List<Type> _determineTargetServices(
  Map<Type, BaseService> services,
  ServiceEvent event,
  EventDistribution distribution,
) {
  final allServices = services.keys.toList();
  final sourceServiceType =
      _getServiceTypeByName(services, event.sourceService);

  switch (distribution.strategy) {
    case EventDistributionStrategy.targeted:
      return distribution.targets.map((t) => t.serviceType).toList();

    case EventDistributionStrategy.broadcast:
    case EventDistributionStrategy.broadcastExcept:
    case EventDistributionStrategy.targetedThenBroadcast:
      var targets = allServices;
      if (!distribution.includeSource && sourceServiceType != null) {
        targets = targets.where((t) => t != sourceServiceType).toList();
      }
      return targets
          .where((t) => !distribution.excludeServices.contains(t))
          .toList();
  }
}

Type? _getServiceTypeByName(
    Map<Type, BaseService> services, String serviceName) {
  for (final entry in services.entries) {
    if (entry.value.serviceName == serviceName) {
      return entry.key;
    }
  }
  return null;
}

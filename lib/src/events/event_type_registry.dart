/// Event type registry for cross-isolate event reconstruction
library event_type_registry;

import 'service_event.dart';
import 'event_bridge.dart';

/// Factory function for creating events from JSON
typedef EventFactory<T extends ServiceEvent> = T Function(
    Map<String, dynamic> json);

/// Registry for event types and their factories
class EventTypeRegistry {
  static final Map<String, EventFactory> _factories = {};

  /// Register an event type with its factory
  static void register<T extends ServiceEvent>(EventFactory<T> factory) {
    _factories[T.toString()] = factory;
  }

  /// Create an event from JSON using registered factories
  static ServiceEvent? createFromJson(Map<String, dynamic> json) {
    final eventType = json['eventType'] as String?;
    if (eventType == null) return null;

    final factory = _factories[eventType];
    if (factory == null) {
      // Fallback to generic event
      return GenericServiceEvent.fromJson(json);
    }

    return factory(json);
  }

  /// Check if an event type is registered
  static bool isRegistered(String eventType) {
    return _factories.containsKey(eventType);
  }

  /// Get all registered event types
  static Set<String> get registeredTypes => Set.from(_factories.keys);

  /// Clear all registrations (for testing)
  static void clear() {
    _factories.clear();
  }
}

/// Mixin for automatic event type registration
mixin AutoEventRegistration {
  /// Register event types automatically
  static void registerEventTypes() {
    // This will be called by generated code to register all event types
    // in the current isolate
  }
}

import 'package:meta/meta.dart';

/// Base class for all service events
///
/// Events are immutable data objects that carry information between services.
/// Each event type should extend this class and provide typed data.
@immutable
abstract class ServiceEvent {
  const ServiceEvent({
    required this.eventId,
    required this.sourceService,
    required this.timestamp,
    this.correlationId,
    this.metadata = const {},
  });

  /// Unique identifier for this event instance
  final String eventId;

  /// The service that originated this event
  final String sourceService;

  /// When this event was created
  final DateTime timestamp;

  /// Optional correlation ID for tracking related events
  final String? correlationId;

  /// Additional metadata for the event
  final Map<String, dynamic> metadata;

  /// The event type name (used for routing and serialization)
  String get eventType => runtimeType.toString();

  /// Convert event to JSON for serialization
  /// OPTIMIZATION: Use static cache for frequently serialized events
  Map<String, dynamic> toJson() {
    // Check static cache first
    final cached = _SerializationCache.getJson(this);
    if (cached != null) return cached;

    // Generate JSON
    final json = {
      'eventId': eventId,
      'eventType': eventType,
      'sourceService': sourceService,
      'timestamp': timestamp.toIso8601String(),
      'correlationId': correlationId,
      'metadata': metadata,
      'data': toJsonEventData(),
    };

    // Cache for future use
    _SerializationCache.putJson(this, json);
    return json;
  }

  /// Get event data JSON
  /// OPTIMIZATION: Use static cache for event data
  Map<String, dynamic> toJsonEventData() {
    // Check static cache first
    final cached = _SerializationCache.getEventData(this);
    if (cached != null) return cached;

    // Generate event data
    final data = eventDataToJson();

    // Cache for future use
    _SerializationCache.putEventData(this, data);
    return data;
  }

  /// Convert event-specific data to JSON
  /// Override this in subclasses to serialize event data
  @protected
  Map<String, dynamic> eventDataToJson();

  /// Create event from JSON
  /// This is a factory method that subclasses should implement
  static ServiceEvent fromJson(Map<String, dynamic> json) {
    throw UnimplementedError('Subclasses must implement fromJson');
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ServiceEvent &&
        other.eventId == eventId &&
        other.eventType == eventType;
  }

  @override
  int get hashCode => Object.hash(eventId, eventType);

  @override
  String toString() =>
      '$eventType(id: $eventId, source: $sourceService, timestamp: $timestamp)';
}

/// OPTIMIZATION: Static cache for event serialization
/// Uses LRU cache to avoid memory leaks while providing performance benefits
class _SerializationCache {
  static const int _maxCacheSize = 1000;
  static final Map<String, Map<String, dynamic>> _jsonCache = {};
  static final Map<String, Map<String, dynamic>> _eventDataCache = {};
  static final List<String> _jsonCacheKeys = [];
  static final List<String> _eventDataCacheKeys = [];

  /// Get cached JSON for an event
  static Map<String, dynamic>? getJson(ServiceEvent event) {
    final key = _getCacheKey(event);
    final cached = _jsonCache[key];
    if (cached != null) {
      // Move to end (LRU)
      _jsonCacheKeys.remove(key);
      _jsonCacheKeys.add(key);
    }
    return cached;
  }

  /// Cache JSON for an event
  static void putJson(ServiceEvent event, Map<String, dynamic> json) {
    final key = _getCacheKey(event);

    // Remove oldest if cache is full
    if (_jsonCache.length >= _maxCacheSize && !_jsonCache.containsKey(key)) {
      final oldestKey = _jsonCacheKeys.removeAt(0);
      _jsonCache.remove(oldestKey);
    }

    _jsonCache[key] = json;
    _jsonCacheKeys.remove(key); // Remove if exists
    _jsonCacheKeys.add(key); // Add to end
  }

  /// Get cached event data for an event
  static Map<String, dynamic>? getEventData(ServiceEvent event) {
    final key = _getCacheKey(event);
    final cached = _eventDataCache[key];
    if (cached != null) {
      // Move to end (LRU)
      _eventDataCacheKeys.remove(key);
      _eventDataCacheKeys.add(key);
    }
    return cached;
  }

  /// Cache event data for an event
  static void putEventData(ServiceEvent event, Map<String, dynamic> data) {
    final key = _getCacheKey(event);

    // Remove oldest if cache is full
    if (_eventDataCache.length >= _maxCacheSize &&
        !_eventDataCache.containsKey(key)) {
      final oldestKey = _eventDataCacheKeys.removeAt(0);
      _eventDataCache.remove(oldestKey);
    }

    _eventDataCache[key] = data;
    _eventDataCacheKeys.remove(key); // Remove if exists
    _eventDataCacheKeys.add(key); // Add to end
  }

  /// Generate cache key for an event
  static String _getCacheKey(ServiceEvent event) {
    // Use event ID and type as cache key
    // This assumes events with same ID and type have same data
    return '${event.eventType}_${event.eventId}';
  }

  /// Clear cache (for testing or memory management)
  static void clear() {
    _jsonCache.clear();
    _eventDataCache.clear();
    _jsonCacheKeys.clear();
    _eventDataCacheKeys.clear();
  }

  /// Get cache statistics
  static Map<String, int> getStats() => {
        'jsonCacheSize': _jsonCache.length,
        'eventDataCacheSize': _eventDataCache.length,
        'maxCacheSize': _maxCacheSize,
      };
}

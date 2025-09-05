/// Service event system for typed inter-service communication
library service_event;

// Barrel exports for event models
export 'models/service_event_base.dart';
export 'models/event_processing.dart';
export 'models/event_distribution.dart';
export 'models/event_listener.dart';
export 'models/dispatcher_models.dart';
export 'models/event_target.dart';

// This file intentionally provides only exports and no concrete declarations.

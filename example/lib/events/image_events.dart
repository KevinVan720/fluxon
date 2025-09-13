import 'dart:convert';
import 'dart:typed_data';
import 'package:fluxon/fluxon.dart';

/// Call this in each isolate that needs to reconstruct typed events
void registerImageEventTypes() {
  EventTypeRegistry.register<FilterRequestEvent>(FilterRequestEvent.fromJson);
  EventTypeRegistry.register<FilterProgressEvent>(FilterProgressEvent.fromJson);
  EventTypeRegistry.register<FilterResultEvent>(FilterResultEvent.fromJson);
  EventTypeRegistry.register<FilterCancelledEvent>(
    FilterCancelledEvent.fromJson,
  );
}

class FilterRequestEvent extends ServiceEvent {
  const FilterRequestEvent({
    required super.eventId,
    required super.sourceService,
    required super.timestamp,
    required this.requestId,
    required this.target, // 'remote' | 'local'
    required this.filter,
    required this.amount,
    required this.sigma,
    required this.brightness,
    required this.contrast,
    required this.saturation,
    required this.hue,
    required this.imageBytesBase64,
    super.correlationId,
    super.metadata = const {},
  });

  factory FilterRequestEvent.fromJson(Map<String, dynamic> json) {
    final data = Map<String, dynamic>.from(json['data'] as Map? ?? {});
    return FilterRequestEvent(
      eventId: json['eventId'] as String,
      sourceService: json['sourceService'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      correlationId: json['correlationId'] as String?,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      requestId: data['requestId'] as String,
      target: data['target'] as String,
      filter: data['filter'] as String,
      amount: (data['amount'] as num).toDouble(),
      sigma: (data['sigma'] as num).toDouble(),
      brightness: (data['brightness'] as num).toDouble(),
      contrast: (data['contrast'] as num).toDouble(),
      saturation: (data['saturation'] as num).toDouble(),
      hue: (data['hue'] as num).toDouble(),
      imageBytesBase64: data['image'] as String,
    );
  }

  final String requestId;
  final String target; // 'remote' | 'local'
  final String filter;
  final double amount;
  final double sigma;
  final double brightness;
  final double contrast;
  final double saturation;
  final double hue;
  final String imageBytesBase64;

  Uint8List get imageBytes => base64Decode(imageBytesBase64);

  @override
  Map<String, dynamic> eventDataToJson() => {
    'requestId': requestId,
    'target': target,
    'filter': filter,
    'amount': amount,
    'sigma': sigma,
    'brightness': brightness,
    'contrast': contrast,
    'saturation': saturation,
    'hue': hue,
    'image': imageBytesBase64,
  };
}

class FilterProgressEvent extends ServiceEvent {
  const FilterProgressEvent({
    required super.eventId,
    required super.sourceService,
    required super.timestamp,
    required this.requestId,
    required this.percent,
    super.correlationId,
    super.metadata = const {},
  });

  factory FilterProgressEvent.fromJson(Map<String, dynamic> json) {
    final data = Map<String, dynamic>.from(json['data'] as Map? ?? {});
    return FilterProgressEvent(
      eventId: json['eventId'] as String,
      sourceService: json['sourceService'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      correlationId: json['correlationId'] as String?,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      requestId: data['requestId'] as String,
      percent: (data['percent'] as num).toDouble(),
    );
  }

  final String requestId;
  final double percent;

  @override
  Map<String, dynamic> eventDataToJson() => {
    'requestId': requestId,
    'percent': percent,
  };
}

class FilterResultEvent extends ServiceEvent {
  const FilterResultEvent({
    required super.eventId,
    required super.sourceService,
    required super.timestamp,
    required this.requestId,
    required this.imageBytesBase64,
    super.correlationId,
    super.metadata = const {},
  });

  factory FilterResultEvent.fromJson(Map<String, dynamic> json) {
    final data = Map<String, dynamic>.from(json['data'] as Map? ?? {});
    return FilterResultEvent(
      eventId: json['eventId'] as String,
      sourceService: json['sourceService'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      correlationId: json['correlationId'] as String?,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      requestId: data['requestId'] as String,
      imageBytesBase64: data['image'] as String,
    );
  }

  final String requestId;
  final String imageBytesBase64;
  Uint8List get imageBytes => base64Decode(imageBytesBase64);

  @override
  Map<String, dynamic> eventDataToJson() => {
    'requestId': requestId,
    'image': imageBytesBase64,
  };
}

class FilterCancelledEvent extends ServiceEvent {
  const FilterCancelledEvent({
    required super.eventId,
    required super.sourceService,
    required super.timestamp,
    required this.requestId,
    super.correlationId,
    super.metadata = const {},
  });

  factory FilterCancelledEvent.fromJson(Map<String, dynamic> json) {
    final data = Map<String, dynamic>.from(json['data'] as Map? ?? {});
    return FilterCancelledEvent(
      eventId: json['eventId'] as String,
      sourceService: json['sourceService'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      correlationId: json['correlationId'] as String?,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      requestId: data['requestId'] as String,
    );
  }

  final String requestId;

  @override
  Map<String, dynamic> eventDataToJson() => {'requestId': requestId};
}

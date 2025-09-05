/// Service logging system with prefixes and metadata support.
library service_logger;

import 'dart:convert';
import 'dart:io';

import 'models/service_models.dart';

/// A logger for services with automatic prefixing and metadata support.
class ServiceLogger {
  /// Creates a service logger.
  ServiceLogger({
    required String serviceName,
    ServiceLogLevel level = ServiceLogLevel.info,
    Map<String, dynamic>? metadata,
    ServiceLogWriter? writer,
  })  : _serviceName = serviceName,
        _level = level,
        _metadata = Map<String, dynamic>.from(metadata ?? {}),
        _writer = writer ?? ConsoleLogWriter();

  final String _serviceName;
  ServiceLogLevel _level;
  final Map<String, dynamic> _metadata;
  final ServiceLogWriter _writer;

  /// Gets the current log level.
  ServiceLogLevel get level => _level;

  /// Sets the log level.
  set level(ServiceLogLevel newLevel) => _level = newLevel;

  /// Gets a copy of the current metadata.
  Map<String, dynamic> get metadata => Map<String, dynamic>.from(_metadata);

  /// Sets metadata that will be included in all log entries.
  void setMetadata(Map<String, dynamic> metadata) {
    _metadata.clear();
    _metadata.addAll(metadata);
  }

  /// Adds metadata that will be included in all log entries.
  void addMetadata(String key, value) {
    _metadata[key] = value;
  }

  /// Removes metadata.
  void removeMetadata(String key) {
    _metadata.remove(key);
  }

  /// Clears all metadata.
  void clearMetadata() {
    _metadata.clear();
  }

  /// Logs a debug message.
  void debug(String message, {Map<String, dynamic>? metadata}) {
    _log(ServiceLogLevel.debug, message, metadata);
  }

  /// Logs an info message.
  void info(String message, {Map<String, dynamic>? metadata}) {
    _log(ServiceLogLevel.info, message, metadata);
  }

  /// Logs a warning message.
  void warning(String message, {Map<String, dynamic>? metadata}) {
    _log(ServiceLogLevel.warning, message, metadata);
  }

  /// Logs an error message.
  void error(String message,
      {Object? error, StackTrace? stackTrace, Map<String, dynamic>? metadata}) {
    final combinedMetadata = <String, dynamic>{
      if (metadata != null) ...metadata,
      if (error != null) 'error': error.toString(),
      if (stackTrace != null) 'stackTrace': stackTrace.toString(),
    };
    _log(ServiceLogLevel.error, message, combinedMetadata);
  }

  /// Logs a critical message.
  void critical(String message,
      {Object? error, StackTrace? stackTrace, Map<String, dynamic>? metadata}) {
    final combinedMetadata = <String, dynamic>{
      if (metadata != null) ...metadata,
      if (error != null) 'error': error.toString(),
      if (stackTrace != null) 'stackTrace': stackTrace.toString(),
    };
    _log(ServiceLogLevel.critical, message, combinedMetadata);
  }

  /// Logs a message with timing information.
  void timed(String operation, Duration duration,
      {ServiceLogLevel level = ServiceLogLevel.info,
      Map<String, dynamic>? metadata}) {
    final timedMetadata = <String, dynamic>{
      'operation': operation,
      'duration_ms': duration.inMilliseconds,
      if (metadata != null) ...metadata,
    };
    _log(
        level,
        'Operation completed: $operation (${duration.inMilliseconds}ms)',
        timedMetadata);
  }

  /// Creates a child logger with additional metadata.
  ServiceLogger child(Map<String, dynamic> additionalMetadata) {
    final childMetadata = <String, dynamic>{
      ..._metadata,
      ...additionalMetadata,
    };
    return ServiceLogger(
      serviceName: _serviceName,
      level: _level,
      metadata: childMetadata,
      writer: _writer,
    );
  }

  /// Executes a function and logs its execution time.
  Future<T> timeAsync<T>(String operation, Future<T> Function() function,
      {ServiceLogLevel level = ServiceLogLevel.info,
      Map<String, dynamic>? metadata}) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await function();
      stopwatch.stop();
      timed(operation, stopwatch.elapsed, level: level, metadata: metadata);
      return result;
    } catch (error, stackTrace) {
      stopwatch.stop();
      this.error(
          'Operation failed: $operation (${stopwatch.elapsed.inMilliseconds}ms)',
          error: error,
          stackTrace: stackTrace,
          metadata: metadata);
      rethrow;
    }
  }

  /// Executes a synchronous function and logs its execution time.
  T timeSync<T>(String operation, T Function() function,
      {ServiceLogLevel level = ServiceLogLevel.info,
      Map<String, dynamic>? metadata}) {
    final stopwatch = Stopwatch()..start();
    try {
      final result = function();
      stopwatch.stop();
      timed(operation, stopwatch.elapsed, level: level, metadata: metadata);
      return result;
    } catch (error, stackTrace) {
      stopwatch.stop();
      this.error(
          'Operation failed: $operation (${stopwatch.elapsed.inMilliseconds}ms)',
          error: error,
          stackTrace: stackTrace,
          metadata: metadata);
      rethrow;
    }
  }

  void _log(ServiceLogLevel logLevel, String message,
      Map<String, dynamic>? metadata) {
    if (!_shouldLog(logLevel)) return;

    final entry = ServiceLogEntry(
      timestamp: DateTime.now(),
      level: logLevel,
      serviceName: _serviceName,
      message: message,
      metadata: {
        ..._metadata,
        if (metadata != null) ...metadata,
      },
    );

    _writer.write(entry);
  }

  bool _shouldLog(ServiceLogLevel logLevel) => logLevel.index >= _level.index;
}

/// Represents a single log entry.
class ServiceLogEntry {
  /// Creates a log entry.
  const ServiceLogEntry({
    required this.timestamp,
    required this.level,
    required this.serviceName,
    required this.message,
    required this.metadata,
  });

  /// When the log entry was created.
  final DateTime timestamp;

  /// The log level.
  final ServiceLogLevel level;

  /// The name of the service that created this entry.
  final String serviceName;

  /// The log message.
  final String message;

  /// Additional metadata.
  final Map<String, dynamic> metadata;

  /// Converts the log entry to a formatted string.
  String format({bool includeMetadata = true}) {
    final buffer = StringBuffer();

    // Timestamp
    buffer.write(timestamp.toIso8601String());
    buffer.write(' ');

    // Level
    buffer.write('[${level.name.toUpperCase()}]');
    buffer.write(' ');

    // Service name
    buffer.write('[$serviceName]');
    buffer.write(' ');

    // Message
    buffer.write(message);

    // Metadata
    if (includeMetadata && metadata.isNotEmpty) {
      buffer.write(' ');
      buffer.write(jsonEncode(metadata));
    }

    return buffer.toString();
  }

  /// Converts the log entry to JSON.
  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'level': level.name,
        'serviceName': serviceName,
        'message': message,
        'metadata': metadata,
      };

  @override
  String toString() => format();
}

/// Abstract base class for log writers.
abstract class ServiceLogWriter {
  /// Writes a log entry.
  void write(ServiceLogEntry entry);

  /// Flushes any buffered log entries.
  void flush() {}

  /// Closes the log writer.
  void close() {}
}

/// A log writer that outputs to the console.
class ConsoleLogWriter extends ServiceLogWriter {
  /// Creates a console log writer.
  ConsoleLogWriter({this.colorize = true, IOSink? sink}) : _sink = sink;

  /// Whether to colorize output.
  final bool colorize;

  /// Optional sink for output; if null, defaults to stdout for <= warning and stderr for error/critical
  final IOSink? _sink;

  @override
  void write(ServiceLogEntry entry) {
    final formatted = entry.format();
    final output = colorize ? _colorize(formatted, entry.level) : formatted;

    final IOSink chosen = _sink ??
        ((entry.level.index >= ServiceLogLevel.error.index) ? stderr : stdout);
    chosen.writeln(output);
  }

  @override
  void flush() {
    _sink?.flush();
  }

  @override
  void close() {
    _sink?.close();
  }

  String _colorize(String message, ServiceLogLevel level) {
    const reset = '\x1B[0m';

    switch (level) {
      case ServiceLogLevel.debug:
        return '\x1B[90m$message$reset'; // Gray
      case ServiceLogLevel.info:
        return '\x1B[36m$message$reset'; // Cyan
      case ServiceLogLevel.warning:
        return '\x1B[33m$message$reset'; // Yellow
      case ServiceLogLevel.error:
        return '\x1B[31m$message$reset'; // Red
      case ServiceLogLevel.critical:
        return '\x1B[35m$message$reset'; // Magenta
    }
  }
}

/// A log writer that buffers entries in memory.
class MemoryLogWriter extends ServiceLogWriter {
  /// Creates a memory log writer.
  MemoryLogWriter({this.maxEntries = 1000});

  /// Maximum number of entries to keep in memory.
  final int maxEntries;

  final List<ServiceLogEntry> _entries = [];

  /// Gets all log entries.
  List<ServiceLogEntry> get entries => List.unmodifiable(_entries);

  @override
  void write(ServiceLogEntry entry) {
    _entries.add(entry);
    if (_entries.length > maxEntries) {
      _entries.removeAt(0);
    }
  }

  /// Clears all log entries.
  void clear() {
    _entries.clear();
  }

  /// Gets entries matching the specified criteria.
  List<ServiceLogEntry> getEntries({
    ServiceLogLevel? minLevel,
    String? serviceName,
    DateTime? since,
    DateTime? until,
  }) =>
      _entries.where((entry) {
        if (minLevel != null && entry.level.index < minLevel.index) {
          return false;
        }
        if (serviceName != null && entry.serviceName != serviceName) {
          return false;
        }
        if (since != null && entry.timestamp.isBefore(since)) {
          return false;
        }
        if (until != null && entry.timestamp.isAfter(until)) {
          return false;
        }
        return true;
      }).toList();
}

/// A log writer that writes to multiple other writers.
class MultiLogWriter extends ServiceLogWriter {
  /// Creates a multi log writer.
  MultiLogWriter(this.writers);

  /// The writers to write to.
  final List<ServiceLogWriter> writers;

  @override
  void write(ServiceLogEntry entry) {
    for (final writer in writers) {
      writer.write(entry);
    }
  }

  @override
  void flush() {
    for (final writer in writers) {
      writer.flush();
    }
  }

  @override
  void close() {
    for (final writer in writers) {
      writer.close();
    }
  }
}

/// A log writer that filters entries based on criteria.
class FilteredLogWriter extends ServiceLogWriter {
  /// Creates a filtered log writer.
  FilteredLogWriter({
    required this.writer,
    this.minLevel,
    this.serviceNameFilter,
    this.messageFilter,
  });

  /// The underlying writer.
  final ServiceLogWriter writer;

  /// Minimum log level to write.
  final ServiceLogLevel? minLevel;

  /// Service name filter (regex pattern).
  final String? serviceNameFilter;

  /// Message filter (regex pattern).
  final String? messageFilter;

  late final RegExp? _serviceNameRegex =
      serviceNameFilter != null ? RegExp(serviceNameFilter!) : null;
  late final RegExp? _messageRegex =
      messageFilter != null ? RegExp(messageFilter!) : null;

  @override
  void write(ServiceLogEntry entry) {
    if (!_shouldWrite(entry)) return;
    writer.write(entry);
  }

  @override
  void flush() => writer.flush();

  @override
  void close() => writer.close();

  bool _shouldWrite(ServiceLogEntry entry) {
    if (minLevel != null && entry.level.index < minLevel!.index) {
      return false;
    }

    if (_serviceNameRegex != null &&
        !_serviceNameRegex!.hasMatch(entry.serviceName)) {
      return false;
    }

    if (_messageRegex != null && !_messageRegex!.hasMatch(entry.message)) {
      return false;
    }

    return true;
  }
}

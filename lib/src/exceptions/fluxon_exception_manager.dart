/// Enhanced exception manager for fluxon services
library fluxon_exception_manager;

import 'package:squadron/squadron.dart';
import '../service_logger.dart';
import 'service_exceptions.dart';

/// Serializable exception data for cross-isolate transfer
class SerializableException {
  const SerializableException({
    required this.type,
    required this.message,
    this.data,
    this.stackTrace,
    this.cause,
  });

  final String type;
  final String message;
  final Map<String, dynamic>? data;
  final String? stackTrace;
  final String? cause;

  /// Convert to JSON for isolate transfer
  Map<String, dynamic> toJson() => {
        'type': type,
        'message': message,
        'data': data,
        'stackTrace': stackTrace,
        'cause': cause,
      };

  /// Create from JSON
  static SerializableException fromJson(Map<String, dynamic> json) =>
      SerializableException(
        type: json['type'] as String,
        message: json['message'] as String,
        data: json['data'] as Map<String, dynamic>?,
        stackTrace: json['stackTrace'] as String?,
        cause: json['cause'] as String?,
      );

  @override
  String toString() => '$type: $message';
}

/// Exception manager that provides better cross-isolate exception handling
class FluxonExceptionManager extends ExceptionManager {
  FluxonExceptionManager({ServiceLogger? logger})
      : _logger =
            logger ?? ServiceLogger(serviceName: 'FluxonExceptionManager'),
        super();

  final ServiceLogger _logger;

  /// Convert exceptions to serializable format for cross-isolate transfer
  Object? convertException(Object exception, [StackTrace? stackTrace]) {
    _logger.debug('Converting exception for isolate transfer', metadata: {
      'exceptionType': exception.runtimeType.toString(),
      'message': exception.toString(),
    });

    // Handle custom serializable exceptions
    if (exception is SerializableExceptionMixin) {
      return SerializableException(
        type: exception.runtimeType.toString(),
        message: exception.toString(),
        data: exception.serializeExceptionData(),
        stackTrace: stackTrace?.toString(),
      ).toJson();
    }

    // Handle fluxon service exceptions
    if (exception is ServiceException) {
      return SerializableException(
        type: exception.runtimeType.toString(),
        message: exception.message,
        data: {'cause': exception.cause?.toString()},
        stackTrace: stackTrace?.toString(),
      ).toJson();
    }

    // Handle standard Dart exceptions
    return SerializableException(
      type: exception.runtimeType.toString(),
      message: exception.toString(),
      stackTrace: stackTrace?.toString(),
    ).toJson();
  }

  /// Decode exceptions from serializable format
  Exception decodeException(Object? exception) {
    if (exception is Map<String, dynamic>) {
      try {
        final serializable = SerializableException.fromJson(exception);
        return _reconstructException(serializable);
      } catch (e) {
        _logger.warning('Failed to deserialize exception', metadata: {
          'error': e.toString(),
          'data': exception.toString(),
        });
      }
    }

    // Fallback for unhandled cases
    return ServiceException('Unknown exception: ${exception.toString()}');
  }

  /// Reconstruct the original exception from serializable data
  Exception _reconstructException(SerializableException serializable) {
    // Try to reconstruct specific exception types
    switch (serializable.type) {
      case 'ArgumentError':
        return FluxonRemoteException(
          originalType: 'ArgumentError',
          message: serializable.message,
          data: serializable.data,
          remoteStackTrace: serializable.stackTrace,
        );

      case 'StateError':
        return FluxonRemoteException(
          originalType: 'StateError',
          message: serializable.message,
          data: serializable.data,
          remoteStackTrace: serializable.stackTrace,
        );

      case 'ServiceException':
        return ServiceException(
            serializable.message, serializable.data?['cause']);

      case 'ServiceCallException':
        // Extract service and method names from message if possible
        return ServiceCallException(
            'UnknownService', 'unknownMethod', serializable.message);

      case 'ServiceTimeoutException':
        return ServiceException('Timeout: ${serializable.message}');

      default:
        // For custom exceptions, create a generic wrapper that preserves data
        return FluxonRemoteException(
          originalType: serializable.type,
          message: serializable.message,
          data: serializable.data,
          remoteStackTrace: serializable.stackTrace,
        );
    }
  }
}

/// Mixin for exceptions that can serialize their data
mixin SerializableExceptionMixin on Exception {
  /// Serialize exception-specific data for cross-isolate transfer
  Map<String, dynamic> serializeExceptionData();
}

/// Wrapper exception for remote exceptions that couldn't be fully reconstructed
class FluxonRemoteException extends ServiceException {
  const FluxonRemoteException({
    required this.originalType,
    required String message,
    this.data,
    this.remoteStackTrace,
  }) : super(message);

  final String originalType;
  final Map<String, dynamic>? data;
  final String? remoteStackTrace;

  @override
  String toString() {
    final buffer = StringBuffer('$originalType (remote): $message');
    if (data != null && data!.isNotEmpty) {
      buffer.write('\nData: $data');
    }
    if (remoteStackTrace != null) {
      buffer.write('\nRemote Stack Trace:\n$remoteStackTrace');
    }
    return buffer.toString();
  }
}

/// Create a default fluxon exception manager
FluxonExceptionManager createFluxonExceptionManager({ServiceLogger? logger}) =>
    FluxonExceptionManager(logger: logger);

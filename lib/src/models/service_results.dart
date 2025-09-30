part of 'service_models.dart';

class ServiceResult<T> {
  const ServiceResult.success(this.data)
      : error = null,
        isSuccess = true;

  const ServiceResult.failure(this.error)
      : data = null,
        isSuccess = false;

  final T? data;
  final Object? error;
  final bool isSuccess;

  bool get isFailure => !isSuccess;

  @override
  String toString() => isSuccess
      ? 'ServiceResult.success($data)'
      : 'ServiceResult.failure($error)';
}

class ServiceCallOptions {
  const ServiceCallOptions({
    this.timeout = const Duration(days: 1),
    this.retryAttempts = 0,
    this.retryDelay = const Duration(milliseconds: 500),
    this.metadata = const <String, dynamic>{},
  });

  final Duration timeout;
  final int retryAttempts;
  final Duration retryDelay;
  final Map<String, dynamic> metadata;
}

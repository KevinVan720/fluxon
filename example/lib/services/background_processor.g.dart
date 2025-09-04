// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'background_processor.dart';

// **************************************************************************
// ServiceGenerator
// **************************************************************************

// Service client for BackgroundProcessor
class BackgroundProcessorClient extends BackgroundProcessor {
  BackgroundProcessorClient(this._proxy);
  final ServiceProxy<BackgroundProcessor> _proxy;

  @override
  Future<Map<String, dynamic>> processLargeDataset(
      List<Map<String, dynamic>> data) async {
    return await _proxy
        .callMethod('processLargeDataset', [data], namedArgs: {});
  }

  @override
  Future<List<Map<String, dynamic>>> generateTaskRecommendations(
      String userId) async {
    return await _proxy
        .callMethod('generateTaskRecommendations', [userId], namedArgs: {});
  }

  @override
  Future<Map<String, dynamic>> batchProcessTasks(List<String> taskIds) async {
    return await _proxy
        .callMethod('batchProcessTasks', [taskIds], namedArgs: {});
  }
}

void $registerBackgroundProcessorClientFactory() {
  GeneratedClientRegistry.register<BackgroundProcessor>(
    (proxy) => BackgroundProcessorClient(proxy),
  );
}

class _BackgroundProcessorMethods {
  static const int processLargeDatasetId = 1;
  static const int generateTaskRecommendationsId = 2;
  static const int batchProcessTasksId = 3;
}

Future<dynamic> _BackgroundProcessorDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as BackgroundProcessor;
  switch (methodId) {
    case _BackgroundProcessorMethods.processLargeDatasetId:
      return await s.processLargeDataset(positionalArgs[0]);
    case _BackgroundProcessorMethods.generateTaskRecommendationsId:
      return await s.generateTaskRecommendations(positionalArgs[0]);
    case _BackgroundProcessorMethods.batchProcessTasksId:
      return await s.batchProcessTasks(positionalArgs[0]);
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void $registerBackgroundProcessorDispatcher() {
  GeneratedDispatcherRegistry.register<BackgroundProcessor>(
    _BackgroundProcessorDispatcher,
  );
}

void $registerBackgroundProcessorMethodIds() {
  ServiceMethodIdRegistry.register<BackgroundProcessor>({
    'processLargeDataset': _BackgroundProcessorMethods.processLargeDatasetId,
    'generateTaskRecommendations':
        _BackgroundProcessorMethods.generateTaskRecommendationsId,
    'batchProcessTasks': _BackgroundProcessorMethods.batchProcessTasksId,
  });
}

void registerBackgroundProcessorGenerated() {
  $registerBackgroundProcessorClientFactory();
  $registerBackgroundProcessorMethodIds();
}

// Remote service implementation that auto-registers the dispatcher
class BackgroundProcessorImpl extends BackgroundProcessor {
  @override
  Type get clientBaseType => BackgroundProcessor;
  @override
  Future<void> registerHostSide() async {
    $registerBackgroundProcessorClientFactory();
    $registerBackgroundProcessorMethodIds();
    // Auto-registered from dependencies/optionalDependencies
    try {
      $registerTaskServiceClientFactory();
    } catch (_) {}
    try {
      $registerTaskServiceMethodIds();
    } catch (_) {}
  }

  @override
  Future<void> initialize() async {
    $registerBackgroundProcessorDispatcher();
    // Ensure worker isolate can create clients for dependencies
    try {
      $registerTaskServiceClientFactory();
    } catch (_) {}
    try {
      $registerTaskServiceMethodIds();
    } catch (_) {}
    await super.initialize();
  }
}

void $registerBackgroundProcessorLocalSide() {
  $registerBackgroundProcessorDispatcher();
  $registerBackgroundProcessorClientFactory();
  $registerBackgroundProcessorMethodIds();
  try {
    $registerTaskServiceClientFactory();
  } catch (_) {}
  try {
    $registerTaskServiceMethodIds();
  } catch (_) {}
}

void $autoRegisterBackgroundProcessorLocalSide() {
  LocalSideRegistry.register<BackgroundProcessor>(
      $registerBackgroundProcessorLocalSide);
}

final $_BackgroundProcessorLocalSideRegistered = (() {
  $autoRegisterBackgroundProcessorLocalSide();
  return true;
})();

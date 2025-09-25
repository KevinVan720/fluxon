// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'image_filter_service.dart';

// **************************************************************************
// ServiceGenerator
// **************************************************************************

// Service client for ImageFilterService
class ImageFilterServiceClient extends ImageFilterService {
  ImageFilterServiceClient(this._proxy);
  final ServiceProxy<ImageFilterService> _proxy;

  @override
  Future<Uint8List> applyFilter(Uint8List inputBytes,
      {required String filter,
      double amount = 1.0,
      double sigma = 2.0,
      double brightness = 0.0,
      double contrast = 0.0}) async {
    return await _proxy.callMethod<Uint8List>('applyFilter', [
      inputBytes
    ], namedArgs: {
      'filter': filter,
      'amount': amount,
      'sigma': sigma,
      'brightness': brightness,
      'contrast': contrast
    });
  }
}

void $registerImageFilterServiceClientFactory() {
  GeneratedClientRegistry.register<ImageFilterService>(
    (proxy) => ImageFilterServiceClient(proxy),
  );
}

class _ImageFilterServiceMethods {
  static const int applyFilterId = 1;
}

Future<dynamic> _ImageFilterServiceDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as ImageFilterService;
  switch (methodId) {
    case _ImageFilterServiceMethods.applyFilterId:
      return await s.applyFilter(positionalArgs[0],
          filter: namedArgs['filter'],
          amount: namedArgs['amount'],
          sigma: namedArgs['sigma'],
          brightness: namedArgs['brightness'],
          contrast: namedArgs['contrast']);
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void $registerImageFilterServiceDispatcher() {
  GeneratedDispatcherRegistry.register<ImageFilterService>(
    _ImageFilterServiceDispatcher,
  );
}

void $registerImageFilterServiceMethodIds() {
  ServiceMethodIdRegistry.register<ImageFilterService>({
    'applyFilter': _ImageFilterServiceMethods.applyFilterId,
  });
}

void registerImageFilterServiceGenerated() {
  $registerImageFilterServiceClientFactory();
  $registerImageFilterServiceMethodIds();
}

// Remote service implementation that auto-registers the dispatcher
class ImageFilterServiceImpl extends ImageFilterService {
  @override
  bool get isRemote => true;
  @override
  Type get clientBaseType => ImageFilterService;
  @override
  Future<void> registerHostSide() async {
    $registerImageFilterServiceClientFactory();
    $registerImageFilterServiceMethodIds();
  }

  @override
  Future<void> initialize() async {
    $registerImageFilterServiceDispatcher();
    await super.initialize();
  }
}

void $registerImageFilterServiceLocalSide() {
  $registerImageFilterServiceDispatcher();
  $registerImageFilterServiceClientFactory();
  $registerImageFilterServiceMethodIds();
}

void $autoRegisterImageFilterServiceLocalSide() {
  LocalSideRegistry.register<ImageFilterService>(
      $registerImageFilterServiceLocalSide);
}

final $_ImageFilterServiceLocalSideRegistered = (() {
  $autoRegisterImageFilterServiceLocalSide();
  return true;
})();

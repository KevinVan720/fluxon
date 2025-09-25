// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'image_filter_coordinator.dart';

// **************************************************************************
// ServiceGenerator
// **************************************************************************

// Service client for ImageFilterCoordinator
class ImageFilterCoordinatorClient extends ImageFilterCoordinator {
  ImageFilterCoordinatorClient(this._proxy);
  final ServiceProxy<ImageFilterCoordinator> _proxy;

  @override
  Future<Uint8List> requestFilter(
      {required Uint8List imageBytes,
      required String target,
      required String filter,
      required double amount,
      required double sigma,
      required double brightness,
      required double contrast,
      required double saturation,
      required double hue,
      Duration timeout = const Duration(seconds: 30)}) async {
    return await _proxy.callMethod<Uint8List>('requestFilter', [], namedArgs: {
      'imageBytes': imageBytes,
      'target': target,
      'filter': filter,
      'amount': amount,
      'sigma': sigma,
      'brightness': brightness,
      'contrast': contrast,
      'saturation': saturation,
      'hue': hue,
      'timeout': timeout
    });
  }
}

void $registerImageFilterCoordinatorClientFactory() {
  GeneratedClientRegistry.register<ImageFilterCoordinator>(
    (proxy) => ImageFilterCoordinatorClient(proxy),
  );
}

class _ImageFilterCoordinatorMethods {
  static const int requestFilterId = 1;
}

Future<dynamic> _ImageFilterCoordinatorDispatcher(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
) async {
  final s = service as ImageFilterCoordinator;
  switch (methodId) {
    case _ImageFilterCoordinatorMethods.requestFilterId:
      return await s.requestFilter(
          imageBytes: namedArgs['imageBytes'],
          target: namedArgs['target'],
          filter: namedArgs['filter'],
          amount: namedArgs['amount'],
          sigma: namedArgs['sigma'],
          brightness: namedArgs['brightness'],
          contrast: namedArgs['contrast'],
          saturation: namedArgs['saturation'],
          hue: namedArgs['hue'],
          timeout: namedArgs['timeout']);
    default:
      throw ServiceException('Unknown method id: $methodId');
  }
}

void $registerImageFilterCoordinatorDispatcher() {
  GeneratedDispatcherRegistry.register<ImageFilterCoordinator>(
    _ImageFilterCoordinatorDispatcher,
  );
}

void $registerImageFilterCoordinatorMethodIds() {
  ServiceMethodIdRegistry.register<ImageFilterCoordinator>({
    'requestFilter': _ImageFilterCoordinatorMethods.requestFilterId,
  });
}

void registerImageFilterCoordinatorGenerated() {
  $registerImageFilterCoordinatorClientFactory();
  $registerImageFilterCoordinatorMethodIds();
}

// Local service implementation that auto-registers local side
class ImageFilterCoordinatorImpl extends ImageFilterCoordinator {
  ImageFilterCoordinatorImpl() {
    // 🚀 AUTO-REGISTRATION: Register local side when instance is created
    $registerImageFilterCoordinatorLocalSide();
  }
}

void $registerImageFilterCoordinatorLocalSide() {
  $registerImageFilterCoordinatorDispatcher();
  $registerImageFilterCoordinatorClientFactory();
  $registerImageFilterCoordinatorMethodIds();
}

void $autoRegisterImageFilterCoordinatorLocalSide() {
  LocalSideRegistry.register<ImageFilterCoordinator>(
      $registerImageFilterCoordinatorLocalSide);
}

final $_ImageFilterCoordinatorLocalSideRegistered = (() {
  $autoRegisterImageFilterCoordinatorLocalSide();
  return true;
})();

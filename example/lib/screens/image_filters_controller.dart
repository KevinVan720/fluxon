import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:fluxon/flux.dart';

import '../services/image_filter_coordinator.dart';
import '../events/image_events.dart';

class ImageFiltersController extends ChangeNotifier {
  ImageFiltersController(this.runtime);

  final FluxRuntime runtime;

  // Inputs
  Uint8List? originalBytes;

  // Config
  String filter = 'grayscale';
  bool useRemote = true;
  double amount = 1.0;
  double sigma = 2.0;
  double brightness = 1.0; // 1.0 = unmodified per image package
  double contrast = 1.0; // 1.0 = unmodified per image package
  double saturation = 1.0; // 1.0 = original saturation
  double hue = 0.0; // degrees, -180..180

  // Outputs
  Uint8List? previewBytes;
  bool isProcessing = false;
  Object? lastError;
  String? _latestRequestId;

  Timer? _debounce;

  void setOriginal(Uint8List bytes) {
    originalBytes = bytes;
    previewBytes = bytes;
    _scheduleApply();
    notifyListeners();
  }

  void setFilter(String value) {
    filter = value;
    _scheduleApply();
    notifyListeners();
  }

  void setUseRemote(bool value) {
    useRemote = value;
    _scheduleApply();
    notifyListeners();
  }

  void setAmount(double value) {
    amount = value;
    _scheduleApply();
    notifyListeners();
  }

  void setSigma(double value) {
    sigma = value;
    _scheduleApply();
    notifyListeners();
  }

  void setBrightness(double value) {
    brightness = value;
    _scheduleApply();
    notifyListeners();
  }

  void setContrast(double value) {
    contrast = value;
    _scheduleApply();
    notifyListeners();
  }

  void setSaturation(double value) {
    saturation = value;
    _scheduleApply();
    notifyListeners();
  }

  void setHue(double value) {
    hue = value;
    _scheduleApply();
    notifyListeners();
  }

  void _scheduleApply() {
    _debounce?.cancel();
    // Short debounce to avoid storming the service during slider drags
    _debounce = Timer(const Duration(milliseconds: 50), () {
      apply();
    });
  }

  Future<void> apply() async {
    if (originalBytes == null) return;
    isProcessing = true;
    lastError = null;
    notifyListeners();

    // Create a new request id and remember it as the latest
    final requestId = DateTime.now().microsecondsSinceEpoch.toString();
    _latestRequestId = requestId;

    // Register event types and listeners on host side
    registerImageEventTypes();

    // Use coordinator to issue request and await its completion
    unawaited(() async {
      try {
        final bytes = await runtime.get<ImageFilterCoordinator>().requestFilter(
          imageBytes: originalBytes!,
          target: useRemote ? 'remote' : 'local',
          filter: filter,
          amount: amount,
          sigma: sigma,
          brightness: brightness,
          contrast: contrast,
          saturation: saturation,
          hue: hue,
        );
        if (_latestRequestId == requestId) {
          previewBytes = bytes;
          isProcessing = false;
          notifyListeners();
        }
      } catch (e) {
        if (_latestRequestId == requestId) {
          lastError = e;
          isProcessing = false;
          notifyListeners();
        }
      }
    }());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

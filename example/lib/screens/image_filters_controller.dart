import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flux/flux.dart';
import '../services/image_filter_service.dart';
import '../services/local_image_filter_service.dart';

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
  double brightness = 0.0;
  double contrast = 0.0;

  // Outputs
  Uint8List? previewBytes;
  bool isProcessing = false;
  Object? lastError;

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
    try {
      final result = useRemote
          ? await runtime.get<ImageFilterService>().applyFilter(
              originalBytes!,
              filter: filter,
              amount: amount,
              sigma: sigma,
              brightness: brightness,
              contrast: contrast,
            )
          : await runtime.get<LocalImageFilterService>().applyFilter(
              originalBytes!,
              filter: filter,
              amount: amount,
              sigma: sigma,
              brightness: brightness,
              contrast: contrast,
            );
      previewBytes = result;
    } catch (e) {
      lastError = e;
    } finally {
      isProcessing = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

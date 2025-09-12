import 'dart:typed_data';
import 'package:flux/flux.dart';
import 'package:image/image.dart' as img;

/// Local (non-remote) image filtering service for comparison.
/// Implements the same API as ImageFilterService but runs on the main isolate.
class LocalImageFilterService extends FluxService {
  Future<Uint8List> applyFilter(
    Uint8List inputBytes, {
    required String filter,
    double amount = 1.0,
    double sigma = 2.0,
    double brightness = 0.0,
    double contrast = 0.0,
  }) async {
    final decoded = img.decodeImage(inputBytes);
    if (decoded == null) {
      throw ArgumentError('Unsupported or corrupt image bytes');
    }

    img.Image output = decoded.clone();

    for (int i = 0; i < 10; i++) {
      switch (filter) {
        case 'grayscale':
          output = img.grayscale(output);
          break;
        case 'sepia':
          output = img.sepia(output, amount: amount);
          break;
        case 'gaussianBlur':
          final radius = sigma.isNaN ? 1 : sigma.abs().clamp(1, 64).toInt();
          output = img.gaussianBlur(output, radius: radius);
          break;
        case 'edgeDetect':
          output = img.sobel(output);
          break;
        case 'brightness':
          output = img.adjustColor(
            output,
            brightness: brightness.clamp(-1.0, 1.0),
          );
          break;
        case 'contrast':
          output = img.adjustColor(output, contrast: contrast.clamp(-1.0, 1.0));
          break;
        default:
          break;
      }
    }

    final pngBytes = img.encodePng(output);
    return Uint8List.fromList(pngBytes);
  }
}

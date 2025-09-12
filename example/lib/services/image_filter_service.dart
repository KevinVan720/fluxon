import 'dart:typed_data';
import 'package:flux/flux.dart';
import 'package:image/image.dart' as img;

part 'image_filter_service.g.dart';

/// Image filtering service that runs in a worker isolate.
/// Accepts raw image bytes and returns processed PNG bytes.
@ServiceContract(remote: true)
class ImageFilterService extends FluxService {
  /// Apply a filter by name to the provided image bytes.
  ///
  /// The input can be any supported format (PNG/JPEG/WebP). The output is PNG.
  Future<Uint8List> applyFilter(
    Uint8List inputBytes, {
    required String filter,
    double amount = 1.0,
    double sigma = 2.0,
    double brightness = 0.0, // -1.0 .. 1.0
    double contrast = 0.0, // -1.0 .. 1.0
  }) async {
    final decoded = img.decodeImage(inputBytes);
    if (decoded == null) {
      throw ArgumentError('Unsupported or corrupt image bytes');
    }

    // Work on a copy to avoid mutating input
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
          // radius must be an int in the image package
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
          // No-op: return original encoded as PNG
          break;
      }
    }

    final pngBytes = img.encodePng(output);
    return Uint8List.fromList(pngBytes);
  }
}

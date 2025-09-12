import 'package:image/image.dart' as img;

class FilterOps {
  /// Apply a single-pass filter transformation.
  /// This does not loop; callers decide multi-pass behavior (e.g., motion blur).
  static img.Image applySinglePass(
    img.Image input, {
    required String filter,
    required double amount,
    required double sigma,
    required double brightness,
    required double contrast,
    double saturation = 1.0,
    double hue = 0.0,
  }) {
    switch (filter) {
      case 'grayscale':
        return img.grayscale(input);
      case 'sepia':
        return img.sepia(input, amount: amount);
      case 'gaussianBlur':
        final radius = sigma.isNaN ? 1 : sigma.abs().clamp(1, 64).toInt();
        return img.gaussianBlur(input, radius: radius);
      case 'edgeDetect':
        return img.sobel(input);
      case 'brightness':
        return img.adjustColor(input, brightness: brightness.clamp(0.0, 2.0));
      case 'contrast':
        return img.adjustColor(input, contrast: contrast.clamp(0.0, 2.0));
      case 'saturation':
        return img.adjustColor(input, saturation: saturation.clamp(0.0, 2.0));
      case 'hue':
        return img.adjustColor(input, hue: hue);
      case 'pixelate':
        final block = amount.clamp(2.0, 40.0).round();
        int dw = (input.width / block).floor();
        int dh = (input.height / block).floor();
        if (dw < 1) dw = 1;
        if (dh < 1) dh = 1;
        final small = img.copyResize(
          input,
          width: dw,
          height: dh,
          interpolation: img.Interpolation.average,
        );
        return img.copyResize(
          small,
          width: input.width,
          height: input.height,
          interpolation: img.Interpolation.nearest,
        );
      default:
        return input;
    }
  }
}

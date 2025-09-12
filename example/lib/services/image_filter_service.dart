import 'dart:typed_data';
import 'package:fluxon/flux.dart';
import 'package:image/image.dart' as img;
import 'dart:convert';
import '../events/image_events.dart';
import 'filter_ops.dart';

part 'image_filter_service.g.dart';

/// Image filtering service that runs in a worker isolate.
/// Accepts raw image bytes and returns processed PNG bytes.
@ServiceContract(remote: true)
class ImageFilterService extends FluxService {
  String? _currentRequestId; // for cooperative cancellation

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

    for (int i = 0; i < 20; i++) {
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

  @override
  Future<void> initialize() async {
    await super.initialize();
    // Register typed events in this isolate
    registerImageEventTypes();

    // Listen for versioned filter requests
    onEvent<FilterRequestEvent>((event) async {
      // Only handle events targeted at remote
      if (event.target != 'remote') {
        return const EventProcessingResponse(
          result: EventProcessingResult.ignored,
          processingTime: Duration(milliseconds: 1),
        );
      }

      _currentRequestId = event.requestId;

      // Decode input
      final input = event.imageBytes;
      final decoded = img.decodeImage(input);
      if (decoded == null) {
        return const EventProcessingResponse(
          result: EventProcessingResult.failed,
          processingTime: Duration(milliseconds: 1),
        );
      }

      img.Image output = decoded.clone();

      // 10-pass cooperative loop with progress
      const passes = 10;
      for (int i = 0; i < passes; i++) {
        if (_currentRequestId != event.requestId) {
          // cancelled by a newer request
          await sendEvent(
            createEvent<FilterCancelledEvent>(
              ({
                required String eventId,
                required String sourceService,
                required DateTime timestamp,
                String? correlationId,
                Map<String, dynamic> metadata = const {},
              }) => FilterCancelledEvent(
                eventId: eventId,
                sourceService: sourceService,
                timestamp: timestamp,
                correlationId: correlationId,
                metadata: metadata,
                requestId: event.requestId,
              ),
            ),
          );
          return const EventProcessingResponse(
            result: EventProcessingResult.skipped,
            processingTime: Duration(milliseconds: 1),
          );
        }

        if (event.filter == 'motionBlur') {
          final radius = event.sigma.isNaN
              ? 1
              : event.sigma.abs().clamp(1, 64).toInt();
          final mbPasses = event.amount.clamp(1.0, 10.0).round();
          for (int k = 0; k < mbPasses; k++) {
            output = img.gaussianBlur(output, radius: radius);
          }
        } else {
          output = FilterOps.applySinglePass(
            output,
            filter: event.filter,
            amount: event.amount,
            sigma: event.sigma,
            brightness: event.brightness,
            contrast: event.contrast,
            saturation: event.saturation,
            hue: event.hue,
          );
        }

        // Emit progress
        final percent = ((i + 1) / passes) * 100.0;
        await sendEvent(
          createEvent<FilterProgressEvent>(
            ({
              required String eventId,
              required String sourceService,
              required DateTime timestamp,
              String? correlationId,
              Map<String, dynamic> metadata = const {},
            }) => FilterProgressEvent(
              eventId: eventId,
              sourceService: sourceService,
              timestamp: timestamp,
              correlationId: correlationId,
              metadata: metadata,
              requestId: event.requestId,
              percent: percent,
            ),
          ),
        );
        // Tiny delay to simulate work and allow cancellation checks
        await Future.delayed(const Duration(milliseconds: 2));
      }

      final pngBytes = img.encodePng(output);
      final base64Image = base64Encode(pngBytes);
      await sendEvent(
        createEvent<FilterResultEvent>(
          ({
            required String eventId,
            required String sourceService,
            required DateTime timestamp,
            String? correlationId,
            Map<String, dynamic> metadata = const {},
          }) => FilterResultEvent(
            eventId: eventId,
            sourceService: sourceService,
            timestamp: timestamp,
            correlationId: correlationId,
            metadata: metadata,
            requestId: event.requestId,
            imageBytesBase64: base64Image,
          ),
        ),
      );

      return const EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration(milliseconds: 1),
      );
    });
  }
}

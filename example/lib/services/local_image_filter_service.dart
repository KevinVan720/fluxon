import 'filter_ops.dart';
import 'dart:typed_data';
import 'package:fluxon/fluxon.dart';
import 'package:image/image.dart' as img;
import 'dart:convert';
import '../events/image_events.dart';

/// Local (non-remote) image filtering service for comparison.
/// Implements the same API as ImageFilterService but runs on the main isolate.
class LocalImageFilterService extends FluxonService {
  String? _currentRequestId;
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

  @override
  Future<void> initialize() async {
    await super.initialize();
    registerImageEventTypes();

    onEvent<FilterRequestEvent>((event) async {
      if (event.target != 'local') {
        return const EventProcessingResponse(
          result: EventProcessingResult.ignored,
          processingTime: Duration(milliseconds: 1),
        );
      }

      _currentRequestId = event.requestId;

      final decoded = img.decodeImage(event.imageBytes);
      if (decoded == null) {
        return const EventProcessingResponse(
          result: EventProcessingResult.failed,
          processingTime: Duration(milliseconds: 1),
        );
      }
      img.Image output = decoded.clone();

      const passes = 10;
      for (int i = 0; i < passes; i++) {
        if (_currentRequestId != event.requestId) {
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
        await Future.delayed(const Duration(milliseconds: 2));
      }

      final png = img.encodePng(output);
      final base64Image = base64Encode(png);
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

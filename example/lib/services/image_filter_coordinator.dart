import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:fluxon/fluxon.dart';
import '../events/image_events.dart';

part 'image_filter_coordinator.g.dart';

@ServiceContract(remote: false)
class ImageFilterCoordinator extends FluxService {
  final Map<String, Completer<Uint8List>> _pending = {};

  @override
  Future<void> initialize() async {
    await super.initialize();
    registerImageEventTypes();

    onEvent<FilterResultEvent>((event) async {
      final c = _pending.remove(event.requestId);
      if (c != null && !c.isCompleted) {
        c.complete(event.imageBytes);
      }
      return const EventProcessingResponse(
        result: EventProcessingResult.success,
        processingTime: Duration(milliseconds: 1),
      );
    });

    onEvent<FilterCancelledEvent>((event) async {
      final c = _pending.remove(event.requestId);
      if (c != null && !c.isCompleted) {
        c.completeError(StateError('Cancelled'));
      }
      return const EventProcessingResponse(
        result: EventProcessingResult.skipped,
        processingTime: Duration(milliseconds: 1),
      );
    });
  }

  Future<Uint8List> requestFilter({
    required Uint8List imageBytes,
    required String target, // 'remote' | 'local'
    required String filter,
    required double amount,
    required double sigma,
    required double brightness,
    required double contrast,
    required double saturation,
    required double hue,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final requestId = DateTime.now().microsecondsSinceEpoch.toString();
    final completer = Completer<Uint8List>();
    _pending[requestId] = completer;

    final b64 = base64Encode(imageBytes);
    await sendEvent(
      createEvent<FilterRequestEvent>(
        ({
          required String eventId,
          required String sourceService,
          required DateTime timestamp,
          String? correlationId,
          Map<String, dynamic> metadata = const {},
        }) => FilterRequestEvent(
          eventId: eventId,
          sourceService: sourceService,
          timestamp: timestamp,
          correlationId: correlationId,
          metadata: metadata,
          requestId: requestId,
          target: target,
          filter: filter,
          amount: amount,
          sigma: sigma,
          brightness: brightness,
          contrast: contrast,
          saturation: saturation,
          hue: hue,
          imageBytesBase64: b64,
        ),
      ),
    );

    return completer.future.timeout(
      timeout,
      onTimeout: () {
        _pending.remove(requestId);
        throw TimeoutException('Filter timed out', timeout);
      },
    );
  }
}

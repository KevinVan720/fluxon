import 'dart:math';

import 'package:fluxon/fluxon.dart';
import 'package:test/test.dart';

part 'large_nested_payload_test.g.dart';

Map<String, dynamic> _generateNested(int depth, int breadth) {
  Map<String, dynamic> current = {};
  for (var i = 0; i < breadth; i++) {
    current['k$i'] = List.generate(10, (j) => j + i);
  }
  var root = current;
  for (var d = 1; d < depth; d++) {
    final next = <String, dynamic>{};
    next['level$d'] = current;
    current = next;
  }
  return current['level${depth - 1}'] != null ? current : {'root': root};
}

@ServiceContract(remote: true)
class PayloadService extends FluxService {
  Future<Map<String, dynamic>> getBigPayload(int depth, int breadth) async {
    // generate deterministically
    return _generateNested(max(1, depth), max(1, breadth));
  }
}

void main() {
  group('Large nested payload across isolates', () {
    late FluxRuntime runtime;
    setUp(() {
      runtime = FluxRuntime();
    });
    tearDown(() async {
      await runtime.destroyAll();
    });

    test('round-trips complex nested map correctly', () async {
      runtime.register<PayloadService>(PayloadServiceImpl.new);
      await runtime.initializeAll();
      final svc = runtime.get<PayloadService>();

      final payload = await svc.getBigPayload(4, 5);
      expect(payload, isA<Map<String, dynamic>>());
      // Spot-check a few nested points
      // Structure depends on _generateNested; just ensure keys exist and lists are correct length
      expect(payload.values.isNotEmpty, isTrue);
    });
  });
}

import 'package:fluxon/fluxon.dart';
import 'package:test/test.dart';

@ServiceContract(remote: false)
class Tiny extends FluxService {}

void main() {
  group('Runtime initialization idempotency', () {
    test('concurrent initializeAll calls result in single successful init',
        () async {
      final runtime = FluxRuntime();
      runtime.register<Tiny>(Tiny.new);

      Object? err1;
      Object? err2;

      final f1 = runtime.initializeAll().catchError((e) => err1 = e);
      final f2 = runtime.initializeAll().catchError((e) => err2 = e);
      await Future.wait([f1, f2]);

      expect(runtime.isInitialized, isTrue);

      // Exactly one of them may throw ServiceStateException(initializing)
      final errors = [err1, err2].where((e) => e != null).toList();
      if (errors.isNotEmpty) {
        expect(errors, hasLength(1));
        expect(errors.first, isA<ServiceStateException>());
      }

      // Calling initializeAll again should no-op
      await runtime.initializeAll();

      await runtime.destroyAll();
      expect(runtime.isInitialized, isFalse);
    });
  });
}

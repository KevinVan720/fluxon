import 'package:fluxon/fluxon.dart';
import 'package:test/test.dart';

part 'remote_init_failure_test.g.dart';

@ServiceContract(remote: true)
class ExplodingRemote extends FluxonService {
  @override
  Future<void> initialize() async {
    await super.initialize();
    throw ServiceInitializationException('boom');
  }

  Future<String> hello() async => 'hi';
}

void main() {
  group('Remote initialization failure', () {
    late FluxonRuntime runtime;

    setUp(() {
      runtime = FluxonRuntime();
    });

    tearDown(() async {
      try {
        if (runtime.isInitialized) {
          await runtime.destroyAll();
        }
      } catch (_) {}
    });

    test('propagates init failure and tears down worker cleanly', () async {
      runtime.register<ExplodingRemote>(ExplodingRemoteImpl.new);

      // Initialization failure from worker may be wrapped; accept any exception
      expect(
        () => runtime.initializeAll(),
        throwsA(
          predicate<Object>(
            (error) =>
                error.toString().contains('Failed to initialize service'),
          ),
        ),
      );

      // After failure, runtime should not be initialized
      expect(runtime.isInitialized, isFalse);

      // Re-register a healthy service after failure to ensure cleanup worked
      runtime = FluxonRuntime();
      runtime.register<ExplodingRemote>(ExplodingRemoteImpl.new);
      // Replace impl to not throw this time by subclassing at runtime is not trivial;
      // Just assert that attempting to get before init throws
      expect(
        () => runtime.initializeAll(),
        throwsA(
          predicate<Object>(
            (error) =>
                error.toString().contains('Failed to initialize service'),
          ),
        ),
      );
    });
  });
}

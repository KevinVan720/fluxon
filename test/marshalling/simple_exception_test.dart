import 'package:fluxon/fluxon.dart';
import 'package:test/test.dart';

part 'simple_exception_test.g.dart';

/// Simple service to test basic exception propagation
@ServiceContract(remote: true)
class SimpleExceptionService extends FluxonService {
  /// Throw a standard exception
  Future<String> throwSimpleException() async {
    throw const ServiceException('Simple service exception from worker');
  }

  /// Method that can succeed or fail
  Future<String> conditionalMethod(bool shouldFail) async {
    if (shouldFail) {
      throw const ServiceException('Method failed as requested');
    }
    return 'Success!';
  }

  /// Throw with details
  Future<String> throwWithDetails() async {
    throw const ServiceCallException('SimpleExceptionService',
        'throwWithDetails', 'Detailed error information');
  }
}

void main() {
  group('Simple Exception Tests', () {
    late FluxonRuntime runtime;

    setUp(() {
      // Test with enhanced exception handling
      runtime = FluxonRuntime.withExceptionHandling();
    });

    tearDown(() async {
      await runtime.destroyAll();
    });

    test('should propagate service exceptions with enhanced handling',
        () async {
      runtime.register<SimpleExceptionService>(SimpleExceptionServiceImpl.new);
      await runtime.initializeAll();

      final service = runtime.get<SimpleExceptionService>();

      try {
        await service.throwSimpleException();
        fail('Expected exception to be thrown');
      } catch (e) {
        print('🔍 Exception caught: ${e.runtimeType}');
        print('🔍 Exception message: $e');

        // Test that we can catch specific exception types
        expect(e, isA<Exception>());
        expect(e.toString(), contains('Simple service exception'));
      }
    });

    test('should handle conditional exceptions', () async {
      runtime.register<SimpleExceptionService>(SimpleExceptionServiceImpl.new);
      await runtime.initializeAll();

      final service = runtime.get<SimpleExceptionService>();

      // Test success case
      final success = await service.conditionalMethod(false);
      expect(success, equals('Success!'));

      // Test failure case
      try {
        await service.conditionalMethod(true);
        fail('Expected exception to be thrown');
      } catch (e) {
        print('🔍 Conditional exception: ${e.runtimeType} = $e');
        expect(e, isA<Exception>());
      }
    });

    test('should provide detailed exception information', () async {
      runtime.register<SimpleExceptionService>(SimpleExceptionServiceImpl.new);
      await runtime.initializeAll();

      final service = runtime.get<SimpleExceptionService>();

      try {
        await service.throwWithDetails();
        fail('Expected exception to be thrown');
      } catch (e) {
        print('🔍 Detailed exception: ${e.runtimeType} = $e');
        expect(e, isA<Exception>());
        expect(e.toString(), contains('throwWithDetails'));
      }
    });
  });
}

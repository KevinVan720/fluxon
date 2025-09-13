import 'package:fluxon/src/events/models/event_distribution.dart';
import 'package:fluxon/src/events/service_event.dart';
import 'package:fluxon/src/fluxon_service.dart';
import 'package:test/test.dart';

// Mock service types for testing
class TestServiceA extends FluxonService {}

class TestServiceB extends FluxonService {}

class TestServiceC extends FluxonService {}

void main() {
  group('EventDistribution Factory Methods', () {
    group('EventDistribution.targeted()', () {
      test('should create targeted distribution with single target', () {
        final targets = [const EventTarget(serviceType: TestServiceA)];
        final distribution = EventDistribution.targeted(targets);

        expect(
            distribution.strategy, equals(EventDistributionStrategy.targeted));
        expect(distribution.targets, equals(targets));
        expect(distribution.targets, hasLength(1));
        expect(distribution.targets.first.serviceType, equals(TestServiceA));
        expect(distribution.excludeServices, isEmpty);
        expect(distribution.includeSource, isFalse);
        expect(distribution.parallelProcessing, isTrue);
        expect(distribution.globalTimeout, isNull);
      });

      test('should create targeted distribution with multiple targets', () {
        final targets = [
          const EventTarget(
              serviceType: TestServiceA, waitUntilProcessed: true),
          const EventTarget(
              serviceType: TestServiceB, waitUntilProcessed: false),
          const EventTarget(serviceType: TestServiceC, retryCount: 3),
        ];
        final distribution = EventDistribution.targeted(targets);

        expect(
            distribution.strategy, equals(EventDistributionStrategy.targeted));
        expect(distribution.targets, equals(targets));
        expect(distribution.targets, hasLength(3));
        expect(distribution.targets[0].serviceType, equals(TestServiceA));
        expect(distribution.targets[0].waitUntilProcessed, isTrue);
        expect(distribution.targets[1].serviceType, equals(TestServiceB));
        expect(distribution.targets[1].waitUntilProcessed, isFalse);
        expect(distribution.targets[2].serviceType, equals(TestServiceC));
        expect(distribution.targets[2].retryCount, equals(3));
      });

      test('should create targeted distribution with empty targets', () {
        final distribution = EventDistribution.targeted([]);

        expect(
            distribution.strategy, equals(EventDistributionStrategy.targeted));
        expect(distribution.targets, isEmpty);
      });
    });

    group('EventDistribution.broadcast()', () {
      test('should create broadcast distribution with defaults', () {
        final distribution = EventDistribution.broadcast();

        expect(
            distribution.strategy, equals(EventDistributionStrategy.broadcast));
        expect(distribution.targets, isEmpty);
        expect(distribution.excludeServices, isEmpty);
        expect(distribution.includeSource, isFalse);
        expect(distribution.parallelProcessing, isTrue);
        expect(distribution.globalTimeout, isNull);
      });

      test('should create broadcast distribution with excludeServices', () {
        final distribution = EventDistribution.broadcast(
          excludeServices: [TestServiceA, TestServiceB],
        );

        expect(
            distribution.strategy, equals(EventDistributionStrategy.broadcast));
        expect(
            distribution.excludeServices, equals([TestServiceA, TestServiceB]));
        expect(distribution.excludeServices, hasLength(2));
        expect(distribution.includeSource, isFalse);
      });

      test('should create broadcast distribution with includeSource true', () {
        final distribution = EventDistribution.broadcast(includeSource: true);

        expect(
            distribution.strategy, equals(EventDistributionStrategy.broadcast));
        expect(distribution.includeSource, isTrue);
        expect(distribution.excludeServices, isEmpty);
      });

      test('should create broadcast distribution with both parameters', () {
        final distribution = EventDistribution.broadcast(
          excludeServices: [TestServiceC],
          includeSource: true,
        );

        expect(
            distribution.strategy, equals(EventDistributionStrategy.broadcast));
        expect(distribution.excludeServices, equals([TestServiceC]));
        expect(distribution.includeSource, isTrue);
      });

      test('should create broadcast distribution with empty excludeServices',
          () {
        final distribution = EventDistribution.broadcast(excludeServices: []);

        expect(
            distribution.strategy, equals(EventDistributionStrategy.broadcast));
        expect(distribution.excludeServices, isEmpty);
      });
    });

    group('EventDistribution.targetedThenBroadcast()', () {
      test('should create targetedThenBroadcast distribution with defaults',
          () {
        final targets = [const EventTarget(serviceType: TestServiceA)];
        final distribution = EventDistribution.targetedThenBroadcast(targets);

        expect(distribution.strategy,
            equals(EventDistributionStrategy.targetedThenBroadcast));
        expect(distribution.targets, equals(targets));
        expect(distribution.excludeServices, isEmpty);
        expect(distribution.includeSource, isFalse);
        expect(distribution.parallelProcessing, isTrue);
        expect(distribution.globalTimeout, isNull);
      });

      test(
          'should create targetedThenBroadcast distribution with excludeServices',
          () {
        final targets = [const EventTarget(serviceType: TestServiceA)];
        final distribution = EventDistribution.targetedThenBroadcast(
          targets,
          excludeServices: [TestServiceB, TestServiceC],
        );

        expect(distribution.strategy,
            equals(EventDistributionStrategy.targetedThenBroadcast));
        expect(distribution.targets, equals(targets));
        expect(
            distribution.excludeServices, equals([TestServiceB, TestServiceC]));
        expect(distribution.includeSource, isFalse);
      });

      test(
          'should create targetedThenBroadcast distribution with includeSource',
          () {
        final targets = [const EventTarget(serviceType: TestServiceA)];
        final distribution = EventDistribution.targetedThenBroadcast(
          targets,
          includeSource: true,
        );

        expect(distribution.strategy,
            equals(EventDistributionStrategy.targetedThenBroadcast));
        expect(distribution.targets, equals(targets));
        expect(distribution.includeSource, isTrue);
        expect(distribution.excludeServices, isEmpty);
      });

      test(
          'should create targetedThenBroadcast distribution with all parameters',
          () {
        final targets = [
          const EventTarget(
              serviceType: TestServiceA, waitUntilProcessed: true),
          const EventTarget(serviceType: TestServiceB),
        ];
        final distribution = EventDistribution.targetedThenBroadcast(
          targets,
          excludeServices: [TestServiceC],
          includeSource: true,
        );

        expect(distribution.strategy,
            equals(EventDistributionStrategy.targetedThenBroadcast));
        expect(distribution.targets, equals(targets));
        expect(distribution.targets, hasLength(2));
        expect(distribution.excludeServices, equals([TestServiceC]));
        expect(distribution.includeSource, isTrue);
      });

      test(
          'should create targetedThenBroadcast distribution with empty targets',
          () {
        final distribution = EventDistribution.targetedThenBroadcast([]);

        expect(distribution.strategy,
            equals(EventDistributionStrategy.targetedThenBroadcast));
        expect(distribution.targets, isEmpty);
        expect(distribution.excludeServices, isEmpty);
        expect(distribution.includeSource, isFalse);
      });

      test(
          'should create targetedThenBroadcast distribution with empty excludeServices',
          () {
        final targets = [const EventTarget(serviceType: TestServiceA)];
        final distribution = EventDistribution.targetedThenBroadcast(
          targets,
          excludeServices: [],
        );

        expect(distribution.strategy,
            equals(EventDistributionStrategy.targetedThenBroadcast));
        expect(distribution.targets, equals(targets));
        expect(distribution.excludeServices, isEmpty);
      });
    });

    group('Manual Constructor', () {
      test('should create distribution with all parameters', () {
        const distribution = EventDistribution(
          targets: [EventTarget(serviceType: TestServiceA)],
          strategy: EventDistributionStrategy.broadcastExcept,
          excludeServices: [TestServiceB],
          includeSource: true,
          parallelProcessing: false,
          globalTimeout: Duration(seconds: 30),
        );

        expect(distribution.strategy,
            equals(EventDistributionStrategy.broadcastExcept));
        expect(distribution.targets, hasLength(1));
        expect(distribution.targets.first.serviceType, equals(TestServiceA));
        expect(distribution.excludeServices, equals([TestServiceB]));
        expect(distribution.includeSource, isTrue);
        expect(distribution.parallelProcessing, isFalse);
        expect(distribution.globalTimeout, equals(const Duration(seconds: 30)));
      });

      test('should create distribution with minimal parameters', () {
        const distribution = EventDistribution();

        expect(
            distribution.strategy, equals(EventDistributionStrategy.targeted));
        expect(distribution.targets, isEmpty);
        expect(distribution.excludeServices, isEmpty);
        expect(distribution.includeSource, isFalse);
        expect(distribution.parallelProcessing, isTrue);
        expect(distribution.globalTimeout, isNull);
      });

      test('should create broadcastExcept distribution manually', () {
        const distribution = EventDistribution(
          strategy: EventDistributionStrategy.broadcastExcept,
          excludeServices: [TestServiceA, TestServiceB],
        );

        expect(distribution.strategy,
            equals(EventDistributionStrategy.broadcastExcept));
        expect(
            distribution.excludeServices, equals([TestServiceA, TestServiceB]));
        expect(distribution.targets, isEmpty);
        expect(distribution.includeSource, isFalse);
      });
    });

    group('toString() Method', () {
      test('should provide meaningful string representation', () {
        final targets = [
          const EventTarget(serviceType: TestServiceA),
          const EventTarget(serviceType: TestServiceB),
        ];
        final distribution = EventDistribution.targeted(targets);

        final stringRep = distribution.toString();

        expect(stringRep, contains('EventDistribution'));
        expect(stringRep,
            contains('strategy: EventDistributionStrategy.targeted'));
        expect(stringRep, contains('targets: 2'));
        expect(stringRep, contains('excludes: 0'));
      });

      test('should show correct counts in string representation', () {
        final distribution = EventDistribution.broadcast(
          excludeServices: [TestServiceA, TestServiceB, TestServiceC],
        );

        final stringRep = distribution.toString();

        expect(stringRep,
            contains('strategy: EventDistributionStrategy.broadcast'));
        expect(stringRep, contains('targets: 0'));
        expect(stringRep, contains('excludes: 3'));
      });
    });

    group('Factory Method Consistency', () {
      test('targeted factory should match manual constructor', () {
        final targets = [const EventTarget(serviceType: TestServiceA)];

        final factory = EventDistribution.targeted(targets);
        const manual = EventDistribution(
          targets: [EventTarget(serviceType: TestServiceA)],
          strategy: EventDistributionStrategy.targeted,
        );

        expect(factory.strategy, equals(manual.strategy));
        expect(factory.targets.length, equals(manual.targets.length));
        expect(factory.targets.first.serviceType,
            equals(manual.targets.first.serviceType));
        expect(factory.excludeServices, equals(manual.excludeServices));
        expect(factory.includeSource, equals(manual.includeSource));
        expect(factory.parallelProcessing, equals(manual.parallelProcessing));
      });

      test('broadcast factory should match manual constructor', () {
        final factory = EventDistribution.broadcast(
          excludeServices: [TestServiceA],
          includeSource: true,
        );
        const manual = EventDistribution(
          strategy: EventDistributionStrategy.broadcast,
          excludeServices: [TestServiceA],
          includeSource: true,
        );

        expect(factory.strategy, equals(manual.strategy));
        expect(factory.excludeServices, equals(manual.excludeServices));
        expect(factory.includeSource, equals(manual.includeSource));
        expect(factory.targets, equals(manual.targets));
        expect(factory.parallelProcessing, equals(manual.parallelProcessing));
      });

      test('targetedThenBroadcast factory should match manual constructor', () {
        final targets = [const EventTarget(serviceType: TestServiceA)];
        final factory = EventDistribution.targetedThenBroadcast(
          targets,
          excludeServices: [TestServiceB],
          includeSource: true,
        );
        const manual = EventDistribution(
          targets: [EventTarget(serviceType: TestServiceA)],
          strategy: EventDistributionStrategy.targetedThenBroadcast,
          excludeServices: [TestServiceB],
          includeSource: true,
        );

        expect(factory.strategy, equals(manual.strategy));
        expect(factory.targets.length, equals(manual.targets.length));
        expect(factory.excludeServices, equals(manual.excludeServices));
        expect(factory.includeSource, equals(manual.includeSource));
        expect(factory.parallelProcessing, equals(manual.parallelProcessing));
      });
    });
  });
}

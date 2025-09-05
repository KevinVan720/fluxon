import 'package:flux/src/models/service_models.dart';
import 'package:flux/src/service_logger.dart';
import 'package:test/test.dart';

void main() {
  group('ServiceLogger', () {
    late MemoryLogWriter memoryWriter;
    late ServiceLogger logger;

    setUp(() {
      memoryWriter = MemoryLogWriter();
      logger = ServiceLogger(
        serviceName: 'TestService',
        writer: memoryWriter,
      );
    });

    test('should log messages with correct format', () {
      logger.info('Test message');

      expect(memoryWriter.entries, hasLength(1));
      final entry = memoryWriter.entries.first;
      expect(entry.serviceName, equals('TestService'));
      expect(entry.message, equals('Test message'));
      expect(entry.level, equals(ServiceLogLevel.info));
    });

    test('should respect log level filtering', () {
      logger.level = ServiceLogLevel.warning;

      logger.debug('Debug message');
      logger.info('Info message');
      logger.warning('Warning message');
      logger.error('Error message');

      expect(memoryWriter.entries, hasLength(2));
      expect(memoryWriter.entries[0].level, equals(ServiceLogLevel.warning));
      expect(memoryWriter.entries[1].level, equals(ServiceLogLevel.error));
    });

    test('should include metadata in log entries', () {
      logger.setMetadata({'userId': '123', 'sessionId': 'abc'});
      logger.info('Test message', metadata: {'requestId': '456'});

      final entry = memoryWriter.entries.first;
      expect(entry.metadata['userId'], equals('123'));
      expect(entry.metadata['sessionId'], equals('abc'));
      expect(entry.metadata['requestId'], equals('456'));
    });

    test('should create child loggers with inherited metadata', () {
      logger.setMetadata({'userId': '123'});
      final childLogger = logger.child({'requestId': '456'});

      childLogger.info('Child message');

      final entry = memoryWriter.entries.first;
      expect(entry.metadata['userId'], equals('123'));
      expect(entry.metadata['requestId'], equals('456'));
    });

    test('should log errors with stack traces', () {
      final error = Exception('Test error');
      final stackTrace = StackTrace.current;

      logger.error('Error occurred', error: error, stackTrace: stackTrace);

      final entry = memoryWriter.entries.first;
      expect(entry.metadata['error'], contains('Test error'));
      expect(entry.metadata['stackTrace'], isNotNull);
    });

    test('should measure execution time', () async {
      final result = await logger.timeAsync('test operation', () async {
        await Future.delayed(const Duration(milliseconds: 10));
        return 'result';
      });

      expect(result, equals('result'));
      expect(memoryWriter.entries, hasLength(1));

      final entry = memoryWriter.entries.first;
      expect(entry.message, contains('Operation completed: test operation'));
      expect(entry.metadata['operation'], equals('test operation'));
      expect(entry.metadata['duration_ms'], greaterThan(0));
    });

    test('should handle timed operation failures', () async {
      final error = Exception('Test error');

      try {
        await logger.timeAsync('failing operation', () async {
          throw error;
        });
      } catch (e) {
        expect(e, equals(error));
      }

      expect(memoryWriter.entries, hasLength(1));
      final entry = memoryWriter.entries.first;
      expect(entry.level, equals(ServiceLogLevel.error));
      expect(entry.message, contains('Operation failed: failing operation'));
    });
  });

  group('MemoryLogWriter', () {
    test('should store log entries in memory', () {
      final writer = MemoryLogWriter(maxEntries: 3);

      for (var i = 0; i < 5; i++) {
        writer.write(ServiceLogEntry(
          timestamp: DateTime.now(),
          level: ServiceLogLevel.info,
          serviceName: 'Test',
          message: 'Message $i',
          metadata: const {},
        ));
      }

      expect(writer.entries, hasLength(3));
      expect(writer.entries.first.message, equals('Message 2'));
      expect(writer.entries.last.message, equals('Message 4'));
    });

    test('should filter entries by criteria', () {
      final writer = MemoryLogWriter();
      final now = DateTime.now();

      writer.write(ServiceLogEntry(
        timestamp: now.subtract(const Duration(hours: 2)),
        level: ServiceLogLevel.debug,
        serviceName: 'ServiceA',
        message: 'Old debug message',
        metadata: const {},
      ));

      writer.write(ServiceLogEntry(
        timestamp: now,
        level: ServiceLogLevel.error,
        serviceName: 'ServiceB',
        message: 'Recent error message',
        metadata: const {},
      ));

      final filtered = writer.getEntries(
        minLevel: ServiceLogLevel.warning,
        since: now.subtract(const Duration(hours: 1)),
      );

      expect(filtered, hasLength(1));
      expect(filtered.first.message, equals('Recent error message'));
    });
  });

  group('FilteredLogWriter', () {
    test('should filter by log level', () {
      final memoryWriter = MemoryLogWriter();
      final filteredWriter = FilteredLogWriter(
        writer: memoryWriter,
        minLevel: ServiceLogLevel.warning,
      );

      filteredWriter.write(ServiceLogEntry(
        timestamp: DateTime.now(),
        level: ServiceLogLevel.debug,
        serviceName: 'Test',
        message: 'Debug message',
        metadata: const {},
      ));

      filteredWriter.write(ServiceLogEntry(
        timestamp: DateTime.now(),
        level: ServiceLogLevel.error,
        serviceName: 'Test',
        message: 'Error message',
        metadata: const {},
      ));

      expect(memoryWriter.entries, hasLength(1));
      expect(memoryWriter.entries.first.message, equals('Error message'));
    });

    test('should filter by service name pattern', () {
      final memoryWriter = MemoryLogWriter();
      final filteredWriter = FilteredLogWriter(
        writer: memoryWriter,
        serviceNameFilter: 'Service[AB]',
      );

      filteredWriter.write(ServiceLogEntry(
        timestamp: DateTime.now(),
        level: ServiceLogLevel.info,
        serviceName: 'ServiceA',
        message: 'Message A',
        metadata: const {},
      ));

      filteredWriter.write(ServiceLogEntry(
        timestamp: DateTime.now(),
        level: ServiceLogLevel.info,
        serviceName: 'ServiceC',
        message: 'Message C',
        metadata: const {},
      ));

      expect(memoryWriter.entries, hasLength(1));
      expect(memoryWriter.entries.first.message, equals('Message A'));
    });
  });

  group('MultiLogWriter', () {
    test('should write to multiple writers', () {
      final writer1 = MemoryLogWriter();
      final writer2 = MemoryLogWriter();
      final multiWriter = MultiLogWriter([writer1, writer2]);

      final entry = ServiceLogEntry(
        timestamp: DateTime.now(),
        level: ServiceLogLevel.info,
        serviceName: 'Test',
        message: 'Test message',
        metadata: const {},
      );

      multiWriter.write(entry);

      expect(writer1.entries, hasLength(1));
      expect(writer2.entries, hasLength(1));
      expect(writer1.entries.first.message, equals('Test message'));
      expect(writer2.entries.first.message, equals('Test message'));
    });
  });
}

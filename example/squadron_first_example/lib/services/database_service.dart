/// Squadron-first database service with automatic worker management
library database_service;

import 'dart:async';
import 'package:dart_service_framework/dart_service_framework.dart';

/// Database service that runs as a Squadron worker
@SquadronService()
class DatabaseService extends SquadronService with SquadronServiceHandler {
  DatabaseService() : super(serviceName: 'DatabaseService');

  // Simulated database storage
  final Map<String, Map<String, dynamic>> _data = {};
  int _nextId = 1;

  @override
  List<Type> get dependencies => const [];

  @override
  Future<void> initialize() async {
    await super.initialize();
    
    // Initialize with some sample data
    _data['users'] = {
      '1': {'id': '1', 'name': 'John Doe', 'email': 'john@example.com'},
      '2': {'id': '2', 'name': 'Jane Smith', 'email': 'jane@example.com'},
    };
    _nextId = 3;

    logger.info('Database service initialized with sample data');
  }

  /// Create a new record
  @ServiceMethod(description: 'Create a new record in the specified table')
  Future<Map<String, dynamic>> create(String table, Map<String, dynamic> data) async {
    logger.debug('Creating record in table $table', metadata: data);

    final id = _nextId.toString();
    _nextId++;

    final record = {'id': id, ...data};
    
    if (!_data.containsKey(table)) {
      _data[table] = {};
    }
    
    _data[table]![id] = record;

    logger.info('Record created', metadata: {
      'table': table,
      'id': id,
    });

    return record;
  }

  /// Find a record by ID
  @ServiceMethod(description: 'Find a record by ID')
  Future<Map<String, dynamic>?> findById(String table, String id) async {
    logger.debug('Finding record by ID', metadata: {
      'table': table,
      'id': id,
    });

    final tableData = _data[table];
    if (tableData == null) {
      logger.debug('Table not found', metadata: {'table': table});
      return null;
    }

    final record = tableData[id];
    logger.debug('Record lookup result', metadata: {
      'table': table,
      'id': id,
      'found': record != null,
    });

    return record;
  }

  /// Find records by criteria
  @ServiceMethod(description: 'Find records matching criteria')
  Future<List<Map<String, dynamic>>> findWhere(
    String table, 
    Map<String, dynamic> criteria,
  ) async {
    logger.debug('Finding records with criteria', metadata: {
      'table': table,
      'criteria': criteria,
    });

    final tableData = _data[table];
    if (tableData == null) {
      return [];
    }

    final results = <Map<String, dynamic>>[];
    
    for (final record in tableData.values) {
      bool matches = true;
      
      for (final entry in criteria.entries) {
        if (record[entry.key] != entry.value) {
          matches = false;
          break;
        }
      }
      
      if (matches) {
        results.add(Map<String, dynamic>.from(record));
      }
    }

    logger.debug('Query completed', metadata: {
      'table': table,
      'results': results.length,
    });

    return results;
  }

  /// Update a record
  @ServiceMethod(description: 'Update a record by ID')
  Future<Map<String, dynamic>?> update(
    String table, 
    String id, 
    Map<String, dynamic> updates,
  ) async {
    logger.debug('Updating record', metadata: {
      'table': table,
      'id': id,
      'updates': updates.keys.toList(),
    });

    final tableData = _data[table];
    if (tableData == null) {
      return null;
    }

    final record = tableData[id];
    if (record == null) {
      return null;
    }

    // Apply updates
    record.addAll(updates);

    logger.info('Record updated', metadata: {
      'table': table,
      'id': id,
    });

    return Map<String, dynamic>.from(record);
  }

  /// Delete a record
  @ServiceMethod(description: 'Delete a record by ID')
  Future<bool> delete(String table, String id) async {
    logger.debug('Deleting record', metadata: {
      'table': table,
      'id': id,
    });

    final tableData = _data[table];
    if (tableData == null) {
      return false;
    }

    final removed = tableData.remove(id);
    final success = removed != null;

    logger.info('Record deletion result', metadata: {
      'table': table,
      'id': id,
      'success': success,
    });

    return success;
  }

  /// Get table statistics
  @ServiceMethod(description: 'Get statistics for a table')
  Future<Map<String, dynamic>> getTableStats(String table) async {
    final tableData = _data[table];
    
    return {
      'table': table,
      'recordCount': tableData?.length ?? 0,
      'exists': tableData != null,
    };
  }

  /// Get all table names
  @ServiceProperty(description: 'List of all table names')
  Future<List<String>> get tableNames async {
    return _data.keys.toList();
  }

  @override
  Future<dynamic> handleWorkerRequest(WorkerRequest request) async {
    switch (request.name) {
      case 'create':
        return await create(request.args[0], request.args[1]);
      case 'findById':
        return await findById(request.args[0], request.args[1]);
      case 'findWhere':
        return await findWhere(request.args[0], request.args[1]);
      case 'update':
        return await update(request.args[0], request.args[1], request.args[2]);
      case 'delete':
        return await delete(request.args[0], request.args[1]);
      case 'getTableStats':
        return await getTableStats(request.args[0]);
      case 'tableNames':
        return await tableNames;
      case 'healthCheck':
        return (await healthCheck()).toJson();
      default:
        return await super.handleWorkerRequest(request);
    }
  }
}

/// Entry point for the DatabaseService Squadron worker
/// This function is embedded in the compiled binary and can be referenced directly
void databaseServiceEntryPoint(SendPort sendPort) async {
  final receivePort = ReceivePort();
  sendPort.send(receivePort.sendPort);

  DatabaseService? service;
  final logger = ServiceLogger(serviceName: 'DatabaseServiceWorker');

  try {
    // Initialize the service
    service = DatabaseService();
    await service.initialize();
    
    logger.info('DatabaseService worker started');

    await for (final message in receivePort) {
      try {
        if (message is Map<String, dynamic>) {
          final request = WorkerRequest.fromJson(message);
          final result = await service.handleWorkerRequest(request);
          sendPort.send({'success': true, 'result': result});
        } else {
          sendPort.send({'success': false, 'error': 'Invalid message format'});
        }
      } catch (error, stackTrace) {
        logger.error('Worker request failed', error: error, stackTrace: stackTrace);
        sendPort.send({'success': false, 'error': error.toString()});
      }
    }
  } catch (error, stackTrace) {
    logger.error('DatabaseService worker failed to start', error: error, stackTrace: stackTrace);
    sendPort.send({'success': false, 'error': error.toString()});
  } finally {
    if (service != null) {
      try {
        await service.destroy();
      } catch (error) {
        logger.error('DatabaseService cleanup failed', error: error);
      }
    }
  }
}
library dispatcher_registry;

import '../base_service.dart';

typedef ServiceDispatcher = Future<dynamic> Function(
  BaseService service,
  int methodId,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
);

class GeneratedDispatcherRegistry {
  static final List<_DispatcherEntry> _entries = [];

  static void register<T extends BaseService>(ServiceDispatcher dispatcher) {
    _entries.add(_DispatcherEntry((s) => s is T, dispatcher));
  }

  static ServiceDispatcher? findDispatcherForObject(BaseService service) {
    for (final entry in _entries) {
      if (entry.matches(service)) return entry.dispatcher;
    }
    return null;
  }
}

class _DispatcherEntry {
  _DispatcherEntry(this._predicate, this.dispatcher);
  final bool Function(BaseService) _predicate;
  final ServiceDispatcher dispatcher;
  bool matches(BaseService s) => _predicate(s);
}

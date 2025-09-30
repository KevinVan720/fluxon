import 'package:fluxon/fluxon.dart';
import 'package:test/test.dart';

part 'generic_method_test.g.dart';

@ServiceContract(remote: true)
class GenericSvc extends FluxonService {
  Future<T> echo<T extends Object>(T value) async => value;
  Future<List<T>> listify<T>(T value) async => [value];
  Future<Map<String, T>> mapify<T>(String key, T value) async => {key: value};
  final List<dynamic> _stash = [];

  Future<void> remember<T>(T value) async {
    _stash.add(value);
  }

  Future<List<dynamic>> dumpStash() async => List<dynamic>.from(_stash);
}

@ServiceContract(remote: false)
class GenericCaller extends FluxonService {
  @override
  List<Type> get optionalDependencies => [GenericSvc];

  Future<(int, String)> run() async {
    final s = getService<GenericSvc>();
    final i = await s.echo<int>(42);
    final s1 = await s.echo<String>('ok');
    final l = await s.listify<dynamic>('v');
    expect(l, isA<List>());
    final typedList = List<String>.from(l as List);
    return (i, s1 + typedList.first);
  }
}

void main() {
  group('Generic method codegen', () {
    test('supports method type parameters with bounds', () async {
      final rt = FluxonRuntime();
      rt.register<GenericSvc>(GenericSvcImpl.new);
      rt.register<GenericCaller>(GenericCaller.new);
      await rt.initializeAll();
      final caller = rt.get<GenericCaller>();
      final res = await caller.run();
      expect(res.$1, 42);
      expect(res.$2, 'okv');
      await rt.destroyAll();
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('supports generic map results and void return', () async {
      final rt = FluxonRuntime();
      rt.register<GenericSvc>(GenericSvcImpl.new);
      rt.register<GenericCaller>(GenericCaller.new);
      await rt.initializeAll();

      final svc = rt.get<GenericSvc>();
      final stringMap = await svc.mapify<dynamic>('answer', '42');
      expect(stringMap, isA<Map>());
      final castStringMap = Map<String, String>.from(stringMap as Map);
      expect(castStringMap, isA<Map<String, String>>());
      expect(castStringMap['answer'], '42');

      final intMap = await svc.mapify<dynamic>('value', 7);
      expect(intMap, isA<Map>());
      final castIntMap = Map<String, int>.from(intMap as Map);
      expect(castIntMap, isA<Map<String, int>>());
      expect(castIntMap['value'], 7);

      await svc.remember<int>(7);
      await svc.remember<String>('seven');
      final stash = await svc.dumpStash();
      expect(stash, equals([7, 'seven']));

      await rt.destroyAll();
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}

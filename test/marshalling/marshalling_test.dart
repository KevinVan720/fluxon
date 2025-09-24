import 'package:fluxon/fluxon.dart';
import 'package:test/test.dart';

part 'marshalling_test.g.dart';

/// Custom data class to test marshalling
class CustomData {
  const CustomData({
    required this.id,
    required this.name,
    required this.value,
  });

  final int id;
  final String name;
  final double value;

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'value': value,
      };

  /// Create from JSON
  static CustomData fromJson(Map<String, dynamic> json) => CustomData(
        id: json['id'] as int,
        name: json['name'] as String,
        value: json['value'] as double,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CustomData &&
        other.id == id &&
        other.name == name &&
        other.value == value;
  }

  @override
  int get hashCode => Object.hash(id, name, value);

  @override
  String toString() => 'CustomData(id: $id, name: $name, value: $value)';
}

/// Service that handles custom objects
@ServiceContract(remote: true)
class MarshallingTestService extends FluxonService {
  /// Process a custom data object
  Future<CustomData> processData(CustomData input) async {
    // Transform the data
    return CustomData(
      id: input.id + 1,
      name: '${input.name}_processed',
      value: input.value * 2,
    );
  }

  /// Process a list of custom objects
  Future<List<CustomData>> processDataList(List<CustomData> inputs) async {
    return inputs
        .map((data) => CustomData(
              id: data.id + 100,
              name: '${data.name}_batch',
              value: data.value + 10,
            ))
        .toList();
  }

  /// Return complex nested data
  Future<Map<String, List<CustomData>>> getNestedData(String key) async {
    return {
      key: [
        CustomData(id: 1, name: 'nested1', value: 1.1),
        CustomData(id: 2, name: 'nested2', value: 2.2),
      ],
      '${key}_extra': [
        CustomData(id: 3, name: 'extra1', value: 3.3),
      ],
    };
  }
}

void main() {
  group('Object Marshalling Tests', () {
    late FluxonRuntime runtime;

    setUp(() {
      runtime = FluxonRuntime();
    });

    tearDown(() async {
      await runtime.destroyAll();
    });

    test('should marshall and unmarshall custom objects', () async {
      runtime.register<MarshallingTestService>(MarshallingTestServiceImpl.new);
      await runtime.initializeAll();

      final service = runtime.get<MarshallingTestService>();
      final input = CustomData(id: 1, name: 'test', value: 42.0);

      final result = await service.processData(input);

      expect(result.id, equals(2));
      expect(result.name, equals('test_processed'));
      expect(result.value, equals(84.0));
    });

    test('should marshall and unmarshall lists of custom objects', () async {
      runtime.register<MarshallingTestService>(MarshallingTestServiceImpl.new);
      await runtime.initializeAll();

      final service = runtime.get<MarshallingTestService>();
      final inputs = [
        CustomData(id: 1, name: 'first', value: 10.0),
        CustomData(id: 2, name: 'second', value: 20.0),
      ];

      final results = await service.processDataList(inputs);

      expect(results, hasLength(2));
      expect(results[0].id, equals(101));
      expect(results[0].name, equals('first_batch'));
      expect(results[0].value, equals(20.0));
      expect(results[1].id, equals(102));
      expect(results[1].name, equals('second_batch'));
      expect(results[1].value, equals(30.0));
    });

    test('should marshall and unmarshall nested complex structures', () async {
      runtime.register<MarshallingTestService>(MarshallingTestServiceImpl.new);
      await runtime.initializeAll();

      final service = runtime.get<MarshallingTestService>();
      final result = await service.getNestedData('test');

      expect(result.keys, contains('test'));
      expect(result.keys, contains('test_extra'));
      expect(result['test'], hasLength(2));
      expect(result['test_extra'], hasLength(1));
      expect(result['test']![0].name, equals('nested1'));
      expect(result['test_extra']![0].value, equals(3.3));
    });
  });
}

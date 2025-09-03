import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

// Note: we'll detect @ServiceContract by name to avoid a hard dependency loop.
final _serviceContractChecker = const TypeChecker.fromUrl(
  'package:dart_service_framework/src/annotations/service_annotations.dart#ServiceContract',
);

class ServiceGenerator extends GeneratorForAnnotation<Object> {
  @override
  FutureOr<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement) return '';
    if (!_serviceContractChecker.hasAnnotationOf(element)) return '';

    final classEl = element as ClassElement;
    final className = classEl.name;

    final buf = StringBuffer();
    // NOTE: This content is emitted into a shared part (.g.dart) by
    // SharedPartBuilder. Do not include library/import/part directives here.
    // The surrounding part file provides the library context.
    buf.writeln('// Service client for $className');
    final clientName = '${className}Client';
    buf.writeln('class $clientName extends $className {');
    buf.writeln('  $clientName(this._proxy);');
    buf.writeln('  final ServiceProxy<$className> _proxy;');
    buf.writeln('');

    var nextId = 1;
    final methodIds = <String, int>{};
    for (final m in classEl.methods.where((m) => m.isAbstract && !m.isStatic)) {
      if (m.returnType is! InterfaceType && !m.returnType.isDartAsyncFuture) {
        // Only generate for Future-returning methods in MVP
        continue;
      }
      final methodName = m.displayName;
      methodIds[methodName] = nextId++;
      final returnType = m.returnType.getDisplayString(withNullability: true);
      final paramsSig = m.parameters.map((p) {
        final t = p.type.getDisplayString(withNullability: true);
        return '$t ${p.name}';
      }).join(', ');
      final argsList = m.parameters.map((p) => p.name).join(', ');
      buf.writeln('  @override');
      buf.writeln('  $returnType $methodName($paramsSig) async {');
      buf.writeln(
          "    return await _proxy.callMethod('$methodName', [$argsList]);");
      buf.writeln('  }');
      buf.writeln('');
    }

    buf.writeln('}');
    buf.writeln('');
    buf.writeln('void _register${className}ClientFactory() {');
    buf.writeln('  GeneratedClientRegistry.register<$className>(');
    buf.writeln('    (proxy) => $clientName(proxy),');
    buf.writeln('  );');
    buf.writeln('}');
    buf.writeln('');
    // Dispatcher & method IDs
    buf.writeln('class _${className}Methods {');
    methodIds.forEach((name, id) {
      buf.writeln('  static const int ${name}Id = $id;');
    });
    buf.writeln('}');
    buf.writeln('');
    buf.writeln('Future<dynamic> _${className}Dispatcher(');
    buf.writeln('  BaseService service,');
    buf.writeln('  int methodId,');
    buf.writeln('  List<dynamic> args,');
    buf.writeln(') async {');
    buf.writeln('  final s = service as $className;');
    buf.writeln('  switch (methodId) {');
    for (final entry in methodIds.entries) {
      final method =
          classEl.methods.firstWhere((m) => m.displayName == entry.key);
      final argList = method.parameters
          .asMap()
          .entries
          .map((e) => 'args[${e.key}]')
          .join(', ');
      buf.writeln('    case _${className}Methods.${entry.key}Id:');
      buf.writeln('      return await s.${entry.key}($argList);');
    }
    buf.writeln('    default:');
    buf.writeln(
        "      throw ServiceException('Unknown method id: \$methodId');");
    buf.writeln('  }');
    buf.writeln('}');
    buf.writeln('');
    buf.writeln('void _register${className}Dispatcher() {');
    buf.writeln('  GeneratedDispatcherRegistry.register<$className>(');
    buf.writeln('    _${className}Dispatcher,');
    buf.writeln('  );');
    buf.writeln('}');
    buf.writeln('');
    // Register method IDs for client-side lookup
    buf.writeln('void _register${className}MethodIds() {');
    buf.writeln('  ServiceMethodIdRegistry.register<$className>({');
    for (final entry in methodIds.entries) {
      buf.writeln("    '${entry.key}': _${className}Methods.${entry.key}Id,");
    }
    buf.writeln('  });');
    buf.writeln('}');
    buf.writeln('');
    // Public registrar for host-side (client + method IDs)
    buf.writeln('void register${className}Generated() {');
    buf.writeln('  _register${className}ClientFactory();');
    buf.writeln('  _register${className}MethodIds();');
    buf.writeln('}');
    return buf.toString();
  }
}

Builder serviceBuilder(BuilderOptions options) =>
    SharedPartBuilder([ServiceGenerator()], 'service_generator');

class _PlaceholderGenerator extends Generator {}

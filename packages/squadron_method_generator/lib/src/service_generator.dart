import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

// Note: we'll detect @ServiceContract by name to avoid a hard dependency loop.
final _serviceContractChecker = const TypeChecker.fromUrl(
  'package:dart_service_framework/src/annotations/service_annotations.dart#ServiceContract',
);

final _serviceMethodChecker = const TypeChecker.fromUrl(
  'package:dart_service_framework/src/annotations/service_annotations.dart#ServiceMethod',
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
    final isRemote = annotation.peek('remote')?.boolValue ?? false;

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
    // 🚀 SINGLE CLASS: Generate for both abstract AND concrete methods
    // Exclude inherited methods from BaseService/FluxService
    final inheritedMethods = {
      'initialize',
      'destroy',
      'onDependencyAvailable',
      'onDependencyUnavailable'
    };
    for (final m in classEl.methods.where((m) =>
            !m.isStatic &&
            !m.isPrivate &&
            !m.isOperator &&
            !inheritedMethods.contains(m.name) &&
            m.enclosingElement == classEl // Only methods declared in this class
        )) {
      if (m.returnType is! InterfaceType && !m.returnType.isDartAsyncFuture) {
        // Only generate for Future-returning methods in MVP
        continue;
      }
      final methodName = m.displayName;
      methodIds[methodName] = nextId++;
      final returnType = m.returnType.getDisplayString(withNullability: true);
      // Separate positional and named parameters
      final positionalParams =
          m.parameters.where((p) => p.isPositional).toList();
      final namedParams = m.parameters.where((p) => p.isNamed).toList();

      final positionalSig = positionalParams.map((p) {
        final t = p.type.getDisplayString(withNullability: true);
        return '$t ${p.name}';
      }).join(', ');

      final namedSig = namedParams.map((p) {
        final t = p.type.getDisplayString(withNullability: true);
        final isRequiredNamed = p.isRequiredNamed;
        final defaultValue =
            p.hasDefaultValue ? ' = ${p.defaultValueCode}' : '';
        return isRequiredNamed
            ? 'required $t ${p.name}'
            : '$t ${p.name}$defaultValue';
      }).join(', ');

      final paramsSig = [
        if (positionalSig.isNotEmpty) positionalSig,
        if (namedSig.isNotEmpty) '{$namedSig}',
      ].join(', ');
      final positionalNames =
          m.parameters.where((p) => p.isPositional).map((p) => p.name).toList();
      final namedNames = m.parameters
          .where((p) => p.isNamed)
          .map((p) => "'${p.name}': ${p.name}")
          .join(', ');
      // Build optional ServiceCallOptions from @ServiceMethod annotation
      final methodAnno = _serviceMethodChecker.firstAnnotationOf(m);
      String optionsArg = '';
      if (methodAnno != null) {
        final reader = ConstantReader(methodAnno);
        final timeoutMs = reader.peek('timeoutMs')?.intValue;
        final retryAttempts = reader.peek('retryAttempts')?.intValue;
        final retryDelayMs = reader.peek('retryDelayMs')?.intValue;
        final opts = <String>[];
        if (timeoutMs != null) {
          opts.add('timeout: Duration(milliseconds: $timeoutMs)');
        }
        if (retryAttempts != null) {
          opts.add('retryAttempts: $retryAttempts');
        }
        if (retryDelayMs != null) {
          opts.add('retryDelay: Duration(milliseconds: $retryDelayMs)');
        }
        if (opts.isNotEmpty) {
          optionsArg =
              ', options: const ServiceCallOptions(${opts.join(', ')})';
        }
      }

      buf.writeln('  @override');
      buf.writeln('  $returnType $methodName($paramsSig) async {');
      buf.writeln(
          "    return await _proxy.callMethod('$methodName', [${positionalNames.join(', ')}], namedArgs: {${namedNames}}$optionsArg);");
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
    buf.writeln('  List<dynamic> positionalArgs,');
    buf.writeln('  Map<String, dynamic> namedArgs,');
    buf.writeln(') async {');
    buf.writeln('  final s = service as $className;');
    buf.writeln('  switch (methodId) {');
    for (final entry in methodIds.entries) {
      final method =
          classEl.methods.firstWhere((m) => m.displayName == entry.key);
      final argList = () {
        final parts = <String>[];
        var positionalIndex = 0;
        for (final p in method.parameters) {
          if (p.isPositional) {
            parts.add('positionalArgs[' + (positionalIndex++).toString() + ']');
          } else if (p.isNamed) {
            parts.add("${p.name}: namedArgs['${p.name}']");
          }
        }
        return parts.join(', ');
      }();
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
    buf.writeln('');

    // Generate a worker-side concrete class that auto-registers the dispatcher.
    // Consumers should use <ClassName>Worker as the serviceFactory for remote services.
    if (isRemote && !classEl.isAbstract) {
      buf.writeln(
          '// Worker implementation that auto-registers the dispatcher');
      buf.writeln('class ${className}Worker extends $className {');
      buf.writeln('  @override');
      buf.writeln('  Type get clientBaseType => $className;');
      buf.writeln('  @override');
      buf.writeln('  Future<void> registerHostSide() async {');
      buf.writeln('    _register${className}ClientFactory();');
      buf.writeln('    _register${className}MethodIds();');
      buf.writeln('  }');
      buf.writeln('  @override');
      buf.writeln('  Future<void> initialize() async {');
      buf.writeln('    _register${className}Dispatcher();');
      buf.writeln('    await super.initialize();');
      buf.writeln('  }');
      buf.writeln('}');
      buf.writeln('');
    }

    // 🚀 SINGLE CALL: Generate mixin with one method to rule them all!
    buf.writeln('// 🚀 FLUX: Single registration call mixin');
    buf.writeln('mixin ${className}Registration {');
    buf.writeln('  void registerService() {');
    buf.writeln('    _register${className}Dispatcher();');
    // Note: client factory registrations remain manual for now.
    buf.writeln('  }');
    buf.writeln('}');
    return buf.toString();
  }

  /// Extract dependency types from optionalDependencies/dependencies getters
  List<String> _extractDependencyTypes(ClassElement classEl) {
    final dependencies = <String>[];

    for (final method in classEl.methods) {
      if (method.name == 'optionalDependencies' ||
          method.name == 'dependencies') {
        // Try to extract the return type which should be List<Type>
        final returnType = method.returnType;
        if (returnType.isDartCoreList) {
          // For now, we'll use a simplified approach
          // In a full implementation, we'd parse the method body or type annotations
          // This is a placeholder that can be enhanced

          // Look for Type literals in the method body (if available)
          // For MVP, we'll return empty list and require manual specification
          break;
        }
      }
    }

    return dependencies; // Empty for now - can be enhanced to parse actual dependencies
  }
}

Builder serviceBuilder(BuilderOptions options) =>
    SharedPartBuilder([ServiceGenerator()], 'service_generator');

class _PlaceholderGenerator extends Generator {}

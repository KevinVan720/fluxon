import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

// Note: we'll detect @ServiceContract by name to avoid a hard dependency loop.
const _serviceContractChecker = TypeChecker.fromUrl(
  'package:fluxon/src/annotations/service_annotations.dart#ServiceContract',
);

const _serviceMethodChecker = TypeChecker.fromUrl(
  'package:fluxon/src/annotations/service_annotations.dart#ServiceMethod',
);

class ServiceGenerator extends GeneratorForAnnotation<Object> {
  @override
  FutureOr<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    if (element is! ClassElement) return '';
    if (!_serviceContractChecker.hasAnnotationOf(element)) return '';

    final classEl = element;
    final className = classEl.name;
    final isRemote = annotation.peek('remote')?.boolValue ?? false;

    final buf = StringBuffer();

    // Discover declared dependency type names by scanning source text.
    final sourceText = await buildStep.readAsString(buildStep.inputId);
    final depTypeNames = _extractDependencyTypeNamesFromSource(
      sourceText,
      className,
    );
    // NOTE: This content is emitted into a shared part (.g.dart) by
    // SharedPartBuilder. Do not include library/import/part directives here.
    // The surrounding part file provides the library context.
    buf.writeln('// Service client for $className');
    final clientName = '${className}Client';
    buf.writeln('class $clientName extends $className {');
    buf.writeln('  $clientName(this._proxy);');
    buf.writeln('  final ServiceProxy<$className> _proxy;');
    buf.writeln();

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
      var optionsArg = '';
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
          "    return await _proxy.callMethod('$methodName', [${positionalNames.join(', ')}], namedArgs: {$namedNames}$optionsArg);");
      buf.writeln('  }');
      buf.writeln();
    }

    buf.writeln('}');
    buf.writeln();
    buf.writeln('void \$register${className}ClientFactory() {');
    buf.writeln('  GeneratedClientRegistry.register<$className>(');
    buf.writeln('    (proxy) => $clientName(proxy),');
    buf.writeln('  );');
    buf.writeln('}');
    buf.writeln();
    // Dispatcher & method IDs
    buf.writeln('class _${className}Methods {');
    methodIds.forEach((name, id) {
      buf.writeln('  static const int ${name}Id = $id;');
    });
    buf.writeln('}');
    buf.writeln();
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
            parts.add('positionalArgs[${positionalIndex++}]');
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
    buf.writeln();
    buf.writeln('void \$register${className}Dispatcher() {');
    buf.writeln('  GeneratedDispatcherRegistry.register<$className>(');
    buf.writeln('    _${className}Dispatcher,');
    buf.writeln('  );');
    buf.writeln('}');
    buf.writeln();
    // Register method IDs for client-side lookup
    buf.writeln('void \$register${className}MethodIds() {');
    buf.writeln('  ServiceMethodIdRegistry.register<$className>({');
    for (final entry in methodIds.entries) {
      buf.writeln("    '${entry.key}': _${className}Methods.${entry.key}Id,");
    }
    buf.writeln('  });');
    buf.writeln('}');
    buf.writeln();
    // Public registrar for host-side (client + method IDs)
    buf.writeln('void register${className}Generated() {');
    buf.writeln('  \$register${className}ClientFactory();');
    buf.writeln('  \$register${className}MethodIds();');
    buf.writeln('}');
    buf.writeln();

    // Generate a worker-side concrete class that auto-registers the dispatcher.
    // Consumers should use <ClassName>Impl as the serviceFactory for remote services.
    if (isRemote && !classEl.isAbstract) {
      buf.writeln(
          '// Remote service implementation that auto-registers the dispatcher');
      buf.writeln('class ${className}Impl extends $className {');
      buf.writeln('  @override');
      buf.writeln('  bool get isRemote => true;');
      buf.writeln('  @override');
      buf.writeln('  Type get clientBaseType => $className;');
      buf.writeln('  @override');
      buf.writeln('  Future<void> registerHostSide() async {');
      buf.writeln('    \$register${className}ClientFactory();');
      buf.writeln('    \$register${className}MethodIds();');
      for (final dep in depTypeNames) {
        if (dep != className) {
          buf.writeln(
              '    // Auto-registered from dependencies/optionalDependencies');
          buf.writeln(
              '    try { \$register${dep}ClientFactory(); } catch (_) {}');
          buf.writeln('    try { \$register${dep}MethodIds(); } catch (_) {}');
        }
      }
      buf.writeln('  }');
      buf.writeln('  @override');
      buf.writeln('  Future<void> initialize() async {');
      buf.writeln('    \$register${className}Dispatcher();');
      for (final dep in depTypeNames) {
        if (dep != className) {
          buf.writeln(
              '    // Ensure worker isolate can create clients for dependencies');
          buf.writeln(
              '    try { \$register${dep}ClientFactory(); } catch (_) {}');
          buf.writeln('    try { \$register${dep}MethodIds(); } catch (_) {}');
        }
      }
      buf.writeln('    await super.initialize();');
      buf.writeln('  }');
      buf.writeln('}');
      buf.writeln();
    }

    // 🚀 LOCAL IMPL: Generate a local implementation class for local services
    if (!isRemote && !classEl.isAbstract) {
      buf.writeln(
          '// Local service implementation that auto-registers local side');
      buf.writeln('class ${className}Impl extends $className {');
      buf.writeln('  ${className}Impl() {');
      buf.writeln(
          '    // 🚀 AUTO-REGISTRATION: Register local side when instance is created');
      buf.writeln('    \$register${className}LocalSide();');
      buf.writeln('  }');
      buf.writeln('}');
      buf.writeln();
    }

    // 🚀 LOCAL AUTO-REGISTRATION: emit a hidden registrar invoked by ServiceLocator
    buf.writeln('void \$register${className}LocalSide() {');
    buf.writeln('  \$register${className}Dispatcher();');
    buf.writeln('  \$register${className}ClientFactory();');
    buf.writeln('  \$register${className}MethodIds();');
    // Also register dependencies to enable local->remote client creation symmetry
    for (final dep in depTypeNames) {
      if (dep != className) {
        buf.writeln('  try { \$register${dep}ClientFactory(); } catch (_) {}');
        buf.writeln('  try { \$register${dep}MethodIds(); } catch (_) {}');
      }
    }
    buf.writeln('}');
    buf.writeln();

    // 🚀 AUTO-REGISTRATION: Register the LocalSide function in the global registry
    buf.writeln('void \$autoRegister${className}LocalSide() {');
    buf.writeln(
        '  LocalSideRegistry.register<$className>(\$register${className}LocalSide);');
    buf.writeln('}');
    buf.writeln();

    // 🚀 AUTOMATIC CALL: Execute registration immediately when this code is loaded
    buf.writeln('final \$_${className}LocalSideRegistered = (() {');
    buf.writeln('  \$autoRegister${className}LocalSide();');
    buf.writeln('  return true;');
    buf.writeln('})();');
    return buf.toString();
  }

  /// Scan the source code to extract Type identifiers from
  /// `dependencies` and `optionalDependencies` getters for [className].
  List<String> _extractDependencyTypeNamesFromSource(
    String source,
    String className,
  ) {
    final result = <String>{};
    // Find the start of the desired class
    final classStartRegex =
        RegExp(r'\bclass\s+' + RegExp.escape(className) + r'\b');
    final startMatch = classStartRegex.firstMatch(source);
    if (startMatch == null) return result.toList();
    final start = startMatch.start;
    // Find the start of the next class after this one (to bound the slice)
    final nextClassRegex = RegExp(r'\nclass\s+');
    final nextMatch = nextClassRegex.firstMatch(source.substring(start + 1));
    final end = nextMatch == null ? source.length : start + 1 + nextMatch.start;
    final body = source.substring(start, end);

    // Find getters like: List<Type> get dependencies => [A, B, C];
    final depGetterRegex = RegExp(
        r'List<\s*Type\s*>\s*get\s*(dependencies|optionalDependencies)\s*=>\s*\[(.*?)\];',
        multiLine: true);
    for (final m in depGetterRegex.allMatches(body)) {
      final listContent = m.group(2) ?? '';
      // Split by commas and trim
      for (final part in listContent.split(',')) {
        final name = part.trim();
        if (name.isEmpty) continue;
        // Filter out invalid identifiers
        if (RegExp(r'^[A-Za-z_][A-Za-z0-9_]*\$?').hasMatch(name)) {
          result.add(name.replaceAll(r'$', ''));
        }
      }
    }

    return result.toList();
  }
}

Builder serviceBuilder(BuilderOptions options) =>
    SharedPartBuilder([ServiceGenerator()], 'service_generator');

// ignore_for_file: cascade_invocations, lines_longer_than_80_chars
// ignore_for_file: cascade_invocations, lines_longer_than_80_chars

import 'dart:async';

import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart'
    show DartType, InterfaceType, TypeParameterType, VoidType;
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
    Element2 element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    if (element is! ClassElement2) return '';
    // Convert to Element for TypeChecker compatibility
    final legacyElement = element.firstFragment.element;
    if (!_serviceContractChecker.hasAnnotationOf(legacyElement)) return '';

    final classEl = element;
    final className = classEl.displayName;
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
    final clientName = '${className}Client';
    buf
      ..writeln('// Service client for $className')
      ..writeln('class $clientName extends $className {')
      ..writeln('  $clientName(this._proxy);')
      ..writeln('  final ServiceProxy<$className> _proxy;')
      ..writeln();

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
    for (final m in classEl.methods2.where((m) =>
            !m.isStatic &&
            !m.isPrivate &&
            !m.isOperator &&
            !inheritedMethods.contains(m.displayName) &&
            m.enclosingElement2 ==
                classEl // Only methods declared in this class
        )) {
      if (m.returnType is! InterfaceType && !m.returnType.isDartAsyncFuture) {
        // Only generate for Future-returning methods in MVP
        continue;
      }
      final methodName = m.displayName;
      methodIds[methodName] = nextId++;
      final returnType = _typeCode(m.returnType);
      // Capture method-level type parameters
      final typeParams = m.typeParameters2;
      final typeParamSig = typeParams.isEmpty
          ? ''
          : '<${typeParams.map((tp) {
              final bound = tp.bound;
              final suffix =
                  bound == null ? '' : ' extends ${_typeCode(bound)}';
              return '${tp.displayName}$suffix';
            }).join(', ')}>';
      // Separate positional and named parameters
      final positionalParams =
          m.formalParameters.where((p) => p.isPositional).toList();
      final namedParams = m.formalParameters.where((p) => p.isNamed).toList();

      final positionalSig = positionalParams
          .map((p) => '${_typeCode(p.type)} ${p.displayName}')
          .join(', ');

      final namedSig = namedParams.map((p) {
        final typeDisplay = _typeCode(p.type);
        final defaultValue =
            p.hasDefaultValue ? ' = ${p.defaultValueCode}' : '';
        return p.isRequiredNamed
            ? 'required $typeDisplay ${p.displayName}'
            : '$typeDisplay ${p.displayName}$defaultValue';
      }).join(', ');

      final paramsSig = [
        if (positionalSig.isNotEmpty) positionalSig,
        if (namedSig.isNotEmpty) '{$namedSig}',
      ].join(', ');
      final positionalNames =
          positionalParams.map((p) => p.displayName).toList();
      final namedNames = namedParams
          .map((p) => "'${p.displayName}': ${p.displayName}")
          .join(', ');
      final positionalArgsList = positionalNames.join(', ');
      final namedArgsLiteral = '{$namedNames}';
      DartType? futureValueType;
      var returnsValue = true;
      var specifyReturnGeneric = false;
      String? callReturnType;
      if (m.returnType.isDartAsyncFuture && m.returnType is InterfaceType) {
        final futureType = m.returnType as InterfaceType;
        if (futureType.typeArguments.isNotEmpty) {
          final innerType = futureType.typeArguments.first;
          futureValueType = innerType;
          if (innerType is VoidType) {
            returnsValue = false;
          } else if (innerType is TypeParameterType) {
            specifyReturnGeneric = true;
            callReturnType = _typeCode(innerType);
            if (_typeUsesTypeParameter(innerType)) {
              specifyReturnGeneric = true;
              callReturnType = _typeCode(innerType);
            }
            if (innerType is InterfaceType) {
              if (innerType.isDartCoreList ||
                  innerType.isDartCoreMap ||
                  innerType.isDartCoreSet) {
                // Keep conversions for collection casts regardless of generics
              }
            }
          }
        }
      }
      final callGenericClause = specifyReturnGeneric && callReturnType != null
          ? '<$callReturnType>'
          : '';
      // Build optional ServiceCallOptions from @ServiceMethod annotation
      final methodAnno =
          _serviceMethodChecker.firstAnnotationOf(m.firstFragment.element);
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
      final callExpression = (() {
        final callBuf = StringBuffer()
          ..write("_proxy.callMethod$callGenericClause('$methodName', [")
          ..write(positionalArgsList)
          ..write('], namedArgs: ')
          ..write(namedArgsLiteral)
          ..write(optionsArg)
          ..write(')');
        return callBuf.toString();
      })();

      buf
        ..writeln('  @override')
        ..write('  $returnType $methodName$typeParamSig(')
        ..write(paramsSig)
        ..writeln(') async {');
      if (returnsValue) {
        buf.writeln('    final result = await $callExpression;');
        final returnExpr = _buildReturnExpression('result', futureValueType);
        buf.writeln('    return $returnExpr;');
      } else {
        buf.writeln('    await $callExpression;');
      }
      buf
        ..writeln('  }')
        ..writeln();
    }

    buf
      ..writeln('}')
      ..writeln()
      ..writeln('void \$register${className}ClientFactory() {')
      ..writeln('  GeneratedClientRegistry.register<$className>(')
      ..writeln('    (proxy) => $clientName(proxy),')
      ..writeln('  );')
      ..writeln('}');
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
          classEl.methods2.firstWhere((m) => m.displayName == entry.key);
      final argList = () {
        final parts = <String>[];
        var positionalIndex = 0;
        for (final p in method.formalParameters) {
          if (p.isPositional) {
            parts.add('positionalArgs[${positionalIndex++}]');
          } else if (p.isNamed) {
            parts.add("${p.displayName}: namedArgs['${p.displayName}']");
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
      buf
        ..writeln(
            '// Remote service implementation that auto-registers the dispatcher')
        ..writeln('class ${className}Impl extends $className {')
        ..writeln('  @override')
        ..writeln('  bool get isRemote => true;')
        ..writeln('  @override')
        ..writeln('  Type get clientBaseType => $className;')
        ..writeln('  @override')
        ..writeln('  Future<void> registerHostSide() async {')
        ..writeln('    \$register${className}ClientFactory();')
        ..writeln('    \$register${className}MethodIds();');
      for (final dep in depTypeNames) {
        if (dep != className) {
          buf.writeln(
              '    // Auto-registered from dependencies/optionalDependencies');
          buf.writeln(
              '    try { \$register${dep}ClientFactory(); } catch (_) {}');
          buf.writeln('    try { \$register${dep}MethodIds(); } catch (_) {}');
        }
      }
      buf
        ..writeln('  }')
        ..writeln('  @override')
        ..writeln('  Future<void> initialize() async {')
        ..writeln('    \$register${className}Dispatcher();');
      for (final dep in depTypeNames) {
        if (dep != className) {
          buf.writeln(
              '    // Ensure worker isolate can create clients for dependencies');
          buf.writeln(
              '    try { \$register${dep}ClientFactory(); } catch (_) {}');
          buf.writeln('    try { \$register${dep}MethodIds(); } catch (_) {}');
        }
      }
      buf
        ..writeln('    await super.initialize();')
        ..writeln('  }')
        ..writeln('}')
        ..writeln();
    }

    // 🚀 LOCAL IMPL: Generate a local implementation class for local services
    if (!isRemote && !classEl.isAbstract) {
      buf
        ..writeln(
            '// Local service implementation that auto-registers local side')
        ..writeln('class ${className}Impl extends $className {')
        ..writeln('  ${className}Impl() {')
        ..writeln(
            '    // 🚀 AUTO-REGISTRATION: Register local side when instance is created')
        ..writeln('    \$register${className}LocalSide();')
        ..writeln('  }')
        ..writeln('}')
        ..writeln();
    }

    // 🚀 LOCAL AUTO-REGISTRATION: emit a hidden registrar invoked by ServiceLocator
    buf
      ..writeln('void \$register${className}LocalSide() {')
      ..writeln('  \$register${className}Dispatcher();')
      ..writeln('  \$register${className}ClientFactory();')
      ..writeln('  \$register${className}MethodIds();');
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
    buf
      ..writeln('void \$autoRegister${className}LocalSide() {')
      ..writeln(
          '  LocalSideRegistry.register<$className>(\$register${className}LocalSide);')
      ..writeln('}');
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

  String _buildReturnExpression(String resultVar, DartType? targetType) {
    if (targetType == null) return resultVar;
    if (targetType is TypeParameterType) {
      final typeDisplay = _typeCode(targetType);
      return '$resultVar as $typeDisplay';
    }
    if (targetType is InterfaceType) {
      bool typeArgsUseParameters =
          _typeUsesTypeParameterInArgs(targetType.typeArguments);
      if (targetType.isDartCoreList && targetType.typeArguments.length == 1) {
        final itemType = _typeCode(targetType.typeArguments.first);
        if (typeArgsUseParameters) {
          return '$resultVar.cast<$itemType>()';
        }
        return '$resultVar as List<$itemType>';
      }
      if (targetType.isDartCoreSet && targetType.typeArguments.length == 1) {
        final itemType = _typeCode(targetType.typeArguments.first);
        if (typeArgsUseParameters) {
          return '$resultVar.cast<$itemType>()';
        }
        return '$resultVar as Set<$itemType>';
      }
      if (targetType.isDartCoreMap && targetType.typeArguments.length == 2) {
        final keyType = _typeCode(targetType.typeArguments[0]);
        final valueType = _typeCode(targetType.typeArguments[1]);
        if (typeArgsUseParameters) {
          return '$resultVar.cast<$keyType, $valueType>()';
        }
        return '$resultVar as Map<$keyType, $valueType>';
      }
    }
    final typeDisplay = _typeCode(targetType);
    return '$resultVar as $typeDisplay';
  }

  bool _typeUsesTypeParameter(DartType type) {
    if (type is TypeParameterType) return true;
    if (type is InterfaceType) {
      for (final t in type.typeArguments) {
        if (_typeUsesTypeParameter(t)) return true;
      }
    }
    return false;
  }

  bool _typeUsesTypeParameterInArgs(Iterable<DartType> types) {
    for (final t in types) {
      if (_typeUsesTypeParameter(t)) return true;
    }
    return false;
  }

  String _typeCode(DartType type) {
    final base = type.getDisplayString();
    final suffix = switch (type.nullabilitySuffix) {
      NullabilitySuffix.question => base.endsWith('?') ? '' : '?',
      NullabilitySuffix.star => base.endsWith('*') ? '' : '*',
      _ => '',
    };
    if (type is InterfaceType && type.typeArguments.isNotEmpty) {
      final args = type.typeArguments.map(_typeCode).join(', ');
      final name = type.element.name;
      final typeBase = name + '<$args>';
      if (suffix.isEmpty) return typeBase;
      return '$typeBase$suffix';
    }
    return '$base$suffix';
  }
}

Builder serviceBuilder(BuilderOptions options) =>
    SharedPartBuilder([ServiceGenerator()], 'service_generator');

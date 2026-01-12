import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:simple_routes_annotations/simple_routes_annotations.dart';
import 'package:source_gen/source_gen.dart';
import 'path_parser.dart';

class SimpleRouteGenerator extends GeneratorForAnnotation<Route> {
  final DartFormatter _formatter = DartFormatter();

  static const _routeChecker = TypeChecker.fromUrl(
    'package:simple_routes_annotations/simple_routes_annotations.dart#Route',
  );
  static const _pathChecker = TypeChecker.fromUrl(
    'package:simple_routes_annotations/simple_routes_annotations.dart#Path',
  );
  static const _queryChecker = TypeChecker.fromUrl(
    'package:simple_routes_annotations/simple_routes_annotations.dart#Query',
  );
  static const _extraChecker = TypeChecker.fromUrl(
    'package:simple_routes_annotations/simple_routes_annotations.dart#Extra',
  );

  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        'Route can only be applied to classes.',
        element: element,
      );
    }

    final blueprint = element;
    final hierarchy = _getHierarchy(blueprint, annotation);
    final allPathParams = _collectPathParams(hierarchy);
    final dataSources = _collectDataSources(blueprint, hierarchy);

    final path = annotation.read('path').stringValue;
    final parentReader = annotation.read('parent');
    final parentType = parentReader.isNull ? null : parentReader.typeValue;

    final isData = dataSources.isNotEmpty;

    final library = Library((l) {
      if (isData) {
        l.body.add(_generateDataClass(blueprint, dataSources, allPathParams));
      }
      l.body.add(
        _generateRouteClass(
          blueprint,
          path,
          isData,
          parentType as InterfaceType?,
        ),
      );
      if (isData) {
        l.body.add(
          _generateStateExtension(blueprint, dataSources, allPathParams),
        );
      }
    });

    final emitter = DartEmitter();
    return _formatter.format('${library.accept(emitter)}');
  }

  Class _generateDataClass(
    ClassElement blueprint,
    List<_DataSource> dataSources,
    List<String> allPathParams,
  ) {
    return Class((c) {
      c.name = '${blueprint.name}RouteData';
      c.implements.add(refer('SimpleRouteData'));

      // Add fields
      for (final source in dataSources) {
        c.fields.add(
          Field((f) {
            f.name = source.name;
            f.modifier = FieldModifier.final$;
            f.type = refer(source.type.getDisplayString(withNullability: true));
          }),
        );
      }

      // Add constructor
      c.constructors.add(
        Constructor((ctor) {
          ctor.constant = true;
          for (final source in dataSources) {
            ctor.optionalParameters.add(
              Parameter((p) {
                p.name = source.name;
                p.toThis = true;
                p.required = source.isRequired;
                p.named = true;
              }),
            );
          }
        }),
      );

      // Override [parameters]
      c.methods.add(
        Method((m) {
          m.name = 'parameters';
          m.type = MethodType.getter;
          m.annotations.add(refer('override'));
          m.returns = refer('Map<String, String>');

          final mapValues = <String, Expression>{};
          for (final source in dataSources) {
            if (source.isPath) {
              final paramName = source.paramName ?? source.name;
              mapValues[paramName] = source.type.isDartCoreString
                  ? refer(source.name)
                  : refer(source.name).property('toString').call([]);
            }
          }
          m.body = literalMap(mapValues).code;
        }),
      );

      // Override [query]
      c.methods.add(
        Method((m) {
          m.name = 'query';
          m.type = MethodType.getter;
          m.annotations.add(refer('override'));
          m.returns = refer('Map<String, String?>');

          final mapValues = <String, Expression>{};
          for (final source in dataSources) {
            if (source.isQuery) {
              final queryName = source.paramName ?? source.name;
              if (source.type.isDartCoreString) {
                mapValues[queryName] = refer(source.name);
              } else {
                mapValues[queryName] =
                    source.type.nullabilitySuffix == NullabilitySuffix.none
                    ? refer(source.name).property('toString').call([])
                    : refer(source.name).nullSafeProperty('toString').call([]);
              }
            }
          }
          m.body = literalMap(mapValues).code;
        }),
      );

      // Override [extra]
      final extraSource = dataSources.where((s) => s.isExtra).firstOrNull;
      if (extraSource != null) {
        c.methods.add(
          Method((m) {
            m.name = 'extra';
            m.type = MethodType.getter;
            m.annotations.add(refer('override'));
            m.returns = refer('Object?');
            m.body = refer(extraSource.name).code;
          }),
        );
      }
    });
  }

  Class _generateRouteClass(
    ClassElement blueprint,
    String path,
    bool isData,
    InterfaceType? parent,
  ) {
    final name = '${blueprint.name}Route';
    final dataClassName = '${blueprint.name}RouteData';
    final baseClass = isData
        ? 'SimpleDataRoute<$dataClassName>'
        : 'SimpleRoute';

    return Class((c) {
      c.name = name;
      c.extend = refer(baseClass);

      if (parent != null) {
        final parentName = parent.element.name;
        c.implements.add(refer('ChildRoute<${parentName}Route>'));
      }

      c.constructors.add(
        Constructor((ctor) {
          ctor.constant = true;
          ctor.initializers.add(
            refer('super').call([literalString(path)]).code,
          );
        }),
      );

      if (parent != null) {
        final parentName = parent.element.name;
        c.methods.add(
          Method((m) {
            m.name = 'parent';
            m.type = MethodType.getter;
            m.annotations.add(refer('override'));
            m.returns = refer('${parentName}Route');
            m.body = refer('const ${parentName}Route').call([]).code;
          }),
        );
      }
    });
  }

  Extension _generateStateExtension(
    ClassElement blueprint,
    List<_DataSource> dataSources,
    List<String> allPathParams,
  ) {
    final dataClassName = '${blueprint.name}RouteData';
    return Extension((e) {
      e.name = '${blueprint.name}StateX';
      e.on = refer('GoRouterState');

      e.methods.add(
        Method((m) {
          final getterName =
              '${blueprint.name[0].toLowerCase()}${blueprint.name.substring(1)}';
          m.name = getterName;
          m.returns = refer(dataClassName);
          m.type = MethodType.getter;

          final namedArgs = <String, Expression>{};
          for (final source in dataSources) {
            if (source.isPath) {
              final paramName = source.paramName ?? source.name;
              namedArgs[source.name] = _parseType(
                refer('pathParameters').index(literalString(paramName)),
                source.type,
              );
            } else if (source.isQuery) {
              final queryName = source.paramName ?? source.name;
              namedArgs[source.name] = _parseType(
                refer(
                  'uri',
                ).property('queryParameters').index(literalString(queryName)),
                source.type,
              );
            } else if (source.isExtra) {
              namedArgs[source.name] = refer(
                'extra',
              ).asA(refer(source.type.getDisplayString(withNullability: true)));
            }
          }

          m.body = refer(dataClassName).call([], namedArgs).code;
        }),
      );
    });
  }

  Expression _parseType(Expression source, DartType type) {
    final isNullable = type.nullabilitySuffix != NullabilitySuffix.none;
    final expr = isNullable ? source : source.nullChecked;

    if (type.isDartCoreString) return expr;

    if (type.isDartCoreInt) {
      return refer('int').property('parse').call([expr]);
    }

    return isNullable
        ? source.nullSafeProperty('toString').call([])
        : source.nullChecked.property('toString').call([]);
  }

  List<_RouteInfo> _getHierarchy(
    ClassElement element,
    ConstantReader annotation,
  ) {
    final result = <_RouteInfo>[];
    var currentElement = element;
    var currentAnnotation = annotation;

    while (true) {
      final path = currentAnnotation.read('path').stringValue;
      result.add(_RouteInfo(currentElement, path));

      final parentReader = currentAnnotation.read('parent');
      if (parentReader.isNull) break;

      final parentType = parentReader.typeValue;
      if (parentType is! InterfaceType) break;

      currentElement = parentType.element as ClassElement;
      final nextAnnotation = _getAnnotation(currentElement, _routeChecker);

      if (nextAnnotation == null) break;
      currentAnnotation = ConstantReader(nextAnnotation);
    }

    return result;
  }

  List<String> _collectPathParams(List<_RouteInfo> hierarchy) {
    return hierarchy
        .expand((h) => PathParser.parseParams(h.path))
        .toSet()
        .toList();
  }

  List<_DataSource> _collectDataSources(
    ClassElement blueprint,
    List<_RouteInfo> hierarchy,
  ) {
    final dataSources = <String, _DataSource>{};

    // 1. Collect from factory constructor (if any)
    final factoryConstructor = blueprint.constructors
        .where((c) => c.isFactory)
        .firstOrNull;
    if (factoryConstructor != null) {
      for (final param in factoryConstructor.parameters) {
        dataSources[param.name] = _DataSource.fromParameter(param);
      }
    }

    // 2. Collect from annotated fields and getters
    for (final field in blueprint.fields) {
      if (_isAnnotated(field)) {
        final ds = _DataSource.fromElement(field);
        dataSources[ds.name] = ds;
      }
    }

    for (final accessor in blueprint.accessors) {
      if (accessor.isGetter && _isAnnotated(accessor)) {
        final ds = _DataSource.fromElement(accessor);
        dataSources[ds.name] = ds;
      } else if (accessor.isGetter) {
        // Also check the underlying variable for the accessor
        final variable = accessor.variable;
        if (_isAnnotated(variable)) {
          final ds = _DataSource.fromElement(accessor);
          dataSources[ds.name] = ds;
        }
      }
    }

    // 3. Collect path parameters from hierarchy that are missing in the current leaf
    for (final info in hierarchy.skip(1)) {
      final parentBlueprint = info.element;
      // Check factory
      final parentFactory = parentBlueprint.constructors
          .where((c) => c.isFactory)
          .firstOrNull;
      if (parentFactory != null) {
        for (final param in parentFactory.parameters) {
          if (_hasAnnotation(param, _pathChecker)) {
            final ds = _DataSource.fromParameter(param);
            if (!dataSources.containsKey(ds.name)) {
              dataSources[ds.name] = ds;
            }
          }
        }
      }
      // Check fields/getters
      for (final field in parentBlueprint.fields) {
        if (_hasAnnotation(field, _pathChecker)) {
          final ds = _DataSource.fromElement(field);
          if (!dataSources.containsKey(ds.name)) {
            dataSources[ds.name] = ds;
          }
        }
      }
      for (final accessor in parentBlueprint.accessors) {
        if (accessor.isGetter && _hasAnnotation(accessor, _pathChecker)) {
          final ds = _DataSource.fromElement(accessor);
          if (!dataSources.containsKey(ds.name)) {
            dataSources[ds.name] = ds;
          }
        }
      }
    }

    return dataSources.values.toList();
  }

  static bool _isAnnotated(Element element) {
    return _hasAnnotation(element, _pathChecker) ||
        _hasAnnotation(element, _queryChecker) ||
        _hasAnnotation(element, _extraChecker);
  }

  static DartObject? _getAnnotation(Element element, TypeChecker checker) {
    final annotation = checker.firstAnnotationOf(element);
    if (annotation != null) return annotation;

    if (element is PropertyAccessorElement) {
      final variable = element.variable;
      final varAnnotation = checker.firstAnnotationOf(variable);
      if (varAnnotation != null) return varAnnotation;
    }

    // Fallback: match by name
    final checkerString = checker.toString();
    final parts = checkerString.split(RegExp(r'[#.]'));
    final annotationName = parts.last.replaceAll(')', '').trim();

    for (final metadata in element.metadata) {
      final value = metadata.computeConstantValue();
      final type = value?.type;
      final typeName =
          type?.element?.name ?? type?.getDisplayString(withNullability: false);

      if (typeName == annotationName) {
        return value;
      }
    }

    return null;
  }

  static bool _hasAnnotation(Element element, TypeChecker checker) {
    return _getAnnotation(element, checker) != null;
  }
}

class _RouteInfo {
  _RouteInfo(this.element, this.path);
  final ClassElement element;
  final String path;
}

class _DataSource {
  const _DataSource({
    required this.name,
    required this.type,
    required this.isPath,
    required this.isQuery,
    required this.isExtra,
    required this.isRequired,
    this.paramName,
    required this.element,
  });

  final String name;
  final DartType type;
  final bool isPath;
  final bool isQuery;
  final bool isExtra;
  final bool isRequired;
  final String? paramName;
  final Element element;

  factory _DataSource.fromParameter(ParameterElement param) {
    final pathAnnot = SimpleRouteGenerator._getAnnotation(
      param,
      SimpleRouteGenerator._pathChecker,
    );
    final queryAnnot = SimpleRouteGenerator._getAnnotation(
      param,
      SimpleRouteGenerator._queryChecker,
    );
    final extraAnnot = SimpleRouteGenerator._getAnnotation(
      param,
      SimpleRouteGenerator._extraChecker,
    );

    return _DataSource(
      name: param.name,
      type: param.type,
      isPath: pathAnnot != null,
      isQuery: queryAnnot != null,
      isExtra: extraAnnot != null,
      isRequired: param.isRequiredNamed || !param.isOptional,
      paramName:
          pathAnnot?.getField('name')?.toStringValue() ??
          queryAnnot?.getField('name')?.toStringValue(),
      element: param,
    );
  }

  factory _DataSource.fromElement(Element element) {
    final pathAnnot = SimpleRouteGenerator._getAnnotation(
      element,
      SimpleRouteGenerator._pathChecker,
    );
    final queryAnnot = SimpleRouteGenerator._getAnnotation(
      element,
      SimpleRouteGenerator._queryChecker,
    );
    final extraAnnot = SimpleRouteGenerator._getAnnotation(
      element,
      SimpleRouteGenerator._extraChecker,
    );

    DartType type;
    if (element is VariableElement) {
      type = element.type;
    } else if (element is PropertyAccessorElement) {
      type = element.returnType;
    } else {
      throw InvalidGenerationSourceError(
        'Unexpected element type: ${element.runtimeType}',
        element: element,
      );
    }

    return _DataSource(
      name: element.name!,
      type: type,
      isPath: pathAnnot != null,
      isQuery: queryAnnot != null,
      isExtra: extraAnnot != null,
      isRequired: type.nullabilitySuffix == NullabilitySuffix.none,
      paramName:
          pathAnnot?.getField('name')?.toStringValue() ??
          queryAnnot?.getField('name')?.toStringValue(),
      element: element,
    );
  }
}

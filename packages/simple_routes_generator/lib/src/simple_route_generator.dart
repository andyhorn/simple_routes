import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:simple_routes_annotations/simple_routes_annotations.dart';
import 'package:source_gen/source_gen.dart';

import 'models/models.dart';

class SimpleRouteGenerator extends GeneratorForAnnotation<Route> {
  final DartFormatter _formatter = DartFormatter();
  final Annotations _annotations = const Annotations();

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
    final parentType = parentReader.isNull
        ? null
        : (parentReader.typeValue is InterfaceType
            ? parentReader.typeValue as InterfaceType
            : null);

    _validatePathParams(blueprint, allPathParams, dataSources);
    _validateExtraAnnotations(blueprint, dataSources);

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
          parentType,
        ),
      );
    });

    final emitter = DartEmitter();
    return _formatter.format('${library.accept(emitter)}');
  }

  String _buildRouteClassName(ClassElement blueprint) {
    return '${blueprint.name}Route';
  }

  String _buildRouteDataClassName(ClassElement blueprint) {
    return '${blueprint.name}RouteData';
  }

  String _buildParentRouteClassName(InterfaceType parent) {
    return '${parent.element.name}Route';
  }

  String _buildSimpleDataRouteType(String dataClassName) {
    return 'SimpleDataRoute<$dataClassName>';
  }

  String _buildChildRouteType(String parentRouteClassName) {
    return 'ChildRoute<$parentRouteClassName>';
  }

  /// Generates the route data class that implements [SimpleRouteData].
  ///
  /// Creates a class with fields for each data source, a constructor, a
  /// `fromState` factory, and getters for [parameters], [query], and [extra].
  Class _generateDataClass(
    ClassElement blueprint,
    List<DataSource> dataSources,
    Set<String> allPathParams,
  ) {
    return Class((c) {
      final className = _buildRouteDataClassName(blueprint);
      c.name = className;
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

      // Add parse helper methods
      final parseHelpers = _generateParseHelpers(dataSources);
      for (final helper in parseHelpers) {
        c.methods.add(helper);
      }

      // Add fromState factory
      c.constructors.add(
        Constructor((ctor) {
          ctor.name = 'fromState';
          ctor.factory = true;
          ctor.requiredParameters.add(
            Parameter((p) {
              p.name = 'state';
              p.type = refer('GoRouterState');
            }),
          );

          final namedArgs = <String, Expression>{};
          for (final source in dataSources) {
            if (source.isPath) {
              final paramName = source.paramName ?? source.name;
              namedArgs[source.name] = _parseType(
                refer(
                  'state',
                ).property('pathParameters').index(literalString(paramName)),
                source.type,
              );
            } else if (source.isQuery) {
              final queryName = source.paramName ?? source.name;
              namedArgs[source.name] = _parseType(
                refer('state')
                    .property('uri')
                    .property('queryParameters')
                    .index(literalString(queryName)),
                source.type,
              );
            } else if (source.isExtra) {
              namedArgs[source.name] = refer('state').property('extra').asA(
                    refer(source.type.getDisplayString(withNullability: true)),
                  );
            }
          }

          ctor.body = refer(className).call([], namedArgs).code;
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
              mapValues[paramName] = _serializeType(
                refer(source.name),
                source.type,
              );
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
              mapValues[queryName] = _serializeType(
                refer(source.name),
                source.type,
              );
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

  /// Generates the route class that extends [SimpleRoute] or [SimpleDataRoute].
  ///
  /// If [parent] is provided, the class also implements [ChildRoute].
  Class _generateRouteClass(
    ClassElement blueprint,
    String path,
    bool isData,
    InterfaceType? parent,
  ) {
    final name = _buildRouteClassName(blueprint);
    final dataClassName = _buildRouteDataClassName(blueprint);
    final baseClass =
        isData ? _buildSimpleDataRouteType(dataClassName) : 'SimpleRoute';

    return Class((c) {
      c.name = name;
      c.extend = refer(baseClass);

      if (parent != null) {
        final parentRouteClassName = _buildParentRouteClassName(parent);
        final childRouteType = _buildChildRouteType(parentRouteClassName);
        c.implements.add(refer(childRouteType));
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
        final parentRouteClassName = _buildParentRouteClassName(parent);
        c.methods.add(
          Method((m) {
            m.name = 'parent';
            m.type = MethodType.getter;
            m.annotations.add(refer('override'));
            m.returns = refer(parentRouteClassName);
            m.body = refer('const $parentRouteClassName').call([]).code;
          }),
        );
      }
    });
  }

  /// Generates an expression to parse a string value to the given [type].
  ///
  /// Returns a call to the appropriate helper method (e.g., `_parseInt`) for
  /// non-string types, or the source expression directly for strings.
  Expression _parseType(Expression source, DartType type) {
    final isNullable = type.nullabilitySuffix != NullabilitySuffix.none;

    // Strings come directly from nullable sources like path/query parameters.
    // Apply a null-check for non-nullable String targets.
    if (type.isDartCoreString) {
      return isNullable ? source : source.nullChecked;
    }

    Expression? parsed;

    if (type.isDartCoreInt) {
      parsed = refer('_parseInt').call([source, literalBool(isNullable)]);
    } else if (type.isDartCoreDouble) {
      parsed = refer('_parseDouble').call([source, literalBool(isNullable)]);
    } else if (type.isDartCoreNum) {
      parsed = refer('_parseNum').call([source, literalBool(isNullable)]);
    } else if (type.getDisplayString(withNullability: false) == 'DateTime') {
      parsed = refer('_parseDateTime').call([source, literalBool(isNullable)]);
    } else if (type.isDartCoreBool) {
      parsed = refer('_parseBool').call([source, literalBool(isNullable)]);
    } else if (type is InterfaceType && type.element is EnumElement) {
      final enumName = type.element.name;
      parsed = refer('_parseEnum').call([
        source,
        literalBool(isNullable),
        refer(enumName).property('values'),
      ]);
    }

    if (parsed != null) {
      // Parse helpers return nullable values; assert non-null when the
      // target type is non-nullable.
      return isNullable ? parsed : parsed.nullChecked;
    }

    // Fallback for other types: rely on toString(), preserving existing
    // nullability behavior.
    if (isNullable) {
      return source.nullSafeProperty('toString').call([]);
    }
    return source.nullChecked.property('toString').call([]);
  }

  /// Generates static helper methods for parsing types from strings.
  List<Method> _generateParseHelpers(List<DataSource> dataSources) {
    final helpers = <Method>[];
    final typesNeeded = <String>{};

    // Collect all types that need parsing helpers
    for (final source in dataSources) {
      final type = source.type;
      if (type.isDartCoreInt && !typesNeeded.contains('int')) {
        typesNeeded.add('int');
        helpers.add(_createIntParseHelper());
      } else if (type.isDartCoreDouble && !typesNeeded.contains('double')) {
        typesNeeded.add('double');
        helpers.add(_createDoubleParseHelper());
      } else if (type.isDartCoreNum && !typesNeeded.contains('num')) {
        typesNeeded.add('num');
        helpers.add(_createNumParseHelper());
      } else if (type.getDisplayString(withNullability: false) == 'DateTime' &&
          !typesNeeded.contains('DateTime')) {
        typesNeeded.add('DateTime');
        helpers.add(_createDateTimeParseHelper());
      } else if (type.isDartCoreBool && !typesNeeded.contains('bool')) {
        typesNeeded.add('bool');
        helpers.add(_createBoolParseHelper());
      } else if (type is InterfaceType && type.element is EnumElement) {
        // Only add enum helper once
        if (!typesNeeded.contains('enum')) {
          typesNeeded.add('enum');
          helpers.add(_createEnumParseHelper());
        }
      }
    }

    return helpers;
  }

  Method _createIntParseHelper() {
    return Method((m) {
      m.name = '_parseInt';
      m.static = true;
      m.returns = refer('int?');
      m.requiredParameters.addAll([
        Parameter((p) {
          p.name = 'source';
          p.type = refer('String?');
        }),
        Parameter((p) {
          p.name = 'isNullable';
          p.type = refer('bool');
        }),
      ]);
      m.body = Block.of([
        const Code('if (source == null) {'),
        const Code('  if (isNullable) return null;'),
        const Code(
            "  throw ArgumentError('Required parameter cannot be null');"),
        const Code('}'),
        const Code('if (isNullable) return int.tryParse(source);'),
        const Code('return int.parse(source);'),
      ]);
    });
  }

  Method _createDoubleParseHelper() {
    return Method((m) {
      m.name = '_parseDouble';
      m.static = true;
      m.returns = refer('double?');
      m.requiredParameters.addAll([
        Parameter((p) {
          p.name = 'source';
          p.type = refer('String?');
        }),
        Parameter((p) {
          p.name = 'isNullable';
          p.type = refer('bool');
        }),
      ]);
      m.body = Block.of([
        const Code('if (source == null) {'),
        const Code('  if (isNullable) return null;'),
        const Code(
            "  throw ArgumentError('Required parameter cannot be null');"),
        const Code('}'),
        const Code('if (isNullable) return double.tryParse(source);'),
        const Code('return double.parse(source);'),
      ]);
    });
  }

  Method _createNumParseHelper() {
    return Method((m) {
      m.name = '_parseNum';
      m.static = true;
      m.returns = refer('num?');
      m.requiredParameters.addAll([
        Parameter((p) {
          p.name = 'source';
          p.type = refer('String?');
        }),
        Parameter((p) {
          p.name = 'isNullable';
          p.type = refer('bool');
        }),
      ]);
      m.body = Block.of([
        const Code('if (source == null) {'),
        const Code('  if (isNullable) return null;'),
        const Code(
            "  throw ArgumentError('Required parameter cannot be null');"),
        const Code('}'),
        const Code('if (isNullable) return num.tryParse(source);'),
        const Code('return num.parse(source);'),
      ]);
    });
  }

  Method _createDateTimeParseHelper() {
    return Method((m) {
      m.name = '_parseDateTime';
      m.static = true;
      m.returns = refer('DateTime?');
      m.requiredParameters.addAll([
        Parameter((p) {
          p.name = 'source';
          p.type = refer('String?');
        }),
        Parameter((p) {
          p.name = 'isNullable';
          p.type = refer('bool');
        }),
      ]);
      m.body = Block.of([
        const Code('if (source == null) {'),
        const Code('  if (isNullable) return null;'),
        const Code(
            "  throw ArgumentError('Required parameter cannot be null');"),
        const Code('}'),
        const Code('if (isNullable) return DateTime.tryParse(source);'),
        const Code('return DateTime.parse(source);'),
      ]);
    });
  }

  Method _createBoolParseHelper() {
    return Method((m) {
      m.name = '_parseBool';
      m.static = true;
      m.returns = refer('bool?');
      m.requiredParameters.addAll([
        Parameter((p) {
          p.name = 'source';
          p.type = refer('String?');
        }),
        Parameter((p) {
          p.name = 'isNullable';
          p.type = refer('bool');
        }),
      ]);
      m.body = Block.of([
        const Code('if (source == null) {'),
        const Code('  if (isNullable) return null;'),
        const Code(
            "  throw ArgumentError('Required parameter cannot be null');"),
        const Code('}'),
        const Code("return source == 'true';"),
      ]);
    });
  }

  Method _createEnumParseHelper() {
    return Method((m) {
      m.name = '_parseEnum';
      m.static = true;
      m.returns = refer('Object?');
      m.requiredParameters.addAll([
        Parameter((p) {
          p.name = 'source';
          p.type = refer('String?');
        }),
        Parameter((p) {
          p.name = 'isNullable';
          p.type = refer('bool');
        }),
        Parameter((p) {
          p.name = 'enumValues';
          p.type = refer('List');
        }),
      ]);
      m.body = Block.of([
        const Code('if (source == null) {'),
        const Code('  if (isNullable) return null;'),
        const Code(
            "  throw ArgumentError('Required parameter cannot be null');"),
        const Code('}'),
        const Code('return enumValues.byName(source);'),
      ]);
    });
  }

  /// Generates an expression to serialize a value of [type] to a string.
  ///
  /// Handles enums (uses `.name`), DateTime (uses `.toIso8601String()`), and
  /// other types (uses `.toString()`).
  Expression _serializeType(Expression source, DartType type) {
    final isNullable = type.nullabilitySuffix != NullabilitySuffix.none;

    if (type.isDartCoreString) return source;

    if (type is InterfaceType && type.element is EnumElement) {
      return isNullable
          ? source.nullSafeProperty('name')
          : source.property('name');
    }

    if (type.getDisplayString(withNullability: false) == 'DateTime') {
      return isNullable
          ? source.nullSafeProperty('toIso8601String').call([])
          : source.property('toIso8601String').call([]);
    }

    return isNullable
        ? source.nullSafeProperty('toString').call([])
        : source.property('toString').call([]);
  }

  /// Builds the route hierarchy by traversing parent routes.
  ///
  /// Returns a list of [RouteInfo] objects from the current route up to the
  /// root, following the `parent` annotation chain.
  List<RouteInfo> _getHierarchy(
    ClassElement element,
    ConstantReader annotation,
  ) {
    final result = <RouteInfo>[];
    var currentElement = element;
    var currentAnnotation = annotation;

    while (true) {
      final path = currentAnnotation.read('path').stringValue;
      result.add(RouteInfo(currentElement, path));

      final parentReader = currentAnnotation.read('parent');
      if (parentReader.isNull) break;

      final parentType = parentReader.typeValue;
      if (parentType is! InterfaceType) break;

      final element = parentType.element;
      if (element is! ClassElement) {
        throw InvalidGenerationSourceError(
          'Parent route must be a class, but found ${element.runtimeType}.',
          element: element,
        );
      }
      currentElement = element;
      final nextAnnotation = _annotations.getRouteAnnotation(currentElement);

      if (nextAnnotation == null) break;
      currentAnnotation = ConstantReader(nextAnnotation);
    }

    return result;
  }

  Set<String> _collectPathParams(List<RouteInfo> hierarchy) {
    return hierarchy.expand((h) => _parsePathParams(h.path)).toSet();
  }

  List<String> _parsePathParams(String path) {
    // This is a bug in the Dart SDK, it should not be marked as deprecated
    // ignore: deprecated_member_use
    final regex = RegExp(r':([a-zA-Z0-9_]+)');
    return regex.allMatches(path).map((m) => m.group(1)!).toList();
  }

  /// Collects all data sources from the blueprint and its parent hierarchy.
  ///
  /// Collects all annotated elements from the current blueprint, and path
  /// parameters from parent routes in the hierarchy.
  List<DataSource> _collectDataSources(
    ClassElement blueprint,
    List<RouteInfo> hierarchy,
  ) {
    final dataSources = <String, DataSource>{};

    // 1. Collect from current blueprint - all annotated elements
    final allDataSources = _collectDataSourcesFromElement(
      blueprint,
      (element) => _annotations.isAnnotated(element),
    );

    dataSources.addAll(allDataSources);

    // 2. Collect path parameters from hierarchy that are missing in the current leaf
    for (final info in hierarchy.skip(1)) {
      final parentBlueprint = info.element;
      final parentDataSources = _collectDataSourcesFromElement(
        parentBlueprint,
        (element) => _annotations.getPathAnnotation(element) != null,
      );

      for (final entry in parentDataSources.entries) {
        if (!dataSources.containsKey(entry.key)) {
          dataSources[entry.key] = entry.value;
        }
      }
    }

    return dataSources.values.toList();
  }

  /// Collects data sources from a class element (factory constructor, fields, accessors).
  ///
  /// [blueprint] - The class element to collect from
  /// [shouldCollect] - Predicate function to determine if an element should be collected
  /// Returns a map of data source names to DataSource objects
  Map<String, DataSource> _collectDataSourcesFromElement(
    ClassElement blueprint,
    bool Function(Element element) shouldCollect,
  ) {
    final dataSources = <String, DataSource>{};

    // Collect from factory constructor (if any)
    final factoryConstructors = blueprint.constructors.where(
      (c) => c.isFactory,
    );

    final factoryConstructor = factoryConstructors.firstOrNull;

    if (factoryConstructor != null) {
      for (final param in factoryConstructor.parameters) {
        if (shouldCollect(param)) {
          final ds = DataSource.fromParameter(param);
          dataSources[ds.name] = ds;
        }
      }
    }

    // Collect from fields
    for (final field in blueprint.fields) {
      if (shouldCollect(field)) {
        final ds = DataSource.fromElement(field);
        dataSources[ds.name] = ds;
      }
    }

    final getters = blueprint.accessors.where((a) => a.isGetter);

    // Collect from accessors
    for (final accessor in getters) {
      if (shouldCollect(accessor)) {
        final ds = DataSource.fromElement(accessor);
        dataSources[ds.name] = ds;
      } else {
        // Also check the underlying variable for the accessor
        final variable = accessor.variable;
        if (shouldCollect(variable)) {
          final ds = DataSource.fromElement(accessor);
          dataSources[ds.name] = ds;
        }
      }
    }

    return dataSources;
  }

  void _validatePathParams(
    ClassElement blueprint,
    Set<String> pathParams,
    List<DataSource> dataSources,
  ) {
    final pathDataSources = dataSources.where((ds) => ds.isPath);
    final annotatedParamNames =
        pathDataSources.map((ds) => ds.paramName ?? ds.name).toSet();

    // 1. Check for missing @Path annotations
    for (final templateParam in pathParams) {
      if (!annotatedParamNames.contains(templateParam)) {
        throw InvalidGenerationSourceError(
          'Missing @Path annotation for path parameter ":$templateParam".',
          element: blueprint,
        );
      }
    }

    // 2. Check for @Path annotations that don't match the template
    for (final source in pathDataSources) {
      final effectiveName = source.paramName ?? source.name;
      if (!pathParams.contains(effectiveName)) {
        throw InvalidGenerationSourceError(
          '@Path annotation "$effectiveName" does not match any parameter in the path template.',
          element: source.element,
        );
      }
    }
  }

  void _validateExtraAnnotations(
    ClassElement blueprint,
    List<DataSource> dataSources,
  ) {
    final extraDataSourcesCount = dataSources.where((ds) => ds.isExtra).length;

    if (extraDataSourcesCount > 1) {
      throw InvalidGenerationSourceError(
        'Only one @Extra annotation is allowed per route. Found $extraDataSourcesCount @Extra annotations.',
        element: blueprint,
      );
    }
  }
}

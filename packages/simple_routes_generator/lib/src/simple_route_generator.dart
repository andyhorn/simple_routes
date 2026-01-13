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

  Class _generateDataClass(
    ClassElement blueprint,
    List<DataSource> dataSources,
    List<String> allPathParams,
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

  Expression _parseType(Expression source, DartType type) {
    final isNullable = type.nullabilitySuffix != NullabilitySuffix.none;

    if (type.isDartCoreString) return source;

    if (type.isDartCoreInt) {
      return refer('_parseInt').call([source, literalBool(isNullable)]);
    }

    if (type.isDartCoreDouble) {
      return refer('_parseDouble').call([source, literalBool(isNullable)]);
    }

    if (type.isDartCoreNum) {
      return refer('_parseNum').call([source, literalBool(isNullable)]);
    }

    if (type.getDisplayString(withNullability: false) == 'DateTime') {
      return refer('_parseDateTime').call([source, literalBool(isNullable)]);
    }

    if (type.isDartCoreBool) {
      return refer('_parseBool').call([source, literalBool(isNullable)]);
    }

    if (type is InterfaceType && type.element is EnumElement) {
      final enumName = type.element.name;
      return refer('_parseEnum').call([
        source,
        literalBool(isNullable),
        refer(enumName).property('values'),
      ]);
    }

    // Fallback for other types
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
        const Code('if (source == null) return null;'),
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
        const Code('if (source == null) return null;'),
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
        const Code('if (source == null) return null;'),
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
        const Code('if (source == null) return null;'),
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
        const Code('if (source == null) return null;'),
        const Code('if (isNullable) return source == \'true\';'),
        const Code('return source == \'true\';'),
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
        const Code('if (source == null) return null;'),
        const Code('return enumValues.byName(source);'),
      ]);
    });
  }

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

  List<String> _collectPathParams(List<RouteInfo> hierarchy) {
    return hierarchy.expand((h) => _parsePathParams(h.path)).toSet().toList();
  }

  List<String> _parsePathParams(String path) {
    // This is a bug in the Dart SDK, it should not be marked as deprecated
    // ignore: deprecated_member_use
    final regex = RegExp(r':([a-zA-Z0-9_]+)');
    return regex.allMatches(path).map((m) => m.group(1)!).toList();
  }

  List<DataSource> _collectDataSources(
    ClassElement blueprint,
    List<RouteInfo> hierarchy,
  ) {
    final dataSources = <String, DataSource>{};

    // 1. Collect from factory constructor (if any) - only annotated parameters
    final factoryConstructor =
        blueprint.constructors.where((c) => c.isFactory).firstOrNull;
    if (factoryConstructor != null) {
      for (final param in factoryConstructor.parameters) {
        // Only collect parameters that have annotations
        if (_annotations.isAnnotated(param)) {
          dataSources[param.name] = DataSource.fromParameter(param);
        }
      }
    }

    // 2. Collect from annotated fields and getters
    for (final field in blueprint.fields) {
      if (_annotations.isAnnotated(field)) {
        final ds = DataSource.fromElement(field);
        dataSources[ds.name] = ds;
      }
    }

    for (final accessor in blueprint.accessors) {
      if (accessor.isGetter && _annotations.isAnnotated(accessor)) {
        final ds = DataSource.fromElement(accessor);
        dataSources[ds.name] = ds;
      } else if (accessor.isGetter) {
        // Also check the underlying variable for the accessor
        final variable = accessor.variable;
        if (_annotations.isAnnotated(variable)) {
          final ds = DataSource.fromElement(accessor);
          dataSources[ds.name] = ds;
        }
      }
    }

    // 3. Collect path parameters from hierarchy that are missing in the current leaf
    for (final info in hierarchy.skip(1)) {
      final parentBlueprint = info.element;
      // Check factory
      final parentFactory =
          parentBlueprint.constructors.where((c) => c.isFactory).firstOrNull;
      if (parentFactory != null) {
        for (final param in parentFactory.parameters) {
          if (_annotations.getPathAnnotation(param) != null) {
            final ds = DataSource.fromParameter(param);
            if (!dataSources.containsKey(ds.name)) {
              dataSources[ds.name] = ds;
            }
          }
        }
      }
      // Check fields/getters
      for (final field in parentBlueprint.fields) {
        if (_annotations.getPathAnnotation(field) != null) {
          final ds = DataSource.fromElement(field);
          if (!dataSources.containsKey(ds.name)) {
            dataSources[ds.name] = ds;
          }
        }
      }
      for (final accessor in parentBlueprint.accessors) {
        if (accessor.isGetter &&
            _annotations.getPathAnnotation(accessor) != null) {
          final ds = DataSource.fromElement(accessor);
          if (!dataSources.containsKey(ds.name)) {
            dataSources[ds.name] = ds;
          }
        }
      }
    }

    return dataSources.values.toList();
  }

  void _validatePathParams(
    ClassElement blueprint,
    List<String> allPathParams,
    List<DataSource> dataSources,
  ) {
    final pathDataSources = dataSources.where((ds) => ds.isPath).toList();
    final annotatedParamNames =
        pathDataSources.map((ds) => ds.paramName ?? ds.name).toSet();
    final templateParamNames = allPathParams.toSet();

    // 1. Check for missing @Path annotations
    for (final templateParam in templateParamNames) {
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
      if (!templateParamNames.contains(effectiveName)) {
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
    final extraDataSources = dataSources.where((ds) => ds.isExtra).toList();

    if (extraDataSources.length > 1) {
      throw InvalidGenerationSourceError(
        'Only one @Extra annotation is allowed per route. Found ${extraDataSources.length} @Extra annotations.',
        element: blueprint,
      );
    }
  }
}

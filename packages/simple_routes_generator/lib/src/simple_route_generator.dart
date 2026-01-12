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
    final path = annotation.read('path').stringValue;
    final parentReader = annotation.read('parent');
    final parent = parentReader.isNull ? null : parentReader.typeValue;
    final params = PathParser.parseParams(path);

    // Filter fields and manual getters
    final fields = blueprint.fields.where((f) => !f.isStatic).toList();
    final getters = blueprint.accessors
        .where((a) => a.isGetter && !a.isStatic && !a.isSynthetic)
        .toList();

    // Combined list of "data sources" (fields or manual getters)
    final dataSources = [
      ...fields.map((f) => _DataSource(f.name, f.type, f)),
      ...getters.map((g) => _DataSource(g.name, g.returnType, g)),
    ];

    final library = Library((l) {
      l.body.add(_generateBaseClass(blueprint));
      l.body.add(
        _generateRouteClass(
          blueprint,
          path,
          dataSources.isNotEmpty,
          parent as InterfaceType?,
        ),
      );
      if (dataSources.isNotEmpty) {
        l.body.add(_generateDataClass(blueprint, dataSources, params));
        l.body.add(_generateStateExtension(blueprint, dataSources, params));
      }
    });

    final emitter = DartEmitter();
    return _formatter.format('${library.accept(emitter)}');
  }

  Class _generateBaseClass(ClassElement blueprint) {
    return Class((c) {
      c.name = '_\$${blueprint.name}';
      c.abstract = true;
      c.constructors.add(Constructor((ctor) => ctor.constant = true));
    });
  }

  Class _generateRouteClass(
    ClassElement blueprint,
    String path,
    bool isData,
    InterfaceType? parent,
  ) {
    final name = '${blueprint.name}Route';
    final baseClass = isData
        ? 'SimpleDataRoute<${blueprint.name}Data>'
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

  Class _generateDataClass(
    ClassElement blueprint,
    List<_DataSource> fields,
    List<String> pathParams,
  ) {
    return Class((c) {
      c.name = '${blueprint.name}Data';
      c.extend = refer('SimpleRouteData');

      // Add fields
      for (final field in fields) {
        c.fields.add(
          Field((f) {
            f.name = field.name;
            f.modifier = FieldModifier.final$;
            f.type = refer(field.type.getDisplayString(withNullability: true));
          }),
        );
      }

      // Add constructor
      c.constructors.add(
        Constructor((ctor) {
          ctor.constant = true;
          for (final field in fields) {
            ctor.optionalParameters.add(
              Parameter((p) {
                p.name = field.name;
                p.toThis = true;
                p.required =
                    field.type.nullabilitySuffix == NullabilitySuffix.none;
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
          for (final field in fields) {
            final isPathParam = _isDataPathParam(field, pathParams);
            if (isPathParam) {
              final pathAnnotation = const TypeChecker.fromRuntime(
                Path,
              ).firstAnnotationOf(field.element);
              final paramName =
                  pathAnnotation?.getField('name')?.toStringValue() ??
                  field.name;
              mapValues[paramName] = field.type.isDartCoreString
                  ? refer(field.name)
                  : refer(field.name).property('toString').call([]);
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

          final queryFields = fields.where(
            (f) => !_isDataPathParam(f, pathParams),
          );

          final mapValues = <String, Expression>{};
          for (final field in queryFields) {
            final queryAnnotation = const TypeChecker.fromRuntime(
              Query,
            ).firstAnnotationOf(field.element);
            var queryName = field.name;
            if (queryAnnotation != null) {
              final nameValue = queryAnnotation
                  .getField('name')
                  ?.toStringValue();
              if (nameValue != null) queryName = nameValue;
            }
            if (field.type.isDartCoreString) {
              mapValues[queryName] = refer(field.name);
            } else {
              mapValues[queryName] =
                  field.type.nullabilitySuffix == NullabilitySuffix.none
                  ? refer(field.name).property('toString').call([])
                  : refer(field.name).nullSafeProperty('toString').call([]);
            }
          }
          m.body = literalMap(mapValues).code;
        }),
      );
    });
  }

  Extension _generateStateExtension(
    ClassElement blueprint,
    List<_DataSource> fields,
    List<String> pathParams,
  ) {
    return Extension((e) {
      e.name = '${blueprint.name}StateX';
      e.on = refer('GoRouterState');

      e.methods.add(
        Method((m) {
          final getterName =
              '${blueprint.name[0].toLowerCase()}${blueprint.name.substring(1)}Data';
          m.name = getterName;
          m.returns = refer('${blueprint.name}Data');
          m.type = MethodType.getter;

          final namedArgs = <String, Expression>{};
          for (final field in fields) {
            final pathAnnotation = const TypeChecker.fromRuntime(
              Path,
            ).firstAnnotationOf(field.element);
            final pathParamName = pathAnnotation
                ?.getField('name')
                ?.toStringValue();
            final isPathParam = _isDataPathParam(field, pathParams);

            if (isPathParam) {
              final paramName = pathParamName ?? field.name;
              namedArgs[field.name] = _parseType(
                refer('pathParameters').index(literalString(paramName)),
                field.type,
              );
            } else {
              // Query param
              final queryAnnotation = const TypeChecker.fromRuntime(
                Query,
              ).firstAnnotationOf(field.element);
              var queryName = field.name;
              if (queryAnnotation != null) {
                final nameValue = queryAnnotation
                    .getField('name')
                    ?.toStringValue();
                if (nameValue != null) queryName = nameValue;
              }
              namedArgs[field.name] = _parseType(
                refer(
                  'uri',
                ).property('queryParameters').index(literalString(queryName)),
                field.type,
              );
            }
          }

          m.body = refer('${blueprint.name}Data').call([], namedArgs).code;
        }),
      );
    });
  }

  bool _isDataPathParam(_DataSource field, List<String> pathParams) {
    final pathAnnotation = const TypeChecker.fromRuntime(
      Path,
    ).firstAnnotationOf(field.element);
    if (pathAnnotation != null) {
      return true;
    }
    return pathParams.contains(field.name);
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
}

class _DataSource {
  const _DataSource(this.name, this.type, this.element);

  final String name;
  final DartType type;
  final Element element;
}

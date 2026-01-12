import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:simple_routes_annotations/simple_routes_annotations.dart';
import 'package:source_gen/source_gen.dart';
import 'path_parser.dart';

class SimpleRouteGenerator extends GeneratorForAnnotation<SimpleRouteConfig> {
  final DartFormatter _formatter = DartFormatter();

  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        'SimpleRouteConfig can only be applied to classes.',
        element: element,
      );
    }

    final blueprint = element;
    final path = annotation.read('path').stringValue;
    final params = PathParser.parseParams(path);
    final fields = blueprint.fields.where((f) => !f.isStatic).toList();

    final library = Library((l) {
      l.body.add(_generateRouteClass(blueprint, path, fields.isNotEmpty));
      if (fields.isNotEmpty) {
        l.body.add(_generateDataClass(blueprint, fields, params));
        l.body.add(_generateStateExtension(blueprint, fields, params));
      }
    });

    final emitter = DartEmitter();
    return _formatter.format('${library.accept(emitter)}');
  }

  Class _generateRouteClass(ClassElement blueprint, String path, bool isData) {
    final name = '${blueprint.name}Route';
    final baseClass =
        isData ? 'SimpleDataRoute<${blueprint.name}Data>' : 'SimpleRoute';

    return Class((c) {
      c.name = name;
      c.extend = refer(baseClass);
      c.constructors.add(Constructor((ctor) {
        ctor.constant = true;
        ctor.initializers.add(refer('super').call([literalString(path)]).code);
      }));
    });
  }

  Class _generateDataClass(ClassElement blueprint, List<FieldElement> fields,
      List<String> pathParams) {
    return Class((c) {
      c.name = '${blueprint.name}Data';
      c.extend = refer('SimpleRouteData');

      // Add fields
      for (final field in fields) {
        c.fields.add(Field((f) {
          f.name = field.name;
          f.modifier = FieldModifier.final$;
          f.type = refer(field.type.getDisplayString(withNullability: true));
        }));
      }

      // Add constructor
      c.constructors.add(Constructor((ctor) {
        ctor.constant = true;
        for (final field in fields) {
          ctor.optionalParameters.add(Parameter((p) {
            p.name = field.name;
            p.toThis = true;
            p.required = field.type.nullabilitySuffix == NullabilitySuffix.none;
            p.named = true;
          }));
        }
      }));

      // Override [parameters]
      c.methods.add(Method((m) {
        m.name = 'parameters';
        m.type = MethodType.getter;
        m.annotations.add(refer('override'));
        m.returns = refer('Map<String, String>');

        final mapValues = <String, Expression>{};
        for (final param in pathParams) {
          final field = fields.firstWhere(
            (f) => f.name == param,
            orElse: () => throw InvalidGenerationSourceError(
              'Parameter :$param not found in fields of ${blueprint.name}',
              element: blueprint,
            ),
          );
          mapValues[param] = refer(field.name).property('toString').call([]);
        }
        m.body = literalMap(mapValues).code;
      }));

      // Override [query]
      c.methods.add(Method((m) {
        m.name = 'query';
        m.type = MethodType.getter;
        m.annotations.add(refer('override'));
        m.returns = refer('Map<String, String?>');

        final queryFields = fields.where((f) => !pathParams.contains(f.name));
        final mapValues = <String, Expression>{};
        for (final field in queryFields) {
          final queryAnnotation =
              TypeChecker.fromRuntime(QueryParam).firstAnnotationOf(field);
          var queryName = field.name;
          if (queryAnnotation != null) {
            final nameValue = queryAnnotation.getField('name')?.toStringValue();
            if (nameValue != null) queryName = nameValue;
          }
          mapValues[queryName] =
              refer(field.name).property('toString').call([]);
        }
        m.body = literalMap(mapValues).code;
      }));
    });
  }

  Extension _generateStateExtension(ClassElement blueprint,
      List<FieldElement> fields, List<String> pathParams) {
    return Extension((e) {
      e.name = '${blueprint.name}StateX';
      e.on = refer('GoRouterState');

      e.methods.add(Method((m) {
        final getterName =
            '${blueprint.name[0].toLowerCase()}${blueprint.name.substring(1)}Data';
        m.name = getterName;
        m.returns = refer('${blueprint.name}Data');
        m.type = MethodType.getter;

        final namedArgs = <String, Expression>{};
        for (final field in fields) {
          final isPathParam = pathParams.contains(field.name);
          if (isPathParam) {
            namedArgs[field.name] = _parseType(
              refer('pathParameters').index(literalString(field.name)),
              field.type,
            );
          } else {
            // Query param
            final queryAnnotation =
                TypeChecker.fromRuntime(QueryParam).firstAnnotationOf(field);
            var queryName = field.name;
            if (queryAnnotation != null) {
              final nameValue =
                  queryAnnotation.getField('name')?.toStringValue();
              if (nameValue != null) queryName = nameValue;
            }
            namedArgs[field.name] = _parseType(
              refer('uri')
                  .property('queryParameters')
                  .index(literalString(queryName)),
              field.type,
            );
          }
        }

        m.body = refer('${blueprint.name}Data').call([], namedArgs).code;
      }));
    });
  }

  Expression _parseType(Expression source, DartType type) {
    if (type.isDartCoreString) return source;
    if (type.isDartCoreInt) {
      return refer('int').property('parse').call([source]);
    }
    // TODO: Add more types and error handling for non-parseable types
    return source.property('toString').call([]);
  }
}

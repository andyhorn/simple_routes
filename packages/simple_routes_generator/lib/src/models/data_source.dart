import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:simple_routes_generator/src/models/models.dart';
import 'package:source_gen/source_gen.dart';

/// Represents a data source for route generation.
class DataSource {
  /// Creates a new [DataSource].
  const DataSource({
    required this.name,
    required this.type,
    required this.isPath,
    required this.isQuery,
    required this.isExtra,
    required this.isRequired,
    required this.element,
    this.paramName,
  });

  /// Creates a [DataSource] from a formal parameter element.
  factory DataSource.fromParameter(FormalParameterElement param) {
    const annotations = Annotations();

    final pathAnnotation = annotations.getPathAnnotation(param);
    final queryAnnotation = annotations.getQueryAnnotation(param);
    final extraAnnotation = annotations.getExtraAnnotation(param);

    return DataSource(
      name: param.name!,
      type: param.type,
      isPath: pathAnnotation != null,
      isQuery: queryAnnotation != null,
      isExtra: extraAnnotation != null,
      isRequired: param.isRequiredNamed || !param.isOptional,
      paramName: pathAnnotation?.getField('name')?.toStringValue() ??
          queryAnnotation?.getField('name')?.toStringValue(),
      element: param,
    );
  }

  /// Creates a [DataSource] from a general element.
  factory DataSource.fromElement(Element element) {
    const annotations = Annotations();
    final pathAnnotation = annotations.getPathAnnotation(element);
    final queryAnnotation = annotations.getQueryAnnotation(element);
    final extraAnnotation = annotations.getExtraAnnotation(element);

    final type = switch (element) {
      VariableElement(:final type) => type,
      PropertyAccessorElement(:final returnType) => returnType,
      _ => throw InvalidGenerationSourceError(
          'Unexpected element type: ${element.runtimeType}',
          element: element,
        ),
    };

    return DataSource(
      name: element.name!,
      type: type,
      isPath: pathAnnotation != null,
      isQuery: queryAnnotation != null,
      isExtra: extraAnnotation != null,
      isRequired: type.nullabilitySuffix == NullabilitySuffix.none,
      paramName: pathAnnotation?.getField('name')?.toStringValue() ??
          queryAnnotation?.getField('name')?.toStringValue(),
      element: element,
    );
  }

  /// The name of the data source.
  final String name;

  /// The Dart type of the data source.
  final DartType type;

  /// Whether this is a path parameter.
  final bool isPath;

  /// Whether this is a query parameter.
  final bool isQuery;

  /// Whether this is an extra parameter.
  final bool isExtra;

  /// Whether this parameter is required.
  final bool isRequired;

  /// The custom name for this parameter, if provided.
  final String? paramName;

  /// The element representing this data source.
  final Element element;
}

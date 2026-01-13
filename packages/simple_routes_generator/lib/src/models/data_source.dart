import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:source_gen/source_gen.dart';

import 'models.dart';

class DataSource {
  const DataSource({
    required this.name,
    required this.type,
    required this.isPath,
    required this.isQuery,
    required this.isExtra,
    required this.isRequired,
    this.paramName,
    required this.element,
  });

  factory DataSource.fromParameter(ParameterElement param) {
    const annotations = Annotations();

    final pathAnnotation = annotations.getPathAnnotation(param);
    final queryAnnotation = annotations.getQueryAnnotation(param);
    final extraAnnotation = annotations.getExtraAnnotation(param);

    return DataSource(
      name: param.name,
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

  final String name;
  final DartType type;
  final bool isPath;
  final bool isQuery;
  final bool isExtra;
  final bool isRequired;
  final String? paramName;
  final Element element;
}

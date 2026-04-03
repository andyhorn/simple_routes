import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';

class Annotations {
  const Annotations();

  static const _annotationUrlBase =
      'package:simple_routes_annotations/simple_routes_annotations.dart';

  static const _queryChecker = TypeChecker.fromUrl('$_annotationUrlBase#Query');
  static const _extraChecker = TypeChecker.fromUrl('$_annotationUrlBase#Extra');
  static const _routeChecker = TypeChecker.fromUrl('$_annotationUrlBase#Route');
  static const _pathChecker = TypeChecker.fromUrl('$_annotationUrlBase#Path');

  /// Checks if the element is annotated with any of the supported annotations.
  bool isAnnotated(Element element) {
    return _hasAnnotation(element, _pathChecker) ||
        _hasAnnotation(element, _queryChecker) ||
        _hasAnnotation(element, _extraChecker);
  }

  /// Gets the query annotation for the element.
  DartObject? getQueryAnnotation(Element element) {
    return _getAnnotation(element, _queryChecker);
  }

  /// Gets the extra annotation for the element.
  DartObject? getExtraAnnotation(Element element) {
    return _getAnnotation(element, _extraChecker);
  }

  /// Gets the route annotation for the element.
  DartObject? getRouteAnnotation(Element element) {
    return _getAnnotation(element, _routeChecker);
  }

  /// Gets the path annotation for the element.
  DartObject? getPathAnnotation(Element element) {
    return _getAnnotation(element, _pathChecker);
  }

  DartObject? _getAnnotation(Element element, TypeChecker checker) {
    final annotation = checker.firstAnnotationOf(element);
    if (annotation != null) return annotation;

    if (element is PropertyAccessorElement) {
      final variable = element.variable;
      final varAnnotation = checker.firstAnnotationOf(variable);
      if (varAnnotation != null) return varAnnotation;
    }

    return null;
  }

  bool _hasAnnotation(Element element, TypeChecker checker) {
    return _getAnnotation(element, checker) != null;
  }
}

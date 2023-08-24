import 'package:simple_routes/src/child_route.dart';
import 'package:simple_routes/src/utils.dart';

sealed class PathData {
  const PathData();
}

class AtomicPath extends PathData {
  const AtomicPath.root() : path = '/';
  AtomicPath.from(String? path) : path = path?.replaceAll('/', '') ?? '';

  final String path;
}

class SegmentedPath extends PathData {
  SegmentedPath(List<String> segments)
      : segments = segments.map((s) => s.replaceAll('/', '')).toList();

  final List<String> segments;
}

/// An abstract class to serve as the parent for all routes.
abstract class BaseRoute {
  const BaseRoute(this._pathData);

  final PathData _pathData;

  /// The path for this route. e.g. '/login'.
  String get path => _getPath();

  String get fullPath {
    if (this is ChildRoute) {
      return join([(this as ChildRoute).parent.fullPath, path]);
    }

    return path;
  }

  String _getPath() {
    // get the path String from the path data.
    final path = switch (_pathData) {
      AtomicPath(:final path) => path,
      SegmentedPath(:final segments) => join(segments),
    };

    // if this route is a child but the path contains a slash, remove it.
    if (this is ChildRoute && path.startsWith('/')) {
      return path.substring(1);
    }

    // if this route is NOT a child and the path does NOT contain a slash,
    // add one.
    if (this is! ChildRoute && !path.startsWith('/')) {
      return '/$path';
    }

    return path;
  }
}

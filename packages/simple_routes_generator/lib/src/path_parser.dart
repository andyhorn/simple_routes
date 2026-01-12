class PathParser {
  static final RegExp _paramRegExp = RegExp(r':([a-zA-Z0-9_]+)');

  /// Extracts parameter names from a path template.
  ///
  /// For example, `"/users/:userId/posts/:postId"` returns `["userId", "postId"]`.
  static List<String> parseParams(String path) {
    return _paramRegExp.allMatches(path).map((m) => m.group(1)!).toList();
  }
}

class PathParser {
  /// Extracts parameter names from a path template.
  ///
  /// For example, `"/users/:userId/posts/:postId"` returns `["userId", "postId"]`.
  static List<String> parseParams(String path) {
    final regExp = RegExp(r':([a-zA-Z0-9_]+)');
    return regExp.allMatches(path).map((m) => m.group(1)!).toList();
  }
}

class PathParser {
  /// Extracts parameter names from a path template.
  ///
  /// For example, `"/users/:userId/posts/:postId"` returns `["userId", "postId"]`.
  static List<String> parseParams(String path) {
    // This is a bug in the Dart SDK
    // ignore: deprecated_member_use
    final regExp = RegExp(r':([a-zA-Z0-9_]+)');
    return regExp.allMatches(path).map((m) => m.group(1)!).toList();
  }
}

extension EnumExtensions on Enum {
  /// Get the path template parameter name for this enum value.
  String get prefixed => ':$name';
}

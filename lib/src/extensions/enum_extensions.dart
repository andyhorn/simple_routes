extension EnumExtensions on Enum {
  /// Get the path template parameter name for this enum value.
  /// e.g. `RouteParams.id.prefixed` returns `:id`
  String get prefixed => ':$name';
}

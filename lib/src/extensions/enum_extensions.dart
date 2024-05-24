extension EnumExtensions on Enum {
  /// Get the path template parameter name for this enum value.
  /// e.g. `RouteParams.id.template` returns `:id`
  String get template => ':$name';
}

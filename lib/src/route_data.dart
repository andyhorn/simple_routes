abstract class SimpleRouteData {
  const SimpleRouteData();

  /// Inject path parameters into the route.
  Map<Enum, String> get parameters => const {};

  /// Inject "extra" data into the route.
  Object? get extra => null;

  /// Inject query parameters into the route.
  Map<Enum, String?> get query => const {};
}

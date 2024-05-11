/// A class that contains data to be injected into a route.
/// This can be path parameters, query parameters, or "extra" data, or any
/// combination of the three.
abstract class SimpleRouteData {
  const SimpleRouteData();

  /// Path parameters to be injected into the route.
  ///
  /// ```dart
  /// class MyRouteData extends SimpleRouteData {
  ///   const MyRouteData(this.userId);
  ///
  ///   final String userId;
  ///
  ///   @override
  ///   Map<String, String> get parameters => {
  ///     // The `userId` value will be injected into the path,
  ///     // replacing the `:userId` template parameter.
  ///     'userId': userId,
  ///   };
  /// }
  /// ```
  Map<String, String> get parameters => const {};

  /// Inject "extra" data into the [GoRouterState].
  ///
  /// ```dart
  /// class MyRouteData extends SimpleRouteData {
  ///   const MyRouteData(this.extra);
  ///
  ///   final MyExtraDataClass extra;
  ///
  ///   @override
  ///   MyExtraDataClass get extra => extra;
  /// }
  /// ```
  ///
  /// This data will be stored on `GoRouterState.extra` and can be accessed
  /// directly or by using the `getExtra<T>()` extension method.
  ///
  /// ```dart
  /// final extra = context.getExtra<MyExtraDataClass>();
  /// ```
  Object? get extra => null;

  /// Query parameters to be appended to the route.
  ///
  /// ```dart
  /// class MyRouteData extends SimpleRouteData {
  ///   const MyRouteData(this.redirect);
  ///
  ///   final String? redirect;
  ///
  ///   @override
  ///   Map<String, String?> get query => {
  ///     // The value of `redirect`, if not null, will be
  ///     // appended to the route as a URI-encoded query
  ///     // parameter, using the `redirect` key.
  ///     // e.g. `?redirect=/home`
  ///     'redirect': redirect,
  ///   };
  /// }
  /// ```
  ///
  /// If the value is null or empty, the query parameter will not be appended.
  ///
  /// These values can be accessed directly on the
  /// `GoRouterState.uri.queryParameters` map or by using the
  /// `getQuery()` extension method.
  ///
  /// ```dart
  /// final redirect = context.getQuery('redirect');
  /// ```
  Map<String, String?> get query => const {};
}

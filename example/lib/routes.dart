import 'package:go_router/go_router.dart';
import 'package:simple_routes/simple_routes.dart';

// Simple base route

// Declare your route as a child of [SimpleRoute] or
// [DataRoute] (see more below).
class RootRoute extends SimpleRoute {
  // Use the [root] constructor to signify that this is the root route ('/').
  RootRoute() : super.root();

  // Create static instances of this route and its children to aid in
  // navigation and to reduce the number of instantiations.
  static final RootRoute root = RootRoute();
  static final DashboardRoute dashboard = DashboardRoute();
}

// Simple child route
// Declare your child route as a child of [SimpleRoute] and an implementation
// of the [ChildRoute] interface.
class DashboardRoute extends SimpleRoute implements ChildRoute<RootRoute> {
  // Set the [path] in the super to define the path of this route.
  DashboardRoute() : super('dashboard');

  // override the [path] to define the path of this route.
  // Note: This should be everything that comes _after_ the parent's path,
  // without any leading slash. e.g. 'dashboard'.
  @override
  final String path = 'dashboard';

  // override the [parent] getter to return an instance of the parent route.
  @override
  RootRoute get parent => RootRoute.root;
}

// Simple data route

// Define an enum to use as the path parameter templates for your routes.
enum RouteParams {
  userId,
}

// Define some data for your route as a child of [SimpleRouteData].
class ProfileRouteData extends SimpleRouteData {
  const ProfileRouteData({required this.userId});

  final String userId;

  // Override the [inject] method to define how this data is to be injected into
  // the route path. The [setParam] extension method is extremely useful here.
  @override
  String inject(String path) {
    return path.setParam(RouteParams.userId, userId);
  }
}

// If you find it useful, define a factory class to extract the route data from
// an instance of [GoRouterState].
class ProfileRouteDataFactory extends SimpleRouteDataFactory<ProfileRouteData> {
  const ProfileRouteDataFactory();

  // Override the [fromState] method to create an instance of your data class
  // from the [GoRouterState].
  @override
  ProfileRouteData fromState(GoRouterState state) {
    return ProfileRouteData(
      userId: extractParam(state, RouteParams.userId),
    );
  }

  // Override the [containsData] method to determine if the provided
  // [GoRouterState] contains all the necessary values for your data class.
  // The [containsKey] helper method is extremely useful here.
  @override
  bool containsData(GoRouterState state) {
    return containsKey(state, RouteParams.userId);
  }
}

// Define your route as a child of [DataRoute].
class ProfileRoute extends DataRoute<ProfileRouteData> {
  // Since this is a [DataRoute], the path should contain some dynamic variable,
  // such as a userId. e.g. '/profile/:userId'.
  //
  // Use the [withPrefix] helper method to inject your parameter into the
  // template, and use the [join] constructor to join the path segments
  // together with the appropriate slashes.
  //
  // You could craft this template yourself, but the helper methods are here to
  // minimize the chance of error.
  ProfileRoute() : super.join(['profile', withPrefix(RouteParams.userId)]);

  static final ProfileRoute root = ProfileRoute();
  static final ProfileEditRoute edit = ProfileEditRoute();
}

// Child data route

// Define your route as a child of [DataRoute] with its appropriate data type
// and implement the [ChildRoute] interface.
class ProfileEditRoute extends DataRoute<ProfileRouteData>
    implements ChildRoute<ProfileRoute> {
  ProfileEditRoute() : super('edit');

  // override the [parent] getter to return an instance of this route's parent.
  @override
  ProfileRoute get parent => ProfileRoute.root;
}

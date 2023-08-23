import 'package:go_router/go_router.dart';
import 'package:simple_routes/simple_routes.dart';

// Simple base route

// Declare your route as a child of [SimpleRoute] or
// [DataRoute] (see more below).
class RootRoute extends SimpleRoute {
  const RootRoute();

  // override the [path] to define the path of this route.
  @override
  final String path = '/';
}

// Simple child route
// Declare your child route as a child of [SimpleRoute] and an implementation
// of the [ChildRoute] interface.
class DashboardRoute extends SimpleRoute implements ChildRoute<RootRoute> {
  const DashboardRoute();

  // override the [path] to define the path of this route.
  // Note: This should be everything that comes _after_ the parent's path,
  // without any leading slash. e.g. 'dashboard'.
  @override
  final String path = 'dashboard';

  // override the [parent] getter to return an instance of the parent route.
  @override
  RootRoute get parent => const RootRoute();
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
  const ProfileRoute();

  // override the [path] getter to define the path of this route.
  // since this is a [DataRoute], it should contain some dynamic variable, such
  // as a userId. e.g. '/profile/:userId'.
  //
  // use the [withPrefix] helper method to add the colon prefix to your
  // parameter in the template, and use the [join] method to join the path
  // segments together.
  //
  // you can craft this template yourself, but the helper methods are here to
  // minimize the chance of error.
  @override
  String get path => join(['/profile', withPrefix(RouteParams.userId)]);
}

// Child data route

// Define your route as a child of [DataRoute] with its appropriate data type
// and implement the [ChildRoute] interface.
class ProfileEditRoute extends DataRoute<ProfileRouteData>
    implements ChildRoute<ProfileRoute> {
  const ProfileEditRoute();

  // override the [path] getter with this route's path.
  @override
  String get path => 'edit';

  // override the [parent] getter to return an instance of this route's parent.
  @override
  ProfileRoute get parent => const ProfileRoute();
}

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
  filter,
}

// Define some data for your route as a child of [SimpleRouteData].
class ProfileRouteData extends SimpleRouteData {
  const ProfileRouteData({required this.userId});

  final String userId;

  // Override the [parameters] getter to define the path parameters for this
  // route, using the enum you defined above.
  @override
  Map<String, String> get parameters => {
        RouteParams.userId.name: userId,
      };
}

// Define your route as a child of [DataRoute].
class ProfileRoute extends SimpleDataRoute<ProfileRouteData> {
  const ProfileRoute();

  // Override the [path] getter to define the path of this route.
  // Since this is a [DataRoute], it should contain some dynamic variable, such
  // as a userId. e.g. '/profile/:userId'.
  //
  // Use the `prefixed` property to add the colon (:) prefix to your
  // parameter in the template, and use the [join] method to join the path
  // segments together.
  //
  // You can craft this template yourself, but the extension methods are
  // here to help.
  @override
  String get path => fromSegments([
        'profile',
        RouteParams.userId.template,
      ]);
}

// Child data route

// Define your route as a child of [DataRoute] with its appropriate data type
// and implement the [ChildRoute] interface.
class ProfileEditRoute extends SimpleDataRoute<ProfileRouteData>
    implements ChildRoute<ProfileRoute> {
  const ProfileEditRoute();

  // override the [path] getter with this route's path.
  @override
  String get path => 'edit';

  // override the [parent] getter to return an instance of this route's parent.
  @override
  ProfileRoute get parent => const ProfileRoute();
}

class ProfileEditRouteData extends ProfileRouteData {
  const ProfileEditRouteData({
    required super.userId,
    required this.filter,
  });

  // Define a factory constructor to easily extract the route data from
  // [GoRouterState].
  factory ProfileEditRouteData.fromState(GoRouterState state) {
    return ProfileEditRouteData(
      userId: state.getParam(RouteParams.userId)!,
      filter: state.getQuery(RouteParams.filter),
    );
  }

  final String? filter;

  // Provide an implementation of the [query] getter to define the
  // query parameters for this route.
  @override
  Map<String, String?> get query => {
        RouteParams.filter.name: filter,
      };
}

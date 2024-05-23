import 'package:go_router/go_router.dart';
import 'package:simple_routes/simple_routes.dart';

// Simple base route

// Declare your route as a child of [SimpleRoute].
class RootRoute extends SimpleRoute {
  const RootRoute() : super(SimpleRoute.root);
}

// Simple child route
// Declare your child route and implement the [ChildRoute] interface.
class DashboardRoute extends SimpleRoute implements ChildRoute<RootRoute> {
  const DashboardRoute() : super('dashboard');

  // override the [parent] getter to return an instance of the parent route.
  @override
  RootRoute get parent => const RootRoute();
}

// Simple data route

// Define some data for your route as a child of [SimpleRouteData].
class ProfileRouteData extends SimpleRouteData {
  const ProfileRouteData({required this.userId});

  // Use a factory or named constructor to extract the necessary data from an
  // instance of [GoRouterState]. This encapsulates any validation or parsing
  // logic inside the data class instead of doing it inside the route builder.
  ProfileRouteData.fromState(GoRouterState state)
      : userId = state.pathParameters['userId']!;

  final String userId;

  // Override the [parameters] getter to define the parameters for this route.
  //
  // In this case, we want to inject the [userId] value into the path, replacing
  // `:userId` in the path template.
  @override
  Map<String, String> get parameters => {'userId': userId};
}

// Define your route as a child of [SimpleDataRoute].
class ProfileRoute extends SimpleDataRoute<ProfileRouteData> {
  // Since this is a [SimpleDataRoute], the path should contain some dynamic
  // variable, such as a userId. Make sure to prefix the value with a colon (:),
  // just as you would in your GoRoute definition.
  const ProfileRoute() : super('profile/:userId');
}

// Child data route

// Define your route as a child of [SimpleDataRoute] with its appropriate data
// type and implement the [ChildRoute] interface.
class ProfileEditRoute extends SimpleDataRoute<ProfileRouteData>
    implements ChildRoute<ProfileRoute> {
  const ProfileEditRoute() : super('edit');

  // override the [parent] getter to return an instance of this route's parent.
  @override
  ProfileRoute get parent => const ProfileRoute();
}

class ProfileEditRouteData extends ProfileRouteData {
  const ProfileEditRouteData({
    required super.userId,
  });

  // Define a factory or named constructor to easily extract the route data
  // from a [GoRouterState].
  factory ProfileEditRouteData.fromState(GoRouterState state) {
    return ProfileEditRouteData(
      userId: state.pathParameters['userId']!,
    );
  }
}

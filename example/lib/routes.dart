// ignore_for_file: slash_for_doc_comments

import 'package:go_router/go_router.dart';
import 'package:simple_routes/simple_routes.dart';

/*** Basic Route Example ***/

// Declare a route class as a child of [SimpleRoute] and pass its "path" to
// the `super` constructor.
//
// In this example, we're using the constant `SimpleRoute.root` value, which is
// a forward slash ('/').
class RootRoute extends SimpleRoute {
  const RootRoute() : super(SimpleRoute.root);
}

/*** Basic Child Route Example ***/

// Declare a route class, extending [SimpleRoute] and implement the
// [ChildRoute] interface, supplying the parent route's type.
class DashboardRoute extends SimpleRoute implements ChildRoute<RootRoute> {
  // Pass the path of this route to the `super` constructor.
  //
  // Do not add any leading or trailing slashes - just the path segment for
  // this route.
  const DashboardRoute() : super('dashboard');

  // Override the [parent] getter to return an instance of the parent route.
  @override
  RootRoute get parent => const RootRoute();
}

/*** Data Route Example ***/

// Before defining the route class, we must define a data class as a child of
// the [SimpleRouteData] base class.
//
// This class will be responsible for supplying the data needed to generate the
// URL for your route.
//
// In this example, the "profile" route will require a value for the user ID,
// so our data class will need a `userId` property. This value will then be
// used in the [parameters] map to tell SimpleRoutes what and how to inject
// the value.
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
  // ":userId" in the path template.
  @override
  Map<String, String> get parameters => {'userId': userId};
}

// Then, define your route as a child of [SimpleDataRoute], providing the type
// of your data class.
class ProfileRoute extends SimpleDataRoute<ProfileRouteData> {
  // Since this is a [SimpleDataRoute], the path should contain some dynamic
  // variable, such as a userId. Make sure to prefix the value with a colon (:),
  // just as you would in your GoRoute definition.
  const ProfileRoute() : super('profile/:userId');
}

/*** Data Route Child Example ***/

// If you have child routes of a data route, they will also need to be data
// routes. This is because the parent route(s) need their data, even if this
// route does not.
//
// If the child route does not require any unique data of its own, simply extend
// the [SimpleDataRoute] base class with the data type of its parent.
class ProfileEditRoute extends SimpleDataRoute<ProfileRouteData>
    implements ChildRoute<ProfileRoute> {
  const ProfileEditRoute() : super('edit');

  // override the [parent] getter to return an instance of this route's parent.
  @override
  ProfileRoute get parent => const ProfileRoute();
}

// If, however, your child route requires its own data, such as a path parameter
// or query params, you will need to create a new route data class. You can
// create an entirely new route data class OR you can extend the parent's route
// data class.
class AdditionalRouteData extends ProfileRouteData {
  const AdditionalRouteData({
    // Make sure to provide any data needed by the parent route(s).
    required super.userId,
    this.queryValue,
  });

  AdditionalRouteData.fromState(GoRouterState state)
      : queryValue = state.uri.queryParameters['queryName'],
        super(userId: state.pathParameters['userId']!);

  final String? queryValue;

  // If you don't need to add any parameters, you can get away with not
  // overriding the parameters. Since we're extending the parent's route data
  // class and providing it with its data, it will properly inject the
  // parameters.
  //
  // @override
  // Map<String, String> get parameters => {
  //   'userId': userId,
  // };

  // Supply the data unique to this route. For example, an optional query
  // param. If the value is null, it will not be added to the URL.
  //
  // All query parameter values are URL encoded.
  @override
  Map<String, String?> get query => {
        'queryName': queryValue,
      };
}

class AdditionalDataRoute extends SimpleDataRoute<AdditionalRouteData>
    implements ChildRoute<ProfileRoute> {
  const AdditionalDataRoute() : super('additional');

  @override
  ProfileRoute get parent => const ProfileRoute();
}

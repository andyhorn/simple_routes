// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routes.dart';

// **************************************************************************
// SimpleRouteGenerator
// **************************************************************************

class RootRoute extends SimpleRoute {
  const RootRoute() : super('/');
}

class DashboardRoute extends SimpleRoute {
  const DashboardRoute() : super('dashboard');
}

class ProfileRouteData implements SimpleRouteData {
  const ProfileRouteData({required this.id});

  factory ProfileRouteData.fromState(GoRouterState state) =>
      ProfileRouteData(id: state.pathParameters['userId']!);

  final String id;

  @override
  Map<String, String> get parameters => {'userId': id};

  @override
  Map<String, String?> get query => {};
}

class ProfileRoute extends SimpleDataRoute<ProfileRouteData> {
  const ProfileRoute() : super('profile/:userId');
}

class ProfileEditRouteData implements SimpleRouteData {
  const ProfileEditRouteData({required this.id});

  factory ProfileEditRouteData.fromState(GoRouterState state) =>
      ProfileEditRouteData(id: state.pathParameters['userId']!);

  final String id;

  @override
  Map<String, String> get parameters => {'userId': id};

  @override
  Map<String, String?> get query => {};
}

class ProfileEditRoute extends SimpleDataRoute<ProfileEditRouteData>
    implements ChildRoute<ProfileRoute> {
  const ProfileEditRoute() : super('edit');

  @override
  ProfileRoute get parent => const ProfileRoute();
}

class ProfileSettingsRouteData implements SimpleRouteData {
  const ProfileSettingsRouteData({
    this.theme,
    required this.id,
  });

  factory ProfileSettingsRouteData.fromState(GoRouterState state) =>
      ProfileSettingsRouteData(
        theme: state.uri.queryParameters['theme'],
        id: state.pathParameters['userId']!,
      );

  final String? theme;

  final String id;

  @override
  Map<String, String> get parameters => {'userId': id};

  @override
  Map<String, String?> get query => {'theme': theme};
}

class ProfileSettingsRoute extends SimpleDataRoute<ProfileSettingsRouteData>
    implements ChildRoute<ProfileRoute> {
  const ProfileSettingsRoute() : super('settings');

  @override
  ProfileRoute get parent => const ProfileRoute();
}

class DashboardChildRoute extends SimpleRoute
    implements ChildRoute<DashboardRoute> {
  const DashboardChildRoute() : super('child');

  @override
  DashboardRoute get parent => const DashboardRoute();
}

class ProfileDetailsRouteData implements SimpleRouteData {
  const ProfileDetailsRouteData({required this.id});

  factory ProfileDetailsRouteData.fromState(GoRouterState state) =>
      ProfileDetailsRouteData(id: state.pathParameters['userId']!);

  final String id;

  @override
  Map<String, String> get parameters => {'userId': id};

  @override
  Map<String, String?> get query => {};
}

class ProfileDetailsRoute extends SimpleDataRoute<ProfileDetailsRouteData>
    implements ChildRoute<ProfileRoute> {
  const ProfileDetailsRoute() : super('details');

  @override
  ProfileRoute get parent => const ProfileRoute();
}

class AdditionalDataRouteData implements SimpleRouteData {
  const AdditionalDataRouteData({
    this.queryValue,
    required this.id,
  });

  factory AdditionalDataRouteData.fromState(GoRouterState state) =>
      AdditionalDataRouteData(
        queryValue: state.uri.queryParameters['queryName'],
        id: state.pathParameters['userId']!,
      );

  final String? queryValue;

  final String id;

  @override
  Map<String, String> get parameters => {'userId': id};

  @override
  Map<String, String?> get query => {'queryName': queryValue};
}

class AdditionalDataRoute extends SimpleDataRoute<AdditionalDataRouteData>
    implements ChildRoute<ProfileRoute> {
  const AdditionalDataRoute() : super('additional');

  @override
  ProfileRoute get parent => const ProfileRoute();
}

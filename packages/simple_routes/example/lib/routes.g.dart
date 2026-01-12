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

  final String id;

  @override
  Map<String, String> get parameters => {'userId': id};

  @override
  Map<String, String?> get query => {};
}

class ProfileRoute extends SimpleDataRoute<ProfileRouteData> {
  const ProfileRoute() : super('profile/:userId');
}

extension ProfileStateX on GoRouterState {
  ProfileRouteData get profile =>
      ProfileRouteData(id: pathParameters['userId']!);
}

class ProfileEditRouteData implements SimpleRouteData {
  const ProfileEditRouteData({required this.id});

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

extension ProfileEditStateX on GoRouterState {
  ProfileEditRouteData get profileEdit =>
      ProfileEditRouteData(id: pathParameters['userId']!);
}

class ProfileSettingsRouteData implements SimpleRouteData {
  const ProfileSettingsRouteData({
    required this.id,
    this.theme,
  });

  final String id;

  final String? theme;

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

extension ProfileSettingsStateX on GoRouterState {
  ProfileSettingsRouteData get profileSettings => ProfileSettingsRouteData(
        id: pathParameters['userId']!,
        theme: uri.queryParameters['theme'],
      );
}

class DashboardChildRoute extends SimpleRoute
    implements ChildRoute<DashboardRoute> {
  const DashboardChildRoute() : super('child');

  @override
  DashboardRoute get parent => const DashboardRoute();
}

class AdditionalDataRouteData implements SimpleRouteData {
  const AdditionalDataRouteData({
    required this.id,
    this.queryValue,
  });

  final String id;

  final String? queryValue;

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

extension AdditionalDataStateX on GoRouterState {
  AdditionalDataRouteData get additionalData => AdditionalDataRouteData(
        id: pathParameters['userId']!,
        queryValue: uri.queryParameters['queryName'],
      );
}

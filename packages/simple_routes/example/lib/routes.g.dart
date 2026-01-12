// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routes.dart';

// **************************************************************************
// SimpleRouteGenerator
// **************************************************************************

abstract class _$Root {
  const _$Root();
}

class RootRoute extends SimpleRoute {
  const RootRoute() : super('/');
}

abstract class _$Dashboard {
  const _$Dashboard();
}

class DashboardRoute extends SimpleRoute {
  const DashboardRoute() : super('dashboard');
}

abstract class _$Profile {
  const _$Profile();
}

class ProfileRoute extends SimpleDataRoute<ProfileData> {
  const ProfileRoute() : super('profile/:userId');
}

class ProfileData extends SimpleRouteData {
  const ProfileData({required this.id});

  final String id;

  @override
  Map<String, String> get parameters => {'userId': id};

  @override
  Map<String, String?> get query => {};
}

extension ProfileStateX on GoRouterState {
  ProfileData get profileData => ProfileData(id: pathParameters['userId']!);
}

abstract class _$ProfileEdit {
  const _$ProfileEdit();
}

class ProfileEditRoute extends SimpleDataRoute<ProfileEditData>
    implements ChildRoute<ProfileRoute> {
  const ProfileEditRoute() : super('edit');

  @override
  ProfileRoute get parent => const ProfileRoute();
}

class ProfileEditData extends SimpleRouteData {
  const ProfileEditData({required this.id});

  final String id;

  @override
  Map<String, String> get parameters => {'userId': id};

  @override
  Map<String, String?> get query => {};
}

extension ProfileEditStateX on GoRouterState {
  ProfileEditData get profileEditData =>
      ProfileEditData(id: pathParameters['userId']!);
}

abstract class _$ProfileSettings {
  const _$ProfileSettings();
}

class ProfileSettingsRoute extends SimpleDataRoute<ProfileSettingsData>
    implements ChildRoute<ProfileRoute> {
  const ProfileSettingsRoute() : super('settings');

  @override
  ProfileRoute get parent => const ProfileRoute();
}

class ProfileSettingsData extends SimpleRouteData {
  const ProfileSettingsData({required this.id});

  final String id;

  @override
  Map<String, String> get parameters => {'userId': id};

  @override
  Map<String, String?> get query => {};
}

extension ProfileSettingsStateX on GoRouterState {
  ProfileSettingsData get profileSettingsData =>
      ProfileSettingsData(id: pathParameters['userId']!);
}

abstract class _$DashboardChild {
  const _$DashboardChild();
}

class DashboardChildRoute extends SimpleRoute
    implements ChildRoute<DashboardRoute> {
  const DashboardChildRoute() : super('child');

  @override
  DashboardRoute get parent => const DashboardRoute();
}

abstract class _$AdditionalData {
  const _$AdditionalData();
}

class AdditionalDataRoute extends SimpleDataRoute<AdditionalDataData>
    implements ChildRoute<ProfileRoute> {
  const AdditionalDataRoute() : super('additional');

  @override
  ProfileRoute get parent => const ProfileRoute();
}

class AdditionalDataData extends SimpleRouteData {
  const AdditionalDataData({
    this.queryValue,
    required this.id,
  });

  final String? queryValue;

  final String id;

  @override
  Map<String, String> get parameters => {'userId': id};

  @override
  Map<String, String?> get query => {'queryName': queryValue};
}

extension AdditionalDataStateX on GoRouterState {
  AdditionalDataData get additionalDataData => AdditionalDataData(
        queryValue: uri.queryParameters['queryName'],
        id: pathParameters['userId']!,
      );
}

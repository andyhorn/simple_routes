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

class ProfileEditRoute extends SimpleDataRoute<ProfileEditData> {
  const ProfileEditRoute() : super('edit');
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

abstract class _$AdditionalData {
  const _$AdditionalData();
}

class AdditionalDataRoute extends SimpleDataRoute<AdditionalDataData> {
  const AdditionalDataRoute() : super('additional');
}

class AdditionalDataData extends SimpleRouteData {
  const AdditionalDataData({
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

extension AdditionalDataStateX on GoRouterState {
  AdditionalDataData get additionalDataData => AdditionalDataData(
        id: pathParameters['userId']!,
        queryValue: uri.queryParameters['queryName'],
      );
}

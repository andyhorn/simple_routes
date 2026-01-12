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

class ProfileRoute extends SimpleDataRoute<ProfileData> {
  const ProfileRoute() : super('profile/:userId');
}

class ProfileData extends SimpleRouteData {
  const ProfileData({required this.userId});

  final String userId;

  @override
  Map<String, String> get parameters => {'userId': userId.toString()};

  @override
  Map<String, String?> get query => {};
}

extension ProfileStateX on GoRouterState {
  ProfileData get profileData => ProfileData(userId: pathParameters['userId']);
}

class ProfileEditRoute extends SimpleDataRoute<ProfileEditData> {
  const ProfileEditRoute() : super('edit');
}

class ProfileEditData extends SimpleRouteData {
  const ProfileEditData({required this.userId});

  final String userId;

  @override
  Map<String, String> get parameters => {};

  @override
  Map<String, String?> get query => {'userId': userId.toString()};
}

extension ProfileEditStateX on GoRouterState {
  ProfileEditData get profileEditData =>
      ProfileEditData(userId: uri.queryParameters['userId']);
}

class AdditionalDataRoute extends SimpleDataRoute<AdditionalDataData> {
  const AdditionalDataRoute() : super('additional');
}

class AdditionalDataData extends SimpleRouteData {
  const AdditionalDataData({
    required this.userId,
    this.queryValue,
  });

  final String userId;

  final String? queryValue;

  @override
  Map<String, String> get parameters => {};

  @override
  Map<String, String?> get query => {
        'userId': userId.toString(),
        'queryName': queryValue.toString(),
      };
}

extension AdditionalDataStateX on GoRouterState {
  AdditionalDataData get additionalDataData => AdditionalDataData(
        userId: uri.queryParameters['userId'],
        queryValue: uri.queryParameters['queryName'],
      );
}

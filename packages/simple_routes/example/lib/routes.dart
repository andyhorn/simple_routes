import 'package:go_router/go_router.dart';
import 'package:simple_routes/simple_routes.dart';

part 'routes.g.dart';

@Route('/')
class Root extends _$Root {}

@Route('dashboard')
class Dashboard extends _$Dashboard {}

@Route('profile/:userId')
class Profile extends _$Profile {
  const Profile({required this.id});

  @Path('userId')
  final String id;
}

@Route('edit', parent: Profile)
class ProfileEdit extends _$ProfileEdit {}

@Route('settings', parent: Profile)
class ProfileSettings extends _$ProfileSettings {}

@Route('child', parent: Dashboard)
class DashboardChild extends _$DashboardChild {}

@Route('additional', parent: Profile)
class AdditionalData extends _$AdditionalData {
  const AdditionalData({this.queryValue});

  @Query('queryName')
  final String? queryValue;
}

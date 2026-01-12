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
class ProfileEdit extends _$ProfileEdit {
  const ProfileEdit({required this.id});
  @Path('userId')
  final String id;
}

@Route('additional', parent: Profile)
class AdditionalData extends _$AdditionalData {
  const AdditionalData({required this.id, this.queryValue});
  @Path('userId')
  final String id;
  @Query('queryName')
  final String? queryValue;
}

import 'package:go_router/go_router.dart';
import 'package:simple_routes/simple_routes.dart';

part 'routes.g.dart';

@Route('/')
abstract class Root {}

@Route('dashboard')
abstract class Dashboard {}

@Route('profile/:userId')
abstract class Profile {
  @Path('userId')
  String get id;
}

@Route('edit', parent: Profile)
abstract class ProfileEdit {
  @Path('userId')
  String get id;
}

@Route('settings', parent: Profile)
abstract class ProfileSettings {
  @Path('userId')
  String get id;

  @Query()
  String? get theme;
}

@Route('child', parent: Dashboard)
abstract class DashboardChild {}

@Route('additional', parent: Profile)
abstract class AdditionalData {
  @Path('userId')
  String get id;

  @Query('queryName')
  String? get queryValue;
}

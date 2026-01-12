import 'package:go_router/go_router.dart';
import 'package:simple_routes/simple_routes.dart';

part 'routes.g.dart';

@SimpleRouteConfig('/')
class Root extends _$Root {}

@SimpleRouteConfig('dashboard')
class Dashboard extends _$Dashboard {}

@SimpleRouteConfig('profile/:userId')
class Profile extends _$Profile {
  final String userId;
}

@SimpleRouteConfig('edit')
class ProfileEdit extends _$ProfileEdit {
  final String userId;
}

@SimpleRouteConfig('additional')
class AdditionalData extends _$AdditionalData {
  final String userId;
  @QueryParam('queryName')
  final String? queryValue;
}

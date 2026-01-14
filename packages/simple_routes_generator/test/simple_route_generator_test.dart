import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:simple_routes_generator/simple_routes_generator.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';

void main() {
  const annotationsAsset = {
    'simple_routes_annotations|lib/simple_routes_annotations.dart': '''
class Route {
  const Route(this.path, {this.parent});
  final String path;
  final Type? parent;
}

class Query {
  const Query([this.name]);
  final String? name;
}

class Path {
  const Path([this.name]);
  final String? name;
}

class Extra {
  const Extra();
}
''',
  };

  group('SimpleRouteGenerator', () {
    test('generates simple route', () async {
      await testBuilder(
        simpleRouteBuilder(BuilderOptions.empty),
        {
          ...annotationsAsset,
          'a|lib/routes.dart': '''
import 'package:simple_routes_annotations/simple_routes_annotations.dart';

part 'routes.g.dart';

@Route('/')
abstract class Root {}
''',
        },
        outputs: {
          'a|lib/routes.simple_routes.g.part': decodedMatches(
            contains('class RootRoute extends SimpleRoute'),
          ),
        },
      );
    });

    test('generates route with path parameters', () async {
      await testBuilder(
        simpleRouteBuilder(BuilderOptions.empty),
        {
          ...annotationsAsset,
          'a|lib/routes.dart': '''
import 'package:simple_routes_annotations/simple_routes_annotations.dart';

part 'routes.g.dart';

@Route('user/:userId')
abstract class User {
  @Path()
  String get userId;
}
''',
        },
        outputs: {
          'a|lib/routes.simple_routes.g.part': decodedMatches(
            allOf(
              contains(
                'class UserRoute extends SimpleDataRoute<UserRouteData>',
              ),
              contains('class UserRouteData implements SimpleRouteData'),
              contains('final String userId;'),
              contains("state.pathParameters['userId']!"),
            ),
          ),
        },
      );
    });

    test('generates child route with inherited parameters', () async {
      await testBuilder(
        simpleRouteBuilder(BuilderOptions.empty),
        {
          ...annotationsAsset,
          'a|lib/routes.dart': '''
import 'package:simple_routes_annotations/simple_routes_annotations.dart';

part 'routes.g.dart';

@Route('user/:userId')
abstract class User {
  @Path()
  String get userId;
}

@Route('settings', parent: User)
abstract class UserSettings {}
''',
        },
        outputs: {
          'a|lib/routes.simple_routes.g.part': decodedMatches(
            allOf(
              contains(
                'class UserSettingsRoute extends SimpleDataRoute<UserSettingsRouteData>',
              ),
              contains(
                'class UserSettingsRouteData implements SimpleRouteData',
              ),
              contains('final String userId;'),
            ),
          ),
        },
      );
    });

    test('generates route with query parameters', () async {
      await testBuilder(
        simpleRouteBuilder(BuilderOptions.empty),
        {
          ...annotationsAsset,
          'a|lib/routes.dart': '''
import 'package:simple_routes_annotations/simple_routes_annotations.dart';

part 'routes.g.dart';

@Route('search')
abstract class Search {
  @Query('q')
  String get query;
}
''',
        },
        outputs: {
          'a|lib/routes.simple_routes.g.part': decodedMatches(
            allOf(
              contains('class SearchRouteData implements SimpleRouteData'),
              contains('final String query;'),
              contains("state.uri.queryParameters['q']!"),
              contains("'q': query"),
            ),
          ),
        },
      );
    });

    test('generates route with extra data', () async {
      await testBuilder(
        simpleRouteBuilder(BuilderOptions.empty),
        {
          ...annotationsAsset,
          'a|lib/routes.dart': '''
import 'package:simple_routes_annotations/simple_routes_annotations.dart';

part 'routes.g.dart';

class MyExtraData {}

@Route('details')
abstract class Details {
  @Extra()
  MyExtraData get data;
}
''',
        },
        outputs: {
          'a|lib/routes.simple_routes.g.part': decodedMatches(
            allOf(
              contains('class DetailsRouteData implements SimpleRouteData'),
              contains('final MyExtraData data;'),
              contains('Object? get extra => data;'),
            ),
          ),
        },
      );
    });

    group('validation', () {
      test('throws error when path parameter is missing annotation', () async {
        expect(
          () => testBuilder(simpleRouteBuilder(BuilderOptions.empty), {
            ...annotationsAsset,
            'a|lib/routes.dart': '''
import 'package:simple_routes_annotations/simple_routes_annotations.dart';

part 'routes.g.dart';

@Route('user/:userId')
abstract class User {}
''',
          }),
          throwsA(
            isA<InvalidGenerationSourceError>().having(
              (e) => e.message,
              'message',
              contains('Missing @Path annotation for path parameter ":userId"'),
            ),
          ),
        );
      });

      test(
        'throws error when @Path annotation does not match template',
        () async {
          expect(
            () => testBuilder(simpleRouteBuilder(BuilderOptions.empty), {
              ...annotationsAsset,
              'a|lib/routes.dart': '''
import 'package:simple_routes_annotations/simple_routes_annotations.dart';

part 'routes.g.dart';

@Route('user')
abstract class User {
  @Path('userId')
  String get id;
}
''',
            }),
            throwsA(
              isA<InvalidGenerationSourceError>().having(
                (e) => e.message,
                'message',
                contains(
                  '@Path annotation "userId" does not match any parameter in the path template',
                ),
              ),
            ),
          );
        },
      );

      test('throws error when multiple @Extra annotations are present',
          () async {
        expect(
          () => testBuilder(simpleRouteBuilder(BuilderOptions.empty), {
            ...annotationsAsset,
            'a|lib/routes.dart': '''
import 'package:simple_routes_annotations/simple_routes_annotations.dart';

part 'routes.g.dart';

class MyExtraData {}
class AnotherExtraData {}

@Route('details')
abstract class Details {
  @Extra()
  MyExtraData get data1;
  
  @Extra()
  AnotherExtraData get data2;
}
''',
          }),
          throwsA(
            isA<InvalidGenerationSourceError>().having(
              (e) => e.message,
              'message',
              contains('Only one @Extra annotation is allowed per route'),
            ),
          ),
        );
      });
    });

    test('generates route with bool and enum parameters', () async {
      await testBuilder(
        simpleRouteBuilder(BuilderOptions.empty),
        {
          ...annotationsAsset,
          'a|lib/routes.dart': '''
import 'package:simple_routes_annotations/simple_routes_annotations.dart';

part 'routes.g.dart';

enum MyStatus { active, inactive }

@Route('dashboard')
abstract class Dashboard {
  @Query()
  bool get isAdmin;
  
  @Query()
  MyStatus get status;
}
''',
        },
        outputs: {
          'a|lib/routes.simple_routes.g.part': decodedMatches(
            allOf([
              contains('_parseBool('),
              contains('_parseEnum('),
              contains('MyStatus.values'),
              contains(
                  "_parseBool(state.uri.queryParameters['isAdmin'], false)!",),
              contains(
                  "_parseEnum(state.uri.queryParameters['status'], false, MyStatus.values)!",),
              contains("'isAdmin': isAdmin.toString()"),
              contains("'status': status.name"),
              contains('static bool? _parseBool('),
              contains('static Object? _parseEnum('),
            ]),
          ),
        },
      );
    });

    test('generates route with numeric and DateTime parameters', () async {
      await testBuilder(
        simpleRouteBuilder(BuilderOptions.empty),
        {
          ...annotationsAsset,
          'a|lib/routes.dart': '''
import 'package:simple_routes_annotations/simple_routes_annotations.dart';

part 'routes.g.dart';

@Route('metrics')
abstract class Metrics {
  @Query()
  double get value;
  
  @Query()
  DateTime get timestamp;
}
''',
        },
        outputs: {
          'a|lib/routes.simple_routes.g.part': decodedMatches(
            allOf([
              contains('_parseDouble('),
              contains('_parseDateTime('),
              contains(
                  "_parseDouble(state.uri.queryParameters['value'], false)!",),
              contains(
                  "_parseDateTime(state.uri.queryParameters['timestamp'], false)!",),
              contains("'value': value.toString()"),
              contains("'timestamp': timestamp.toIso8601String()"),
              contains('static double? _parseDouble('),
              contains('static DateTime? _parseDateTime('),
            ]),
          ),
        },
      );
    });

    test('ignores unannotated factory constructor parameters', () async {
      await testBuilder(
        simpleRouteBuilder(BuilderOptions.empty),
        {
          ...annotationsAsset,
          'a|lib/routes.dart': '''
import 'package:simple_routes_annotations/simple_routes_annotations.dart';

part 'routes.g.dart';

@Route('user/:userId')
abstract class User {
  const factory User({
    @Path('userId') required String id,
    String? unannotatedParam,
  }) = _User;
}
''',
        },
        outputs: {
          'a|lib/routes.simple_routes.g.part': decodedMatches(
            allOf(
              contains('class UserRouteData implements SimpleRouteData'),
              contains('final String id;'),
              contains("state.pathParameters['userId']"),
              isNot(contains('unannotatedParam')),
            ),
          ),
        },
      );
    });

    test('generates route with nullable query parameters', () async {
      await testBuilder(
        simpleRouteBuilder(BuilderOptions.empty),
        {
          ...annotationsAsset,
          'a|lib/routes.dart': '''
import 'package:simple_routes_annotations/simple_routes_annotations.dart';

part 'routes.g.dart';

@Route('search')
abstract class Search {
  @Query()
  String? get query;
  
  @Query('page')
  int? get pageNumber;
}
''',
        },
        outputs: {
          'a|lib/routes.simple_routes.g.part': decodedMatches(
            allOf(
              contains('class SearchRouteData implements SimpleRouteData'),
              contains('final String? query;'),
              contains('final int? pageNumber;'),
              contains('_parseInt('),
              contains('true'), // isNullable
            ),
          ),
        },
      );
    });

    test('generates route with custom parameter names', () async {
      await testBuilder(
        simpleRouteBuilder(BuilderOptions.empty),
        {
          ...annotationsAsset,
          'a|lib/routes.dart': '''
import 'package:simple_routes_annotations/simple_routes_annotations.dart';

part 'routes.g.dart';

@Route('user/:userId/posts/:postId')
abstract class Post {
  @Path('userId')
  String get user;
  
  @Path('postId')
  String get post;
  
  @Query('q')
  String? get searchQuery;
}
''',
        },
        outputs: {
          'a|lib/routes.simple_routes.g.part': decodedMatches(
            allOf(
              contains('final String user;'),
              contains('final String post;'),
              contains("state.pathParameters['userId']"),
              contains("state.pathParameters['postId']"),
              contains("state.uri.queryParameters['q']"),
            ),
          ),
        },
      );
    });

    test('generates route with multiple path and query parameters', () async {
      await testBuilder(
        simpleRouteBuilder(BuilderOptions.empty),
        {
          ...annotationsAsset,
          'a|lib/routes.dart': '''
import 'package:simple_routes_annotations/simple_routes_annotations.dart';

part 'routes.g.dart';

@Route('users/:userId/posts/:postId/comments/:commentId')
abstract class Comment {
  @Path()
  String get userId;
  
  @Path()
  String get postId;
  
  @Path()
  String get commentId;
  
  @Query()
  String? get sort;
  
  @Query()
  int? get limit;
}
''',
        },
        outputs: {
          'a|lib/routes.simple_routes.g.part': decodedMatches(
            allOf(
              contains('final String userId;'),
              contains('final String postId;'),
              contains('final String commentId;'),
              contains('final String? sort;'),
              contains('final int? limit;'),
            ),
          ),
        },
      );
    });

    test('generates route with combined path, query, and extra', () async {
      await testBuilder(
        simpleRouteBuilder(BuilderOptions.empty),
        {
          ...annotationsAsset,
          'a|lib/routes.dart': '''
import 'package:simple_routes_annotations/simple_routes_annotations.dart';

part 'routes.g.dart';

class NavigationData {}

@Route('user/:userId')
abstract class UserProfile {
  @Path()
  String get userId;
  
  @Query()
  String? get tab;
  
  @Extra()
  NavigationData get navData;
}
''',
        },
        outputs: {
          'a|lib/routes.simple_routes.g.part': decodedMatches(
            allOf(
              contains('final String userId;'),
              contains('final String? tab;'),
              contains('final NavigationData navData;'),
              contains('Object? get extra => navData;'),
            ),
          ),
        },
      );
    });

    test('generates route with int and num types', () async {
      await testBuilder(
        simpleRouteBuilder(BuilderOptions.empty),
        {
          ...annotationsAsset,
          'a|lib/routes.dart': '''
import 'package:simple_routes_annotations/simple_routes_annotations.dart';

part 'routes.g.dart';

@Route('api')
abstract class Api {
  @Query()
  int get page;
  
  @Query()
  num get count;
}
''',
        },
        outputs: {
          'a|lib/routes.simple_routes.g.part': decodedMatches(
            allOf(
              contains('_parseInt('),
              contains('_parseNum('),
              contains("_parseInt(state.uri.queryParameters['page'], false)!"),
              contains("_parseNum(state.uri.queryParameters['count'], false)!"),
              contains('static int? _parseInt('),
              contains('static num? _parseNum('),
            ),
          ),
        },
      );
    });

    test('generates route with nullable enum and DateTime', () async {
      await testBuilder(
        simpleRouteBuilder(BuilderOptions.empty),
        {
          ...annotationsAsset,
          'a|lib/routes.dart': '''
import 'package:simple_routes_annotations/simple_routes_annotations.dart';

part 'routes.g.dart';

enum Status { active, inactive }

@Route('dashboard')
abstract class Dashboard {
  @Query()
  Status? get status;
  
  @Query()
  DateTime? get updated;
}
''',
        },
        outputs: {
          'a|lib/routes.simple_routes.g.part': decodedMatches(
            allOf(
              contains('final Status? status;'),
              contains('final DateTime? updated;'),
              contains('_parseEnum('),
              contains('_parseDateTime('),
              contains('true'), // isNullable
            ),
          ),
        },
      );
    });

    test('generates route with field-based annotations', () async {
      await testBuilder(
        simpleRouteBuilder(BuilderOptions.empty),
        {
          ...annotationsAsset,
          'a|lib/routes.dart': '''
import 'package:simple_routes_annotations/simple_routes_annotations.dart';

part 'routes.g.dart';

@Route('user/:userId')
abstract class User {
  @Path()
  String userId;
}
''',
        },
        outputs: {
          'a|lib/routes.simple_routes.g.part': decodedMatches(
            allOf(
              contains('class UserRouteData implements SimpleRouteData'),
              contains('final String userId;'),
            ),
          ),
        },
      );
    });

    test('generates route with factory constructor multiple parameters',
        () async {
      await testBuilder(
        simpleRouteBuilder(BuilderOptions.empty),
        {
          ...annotationsAsset,
          'a|lib/routes.dart': '''
import 'package:simple_routes_annotations/simple_routes_annotations.dart';

part 'routes.g.dart';

@Route('user/:userId/posts/:postId')
abstract class Post {
  const factory Post({
    @Path('userId') required String user,
    @Path('postId') required String post,
    @Query() String? sort,
  }) = _Post;
}
''',
        },
        outputs: {
          'a|lib/routes.simple_routes.g.part': decodedMatches(
            allOf(
              contains('final String user;'),
              contains('final String post;'),
              contains('final String? sort;'),
            ),
          ),
        },
      );
    });

    test('generates deep hierarchy route (3 levels)', () async {
      await testBuilder(
        simpleRouteBuilder(BuilderOptions.empty),
        {
          ...annotationsAsset,
          'a|lib/routes.dart': '''
import 'package:simple_routes_annotations/simple_routes_annotations.dart';

part 'routes.g.dart';

@Route('user/:userId')
abstract class User {
  @Path()
  String get userId;
}

@Route('posts/:postId', parent: User)
abstract class Post {
  @Path()
  String get postId;
}

@Route('comments', parent: Post)
abstract class Comments {}
''',
        },
        outputs: {
          'a|lib/routes.simple_routes.g.part': decodedMatches(
            allOf(
              contains('class CommentsRouteData implements SimpleRouteData'),
              contains('final String userId;'),
              contains('final String postId;'),
              contains("state.pathParameters['userId']!"),
              contains("state.pathParameters['postId']!"),
            ),
          ),
        },
      );
    });

    test('generates route with only query parameters', () async {
      await testBuilder(
        simpleRouteBuilder(BuilderOptions.empty),
        {
          ...annotationsAsset,
          'a|lib/routes.dart': '''
import 'package:simple_routes_annotations/simple_routes_annotations.dart';

part 'routes.g.dart';

@Route('search')
abstract class Search {
  @Query()
  String get query;
  
  @Query()
  int? get page;
}
''',
        },
        outputs: {
          'a|lib/routes.simple_routes.g.part': decodedMatches(
            allOf(
              contains('class SearchRouteData implements SimpleRouteData'),
              contains('final String query;'),
              contains('final int? page;'),
              contains('Map<String, String> get parameters => {};'),
            ),
          ),
        },
      );
    });

    test('generates route with only extra data', () async {
      await testBuilder(
        simpleRouteBuilder(BuilderOptions.empty),
        {
          ...annotationsAsset,
          'a|lib/routes.dart': '''
import 'package:simple_routes_annotations/simple_routes_annotations.dart';

part 'routes.g.dart';

class NavData {}

@Route('home')
abstract class Home {
  @Extra()
  NavData get data;
}
''',
        },
        outputs: {
          'a|lib/routes.simple_routes.g.part': decodedMatches(
            allOf(
              contains('class HomeRouteData implements SimpleRouteData'),
              contains('final NavData data;'),
              contains('Map<String, String> get parameters => {};'),
              contains('Map<String, String?> get query => {};'),
            ),
          ),
        },
      );
    });

    group('edge cases', () {
      test('handles nullable bool correctly', () async {
        await testBuilder(
          simpleRouteBuilder(BuilderOptions.empty),
          {
            ...annotationsAsset,
            'a|lib/routes.dart': '''
import 'package:simple_routes_annotations/simple_routes_annotations.dart';

part 'routes.g.dart';

@Route('settings')
abstract class Settings {
  @Query()
  bool? get enabled;
}
''',
          },
          outputs: {
            'a|lib/routes.simple_routes.g.part': decodedMatches(
              allOf(
                contains('final bool? enabled;'),
                contains('_parseBool('),
                contains('true'), // isNullable
              ),
            ),
          },
        );
      });

      test('handles route with no parent type gracefully', () async {
        await testBuilder(
          simpleRouteBuilder(BuilderOptions.empty),
          {
            ...annotationsAsset,
            'a|lib/routes.dart': '''
import 'package:simple_routes_annotations/simple_routes_annotations.dart';

part 'routes.g.dart';

@Route('user/:userId')
abstract class User {
  @Path()
  String get userId;
}
''',
          },
          outputs: {
            'a|lib/routes.simple_routes.g.part': decodedMatches(
              allOf(
                contains('class UserRoute extends SimpleDataRoute'),
                isNot(contains('ChildRoute')),
                isNot(contains('parent')),
              ),
            ),
          },
        );
      });
    });

    test('generates route with required and optional parameters correctly',
        () async {
      await testBuilder(
        simpleRouteBuilder(BuilderOptions.empty),
        {
          ...annotationsAsset,
          'a|lib/routes.dart': '''
import 'package:simple_routes_annotations/simple_routes_annotations.dart';

part 'routes.g.dart';

@Route('user/:userId')
abstract class User {
  @Path()
  String get userId;
  
  @Query()
  String? get optionalQuery;
}
''',
        },
        outputs: {
          'a|lib/routes.simple_routes.g.part': decodedMatches(
            allOf(
              contains('required this.userId'),
              contains('this.optionalQuery'),
              isNot(contains('required this.optionalQuery')),
            ),
          ),
        },
      );
    });

    test('generates correct fromState factory with all parameter types',
        () async {
      await testBuilder(
        simpleRouteBuilder(BuilderOptions.empty),
        {
          ...annotationsAsset,
          'a|lib/routes.dart': '''
import 'package:simple_routes_annotations/simple_routes_annotations.dart';

part 'routes.g.dart';

enum Status { active }

class ExtraData {}

@Route('test/:id')
abstract class Test {
  @Path()
  String get id;
  
  @Query()
  int? get count;
  
  @Query()
  Status get status;
  
  @Extra()
  ExtraData get extra;
}
''',
        },
        outputs: {
          'a|lib/routes.simple_routes.g.part': decodedMatches(
            allOf(
              contains('factory TestRouteData.fromState'),
              contains("state.pathParameters['id']!"),
              contains("_parseInt(state.uri.queryParameters['count'], true)"),
              contains(
                  "_parseEnum(state.uri.queryParameters['status'], false, Status.values)!",),
              contains('state.extra as ExtraData'),
              contains('_parseInt('),
              contains('_parseEnum('),
            ),
          ),
        },
      );
    });
  });
}

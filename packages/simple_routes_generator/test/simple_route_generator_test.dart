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
            allOf(
              contains("== 'true'"),
              contains(
                "MyStatus.values.byName(state.uri.queryParameters['status']!)",
              ),
              contains("'isAdmin': isAdmin.toString()"),
              contains("'status': status.name"),
            ),
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
            allOf(
              contains("double.parse(state.uri.queryParameters['value']!)"),
              contains(
                "DateTime.parse(state.uri.queryParameters['timestamp']!)",
              ),
              contains("'value': value.toString()"),
              contains("'timestamp': timestamp.toIso8601String()"),
            ),
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
              contains("state.pathParameters['userId']!"),
              isNot(contains('unannotatedParam')),
            ),
          ),
        },
      );
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:simple_routes/simple_routes.dart';

enum TestParams {
  userId,
  paramTwo,
}

class _MockGoRouterState extends Mock implements GoRouterState {}

class _MockUri extends Mock implements Uri {}

void main() {
  group('utils', () {
    group('join', () {
      test('empty', () {
        expect(join([]), '');
      });

      test('single', () {
        expect(join(['a']), 'a');
      });

      test('multiple', () {
        expect(join(['a', 'b', 'c']), 'a/b/c');
      });

      test('with leading slash', () {
        expect(join(['/root', 'child']), '/root/child');
      });
    });

    group('getQueryParams', () {
      group('when empty', () {
        final state = _MockGoRouterState();
        final uri = _MockUri();

        setUp(() {
          when(() => state.uri).thenReturn(uri);
          when(() => uri.queryParameters).thenReturn({});
        });

        test('returns empty map', () {
          expect(getQueryParams(state), {});
        });
      });

      group('when not empty', () {
        final state = _MockGoRouterState();
        final uri = _MockUri();

        setUp(() {
          when(() => state.uri).thenReturn(uri);
          when(() => uri.queryParameters).thenReturn({'key': 'value'});
        });

        test('returns query parameters', () {
          expect(getQueryParams(state), {'key': 'value'});
        });
      });
    });
  });
}

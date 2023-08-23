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

    test('withPrefix', () {
      expect(withPrefix(TestParams.userId), ':userId');
    });

    group('toQuery', () {
      test('empty', () {
        expect(toQuery({}), '');
      });

      test('single', () {
        expect(toQuery({'key': 'value'}), '?key=value');
      });

      test('multiple', () {
        expect(toQuery({'key': 'value', 'key2': 'value2'}),
            '?key=value&key2=value2');
      });

      test('with space', () {
        expect(toQuery({'key': 'value one', 'key2': 'value two'}),
            '?key=value%20one&key2=value%20two');
      });
    });

    group('setParam', () {
      test('replaces template', () {
        expect(':userId'.setParam(TestParams.userId, 'value'), 'value');
      });

      test('does not touch other templates', () {
        expect(':userId'.setParam(TestParams.paramTwo, 'value'), ':userId');
      });
    });

    group('maybeAppendQuery', () {
      test('empty', () {
        expect('path'.maybeAppendQuery(null), 'path');
        expect('path'.maybeAppendQuery({}), 'path');
      });

      test('non-empty', () {
        expect('path'.maybeAppendQuery({'key': 'value'}), 'path?key=value');
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

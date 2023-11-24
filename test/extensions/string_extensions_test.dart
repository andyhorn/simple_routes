import 'package:flutter_test/flutter_test.dart';
import 'package:simple_routes/simple_routes.dart';

enum TestParams {
  testParamOne,
  testParamTwo,
}

void main() {
  group('StringExtensions', () {
    group('#setParam', () {
      test('replaces template', () {
        expect(':testParamOne'.setParam(TestParams.testParamOne, 'value'),
            'value');
      });

      test('does not touch other templates', () {
        expect(
          ':testParamOne/:testParamTwo'
              .setParam(TestParams.testParamOne, 'value'),
          'value/:testParamTwo',
        );
      });
    });

    group('#maybeAppendQuery', () {
      test('does not append empty query', () {
        expect('path'.maybeAppendQuery(null), 'path');
        expect('path'.maybeAppendQuery({}), 'path');
      });

      test('appends query string', () {
        expect('path'.maybeAppendQuery({'key': 'value'}), 'path?key=value');
      });

      test('appends query string to existing query', () {
        expect('path?key=value'.maybeAppendQuery({'key2': 'value2'}),
            'path?key=value&key2=value2');
      });

      test('appends multiple query values', () {
        expect(
          'path'.maybeAppendQuery({
            'key': 'value',
            'key2': 'value2',
          }),
          'path?key=value&key2=value2',
        );
      });
    });
  });

  group('IterableStringExtensions', () {
    group('#toPath', () {
      test('joins strings', () {
        expect(['one', 'two', 'three'].toPath(), 'one/two/three');
      });
    });
  });
}

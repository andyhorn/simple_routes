import 'package:flutter_test/flutter_test.dart';
import 'package:simple_routes/simple_routes.dart';

enum TestParams {
  userId,
  paramTwo,
}

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

    group('setParam', () {
      test('replaces template', () {
        expect(':userId'.setParam(TestParams.userId, 'value'), 'value');
      });

      test('does not touch other templates', () {
        expect(':userId'.setParam(TestParams.paramTwo, 'value'), ':userId');
      });
    });
  });
}

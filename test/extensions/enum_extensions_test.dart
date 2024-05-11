import 'package:flutter_test/flutter_test.dart';
import 'package:simple_routes/simple_routes.dart';

enum TestParams {
  testParamOne,
}

void main() {
  group('EnumExtensions', () {
    group('#template', () {
      test('returns prefixed value', () {
        expect(TestParams.testParamOne.template, ':testParamOne');
      });
    });
  });
}

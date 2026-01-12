import 'package:simple_routes_generator/src/path_parser.dart';
import 'package:test/test.dart';

void main() {
  group('PathParser', () {
    test('extracts single parameter', () {
      expect(PathParser.parseParams('/users/:userId'), ['userId']);
    });

    test('extracts multiple parameters', () {
      expect(
        PathParser.parseParams('/users/:userId/posts/:postId'),
        ['userId', 'postId'],
      );
    });

    test('extracts no parameters', () {
      expect(PathParser.parseParams('/home'), isEmpty);
    });

    test('extracts parameters with underscores and numbers', () {
      expect(
          PathParser.parseParams('/v1/:user_id/:item2'), ['user_id', 'item2']);
    });
  });
}

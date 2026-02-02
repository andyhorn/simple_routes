import 'package:simple_routes_annotations/simple_routes_annotations.dart';
import 'package:test/test.dart';

void main() {
  group('Route', () {
    test('creates with path', () {
      const annotation = Route('/');
      expect(annotation.path, '/');
      expect(annotation.parent, isNull);
    });

    test('creates with path and parent', () {
      const annotation = Route('child', parent: Object);
      expect(annotation.path, 'child');
      expect(annotation.parent, Object);
    });
  });

  group('Path', () {
    test('creates with optional name', () {
      const unnamed = Path();
      const named = Path('userId');
      expect(unnamed.name, isNull);
      expect(named.name, 'userId');
    });
  });

  group('Query', () {
    test('creates with optional name', () {
      const unnamed = Query();
      const named = Query('q');
      expect(unnamed.name, isNull);
      expect(named.name, 'q');
    });
  });

  group('Extra', () {
    test('creates', () {
      const annotation = Extra();
      expect(annotation, isNotNull);
    });
  });
}

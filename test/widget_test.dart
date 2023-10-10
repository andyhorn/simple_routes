import 'package:flutter_test/flutter_test.dart';
import 'package:simple_routes/simple_routes.dart';

import 'models/routes.dart';
import 'models/test_app.dart';

void main() {
  group(SimpleRoute, () {
    group('#isCurrentRoute', () {
      testWidgets('detects root-level route', (widgetTester) async {
        var isCurrentRoute = false;

        await widgetTester.pumpWidget(
          TestApp(
            onPath2Load: (context) {
              isCurrentRoute = const Path2().isCurrentRoute(context);
            },
          ),
        );

        await widgetTester.tap(find.text('Click me'));
        await widgetTester.pump();

        expect(
          isCurrentRoute,
          isTrue,
          reason: 'Path2 is not the current route',
        );
      });

      testWidgets('detects child data route', (widgetTester) async {
        var isPath2Route = false;
        var isCurrentRoute = false;

        await widgetTester.pumpWidget(
          TestApp(
            onDataPathLoad: (context) {
              isPath2Route = const Path2().isCurrentRoute(context);
              isCurrentRoute = const DataPath().isCurrentRoute(context);
            },
          ),
        );

        await widgetTester.tap(find.text('Click me'));
        await widgetTester.pumpAndSettle();
        await widgetTester.tap(find.text('Click me'));
        await widgetTester.pumpAndSettle();

        expect(isCurrentRoute, isTrue, reason: 'DataPath is current route');
        expect(isPath2Route, isFalse, reason: 'Path2 should not be current');
      });
    });

    group('#isAncestor', () {
      testWidgets('is true for a parent route', (widgetTester) async {
        var path2IsAncestor = false;
        var dataPathIsAncestor = false;

        await widgetTester.pumpWidget(
          TestApp(
            onDataPathLoad: (context) {
              path2IsAncestor = const Path2().isAncestor(context);
              dataPathIsAncestor = const DataPath().isAncestor(context);
            },
          ),
        );

        await widgetTester.tap(find.text('Click me'));
        await widgetTester.pumpAndSettle();
        await widgetTester.tap(find.text('Click me'));
        await widgetTester.pumpAndSettle();

        expect(path2IsAncestor, isTrue, reason: 'Path2 is not an ancestor');
        expect(dataPathIsAncestor, isFalse, reason: 'DataPath is an ancestor');
      });
    });
  });
}

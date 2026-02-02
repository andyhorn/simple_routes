import 'package:example/main.dart' show MyApp;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App pumps and shows root content', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    expect(find.text('Root'), findsOneWidget);
  });

  testWidgets('Navigation to dashboard works', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    expect(find.text('Root'), findsOneWidget);

    await tester.tap(find.text('Go to dashboard'));
    await tester.pumpAndSettle();
    expect(find.text('Dashboard'), findsOneWidget);
  });

  testWidgets('Navigation to profile with data works', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Go to profile'));
    await tester.pumpAndSettle();
    expect(find.text('Profile for 123'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockGoRouterState extends Mock implements GoRouterState {}

class MockGoRouter extends Mock implements GoRouter {
  MockGoRouter() {
    when(() => go(
          any(),
          extra: any(named: 'extra'),
        )).thenReturn(null);
    when(() => push(
          any(),
          extra: any(named: 'extra'),
        )).thenAnswer(
      (_) => Future.value(null),
    );
  }
}

class MockGoRouterProvider extends StatelessWidget {
  const MockGoRouterProvider({
    required this.goRouter,
    required this.child,
    Key? key,
  }) : super(key: key);

  final GoRouter goRouter;
  final Widget child;

  @override
  Widget build(BuildContext context) => InheritedGoRouter(
        goRouter: goRouter,
        child: child,
      );
}

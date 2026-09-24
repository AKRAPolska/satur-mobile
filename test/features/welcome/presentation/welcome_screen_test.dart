import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:satur_app/core/theme/satur_theme.dart';
import 'package:satur_app/features/welcome/presentation/welcome_screen.dart';

void main() {
  testWidgets('Welcome shows CTAs; Dołącz navigates; Zaloguj stays', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/welcome',
      routes: [
        GoRoute(
          path: '/welcome',
          builder: (_, _) => const WelcomeScreen(),
        ),
        GoRoute(
          path: '/join-program',
          builder: (_, _) => const Scaffold(
            body: Text('join-destination'),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        theme: SaturTheme.light(),
        routerConfig: router,
      ),
    );

    expect(find.text('Witaj w Satur'), findsOneWidget);
    expect(find.text('Zaloguj się'), findsOneWidget);
    expect(find.text('Dołącz do programu'), findsOneWidget);

    await tester.tap(find.text('Zaloguj się'));
    await tester.pumpAndSettle();
    expect(find.text('Witaj w Satur'), findsOneWidget);
    expect(find.text('join-destination'), findsNothing);

    await tester.tap(find.text('Dołącz do programu'));
    await tester.pumpAndSettle();
    expect(find.text('join-destination'), findsOneWidget);
  });
}

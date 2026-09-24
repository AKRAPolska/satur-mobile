import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:satur_app/core/theme/satur_theme.dart';
import 'package:satur_app/features/join_program/data/stub_join_program_repository.dart';
import 'package:satur_app/features/join_program/domain/join_program.dart';
import 'package:satur_app/features/join_program/presentation/join_program_cubit.dart';
import 'package:satur_app/features/join_program/presentation/join_program_screen.dart';

void main() {
  testWidgets('Join shows form; invalid email shows error; valid succeeds', (
    tester,
  ) async {
    final repository = StubJoinProgramRepository(delay: Duration.zero);

    final router = GoRouter(
      initialLocation: '/join-program',
      routes: [
        GoRoute(
          path: '/welcome',
          builder: (_, _) => const Scaffold(body: Text('welcome')),
        ),
        GoRoute(
          path: '/join-program',
          builder: (_, _) => BlocProvider(
            create: (_) => JoinProgramCubit(JoinProgram(repository)),
            child: const JoinProgramScreen(),
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

    expect(find.textContaining('Dołącz do'), findsOneWidget);
    expect(find.text('Zarejestruj się'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'bad');
    await tester.tap(find.text('Zarejestruj się'));
    await tester.pumpAndSettle();
    expect(find.text('Podaj poprawny adres e-mail'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'ok@firma.pl');
    await tester.tap(find.text('Zarejestruj się'));
    await tester.pumpAndSettle();
    expect(find.text('Zgłoszenie przyjęte'), findsOneWidget);
    expect(repository.lastRequestedEmail?.value, 'ok@firma.pl');
  });
}

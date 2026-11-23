import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satur_app/features/auth/data/memory_session_store.dart';
import 'package:satur_app/features/auth/domain/auth_session.dart';
import 'package:satur_app/features/auth/presentation/account/account_screen.dart';
import 'package:satur_app/features/auth/presentation/session_cubit.dart';

void main() {
  testWidgets('AccountScreen shows logout and email', (tester) async {
    final store = MemorySessionStore();
    await store.save(const AuthSession(token: 't', email: 'user@satur.pl'));
    final sessionCubit = SessionCubit(store);
    await sessionCubit.hydrate();

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: sessionCubit,
          child: const AccountScreen(),
        ),
      ),
    );

    expect(find.text('Moje konto'), findsWidgets);
    expect(find.text('user@satur.pl'), findsOneWidget);
    expect(find.text('Wyloguj się'), findsOneWidget);
  });
}

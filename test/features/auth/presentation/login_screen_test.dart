import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satur_app/core/result/result.dart';
import 'package:satur_app/features/auth/data/memory_session_store.dart';
import 'package:satur_app/features/auth/domain/auth_failure.dart';
import 'package:satur_app/features/auth/domain/auth_repository.dart';
import 'package:satur_app/features/auth/domain/auth_session.dart';
import 'package:satur_app/features/auth/presentation/login/login_cubit.dart';
import 'package:satur_app/features/auth/presentation/login/login_screen.dart';
import 'package:satur_app/features/auth/presentation/session_cubit.dart';

void main() {
  testWidgets('LoginScreen shows email and password fields', (tester) async {
    final store = MemorySessionStore();
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => LoginCubit(
            _NeverAuthRepository(),
            SessionCubit(store),
          ),
          child: const LoginScreen(),
        ),
      ),
    );

    expect(find.text('Zaloguj się'), findsWidgets);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Hasło'), findsOneWidget);
    expect(find.text('Nie pamiętasz hasła?'), findsOneWidget);
  });
}

final class _NeverAuthRepository implements AuthRepository {
  @override
  Future<Result<AuthSession, AuthFailure>> login({
    required String email,
    required String password,
  }) async =>
      const Failure(AuthUnknownFailure());
}

import 'package:flutter_test/flutter_test.dart';
import 'package:satur_app/core/result/result.dart';
import 'package:satur_app/features/auth/data/memory_session_store.dart';
import 'package:satur_app/features/auth/domain/auth_failure.dart';
import 'package:satur_app/features/auth/domain/auth_repository.dart';
import 'package:satur_app/features/auth/domain/auth_session.dart';
import 'package:satur_app/features/auth/presentation/login/login_cubit.dart';
import 'package:satur_app/features/auth/presentation/login/login_state.dart';
import 'package:satur_app/features/auth/presentation/session_cubit.dart';

void main() {
  test('submit success emits success and updates session', () async {
    final store = MemorySessionStore();
    final sessionCubit = SessionCubit(store);
    final cubit = LoginCubit(
      _FakeAuthRepository(
        const Success(AuthSession(token: 't', email: 'a@b.pl')),
      ),
      sessionCubit,
    );

    cubit.emailChanged('a@b.pl');
    cubit.passwordChanged('secret');
    await cubit.submit();

    expect(cubit.state, isA<LoginSuccess>());
    expect(sessionCubit.state?.token, 't');
  });

  test('submit invalid credentials emits failure', () async {
    final store = MemorySessionStore();
    final cubit = LoginCubit(
      _FakeAuthRepository(
        const Failure(AuthInvalidCredentialsFailure()),
      ),
      SessionCubit(store),
    );

    cubit.emailChanged('a@b.pl');
    cubit.passwordChanged('bad');
    await cubit.submit();

    expect(cubit.state, isA<LoginFailureState>());
    expect(
      (cubit.state as LoginFailureState).failure,
      isA<AuthInvalidCredentialsFailure>(),
    );
  });
}

final class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this._result);

  final Result<AuthSession, AuthFailure> _result;

  @override
  Future<Result<AuthSession, AuthFailure>> login({
    required String email,
    required String password,
  }) async =>
      _result;
}

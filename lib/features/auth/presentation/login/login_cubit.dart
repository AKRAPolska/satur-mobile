import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:satur_app/features/auth/domain/auth_repository.dart';
import 'package:satur_app/features/auth/presentation/login/login_state.dart';
import 'package:satur_app/features/auth/presentation/session_cubit.dart';

final class LoginCubit extends Cubit<LoginState> {
  LoginCubit(this._auth, this._session) : super(const LoginIdle());

  final AuthRepository _auth;
  final SessionCubit _session;

  String _email = '';
  String _password = '';

  void emailChanged(String value) {
    _email = value;
    _resetError();
  }

  void passwordChanged(String value) {
    _password = value;
    _resetError();
  }

  void _resetError() {
    if (state is LoginFailureState || state is LoginSuccess) {
      emit(const LoginIdle());
    }
  }

  Future<void> submit() async {
    emit(const LoginSubmitting());
    final result = await _auth.login(email: _email.trim(), password: _password);
    await result.when(
      success: (session) async {
        await _session.setSession(session);
        emit(const LoginSuccess());
      },
      failure: (error) async {
        emit(LoginFailureState(error));
      },
    );
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:satur_app/features/auth/domain/auth_session.dart';
import 'package:satur_app/features/auth/domain/session_store.dart';

final class SessionCubit extends Cubit<AuthSession?> {
  SessionCubit(this._store) : super(null);

  final SessionStore _store;

  Future<void> hydrate() async {
    emit(await _store.read());
  }

  Future<void> setSession(AuthSession session) async {
    await _store.save(session);
    emit(session);
  }

  Future<void> clear() async {
    await _store.clear();
    emit(null);
  }

  bool get isAuthenticated => state != null;
}

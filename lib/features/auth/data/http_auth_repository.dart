import 'package:satur_app/core/network/api_client.dart';
import 'package:satur_app/core/network/api_failure.dart';
import 'package:satur_app/core/result/result.dart';
import 'package:satur_app/features/auth/domain/auth_failure.dart';
import 'package:satur_app/features/auth/domain/auth_repository.dart';
import 'package:satur_app/features/auth/domain/auth_session.dart';
import 'package:satur_app/features/auth/domain/session_store.dart';

final class HttpAuthRepository implements AuthRepository {
  HttpAuthRepository(this._api, this._sessionStore);

  final ApiClient _api;
  final SessionStore _sessionStore;

  @override
  Future<Result<AuthSession, AuthFailure>> login({
    required String email,
    required String password,
  }) async {
    final result = await _api.post<Map<String, dynamic>>(
      '/api/v2/shop/customers/token',
      body: {'email': email, 'password': password},
      decode: (json) => Map<String, dynamic>.from(json as Map),
    );

    return result.when(
      success: (body) async {
        final token = body['token'] as String?;
        if (token == null || token.isEmpty) {
          return const Failure(AuthUnknownFailure('Missing token'));
        }
        final session = AuthSession(token: token, email: email);
        await _sessionStore.save(session);
        return Success(session);
      },
      failure: (err) async => Failure(_mapFailure(err)),
    );
  }

  AuthFailure _mapFailure(ApiFailure failure) {
    return switch (failure) {
      ApiNetworkFailure(:final message) => AuthNetworkFailure(message),
      ApiTimeoutFailure() => const AuthNetworkFailure('timeout'),
      ApiHttpFailure(:final statusCode) when statusCode == 401 =>
        const AuthInvalidCredentialsFailure(),
      ApiHttpFailure(:final statusCode, :final body) => AuthHttpFailure(
          statusCode: statusCode,
          message: body,
        ),
      ApiParseFailure(:final message) => AuthUnknownFailure(message),
    };
  }
}

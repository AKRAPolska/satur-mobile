import 'package:http/http.dart' as http;

import 'package:satur_app/core/config.dart';
import 'package:satur_app/core/network/api_client.dart';
import 'package:satur_app/features/auth/data/http_auth_repository.dart';
import 'package:satur_app/features/auth/data/secure_session_store.dart';
import 'package:satur_app/features/auth/domain/auth_repository.dart';
import 'package:satur_app/features/auth/domain/session_store.dart';
import 'package:satur_app/features/auth/presentation/session_cubit.dart';
import 'package:satur_app/features/cart/data/http_cart_repository.dart';
import 'package:satur_app/features/cart/data/secure_cart_token_store.dart';
import 'package:satur_app/features/cart/domain/cart_repository.dart';
import 'package:satur_app/features/cart/domain/cart_token_store.dart';
import 'package:satur_app/features/cart/presentation/cart_cubit.dart';
import 'package:satur_app/features/catalog/data/http_catalog_repository.dart';
import 'package:satur_app/features/catalog/domain/catalog_repository.dart';
import 'package:satur_app/features/join_program/data/stub_join_program_repository.dart';
import 'package:satur_app/features/join_program/domain/join_program.dart';
import 'package:satur_app/features/join_program/domain/join_program_repository.dart';

/// Manual composition root. Swap [JoinProgramRepository] when HTTP is ready.
final class AppDependencies {
  AppDependencies._({
    required this.httpClient,
    required this.apiClient,
    required this.sessionStore,
    required this.sessionCubit,
    required this.authRepository,
    required this.cartTokenStore,
    required this.cartRepository,
    required this.cartCubit,
    required this.catalogRepository,
    required this.joinProgramRepository,
    required this.joinProgram,
  });

  final http.Client httpClient;
  final ApiClient apiClient;
  final SessionStore sessionStore;
  final SessionCubit sessionCubit;
  final AuthRepository authRepository;
  final CartTokenStore cartTokenStore;
  final CartRepository cartRepository;
  final CartCubit cartCubit;
  final CatalogRepository catalogRepository;
  final JoinProgramRepository joinProgramRepository;
  final JoinProgram joinProgram;

  factory AppDependencies.create() {
    final httpClient = http.Client();
    final sessionStore = SecureSessionStore();
    final apiClient = ApiClient(
      httpClient: httpClient,
      baseUrl: AppConfig.apiBaseUrl,
      tokenProvider: sessionStore.readToken,
    );
    final cartTokenStore = SecureCartTokenStore();
    final cartRepository = HttpCartRepository(apiClient, cartTokenStore);
    final joinRepo = StubJoinProgramRepository();
    return AppDependencies._(
      httpClient: httpClient,
      apiClient: apiClient,
      sessionStore: sessionStore,
      sessionCubit: SessionCubit(sessionStore),
      authRepository: HttpAuthRepository(apiClient, sessionStore),
      cartTokenStore: cartTokenStore,
      cartRepository: cartRepository,
      cartCubit: CartCubit(cartRepository),
      catalogRepository: HttpCatalogRepository(apiClient),
      joinProgramRepository: joinRepo,
      joinProgram: JoinProgram(joinRepo),
    );
  }
}

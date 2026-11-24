import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:satur_app/app/di.dart';
import 'package:satur_app/features/auth/presentation/account/account_screen.dart';
import 'package:satur_app/features/auth/presentation/login/login_cubit.dart';
import 'package:satur_app/features/auth/presentation/login/login_screen.dart';
import 'package:satur_app/features/cart/presentation/cart_screen.dart';
import 'package:satur_app/features/catalog/presentation/product_detail/product_detail_cubit.dart';
import 'package:satur_app/features/catalog/presentation/product_detail/product_detail_screen.dart';
import 'package:satur_app/features/catalog/presentation/product_list/product_list_cubit.dart';
import 'package:satur_app/features/catalog/presentation/product_list/product_list_screen.dart';
import 'package:satur_app/features/join_program/presentation/join_program_cubit.dart';
import 'package:satur_app/features/join_program/presentation/join_program_screen.dart';
import 'package:satur_app/features/welcome/presentation/welcome_screen.dart';

GoRouter createRouter(AppDependencies deps) {
  return GoRouter(
    initialLocation: '/welcome',
    redirect: (context, state) {
      final onAccount = state.matchedLocation == '/account';
      final loggedIn = deps.sessionCubit.isAuthenticated;
      if (onAccount && !loggedIn) return '/login';
      return null;
    },
    refreshListenable: GoRouterRefreshStream(deps.sessionCubit.stream),
    routes: [
      GoRoute(
        path: '/welcome',
        name: 'welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => BlocProvider(
          create: (_) => LoginCubit(deps.authRepository, deps.sessionCubit),
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/account',
        name: 'account',
        builder: (context, state) => const AccountScreen(),
      ),
      GoRoute(
        path: '/cart',
        name: 'cart',
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: '/join-program',
        name: 'join-program',
        builder: (context, state) => BlocProvider(
          create: (_) => JoinProgramCubit(deps.joinProgram),
          child: const JoinProgramScreen(),
        ),
      ),
      GoRoute(
        path: '/products',
        name: 'products',
        builder: (context, state) => BlocProvider(
          create: (_) => ProductListCubit(deps.catalogRepository),
          child: const ProductListScreen(),
        ),
      ),
      GoRoute(
        path: '/products/:code',
        name: 'product-detail',
        builder: (context, state) {
          final code = state.pathParameters['code']!;
          return BlocProvider(
            create: (_) => ProductDetailCubit(
              deps.catalogRepository,
              code: code,
            ),
            child: const ProductDetailScreen(),
          );
        },
      ),
    ],
  );
}

final class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

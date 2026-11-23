import 'package:satur_app/app/package:flutter_bloc/flutter_bloc.dart';
import 'package:satur_app/app/package:go_router/go_router.dart';

import 'package:satur_app/app/package:satur_app/features/catalog/presentation/product_detail_cubit.dart';
import 'package:satur_app/app/package:satur_app/features/catalog/presentation/product_detail_screen.dart';
import 'package:satur_app/app/package:satur_app/features/catalog/presentation/product_list_cubit.dart';
import 'package:satur_app/app/package:satur_app/features/catalog/presentation/product_list_screen.dart';
import 'package:satur_app/app/package:satur_app/features/join_program/presentation/join_program_cubit.dart';
import 'package:satur_app/app/package:satur_app/features/join_program/presentation/join_program_screen.dart';
import 'package:satur_app/app/package:satur_app/features/welcome/presentation/welcome_screen.dart';
import 'package:satur_app/app/di.dart';

GoRouter createRouter(AppDependencies deps) {
  return GoRouter(
    initialLocation: '/welcome',
    routes: [
      GoRoute(
        path: '/welcome',
        name: 'welcome',
        builder: (context, state) => const WelcomeScreen(),
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

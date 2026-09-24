import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../features/join_program/presentation/join_program_cubit.dart';
import '../features/join_program/presentation/join_program_screen.dart';
import '../features/welcome/presentation/welcome_screen.dart';
import 'di.dart';

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
    ],
  );
}

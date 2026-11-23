import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:satur_app/app/di.dart';
import 'package:satur_app/app/router.dart';
import 'package:satur_app/core/theme/satur_theme.dart';
import 'package:satur_app/features/auth/presentation/session_cubit.dart';

class SaturApp extends StatelessWidget {
  const SaturApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    final router = createRouter(dependencies);
    return BlocProvider<SessionCubit>.value(
      value: dependencies.sessionCubit,
      child: MaterialApp.router(
        title: 'Satur',
        debugShowCheckedModeBanner: false,
        theme: SaturTheme.light(),
        routerConfig: router,
      ),
    );
  }
}

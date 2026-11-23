import 'package:flutter/material.dart';

import 'package:satur_app/core/theme/satur_theme.dart';
import 'package:satur_app/app/di.dart';
import 'package:satur_app/app/router.dart';

class SaturApp extends StatelessWidget {
  const SaturApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    final router = createRouter(dependencies);
    return MaterialApp.router(
      title: 'Satur',
      debugShowCheckedModeBanner: false,
      theme: SaturTheme.light(),
      routerConfig: router,
    );
  }
}

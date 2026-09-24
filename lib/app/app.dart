import 'package:flutter/material.dart';

import '../core/theme/satur_theme.dart';
import 'di.dart';
import 'router.dart';

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

import 'package:flutter/material.dart';

import 'package:satur_app/app/app.dart';
import 'package:satur_app/app/di.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dependencies = AppDependencies.create();
  await dependencies.sessionCubit.hydrate();
  runApp(SaturApp(dependencies: dependencies));
}

import 'package:flutter/material.dart';

import 'package:satur_app/app/app.dart';
import 'package:satur_app/app/di.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final dependencies = AppDependencies.create();
  runApp(SaturApp(dependencies: dependencies));
}

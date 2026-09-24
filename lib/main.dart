import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/di.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final dependencies = AppDependencies.create();
  runApp(SaturApp(dependencies: dependencies));
}

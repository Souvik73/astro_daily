import 'package:flutter/material.dart';

import 'app/astro_daily_app.dart';
import 'core/di/injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();
  runApp(const AstroDailyApp());
}

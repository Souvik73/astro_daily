import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/astro_daily_app.dart';
import 'core/config/auth_environment.dart';
import 'core/di/injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load();

  await Supabase.initialize(
    url: AuthEnvironment.supabaseUrl,
    anonKey: AuthEnvironment.supabaseAnonKey,
  );
  await initDependencies();
  runApp(const AstroDailyApp());
}

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/astro_daily_app.dart';
import 'core/config/auth_environment.dart';
import 'core/config/firebase_options.dart';
import 'core/di/injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load();

  await Supabase.initialize(
    url: AuthEnvironment.supabaseUrl,
    anonKey: AuthEnvironment.supabaseAnonKey,
  );
  await MobileAds.instance.initialize();
  await _initializeFirebase();
  await initDependencies();
  runApp(const AstroDailyApp());
}

/// No-op until a real Firebase project's values are set in .env — push
/// notifications degrade to "unavailable" rather than the app crashing.
Future<void> _initializeFirebase() async {
  if (!AuthEnvironment.firebaseConfigured) {
    return;
  }
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (error) {
    debugPrint('Firebase initialization failed: $error');
  }
}

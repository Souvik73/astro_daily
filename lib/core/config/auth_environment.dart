import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthEnvironment {
  const AuthEnvironment._();

  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  static String get googleServerClientId =>
      dotenv.env['GOOGLE_SERVER_CLIENT_ID'] ?? '';
  static String get googleIosClientId =>
      dotenv.env['GOOGLE_IOS_CLIENT_ID'] ?? '';
  static String get appleWebRedirectUrl =>
      dotenv.env['APPLE_WEB_REDIRECT_URL'] ?? '';
  static String get appleWebClientId =>
      dotenv.env['APPLE_WEB_CLIENT_ID'] ?? '';
}
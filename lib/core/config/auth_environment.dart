import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthEnvironment {
  const AuthEnvironment._();

  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  static String get googleServerClientId =>
      dotenv.env['GOOGLE_SERVER_CLIENT_ID'] ?? '';
  static String get googleIosClientId =>
      dotenv.env['GOOGLE_IOS_CLIENT_ID'] ?? '';
  static bool get googleMacosSignInEnabled =>
      _readBool(dotenv.env['GOOGLE_MACOS_SIGN_IN_ENABLED']);
  static String get appleWebRedirectUrl =>
      dotenv.env['APPLE_WEB_REDIRECT_URL'] ?? '';
  static String get appleWebClientId => dotenv.env['APPLE_WEB_CLIENT_ID'] ?? '';
  static bool get supabaseProfileTablesEnabled =>
      _readBool(dotenv.env['SUPABASE_PROFILE_TABLES_ENABLED']);
  static bool get appleSignInEnabled =>
      _readBool(dotenv.env['APPLE_SIGN_IN_ENABLED']);

  static bool _readBool(String? value) {
    if (value == null) {
      return false;
    }

    switch (value.trim().toLowerCase()) {
      case 'true':
      case '1':
      case 'yes':
      case 'on':
        return true;
      default:
        return false;
    }
  }
}

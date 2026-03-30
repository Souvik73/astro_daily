class AuthEnvironment {
  const AuthEnvironment._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );
  static const String googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
  );
  static const String appleWebRedirectUrl = String.fromEnvironment(
    'APPLE_WEB_REDIRECT_URL',
  );
  static const String appleWebClientId = String.fromEnvironment(
    'APPLE_WEB_CLIENT_ID',
  );
}
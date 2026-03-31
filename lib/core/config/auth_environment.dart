class AuthEnvironment {
  const AuthEnvironment._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://iyanziehbldtysjttrht.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml5YW56aWVoYmxkdHlzanR0cmh0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ3MDEwNjksImV4cCI6MjA5MDI3NzA2OX0.xJ5j6OoMpc8vEpv-4VPs_RH6_agBY9dEWgH8r97rCkY',
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
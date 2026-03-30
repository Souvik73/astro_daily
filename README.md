# astro_daily

Astro Daily is a Flutter application with Supabase-backed authentication.

## Supabase Auth Setup

The auth feature now uses Supabase for:

- email/password sign in on the login screen
- email/password sign up on the signup screen
- native Google sign in with `supabase.auth.signInWithIdToken`
- native Apple sign in with `supabase.auth.signInWithIdToken`

### Dart defines

Provide these at runtime for Supabase and Google sign in:

```bash
flutter run \
	--dart-define=SUPABASE_URL=https://your-project.supabase.co \
	--dart-define=SUPABASE_ANON_KEY=your-supabase-publishable-key \
	--dart-define=GOOGLE_SERVER_CLIENT_ID=your-web-client-id.apps.googleusercontent.com \
	--dart-define=GOOGLE_IOS_CLIENT_ID=your-ios-client-id.apps.googleusercontent.com
```

Optional Apple web fallback defines:

```bash
flutter run \
	--dart-define=APPLE_WEB_CLIENT_ID=your.apple.services.id \
	--dart-define=APPLE_WEB_REDIRECT_URL=https://your-app.example.com/auth/callback
```

### Supabase provider configuration

Configure Google and Apple providers in your Supabase dashboard before testing.

For Google:

- enable the Google provider in Supabase Auth
- register the Google web client ID in Supabase
- if you use multiple client IDs, Supabase expects the web client ID first
- add the Supabase callback URL from the dashboard to Google Cloud

In this app, the Google web client ID is supplied as `GOOGLE_SERVER_CLIENT_ID`
because the native Google sign-in package uses it as the `serverClientId`.

For Apple:

- enable the Apple provider in Supabase Auth
- for native iOS or macOS, enable Sign in with Apple in the Apple Developer portal
- for web or non-Apple fallback flows, configure the Apple Services ID and callback URL in Supabase

### Native app setup still required

This repository does not yet contain the native Google configuration files or URL scheme setup.

You still need to add:

- the iOS reversed client ID or URL scheme in the Xcode project
- the Android Google configuration if your Google Cloud setup requires it
- the Sign in with Apple capability in Xcode for iOS and macOS targets

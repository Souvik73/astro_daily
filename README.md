# astro_daily

Astro Daily is a Flutter application with Supabase-backed authentication.

## Supabase Auth Setup

The auth feature now uses Supabase for:

- email/password sign in on the login screen
- email/password sign up on the signup screen
- native Google sign in with `supabase.auth.signInWithIdToken`
- native Apple sign in with `supabase.auth.signInWithIdToken`

### Dart defines

Provide these in `.env` for Supabase and Google sign in:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-supabase-publishable-key
GOOGLE_SERVER_CLIENT_ID=your-web-client-id.apps.googleusercontent.com
GOOGLE_IOS_CLIENT_ID=your-ios-client-id.apps.googleusercontent.com
GOOGLE_MACOS_SIGN_IN_ENABLED=false
SUPABASE_PROFILE_TABLES_ENABLED=false
```

`GOOGLE_SERVER_CLIENT_ID` is the Google web/server client ID. `GOOGLE_IOS_CLIENT_ID`
is the Apple-platform OAuth client ID used for native Google sign-in on both
iOS and macOS.

`GOOGLE_MACOS_SIGN_IN_ENABLED` defaults to `false` because native Google sign-in
on macOS requires a signed keychain-sharing entitlement. Enable it only after
you configure Apple development signing for the macOS target.

`SUPABASE_PROFILE_TABLES_ENABLED` should stay `false` unless you have created
the optional `public.profiles` and `public.birth_details` tables in Supabase.

Optional Apple visibility flag for the mobile UI in `.env`:

```env
APPLE_SIGN_IN_ENABLED=true
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

Native Google sign-in on iOS requires committed native setup:

- `ios/Runner/Info.plist` must contain the reversed client ID URL scheme for the
  Apple-platform Google OAuth client

macOS support remains opt-in:

- `macos/Runner/Info.plist` already contains the callback URL scheme
- you must enable Apple development signing and add
  `$(AppIdentifierPrefix)com.google.GIDSignIn` to macOS keychain access groups
  before turning on `GOOGLE_MACOS_SIGN_IN_ENABLED`

For Apple:

- enable the Apple provider in Supabase Auth
- for native iOS or macOS, enable Sign in with Apple in the Apple Developer portal
- for web or non-Apple fallback flows, configure the Apple Services ID and callback URL in Supabase
- in this app, the Apple button is hidden unless `APPLE_SIGN_IN_ENABLED=true`

### Native app setup still required

This repository commits the Apple-platform Google callback URL scheme for iOS
and macOS, but macOS Google sign-in is disabled by default until signing is
configured. The repo still does not contain Firebase/Google service plist files
or any additional Android native setup.

You still need to add or verify:

- `GOOGLE_IOS_CLIENT_ID` in `.env` for Apple-platform native Google sign-in
- Apple development signing plus macOS keychain sharing before enabling
  `GOOGLE_MACOS_SIGN_IN_ENABLED=true`
- the Android Google configuration if your Google Cloud setup requires it
- the Sign in with Apple capability in Xcode for iOS and macOS targets

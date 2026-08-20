import 'dart:io' show Platform;

import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthEnvironment {
  const AuthEnvironment._();

  /// Google's official, permanently-stable test ad unit IDs. Used only if
  /// the platform-specific env vars below are unset — safe fallback for
  /// local/dev builds since they always serve test creatives and never earn
  /// real revenue. See: https://developers.google.com/admob/flutter/test-ads
  static const String _testRewardedAdUnitIdAndroid =
      'ca-app-pub-3940256099942544/5224354917';
  static const String _testRewardedAdUnitIdIos =
      'ca-app-pub-3940256099942544/1712485313';

  /// Rewarded ad unit ID for the current platform. Reads
  /// ADMOB_REWARDED_AD_UNIT_ID_ANDROID / _IOS from .env; falls back to
  /// Google's test unit ID when unset.
  static String get admobRewardedAdUnitId {
    final String key = Platform.isIOS
        ? 'ADMOB_REWARDED_AD_UNIT_ID_IOS'
        : 'ADMOB_REWARDED_AD_UNIT_ID_ANDROID';
    final String? value = dotenv.env[key];
    if (value != null && value.isNotEmpty) return value;
    return Platform.isIOS
        ? _testRewardedAdUnitIdIos
        : _testRewardedAdUnitIdAndroid;
  }

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

  /// Set AI_REMOTE_ENABLED=false in .env to fall back to local mock responses.
  /// Defaults to true so new installs use real AI immediately.
  static bool get aiRemoteEnabled {
    final String? value = dotenv.env['AI_REMOTE_ENABLED'];
    return value == null ? true : _readBool(value);
  }

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

import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';

import 'auth_environment.dart';

/// Firebase options sourced from `.env` rather than the usual
/// flutterfire-generated hardcoded file, matching how every other
/// provider config in this app works. No native `google-services.json` /
/// `GoogleService-Info.plist` is required — `Firebase.initializeApp` is
/// always called with explicit [FirebaseOptions] instead.
class DefaultFirebaseOptions {
  const DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform =>
      Platform.isIOS ? ios : android;

  static FirebaseOptions get android => FirebaseOptions(
    apiKey: AuthEnvironment.firebaseApiKeyAndroid,
    appId: AuthEnvironment.firebaseAppIdAndroid,
    messagingSenderId: AuthEnvironment.firebaseMessagingSenderId,
    projectId: AuthEnvironment.firebaseProjectId,
  );

  static FirebaseOptions get ios => FirebaseOptions(
    apiKey: AuthEnvironment.firebaseApiKeyIos,
    appId: AuthEnvironment.firebaseAppIdIos,
    messagingSenderId: AuthEnvironment.firebaseMessagingSenderId,
    projectId: AuthEnvironment.firebaseProjectId,
    iosBundleId: AuthEnvironment.firebaseIosBundleId,
  );
}

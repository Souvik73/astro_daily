import 'package:flutter/foundation.dart';

bool shouldShowGoogleAuthButton({
  required String googleServerClientId,
  required String googleIosClientId,
  required bool googleMacosSignInEnabled,
  required bool isWeb,
  required TargetPlatform targetPlatform,
}) {
  if (isWeb) {
    return true;
  }

  if (googleServerClientId.trim().isEmpty) {
    return false;
  }

  switch (targetPlatform) {
    case TargetPlatform.iOS:
      return googleIosClientId.trim().isNotEmpty;
    case TargetPlatform.macOS:
      return googleMacosSignInEnabled && googleIosClientId.trim().isNotEmpty;
    default:
      return true;
  }
}

bool shouldShowAppleAuthButton({
  required bool appleSignInEnabled,
  required bool isWeb,
  required TargetPlatform targetPlatform,
}) {
  if (!appleSignInEnabled || isWeb) {
    return false;
  }

  return targetPlatform == TargetPlatform.iOS;
}

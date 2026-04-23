import 'package:astro_daily/features/auth/presentation/auth_provider_visibility.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shows Google auth button on Android when server client ID exists', () {
    expect(
      shouldShowGoogleAuthButton(
        googleServerClientId:
            '753966977906-q6h8i8ulm14910kispqhtpvbjjgeutuc.apps.googleusercontent.com',
        googleIosClientId: '',
        googleMacosSignInEnabled: false,
        isWeb: false,
        targetPlatform: TargetPlatform.android,
      ),
      isTrue,
    );
  });

  test('hides Google auth button on iOS without iOS client ID', () {
    expect(
      shouldShowGoogleAuthButton(
        googleServerClientId:
            '753966977906-q6h8i8ulm14910kispqhtpvbjjgeutuc.apps.googleusercontent.com',
        googleIosClientId: '',
        googleMacosSignInEnabled: false,
        isWeb: false,
        targetPlatform: TargetPlatform.iOS,
      ),
      isFalse,
    );
  });

  test('shows Google auth button on iOS when both client IDs exist', () {
    expect(
      shouldShowGoogleAuthButton(
        googleServerClientId:
            '753966977906-q6h8i8ulm14910kispqhtpvbjjgeutuc.apps.googleusercontent.com',
        googleIosClientId: 'ios-client-id.apps.googleusercontent.com',
        googleMacosSignInEnabled: false,
        isWeb: false,
        targetPlatform: TargetPlatform.iOS,
      ),
      isTrue,
    );
  });

  test('hides Google auth button on macOS by default', () {
    expect(
      shouldShowGoogleAuthButton(
        googleServerClientId:
            '753966977906-q6h8i8ulm14910kispqhtpvbjjgeutuc.apps.googleusercontent.com',
        googleIosClientId: 'ios-client-id.apps.googleusercontent.com',
        googleMacosSignInEnabled: false,
        isWeb: false,
        targetPlatform: TargetPlatform.macOS,
      ),
      isFalse,
    );
  });

  test('shows Google auth button on macOS when explicitly enabled', () {
    expect(
      shouldShowGoogleAuthButton(
        googleServerClientId:
            '753966977906-q6h8i8ulm14910kispqhtpvbjjgeutuc.apps.googleusercontent.com',
        googleIosClientId: 'ios-client-id.apps.googleusercontent.com',
        googleMacosSignInEnabled: true,
        isWeb: false,
        targetPlatform: TargetPlatform.macOS,
      ),
      isTrue,
    );
  });

  test('shows Apple auth button only for enabled native iOS', () {
    expect(
      shouldShowAppleAuthButton(
        appleSignInEnabled: true,
        isWeb: false,
        targetPlatform: TargetPlatform.iOS,
      ),
      isTrue,
    );
  });

  test('hides Apple auth button when Apple sign in is disabled', () {
    expect(
      shouldShowAppleAuthButton(
        appleSignInEnabled: false,
        isWeb: false,
        targetPlatform: TargetPlatform.iOS,
      ),
      isFalse,
    );
  });

  test('hides Apple auth button on Android', () {
    expect(
      shouldShowAppleAuthButton(
        appleSignInEnabled: true,
        isWeb: false,
        targetPlatform: TargetPlatform.android,
      ),
      isFalse,
    );
  });

  test('hides Apple auth button on web', () {
    expect(
      shouldShowAppleAuthButton(
        appleSignInEnabled: true,
        isWeb: true,
        targetPlatform: TargetPlatform.iOS,
      ),
      isFalse,
    );
  });
}

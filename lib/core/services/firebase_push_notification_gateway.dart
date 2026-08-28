import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/auth_environment.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import 'contracts.dart';

/// Real implementation of [PushNotificationGateway] backed by Firebase
/// Cloud Messaging. Registers/removes this device's FCM token in the
/// `push_tokens` table directly (RLS-protected, no edge function needed —
/// see the `push_tokens` migration).
///
/// Sending the actual daily notification is a separate, not-yet-built
/// piece (a scheduled server-side job) — this gateway only owns the
/// device-side "does this user want to be notified" registration.
class FirebasePushNotificationGateway implements PushNotificationGateway {
  FirebasePushNotificationGateway({
    required SupabaseClient supabaseClient,
    required AuthRepository authRepository,
  }) : _supabaseClient = supabaseClient,
       _authRepository = authRepository;

  final SupabaseClient _supabaseClient;
  final AuthRepository _authRepository;

  @override
  Future<PushPermissionResult> requestPermissionAndRegister() async {
    if (!AuthEnvironment.firebaseConfigured) {
      return PushPermissionResult.unavailable;
    }

    final user = _authRepository.getCurrentUser();
    if (user == null) {
      return PushPermissionResult.unavailable;
    }

    try {
      final FirebaseMessaging messaging = FirebaseMessaging.instance;
      final NotificationSettings settings = await messaging
          .requestPermission();

      final bool authorized =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      if (!authorized) {
        return PushPermissionResult.denied;
      }

      final String? token = await messaging.getToken();
      if (token == null) {
        return PushPermissionResult.unavailable;
      }

      await _supabaseClient.from('push_tokens').upsert(<String, dynamic>{
        'user_id': user.id,
        'token': token,
        'platform': Platform.isIOS ? 'ios' : 'android',
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'user_id,token');

      return PushPermissionResult.granted;
    } catch (_) {
      return PushPermissionResult.unavailable;
    }
  }

  @override
  Future<void> unregister() async {
    final user = _authRepository.getCurrentUser();
    if (user == null) {
      return;
    }
    try {
      await _supabaseClient
          .from('push_tokens')
          .delete()
          .eq('user_id', user.id);
    } catch (_) {
      // Best-effort — the preference still flips off locally either way,
      // and re-registering later simply upserts a fresh token.
    }
  }
}

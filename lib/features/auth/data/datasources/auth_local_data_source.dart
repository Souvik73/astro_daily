import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../../core/models/subscription_models.dart';
import '../../domain/entities/auth_profile.dart';
import '../../domain/entities/user.dart';

abstract class AuthLocalDataSource {
  Stream<User?> observeAuthState();
  User? getCurrentUser();
  User? getUserById(String userId);
  Future<void> signInWithEmail(String email, String password);
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required AuthProfile profile,
  });
  Future<void> signInWithGoogle({AuthProfile? profile});
  Future<void> signInWithApple({AuthProfile? profile});
  Future<void> signOut();
  Future<void> updateSubscriptionTier(SubscriptionTier tier);
  void dispose();
}

class SupabaseAuthLocalDataSource implements AuthLocalDataSource {
  SupabaseAuthLocalDataSource({
    required supabase.SupabaseClient supabaseClient,
    required GoogleSignIn googleSignIn,
    required String googleServerClientId,
    required String googleIosClientId,
    required String appleWebClientId,
    required String appleWebRedirectUrl,
  }) : _supabaseClient = supabaseClient,
       _googleSignIn = googleSignIn,
       _googleServerClientId = googleServerClientId,
       _googleIosClientId = googleIosClientId,
       _appleWebClientId = appleWebClientId,
       _appleWebRedirectUrl = appleWebRedirectUrl;

  static final DateTime _defaultBirthDate = DateTime(2000, 1, 1);
  static const String _displayNameKey = 'display_name';
  static const String _fullNameKey = 'full_name';
  static const String _zodiacSignKey = 'zodiac_sign';
  static const String _dateOfBirthKey = 'date_of_birth';
  static const String _timeOfBirthKey = 'time_of_birth';
  static const String _placeOfBirthKey = 'place_of_birth';
  static const String _subscriptionTierKey = 'subscription_tier';

  final supabase.SupabaseClient _supabaseClient;
  final GoogleSignIn _googleSignIn;
  final String _googleServerClientId;
  final String _googleIosClientId;
  final String _appleWebClientId;
  final String _appleWebRedirectUrl;
  final Map<String, User> _usersById = <String, User>{};

  Future<void>? _googleInitialization;

  supabase.GoTrueClient get _authClient => _supabaseClient.auth;

  @override
  Stream<User?> observeAuthState() {
    return _authClient.onAuthStateChange.map((supabase.AuthState data) {
      final User? user = _mapSupabaseUser(data.session?.user);
      if (user != null) {
        _usersById[user.id] = user;
      }
      return user;
    });
  }

  @override
  User? getCurrentUser() {
    final User? user = _mapSupabaseUser(_authClient.currentUser);
    if (user != null) {
      _usersById[user.id] = user;
    }
    return user;
  }

  @override
  User? getUserById(String userId) => _usersById[userId];

  @override
  Future<void> signInWithEmail(String email, String password) async {
    await _authClient.signInWithPassword(email: email, password: password);
    await _ensureProfile();
  }

  @override
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required AuthProfile profile,
  }) async {
    await _authClient.signUp(
      email: email,
      password: password,
      data: _metadataFromProfile(profile),
    );
    await _ensureProfile(profile: profile);
  }

  @override
  Future<void> signInWithGoogle({AuthProfile? profile}) async {
    if (kIsWeb) {
      await _authClient.signInWithOAuth(
        supabase.OAuthProvider.google,
        queryParams: <String, String>{
          'access_type': 'offline',
          'prompt': 'consent',
        },
      );
      return;
    }

    await _ensureGoogleInitialized();
    final GoogleSignInAccount googleAccount = await _googleSignIn.authenticate();
    final GoogleSignInClientAuthorization? googleAuthorization =
        await googleAccount.authorizationClient.authorizationForScopes(
          const <String>[],
        );
    final String? idToken = googleAccount.authentication.idToken;

    if (idToken == null) {
      throw const supabase.AuthException(
        'No ID token found from Google sign in.',
      );
    }

    await _authClient.signInWithIdToken(
      provider: supabase.OAuthProvider.google,
      idToken: idToken,
      accessToken: googleAuthorization?.accessToken,
    );
    await _ensureProfile(profile: profile);
  }

  @override
  Future<void> signInWithApple({AuthProfile? profile}) async {
    if (!kIsWeb && await SignInWithApple.isAvailable()) {
      final String rawNonce = _authClient.generateRawNonce();
      final String hashedNonce = sha256
          .convert(utf8.encode(rawNonce))
          .toString();

      final AuthorizationCredentialAppleID credential =
          await SignInWithApple.getAppleIDCredential(
            scopes: const <AppleIDAuthorizationScopes>[
              AppleIDAuthorizationScopes.email,
              AppleIDAuthorizationScopes.fullName,
            ],
            nonce: hashedNonce,
          );

      final String? idToken = credential.identityToken;
      if (idToken == null) {
        throw const supabase.AuthException(
          'Could not find ID token from Apple credential.',
        );
      }

      await _authClient.signInWithIdToken(
        provider: supabase.OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );

      final String appleName = <String?>[
        credential.givenName,
        credential.familyName,
      ].whereType<String>().where((String value) => value.trim().isNotEmpty).join(' ');

      await _ensureProfile(
        profile: profile,
        fallbackDisplayName: appleName.isEmpty ? null : appleName,
      );
      return;
    }

    if (_appleWebClientId.isEmpty || _appleWebRedirectUrl.isEmpty) {
      throw const supabase.AuthException(
        'Apple sign in is not configured for this platform.',
      );
    }

    final String rawNonce = _authClient.generateRawNonce();
    await _authClient.signInWithOAuth(
      supabase.OAuthProvider.apple,
      redirectTo: _appleWebRedirectUrl,
      queryParams: <String, String>{
        'client_id': _appleWebClientId,
        'nonce': rawNonce,
      },
    );
  }

  @override
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _authClient.signOut();
  }

  @override
  Future<void> updateSubscriptionTier(SubscriptionTier tier) async {
    final User? user = getCurrentUser();
    if (user == null) {
      return;
    }

    await _authClient.updateUser(
      supabase.UserAttributes(
        data: <String, dynamic>{
          _subscriptionTierKey: tier.name,
        },
      ),
    );
    final User updated = user.copyWith(tier: tier);
    _usersById[updated.id] = updated;
  }

  @override
  void dispose() {
  }

  Future<void> _ensureGoogleInitialized() {
    if (_googleServerClientId.isEmpty) {
      throw const supabase.AuthException(
        'Missing GOOGLE_SERVER_CLIENT_ID dart define for native Google sign in.',
      );
    }
    if (_requiresIosClientId && _googleIosClientId.isEmpty) {
      throw const supabase.AuthException(
        'Missing GOOGLE_IOS_CLIENT_ID dart define for native Google sign in.',
      );
    }

    return _googleInitialization ??= _googleSignIn.initialize(
      clientId: _requiresIosClientId ? _googleIosClientId : null,
      serverClientId: _googleServerClientId,
    );
  }

  Future<void> _ensureProfile({
    AuthProfile? profile,
    String? fallbackDisplayName,
  }) async {
    final supabaseUser = _authClient.currentUser;
    if (supabaseUser == null) {
      return;
    }

    final Map<String, dynamic> metadata = Map<String, dynamic>.from(
      supabaseUser.userMetadata ?? const <String, dynamic>{},
    );

    final AuthProfile resolvedProfile = profile ??
        AuthProfile(
          displayName: _resolveDisplayName(
            metadata: metadata,
            email: supabaseUser.email,
            fallbackDisplayName: fallbackDisplayName,
          ),
          zodiacSign: _readString(metadata, _zodiacSignKey) ?? 'Aries',
          dateOfBirth:
              _parseDate(_readString(metadata, _dateOfBirthKey)) ??
              _defaultBirthDate,
          timeOfBirth:
              _readString(metadata, _timeOfBirthKey) ?? '06:30 AM',
          placeOfBirth:
              _readString(metadata, _placeOfBirthKey) ?? 'Kolkata, India',
        );

    final Map<String, dynamic> nextMetadata = <String, dynamic>{
      ...metadata,
      ..._metadataFromProfile(resolvedProfile),
      if (!metadata.containsKey(_subscriptionTierKey))
        _subscriptionTierKey: SubscriptionTier.free.name,
    };

    if (!_mapsEqual(metadata, nextMetadata)) {
      await _authClient.updateUser(
        supabase.UserAttributes(data: nextMetadata),
      );
    }

    final User mappedUser = _mapSupabaseUser(_authClient.currentUser)!;
    _usersById[mappedUser.id] = mappedUser;
  }

  User? _mapSupabaseUser(supabase.User? supabaseUser) {
    if (supabaseUser == null) {
      return null;
    }
    final Map<String, dynamic> metadata = Map<String, dynamic>.from(
      supabaseUser.userMetadata ?? const <String, dynamic>{},
    );
    return User(
      id: supabaseUser.id,
      email: supabaseUser.email ?? '',
      displayName: _resolveDisplayName(
        metadata: metadata,
        email: supabaseUser.email,
      ),
      zodiacSign: _readString(metadata, _zodiacSignKey) ?? 'Aries',
      dateOfBirth:
          _parseDate(_readString(metadata, _dateOfBirthKey)) ?? _defaultBirthDate,
      timeOfBirth: _readString(metadata, _timeOfBirthKey) ?? '06:30 AM',
      placeOfBirth: _readString(metadata, _placeOfBirthKey) ?? 'Kolkata, India',
      tier: _parseTier(_readString(metadata, _subscriptionTierKey)),
    );
  }

  Map<String, dynamic> _metadataFromProfile(AuthProfile profile) {
    return <String, dynamic>{
      _displayNameKey: profile.displayName,
      _fullNameKey: profile.displayName,
      _zodiacSignKey: profile.zodiacSign,
      _dateOfBirthKey: profile.dateOfBirth.toIso8601String(),
      _timeOfBirthKey: profile.timeOfBirth,
      _placeOfBirthKey: profile.placeOfBirth,
      _subscriptionTierKey: SubscriptionTier.free.name,
    };
  }

  bool get _requiresIosClientId {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return true;
      default:
        return false;
    }
  }

  String _resolveDisplayName({
    required Map<String, dynamic> metadata,
    required String? email,
    String? fallbackDisplayName,
  }) {
    final String? metadataDisplayName = _readString(metadata, _displayNameKey);
    if (metadataDisplayName != null && metadataDisplayName.trim().isNotEmpty) {
      return metadataDisplayName;
    }
    final String? fullName = _readString(metadata, _fullNameKey);
    if (fullName != null && fullName.trim().isNotEmpty) {
      return fullName;
    }
    if (fallbackDisplayName != null && fallbackDisplayName.trim().isNotEmpty) {
      return fallbackDisplayName.trim();
    }
    final String localPart = (email ?? 'seeker').split('@').first.trim();
    return localPart.isEmpty ? 'Seeker' : localPart;
  }

  String? _readString(Map<String, dynamic> metadata, String key) {
    final Object? value = metadata[key];
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    return null;
  }

  DateTime? _parseDate(String? value) {
    if (value == null) {
      return null;
    }
    return DateTime.tryParse(value);
  }

  SubscriptionTier _parseTier(String? rawTier) {
    return SubscriptionTier.values.firstWhere(
      (SubscriptionTier tier) => tier.name == rawTier,
      orElse: () => SubscriptionTier.free,
    );
  }

  bool _mapsEqual(Map<String, dynamic> left, Map<String, dynamic> right) {
    if (left.length != right.length) {
      return false;
    }
    for (final MapEntry<String, dynamic> entry in left.entries) {
      if (right[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }
}

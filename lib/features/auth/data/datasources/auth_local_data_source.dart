import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../../core/error/failures.dart';
import '../../../../core/models/birth_profile.dart';
import '../../../../core/models/subscription_models.dart';
import 'postgrest_error_utils.dart';
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
  Future<void> completeProfile(AuthProfile profile);
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
    required bool supabaseProfileTablesEnabled,
  }) : _supabaseClient = supabaseClient,
       _googleSignIn = googleSignIn,
       _googleServerClientId = googleServerClientId,
       _googleIosClientId = googleIosClientId,
       _appleWebClientId = appleWebClientId,
       _appleWebRedirectUrl = appleWebRedirectUrl,
       _profilesTableAvailable = supabaseProfileTablesEnabled ? null : false,
       _birthDetailsTableAvailable = supabaseProfileTablesEnabled
           ? null
           : false {
    _authStateSubscription = _authClient.onAuthStateChange.listen((
      supabase.AuthState data,
    ) {
      unawaited(_handleAuthStateChange(data));
    });
    final supabase.User? currentUser = _authClient.currentUser;
    if (currentUser != null) {
      _currentUser = _buildFallbackUser(currentUser);
      _usersById[currentUser.id] = _currentUser!;
      unawaited(_primeCurrentUser(currentUser));
    }
  }

  static const String _profilesTable = 'profiles';
  static const String _birthDetailsTable = 'birth_details';
  static const String _displayNameKey = 'display_name';
  static const String _fullNameKey = 'full_name';
  static const String _pendingProfileSyncKey = 'profile_sync_pending';
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
  final StreamController<User?> _authStateController =
      StreamController<User?>.broadcast();

  Future<void>? _googleInitialization;
  _PendingProfileSeed? _pendingProfileSeed;
  late final StreamSubscription<supabase.AuthState> _authStateSubscription;
  User? _currentUser;
  bool? _profilesTableAvailable;
  bool? _birthDetailsTableAvailable;

  supabase.GoTrueClient get _authClient => _supabaseClient.auth;

  @override
  Stream<User?> observeAuthState() => _authStateController.stream;

  @override
  User? getCurrentUser() => _currentUser;

  @override
  User? getUserById(String userId) => _usersById[userId];

  @override
  Future<void> signInWithEmail(String email, String password) async {
    try {
      await _authClient.signInWithPassword(email: email, password: password);
      final supabase.User? currentUser = _authClient.currentUser;
      if (currentUser != null) {
        await _refreshCurrentUser(currentUser);
      }
    } on Failure {
      rethrow;
    } on supabase.AuthException catch (error) {
      throw AuthFailure(_normalizeAuthMessage(error.message));
    } catch (_) {
      throw const AuthFailure('Unable to sign in right now. Please try again.');
    }
  }

  @override
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required AuthProfile profile,
  }) async {
    _pendingProfileSeed = _PendingProfileSeed(profile: profile);
    try {
      final supabase.AuthResponse response = await _authClient.signUp(
        email: email,
        password: password,
        data: _metadataFromProfile(profile, profileSyncPending: true),
      );
      final supabase.User? currentUser =
          response.user ?? _authClient.currentUser;
      if (response.session != null && currentUser != null) {
        await _persistProfileRecords(currentUser.id, profile);
        await _clearPendingProfileSyncFlag();
        await _refreshCurrentUser(currentUser);
      } else {
        _pendingProfileSeed = null;
      }
    } catch (error) {
      _pendingProfileSeed = null;
      throw _mapWriteFailure(
        error,
        fallbackMessage: 'Unable to create your account right now.',
      );
    }
  }

  @override
  Future<void> signInWithGoogle({AuthProfile? profile}) async {
    _pendingProfileSeed = _PendingProfileSeed(profile: profile);
    try {
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
      final GoogleSignInAccount googleAccount = await _googleSignIn
          .authenticate();
      final String? idToken = googleAccount.authentication.idToken;

      if (idToken == null) {
        throw const supabase.AuthException(
          'No ID token found from Google sign in.',
        );
      }

      // Best-effort access token lookup. We do not require it for Supabase
      // auth (only the ID token is needed) and we never force an additional
      // consent sheet on first-time sign-in, which can race with the
      // Supabase signInWithIdToken call and crash the activity on some
      // Android devices.
      String? accessToken;
      try {
        final GoogleSignInClientAuthorization? cached = await googleAccount
            .authorizationClient
            .authorizationForScopes(const <String>['email', 'profile']);
        accessToken = cached?.accessToken;
      } catch (_) {
        accessToken = null;
      }

      await _authClient.signInWithIdToken(
        provider: supabase.OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      // The onAuthStateChange listener will refresh the current user from
      // the new session, so we deliberately do not call _refreshCurrentUser
      // here. Doing so can race with the listener and any transient
      // PostgREST/metadata error during the first-time user creation would
      // otherwise bubble up as a fatal sign-in failure.
    } catch (error) {
      _pendingProfileSeed = null;
      throw _mapAuthOrWriteFailure(
        error,
        fallbackMessage: 'Unable to continue with Google right now.',
      );
    }
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

      final String appleName =
          <String?>[credential.givenName, credential.familyName]
              .whereType<String>()
              .where((String value) => value.trim().isNotEmpty)
              .join(' ');
      _pendingProfileSeed = _PendingProfileSeed(
        profile: profile,
        fallbackDisplayName: appleName.isEmpty ? null : appleName,
      );
      try {
        await _authClient.signInWithIdToken(
          provider: supabase.OAuthProvider.apple,
          idToken: idToken,
          nonce: rawNonce,
        );
        final supabase.User? currentUser = _authClient.currentUser;
        if (currentUser != null) {
          await _refreshCurrentUser(currentUser);
        }
        return;
      } catch (error) {
        _pendingProfileSeed = null;
        throw _mapAuthOrWriteFailure(
          error,
          fallbackMessage: 'Unable to continue with Apple right now.',
        );
      }
    }

    if (_appleWebClientId.isEmpty || _appleWebRedirectUrl.isEmpty) {
      throw const supabase.AuthException(
        'Apple sign in is not configured for this platform.',
      );
    }

    final String rawNonce = _authClient.generateRawNonce();
    _pendingProfileSeed = _PendingProfileSeed(profile: profile);
    try {
      await _authClient.signInWithOAuth(
        supabase.OAuthProvider.apple,
        redirectTo: _appleWebRedirectUrl,
        queryParams: <String, String>{
          'client_id': _appleWebClientId,
          'nonce': rawNonce,
        },
      );
    } catch (error) {
      _pendingProfileSeed = null;
      throw _mapAuthOrWriteFailure(
        error,
        fallbackMessage: 'Unable to continue with Apple right now.',
      );
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _authClient.signOut();
      _currentUser = null;
      _usersById.clear();
      _authStateController.add(null);
    } on supabase.AuthException catch (error) {
      throw AuthFailure(_normalizeAuthMessage(error.message));
    } catch (_) {
      throw const AuthFailure(
        'Unable to sign out right now. Please try again.',
      );
    }
  }

  @override
  Future<void> completeProfile(AuthProfile profile) async {
    final supabase.User? currentUser = _authClient.currentUser;
    if (currentUser == null) {
      return;
    }

    try {
      await _persistProfileRecords(currentUser.id, profile);
      await _clearPendingProfileSyncFlag();
      await _refreshCurrentUser(
        currentUser,
        explicitDisplayName: profile.displayName,
      );
    } on Failure {
      rethrow;
    } catch (error) {
      throw _mapWriteFailure(
        error,
        fallbackMessage: 'Unable to save your profile right now.',
      );
    }
  }

  @override
  Future<void> updateSubscriptionTier(SubscriptionTier tier) async {
    final User? user = getCurrentUser();
    if (user == null) {
      return;
    }

    try {
      await _authClient.updateUser(
        supabase.UserAttributes(
          data: <String, dynamic>{_subscriptionTierKey: tier.name},
        ),
      );
      final User updated = user.copyWith(tier: tier);
      _currentUser = updated;
      _usersById[updated.id] = updated;
      _authStateController.add(updated);
    } on supabase.AuthException catch (error) {
      throw AuthFailure(_normalizeAuthMessage(error.message));
    } catch (_) {
      throw const DataFailure(
        'Unable to update subscription status right now.',
      );
    }
  }

  @override
  void dispose() {
    _authStateSubscription.cancel();
    _authStateController.close();
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

  Future<void> _handleAuthStateChange(supabase.AuthState data) async {
    final supabase.User? user = data.session?.user;
    if (user == null) {
      _pendingProfileSeed = null;
      _currentUser = null;
      _usersById.clear();
      _authStateController.add(null);
      return;
    }

    try {
      await _refreshCurrentUser(user);
    } catch (error, stackTrace) {
      debugPrint('Failed to refresh auth state: $error');
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'auth_local_data_source',
          context: ErrorDescription('while syncing auth state'),
        ),
      );
      _pendingProfileSeed = null;
      _emitUser(_buildFallbackUser(user));
    }
  }

  Future<void> _primeCurrentUser(supabase.User currentUser) async {
    try {
      await _refreshCurrentUser(currentUser);
    } catch (error, stackTrace) {
      debugPrint('Failed to prime current user: $error');
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'auth_local_data_source',
          context: ErrorDescription('while priming current user'),
        ),
      );
      _pendingProfileSeed = null;
      _emitUser(_buildFallbackUser(currentUser));
    }
  }

  Future<void> _refreshCurrentUser(
    supabase.User supabaseUser, {
    bool emit = true,
    String? explicitDisplayName,
  }) async {
    final User mappedUser = await _buildUser(
      supabaseUser,
      explicitDisplayName: explicitDisplayName,
    );
    _emitUser(mappedUser, emit: emit);
  }

  Future<User> _buildUser(
    supabase.User supabaseUser, {
    String? explicitDisplayName,
  }) async {
    final Map<String, dynamic> metadata = Map<String, dynamic>.from(
      supabaseUser.userMetadata ?? const <String, dynamic>{},
    );
    final _PendingProfileSeed? pendingSeed = _pendingProfileSeed;
    final AuthProfile? pendingProfile = pendingSeed?.profile;
    AuthProfile? resolvedProfile;

    if (pendingProfile != null) {
      resolvedProfile = pendingProfile;
      await _persistProfileRecords(supabaseUser.id, pendingProfile);
      await _clearPendingProfileSyncFlag();
    } else if (_isPendingMetadataSync(metadata)) {
      final AuthProfile? profileFromMetadata = _profileFromMetadata(
        metadata: metadata,
        email: supabaseUser.email,
        fallbackDisplayName: pendingSeed?.fallbackDisplayName,
      );
      if (profileFromMetadata != null) {
        resolvedProfile = profileFromMetadata;
        await _persistProfileRecords(supabaseUser.id, profileFromMetadata);
        await _clearPendingProfileSyncFlag();
      }
    } else {
      await _ensureProfileRow(
        userId: supabaseUser.id,
        displayName:
            explicitDisplayName ??
            pendingSeed?.fallbackDisplayName ??
            _resolveDisplayName(
              metadata: metadata,
              email: supabaseUser.email,
              fallbackDisplayName: pendingSeed?.fallbackDisplayName,
            ),
      );
    }

    _pendingProfileSeed = null;

    final Map<String, dynamic>? profileRow = await _fetchProfileRow(
      supabaseUser.id,
    );
    final Map<String, dynamic>? birthDetailsRow = await _fetchBirthDetailsRow(
      supabaseUser.id,
    );

    return User(
      id: supabaseUser.id,
      email: supabaseUser.email ?? '',
      displayName:
          _readString(profileRow, _displayNameKey) ??
          explicitDisplayName ??
          resolvedProfile?.displayName ??
          _resolveDisplayName(
            metadata: metadata,
            email: supabaseUser.email,
            fallbackDisplayName: pendingSeed?.fallbackDisplayName,
          ),
      tier: _parseTier(_readString(metadata, _subscriptionTierKey)),
      birthProfile:
          _birthProfileFromRow(birthDetailsRow) ??
          resolvedProfile?.birthProfile ??
          _birthProfileFromRow(metadata),
    );
  }

  Map<String, dynamic> _metadataFromProfile(
    AuthProfile profile, {
    required bool profileSyncPending,
  }) {
    return <String, dynamic>{
      _displayNameKey: profile.displayName,
      _fullNameKey: profile.displayName,
      _pendingProfileSyncKey: profileSyncPending,
      _zodiacSignKey: profile.birthProfile.zodiacSign,
      _dateOfBirthKey: profile.birthProfile.dateOfBirth.toIso8601String(),
      _timeOfBirthKey: profile.birthProfile.timeOfBirth,
      _placeOfBirthKey: profile.birthProfile.placeOfBirth,
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

  Future<void> _persistProfileRecords(
    String userId,
    AuthProfile profile,
  ) async {
    try {
      await _syncProfileMetadata(profile, profileSyncPending: false);
      await _ensureProfileRow(userId: userId, displayName: profile.displayName);
      if (_birthDetailsTableAvailable == false) {
        return;
      }
      try {
        await _supabaseClient.from(_birthDetailsTable).upsert(<String, dynamic>{
          'user_id': userId,
          _zodiacSignKey: profile.birthProfile.zodiacSign,
          _dateOfBirthKey: profile.birthProfile.dateOfBirth.toIso8601String(),
          _timeOfBirthKey: profile.birthProfile.timeOfBirth,
          _placeOfBirthKey: profile.birthProfile.placeOfBirth,
        }, onConflict: 'user_id');
        _birthDetailsTableAvailable = true;
      } on supabase.PostgrestException catch (error) {
        if (!_markTableUnavailableIfMissing(error, _birthDetailsTable)) {
          rethrow;
        }
      }
    } on Failure {
      rethrow;
    } catch (error) {
      throw _mapWriteFailure(
        error,
        fallbackMessage: 'Unable to save your birth details right now.',
      );
    }
  }

  Future<void> _ensureProfileRow({
    required String userId,
    required String displayName,
  }) async {
    if (_profilesTableAvailable == false) {
      return;
    }
    try {
      final Map<String, dynamic>? existingRow = await _fetchProfileRow(userId);
      if (_profilesTableAvailable == false) {
        return;
      }
      final String? existingName = _readString(existingRow, _displayNameKey);
      if (existingName == displayName) {
        return;
      }
      await _supabaseClient.from(_profilesTable).upsert(<String, dynamic>{
        'user_id': userId,
        _displayNameKey: displayName,
      }, onConflict: 'user_id');
      _profilesTableAvailable = true;
    } on Failure {
      rethrow;
    } on supabase.PostgrestException catch (error) {
      if (_markTableUnavailableIfMissing(error, _profilesTable)) {
        return;
      }
      throw _mapWriteFailure(
        error,
        fallbackMessage: 'Unable to sync your profile right now.',
      );
    } catch (error) {
      throw _mapWriteFailure(
        error,
        fallbackMessage: 'Unable to sync your profile right now.',
      );
    }
  }

  Future<Map<String, dynamic>?> _fetchProfileRow(String userId) async {
    if (_profilesTableAvailable == false) {
      return null;
    }
    try {
      final dynamic result = await _supabaseClient
          .from(_profilesTable)
          .select(_displayNameKey)
          .eq('user_id', userId)
          .maybeSingle();
      _profilesTableAvailable = true;
      if (result is Map<String, dynamic>) {
        return result;
      }
      if (result is Map) {
        return Map<String, dynamic>.from(result);
      }
      return null;
    } on supabase.PostgrestException catch (error) {
      if (isNoRowsPostgrestError(error)) {
        _profilesTableAvailable = true;
        return null;
      }
      if (_markTableUnavailableIfMissing(error, _profilesTable)) {
        return null;
      }
      throw DataFailure(
        normalizePostgrestDataMessage(error, tableName: _profilesTable),
      );
    } catch (_) {
      throw const DataFailure('Unable to load your profile right now.');
    }
  }

  Future<Map<String, dynamic>?> _fetchBirthDetailsRow(String userId) async {
    if (_birthDetailsTableAvailable == false) {
      return null;
    }
    try {
      final dynamic result = await _supabaseClient
          .from(_birthDetailsTable)
          .select(
            '$_zodiacSignKey,$_dateOfBirthKey,$_timeOfBirthKey,$_placeOfBirthKey',
          )
          .eq('user_id', userId)
          .maybeSingle();
      _birthDetailsTableAvailable = true;
      if (result is Map<String, dynamic>) {
        return result;
      }
      if (result is Map) {
        return Map<String, dynamic>.from(result);
      }
      return null;
    } on supabase.PostgrestException catch (error) {
      if (isNoRowsPostgrestError(error)) {
        _birthDetailsTableAvailable = true;
        return null;
      }
      if (_markTableUnavailableIfMissing(error, _birthDetailsTable)) {
        return null;
      }
      throw DataFailure(
        normalizePostgrestDataMessage(error, tableName: _birthDetailsTable),
      );
    } catch (_) {
      throw const DataFailure('Unable to load your birth details right now.');
    }
  }

  Future<void> _syncProfileMetadata(
    AuthProfile profile, {
    required bool profileSyncPending,
  }) async {
    final supabase.User? currentUser = _authClient.currentUser;
    if (currentUser == null) {
      return;
    }

    final Map<String, dynamic> currentMetadata = Map<String, dynamic>.from(
      currentUser.userMetadata ?? const <String, dynamic>{},
    );
    final Map<String, dynamic> nextMetadata = <String, dynamic>{
      ...currentMetadata,
      ..._metadataFromProfile(profile, profileSyncPending: profileSyncPending),
      _subscriptionTierKey:
          _readString(currentMetadata, _subscriptionTierKey) ??
          SubscriptionTier.free.name,
    };
    if (_mapsEqual(currentMetadata, nextMetadata)) {
      return;
    }

    try {
      await _authClient.updateUser(supabase.UserAttributes(data: nextMetadata));
    } on supabase.AuthException catch (error) {
      throw AuthFailure(_normalizeAuthMessage(error.message));
    } catch (_) {
      throw const DataFailure('Unable to sync your profile right now.');
    }
  }

  BirthProfile? _birthProfileFromRow(Map<String, dynamic>? row) {
    final DateTime? dateOfBirth = _parseDate(_readString(row, _dateOfBirthKey));
    final String? timeOfBirth = _readString(row, _timeOfBirthKey);
    final String? placeOfBirth = _readString(row, _placeOfBirthKey);
    final String? zodiacSign = _readString(row, _zodiacSignKey);

    if (dateOfBirth == null ||
        timeOfBirth == null ||
        placeOfBirth == null ||
        zodiacSign == null) {
      return null;
    }

    return BirthProfile(
      zodiacSign: zodiacSign,
      dateOfBirth: dateOfBirth,
      timeOfBirth: timeOfBirth,
      placeOfBirth: placeOfBirth,
    );
  }

  AuthProfile? _profileFromMetadata({
    required Map<String, dynamic> metadata,
    required String? email,
    String? fallbackDisplayName,
  }) {
    final BirthProfile? birthProfile = _birthProfileFromRow(metadata);
    if (birthProfile == null) {
      return null;
    }

    return AuthProfile(
      displayName: _resolveDisplayName(
        metadata: metadata,
        email: email,
        fallbackDisplayName: fallbackDisplayName,
      ),
      birthProfile: birthProfile,
    );
  }

  Future<void> _clearPendingProfileSyncFlag() async {
    try {
      final Map<String, dynamic> metadata = Map<String, dynamic>.from(
        _authClient.currentUser?.userMetadata ?? const <String, dynamic>{},
      );
      if (!_isPendingMetadataSync(metadata)) {
        return;
      }
      final Map<String, dynamic> nextMetadata = <String, dynamic>{
        ...metadata,
        _pendingProfileSyncKey: false,
      };
      if (_mapsEqual(metadata, nextMetadata)) {
        return;
      }
      await _authClient.updateUser(supabase.UserAttributes(data: nextMetadata));
    } on supabase.AuthException catch (error) {
      throw AuthFailure(_normalizeAuthMessage(error.message));
    } catch (_) {
      throw const DataFailure('Unable to finalize your profile right now.');
    }
  }

  bool _isPendingMetadataSync(Map<String, dynamic>? metadata) {
    final Object? value = metadata?[_pendingProfileSyncKey];
    return value is bool && value;
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

  String? _readString(Map<String, dynamic>? metadata, String key) {
    final Object? value = metadata?[key];
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

  void _emitUser(User user, {bool emit = true}) {
    _currentUser = user;
    _usersById[user.id] = user;
    if (emit) {
      _authStateController.add(user);
    }
  }

  User _buildFallbackUser(supabase.User supabaseUser) {
    final Map<String, dynamic> metadata = Map<String, dynamic>.from(
      supabaseUser.userMetadata ?? const <String, dynamic>{},
    );
    return User(
      id: supabaseUser.id,
      email: supabaseUser.email ?? '',
      displayName: _resolveDisplayName(
        metadata: metadata,
        email: supabaseUser.email,
        fallbackDisplayName: _pendingProfileSeed?.fallbackDisplayName,
      ),
      tier: _parseTier(_readString(metadata, _subscriptionTierKey)),
      birthProfile: _birthProfileFromRow(metadata),
    );
  }

  Failure _mapAuthOrWriteFailure(
    Object error, {
    required String fallbackMessage,
  }) {
    if (error is Failure) {
      return error;
    }
    if (error is supabase.AuthException) {
      return AuthFailure(_normalizeAuthMessage(error.message));
    }
    if (error is supabase.PostgrestException) {
      return DataFailure(normalizePostgrestDataMessage(error));
    }
    return DataFailure(fallbackMessage);
  }

  Failure _mapWriteFailure(Object error, {required String fallbackMessage}) {
    if (error is Failure) {
      return error;
    }
    if (error is supabase.PostgrestException) {
      return DataFailure(normalizePostgrestDataMessage(error));
    }
    if (error is supabase.AuthException) {
      return AuthFailure(_normalizeAuthMessage(error.message));
    }
    return DataFailure(fallbackMessage);
  }

  String _normalizeAuthMessage(String message) {
    final String normalized = message.trim();
    if (normalized.isEmpty) {
      return 'Authentication failed. Please try again.';
    }
    return normalized;
  }

  bool _markTableUnavailableIfMissing(
    supabase.PostgrestException error,
    String tableName,
  ) {
    if (!isMissingPostgrestTableError(error, tableName: tableName)) {
      return false;
    }

    if (tableName == _profilesTable) {
      _profilesTableAvailable = false;
    } else if (tableName == _birthDetailsTable) {
      _birthDetailsTableAvailable = false;
    }
    return true;
  }
}

class _PendingProfileSeed {
  const _PendingProfileSeed({this.profile, this.fallbackDisplayName});

  final AuthProfile? profile;
  final String? fallbackDisplayName;
}

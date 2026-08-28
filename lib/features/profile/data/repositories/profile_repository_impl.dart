import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/models/birth_profile.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/profile_data.dart';
import '../../domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl({
    required AuthRepository authRepository,
    required SupabaseClient supabaseClient,
  }) : _authRepository = authRepository,
       _supabaseClient = supabaseClient;

  final AuthRepository _authRepository;
  final SupabaseClient _supabaseClient;

  static const Duration _birthDetailsCooldown = Duration(hours: 24);

  @override
  Future<ProfileData> getProfile() async {
    final user = _authRepository.getCurrentUser();
    if (user == null) {
      throw const AuthFailure('No active profile.');
    }
    final birthProfile = user.birthProfile;
    if (birthProfile == null) {
      throw const AuthFailure('Complete your profile to continue.');
    }
    return ProfileData(
      displayName: user.displayName,
      email: user.email,
      birthProfile: birthProfile,
      tier: user.tier,
      birthDetailsEditableAfter: await _fetchBirthDetailsEditableAfter(
        user.id,
      ),
    );
  }

  /// Reads when DOB/time/place were last recomputed, mirroring the 24-hour
  /// cooldown `compute-chart` enforces server-side. Degrades to "not
  /// locked" (null) on any read failure rather than blocking the whole
  /// profile load — the server remains the actual authority regardless.
  Future<DateTime?> _fetchBirthDetailsEditableAfter(String userId) async {
    try {
      final Map<String, dynamic>? row = await _supabaseClient
          .from('birth_charts')
          .select('computed_at')
          .eq('user_id', userId)
          .maybeSingle();
      final String? computedAt = row?['computed_at'] as String?;
      if (computedAt == null) {
        return null;
      }
      return DateTime.parse(computedAt).add(_birthDetailsCooldown);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ProfileData> updateDisplayName(String displayName) async {
    await _authRepository.updateDisplayName(displayName);
    return getProfile();
  }

  @override
  Future<ProfileData> updateBirthProfile(BirthProfile birthProfile) async {
    await _authRepository.updateBirthProfile(birthProfile);
    return getProfile();
  }
}

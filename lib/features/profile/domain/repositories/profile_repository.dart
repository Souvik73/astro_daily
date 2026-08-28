import '../../../../core/models/birth_profile.dart';
import '../entities/profile_data.dart';

abstract class ProfileRepository {
  Future<ProfileData> getProfile();
  Future<ProfileData> updateDisplayName(String displayName);
  Future<ProfileData> updateBirthProfile(BirthProfile birthProfile);
}

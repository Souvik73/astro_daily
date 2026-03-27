import '../../../../core/error/failures.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/profile_data.dart';
import '../../domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl({required AuthRepository authRepository})
    : _authRepository = authRepository;

  final AuthRepository _authRepository;

  @override
  Future<ProfileData> getProfile() async {
    final user = _authRepository.getCurrentUser();
    if (user == null) {
      throw const AuthFailure('No active profile.');
    }
    return ProfileData(
      displayName: user.displayName,
      email: user.email,
      zodiacSign: user.zodiacSign,
      dateOfBirth: user.dateOfBirth,
      timeOfBirth: user.timeOfBirth,
      placeOfBirth: user.placeOfBirth,
      tier: user.tier,
    );
  }
}

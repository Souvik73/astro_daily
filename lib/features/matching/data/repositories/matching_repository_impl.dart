import '../../../../core/error/failures.dart';
import '../../../../core/mappers/birth_details_mapper.dart';
import '../../../../core/models/astro_models.dart';
import '../../../../core/models/birth_profile.dart';
import '../../../auth/domain/mappers/user_birth_details_mapper.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/matching_result.dart';
import '../../domain/repositories/matching_repository.dart';
import '../datasources/matching_local_data_source.dart';
import '../datasources/matching_remote_data_source.dart';

class MatchingRepositoryImpl implements MatchingRepository {
  MatchingRepositoryImpl({
    required MatchingRemoteDataSource remoteDataSource,
    required MatchingLocalDataSource localDataSource,
    required AuthRepository authRepository,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource,
       _authRepository = authRepository;

  final MatchingRemoteDataSource _remoteDataSource;
  final MatchingLocalDataSource _localDataSource;
  final AuthRepository _authRepository;
  static const UserBirthDetailsMapper _userBirthDetailsMapper =
      UserBirthDetailsMapper();
  static const BirthDetailsMapper _birthDetailsMapper = BirthDetailsMapper();

  @override
  Future<BirthProfile?> getSavedPartner() {
    return _localDataSource.getSavedPartner();
  }

  @override
  Future<MatchingResult> getMatchingResult(BirthProfile partner) async {
    final user = _authRepository.getCurrentUser();
    if (user == null) {
      throw const AuthFailure('User session expired. Please sign in again.');
    }

    // Persist the entered partner so it's remembered on next visit, even if
    // the compatibility lookup below fails.
    await _localDataSource.savePartner(partner);

    final CompatibilityResult result = await _remoteDataSource.getCompatibility(
      CompatibilityRequest(
        primary: _userBirthDetailsMapper.map(user),
        partner: _birthDetailsMapper.map(partner),
      ),
    );

    return MatchingResult(
      score: result.score,
      summary: result.summary,
      strengths: result.strengths,
      partner: partner,
    );
  }
}

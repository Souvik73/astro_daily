import '../../../../core/error/failures.dart';
import '../../../../core/mappers/birth_details_mapper.dart';
import '../../../../core/models/astro_models.dart';
import '../../../../core/models/birth_profile.dart';
import '../../../auth/domain/mappers/user_birth_details_mapper.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/matching_result.dart';
import '../../domain/repositories/matching_repository.dart';
import '../datasources/matching_remote_data_source.dart';

class MatchingRepositoryImpl implements MatchingRepository {
  MatchingRepositoryImpl({
    required MatchingRemoteDataSource remoteDataSource,
    required AuthRepository authRepository,
  }) : _remoteDataSource = remoteDataSource,
       _authRepository = authRepository;

  static final BirthProfile _placeholderPartnerBirthProfile = BirthProfile(
    zodiacSign: 'Libra',
    dateOfBirth: DateTime(1995, 12, 5),
    timeOfBirth: '18:10',
    placeOfBirth: 'Mumbai',
  );

  final MatchingRemoteDataSource _remoteDataSource;
  final AuthRepository _authRepository;
  static const UserBirthDetailsMapper _userBirthDetailsMapper =
      UserBirthDetailsMapper();
  static const BirthDetailsMapper _birthDetailsMapper = BirthDetailsMapper();

  @override
  Future<MatchingResult> getMatchingResult() async {
    final user = _authRepository.getCurrentUser();
    if (user == null) {
      throw const AuthFailure('User session expired. Please sign in again.');
    }

    final CompatibilityResult result = await _remoteDataSource.getCompatibility(
      CompatibilityRequest(
        primary: _userBirthDetailsMapper.map(user),
        partner: _birthDetailsMapper.map(_placeholderPartnerBirthProfile),
      ),
    );

    return MatchingResult(
      score: result.score,
      summary: result.summary,
      strengths: result.strengths,
    );
  }
}

import '../../../../core/error/failures.dart';
import '../../../../core/models/astro_models.dart';
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

  final MatchingRemoteDataSource _remoteDataSource;
  final AuthRepository _authRepository;

  @override
  Future<MatchingResult> getMatchingResult() async {
    final user = _authRepository.getCurrentUser();
    if (user == null) {
      throw const AuthFailure('User session expired. Please sign in again.');
    }

    final CompatibilityResult result = await _remoteDataSource.getCompatibility(
      CompatibilityRequest(
        primary: BirthDetails(
          dateTime: DateTime(1994, 4, 16, 8, 45),
          place: 'Kolkata',
          zodiacSign: user.zodiacSign,
        ),
        partner: BirthDetails(
          dateTime: DateTime(1995, 12, 5, 18, 10),
          place: 'Mumbai',
          zodiacSign: 'Libra',
        ),
      ),
    );

    return MatchingResult(
      score: result.score,
      summary: result.summary,
      strengths: result.strengths,
    );
  }
}

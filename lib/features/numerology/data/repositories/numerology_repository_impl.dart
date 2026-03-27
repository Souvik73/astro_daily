import '../../../../core/error/failures.dart';
import '../../../../core/models/astro_models.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/numerology_insight.dart';
import '../../domain/repositories/numerology_repository.dart';
import '../datasources/numerology_remote_data_source.dart';

class NumerologyRepositoryImpl implements NumerologyRepository {
  NumerologyRepositoryImpl({
    required NumerologyRemoteDataSource remoteDataSource,
    required AuthRepository authRepository,
  }) : _remoteDataSource = remoteDataSource,
       _authRepository = authRepository;

  final NumerologyRemoteDataSource _remoteDataSource;
  final AuthRepository _authRepository;

  @override
  Future<NumerologyInsight> getNumerologyInsight() async {
    final user = _authRepository.getCurrentUser();
    if (user == null) {
      throw const AuthFailure('User session expired. Please sign in again.');
    }

    final NumerologyResult result = await _remoteDataSource.getNumerology(
      BirthDetails(
        dateTime: DateTime(1994, 4, 16, 8, 45),
        place: 'Kolkata',
        zodiacSign: user.zodiacSign,
      ),
    );

    return NumerologyInsight(
      lifePathNumber: result.lifePathNumber,
      personalDayNumber: result.personalDayNumber,
      guidance: result.guidance,
    );
  }
}

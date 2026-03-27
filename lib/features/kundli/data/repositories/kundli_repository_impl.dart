import '../../../../core/error/failures.dart';
import '../../../../core/models/astro_models.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/kundli_insight.dart';
import '../../domain/repositories/kundli_repository.dart';
import '../datasources/kundli_remote_data_source.dart';

class KundliRepositoryImpl implements KundliRepository {
  KundliRepositoryImpl({
    required KundliRemoteDataSource remoteDataSource,
    required AuthRepository authRepository,
  }) : _remoteDataSource = remoteDataSource,
       _authRepository = authRepository;

  final KundliRemoteDataSource _remoteDataSource;
  final AuthRepository _authRepository;

  @override
  Future<KundliInsight> getKundliInsight() async {
    final user = _authRepository.getCurrentUser();
    if (user == null) {
      throw const AuthFailure('User session expired. Please sign in again.');
    }

    final KundliData data = await _remoteDataSource.getKundli(
      BirthDetails(
        dateTime: DateTime(1994, 4, 16, 8, 45),
        place: 'Kolkata',
        zodiacSign: user.zodiacSign,
      ),
    );

    return KundliInsight(
      sunSign: data.sunSign,
      moonSign: data.moonSign,
      ascendant: data.ascendant,
      focusArea: data.focusArea,
    );
  }
}

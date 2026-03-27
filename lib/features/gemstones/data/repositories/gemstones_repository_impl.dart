import '../../../../core/error/failures.dart';
import '../../../../core/models/astro_models.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/gemstone_insight.dart';
import '../../domain/repositories/gemstones_repository.dart';
import '../datasources/gemstones_remote_data_source.dart';

class GemstonesRepositoryImpl implements GemstonesRepository {
  GemstonesRepositoryImpl({
    required GemstonesRemoteDataSource remoteDataSource,
    required AuthRepository authRepository,
  }) : _remoteDataSource = remoteDataSource,
       _authRepository = authRepository;

  final GemstonesRemoteDataSource _remoteDataSource;
  final AuthRepository _authRepository;

  @override
  Future<GemstoneInsight> getGemstoneInsight() async {
    final user = _authRepository.getCurrentUser();
    if (user == null) {
      throw const AuthFailure('User session expired. Please sign in again.');
    }

    final GemstoneBuildResult data = await _remoteDataSource
        .buildGemstoneReport(
          birthDetails: BirthDetails(
            dateTime: DateTime(1994, 4, 16, 8, 45),
            place: 'Kolkata',
            zodiacSign: user.zodiacSign,
          ),
          locale: 'en',
        );

    return GemstoneInsight(
      primaryStone: data.report.primaryStone,
      alternativeStones: data.report.alternativeStones,
      rationale: data.report.rationale,
      summary: data.summary,
      ascendant: data.kundliData.ascendant,
      focusArea: data.kundliData.focusArea,
    );
  }
}

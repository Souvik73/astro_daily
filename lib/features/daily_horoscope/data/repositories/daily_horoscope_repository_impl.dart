import '../../../../core/error/failures.dart';
import '../../../../core/models/astro_models.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/daily_horoscope.dart';
import '../../domain/repositories/daily_horoscope_repository.dart';
import '../datasources/daily_horoscope_remote_data_source.dart';

class DailyHoroscopeRepositoryImpl implements DailyHoroscopeRepository {
  DailyHoroscopeRepositoryImpl({
    required DailyHoroscopeRemoteDataSource remoteDataSource,
    required AuthRepository authRepository,
  }) : _remoteDataSource = remoteDataSource,
       _authRepository = authRepository;

  final DailyHoroscopeRemoteDataSource _remoteDataSource;
  final AuthRepository _authRepository;

  @override
  Future<DailyHoroscope> getPersonalizedDailyHoroscope({
    required String locale,
    required DateTime date,
  }) async {
    final user = _authRepository.getCurrentUser();
    if (user == null) {
      throw const AuthFailure('User session expired. Please sign in again.');
    }

    final HoroscopeResponse horoscope = await _remoteDataSource
        .getDailyHoroscope(
          DailyHoroscopeRequest(
            zodiacSign: user.zodiacSign,
            date: date,
            locale: locale,
          ),
        );
    final List<String> dosDonts = await _remoteDataSource.generateDosDonts(
      horoscope,
      locale: locale,
    );

    return DailyHoroscope(
      date: horoscope.date,
      zodiacSign: horoscope.zodiacSign,
      locale: horoscope.locale,
      summary: horoscope.summary,
      luckyColor: horoscope.luckyColor,
      luckyNumber: horoscope.luckyNumber,
      dosDonts: dosDonts,
      personalizedFocus: '${user.displayName}, ${horoscope.summary}',
    );
  }
}

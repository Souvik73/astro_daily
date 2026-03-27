import '../../../../core/models/astro_models.dart';
import '../../../../core/services/contracts.dart';

abstract class DailyHoroscopeRemoteDataSource {
  Future<HoroscopeResponse> getDailyHoroscope(DailyHoroscopeRequest request);
  Future<List<String>> generateDosDonts(
    HoroscopeResponse horoscope, {
    required String locale,
  });
}

class DailyHoroscopeRemoteDataSourceImpl
    implements DailyHoroscopeRemoteDataSource {
  DailyHoroscopeRemoteDataSourceImpl({
    required AstroProvider astroProvider,
    required AiPersonalizer aiPersonalizer,
  }) : _astroProvider = astroProvider,
       _aiPersonalizer = aiPersonalizer;

  final AstroProvider _astroProvider;
  final AiPersonalizer _aiPersonalizer;

  @override
  Future<HoroscopeResponse> getDailyHoroscope(DailyHoroscopeRequest request) {
    return _astroProvider.getDailyHoroscope(request);
  }

  @override
  Future<List<String>> generateDosDonts(
    HoroscopeResponse horoscope, {
    required String locale,
  }) {
    return _aiPersonalizer.generateDosDonts(horoscope, locale: locale);
  }
}

import '../entities/daily_horoscope.dart';

abstract class DailyHoroscopeRepository {
  Future<DailyHoroscope> getPersonalizedDailyHoroscope({
    required String locale,
    required DateTime date,
  });
}

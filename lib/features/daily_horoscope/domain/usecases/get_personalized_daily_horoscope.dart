import '../../../../core/usecase/usecase.dart';
import '../entities/daily_horoscope.dart';
import '../repositories/daily_horoscope_repository.dart';

class GetPersonalizedDailyHoroscope
    implements
        UseCase<Future<DailyHoroscope>, GetPersonalizedDailyHoroscopeParams> {
  GetPersonalizedDailyHoroscope(this._repository);

  final DailyHoroscopeRepository _repository;

  @override
  Future<DailyHoroscope> call(GetPersonalizedDailyHoroscopeParams params) {
    return _repository.getPersonalizedDailyHoroscope(
      locale: params.locale,
      date: params.date,
    );
  }
}

class GetPersonalizedDailyHoroscopeParams {
  const GetPersonalizedDailyHoroscopeParams({
    required this.locale,
    required this.date,
  });

  final String locale;
  final DateTime date;
}

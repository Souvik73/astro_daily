import 'package:astro_daily/core/error/failures.dart';
import 'package:astro_daily/features/daily_horoscope/domain/entities/daily_horoscope.dart';
import 'package:astro_daily/features/daily_horoscope/domain/repositories/daily_horoscope_repository.dart';
import 'package:astro_daily/features/daily_horoscope/domain/usecases/get_personalized_daily_horoscope.dart';
import 'package:astro_daily/features/daily_horoscope/presentation/bloc/daily_horoscope_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('emits success state when use case returns horoscope', () async {
    final bloc = DailyHoroscopeBloc(
      getPersonalizedDailyHoroscope: _SuccessUseCase(),
    );

    bloc.add(
      DailyHoroscopeRequested(locale: 'en', date: DateTime(2026, 3, 19)),
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(bloc.state.status, DailyHoroscopeStatus.success);
    expect(bloc.state.horoscope?.zodiacSign, 'Aries');
    await bloc.close();
  });

  test('emits failure state when use case throws auth failure', () async {
    final bloc = DailyHoroscopeBloc(
      getPersonalizedDailyHoroscope: _FailureUseCase(),
    );

    bloc.add(
      DailyHoroscopeRequested(locale: 'en', date: DateTime(2026, 3, 19)),
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(bloc.state.status, DailyHoroscopeStatus.failure);
    expect(
      bloc.state.errorMessage,
      'User session expired. Please sign in again.',
    );
    await bloc.close();
  });
}

class _SuccessUseCase extends GetPersonalizedDailyHoroscope {
  _SuccessUseCase() : super(_NoopDailyHoroscopeRepository());

  @override
  Future<DailyHoroscope> call(
    GetPersonalizedDailyHoroscopeParams params,
  ) async {
    return DailyHoroscope(
      date: params.date,
      zodiacSign: 'Aries',
      locale: params.locale,
      summary: 'Steady progress wins today.',
      luckyColor: 'Green',
      luckyNumber: 5,
      dosDonts: const <String>['Do: Focus', "Don't: Rush"],
      personalizedFocus: 'pilot, steady progress wins today.',
    );
  }
}

class _FailureUseCase extends GetPersonalizedDailyHoroscope {
  _FailureUseCase() : super(_NoopDailyHoroscopeRepository());

  @override
  Future<DailyHoroscope> call(GetPersonalizedDailyHoroscopeParams params) {
    throw const AuthFailure('User session expired. Please sign in again.');
  }
}

class _NoopDailyHoroscopeRepository implements DailyHoroscopeRepository {
  const _NoopDailyHoroscopeRepository();

  @override
  Future<DailyHoroscope> getPersonalizedDailyHoroscope({
    required String locale,
    required DateTime date,
  }) {
    throw UnimplementedError();
  }
}

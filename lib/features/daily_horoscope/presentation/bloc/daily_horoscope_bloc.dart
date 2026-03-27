import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/daily_horoscope.dart';
import '../../domain/usecases/get_personalized_daily_horoscope.dart';

enum DailyHoroscopeStatus { initial, loading, success, failure }

final class DailyHoroscopeState extends Equatable {
  const DailyHoroscopeState({
    required this.status,
    this.horoscope,
    this.errorMessage,
  });

  const DailyHoroscopeState.initial()
    : this(status: DailyHoroscopeStatus.initial);

  final DailyHoroscopeStatus status;
  final DailyHoroscope? horoscope;
  final String? errorMessage;

  DailyHoroscopeState copyWith({
    DailyHoroscopeStatus? status,
    DailyHoroscope? horoscope,
    String? errorMessage,
  }) {
    return DailyHoroscopeState(
      status: status ?? this.status,
      horoscope: horoscope ?? this.horoscope,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[status, horoscope, errorMessage];
}

sealed class DailyHoroscopeEvent extends Equatable {
  const DailyHoroscopeEvent();

  @override
  List<Object?> get props => <Object?>[];
}

final class DailyHoroscopeRequested extends DailyHoroscopeEvent {
  const DailyHoroscopeRequested({required this.locale, required this.date});

  final String locale;
  final DateTime date;

  @override
  List<Object?> get props => <Object?>[locale, date];
}

class DailyHoroscopeBloc
    extends Bloc<DailyHoroscopeEvent, DailyHoroscopeState> {
  DailyHoroscopeBloc({
    required GetPersonalizedDailyHoroscope getPersonalizedDailyHoroscope,
  }) : _getPersonalizedDailyHoroscope = getPersonalizedDailyHoroscope,
       super(const DailyHoroscopeState.initial()) {
    on<DailyHoroscopeRequested>(_onDailyHoroscopeRequested);
  }

  final GetPersonalizedDailyHoroscope _getPersonalizedDailyHoroscope;

  Future<void> _onDailyHoroscopeRequested(
    DailyHoroscopeRequested event,
    Emitter<DailyHoroscopeState> emit,
  ) async {
    emit(state.copyWith(status: DailyHoroscopeStatus.loading));
    try {
      final DailyHoroscope horoscope = await _getPersonalizedDailyHoroscope(
        GetPersonalizedDailyHoroscopeParams(
          locale: event.locale,
          date: event.date,
        ),
      );
      emit(
        state.copyWith(
          status: DailyHoroscopeStatus.success,
          horoscope: horoscope,
        ),
      );
    } on Failure catch (failure) {
      emit(
        state.copyWith(
          status: DailyHoroscopeStatus.failure,
          errorMessage: failure.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: DailyHoroscopeStatus.failure,
          errorMessage: 'Could not load horoscope right now.',
        ),
      );
    }
  }
}

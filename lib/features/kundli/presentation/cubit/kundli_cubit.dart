import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/kundli_insight.dart';
import '../../domain/usecases/get_kundli_insight.dart';

enum KundliStatus { initial, loading, success, failure }

class KundliState extends Equatable {
  const KundliState({required this.status, this.kundli, this.errorMessage});

  const KundliState.initial() : this(status: KundliStatus.initial);

  final KundliStatus status;
  final KundliInsight? kundli;
  final String? errorMessage;

  KundliState copyWith({
    KundliStatus? status,
    KundliInsight? kundli,
    String? errorMessage,
  }) {
    return KundliState(
      status: status ?? this.status,
      kundli: kundli ?? this.kundli,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[status, kundli, errorMessage];
}

class KundliCubit extends Cubit<KundliState> {
  KundliCubit({required GetKundliInsight getKundliInsight})
    : _getKundliInsight = getKundliInsight,
      super(const KundliState.initial());

  final GetKundliInsight _getKundliInsight;

  Future<void> fetchKundli() async {
    emit(state.copyWith(status: KundliStatus.loading, errorMessage: null));
    try {
      final KundliInsight insight = await _getKundliInsight(const NoParams());
      emit(state.copyWith(status: KundliStatus.success, kundli: insight));
    } on Failure catch (failure) {
      emit(
        state.copyWith(
          status: KundliStatus.failure,
          errorMessage: failure.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: KundliStatus.failure,
          errorMessage: 'Unable to load kundli.',
        ),
      );
    }
  }
}

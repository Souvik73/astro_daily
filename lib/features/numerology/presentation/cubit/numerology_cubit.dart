import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/numerology_insight.dart';
import '../../domain/usecases/get_numerology_insight.dart';

enum NumerologyStatus { initial, loading, success, failure }

class NumerologyState extends Equatable {
  const NumerologyState({
    required this.status,
    this.insight,
    this.errorMessage,
  });

  const NumerologyState.initial() : this(status: NumerologyStatus.initial);

  final NumerologyStatus status;
  final NumerologyInsight? insight;
  final String? errorMessage;

  NumerologyState copyWith({
    NumerologyStatus? status,
    NumerologyInsight? insight,
    String? errorMessage,
  }) {
    return NumerologyState(
      status: status ?? this.status,
      insight: insight ?? this.insight,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[status, insight, errorMessage];
}

class NumerologyCubit extends Cubit<NumerologyState> {
  NumerologyCubit({required GetNumerologyInsight getNumerologyInsight})
    : _getNumerologyInsight = getNumerologyInsight,
      super(const NumerologyState.initial());

  final GetNumerologyInsight _getNumerologyInsight;

  Future<void> fetchNumerology() async {
    emit(state.copyWith(status: NumerologyStatus.loading, errorMessage: null));
    try {
      final NumerologyInsight insight = await _getNumerologyInsight(
        const NoParams(),
      );
      emit(state.copyWith(status: NumerologyStatus.success, insight: insight));
    } on Failure catch (failure) {
      emit(
        state.copyWith(
          status: NumerologyStatus.failure,
          errorMessage: failure.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: NumerologyStatus.failure,
          errorMessage: 'Unable to load numerology.',
        ),
      );
    }
  }
}

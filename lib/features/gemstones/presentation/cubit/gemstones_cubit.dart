import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/gemstone_insight.dart';
import '../../domain/usecases/get_gemstone_insight.dart';

enum GemstonesStatus { initial, loading, success, failure }

class GemstonesState extends Equatable {
  const GemstonesState({required this.status, this.insight, this.errorMessage});

  const GemstonesState.initial() : this(status: GemstonesStatus.initial);

  final GemstonesStatus status;
  final GemstoneInsight? insight;
  final String? errorMessage;

  GemstonesState copyWith({
    GemstonesStatus? status,
    GemstoneInsight? insight,
    String? errorMessage,
  }) {
    return GemstonesState(
      status: status ?? this.status,
      insight: insight ?? this.insight,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[status, insight, errorMessage];
}

class GemstonesCubit extends Cubit<GemstonesState> {
  GemstonesCubit({required GetGemstoneInsight getGemstoneInsight})
    : _getGemstoneInsight = getGemstoneInsight,
      super(const GemstonesState.initial());

  final GetGemstoneInsight _getGemstoneInsight;

  Future<void> fetchGemstoneInsight() async {
    emit(state.copyWith(status: GemstonesStatus.loading, errorMessage: null));
    try {
      final GemstoneInsight insight = await _getGemstoneInsight(
        const NoParams(),
      );
      emit(state.copyWith(status: GemstonesStatus.success, insight: insight));
    } on Failure catch (failure) {
      emit(
        state.copyWith(
          status: GemstonesStatus.failure,
          errorMessage: failure.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: GemstonesStatus.failure,
          errorMessage: 'Unable to build gemstone report.',
        ),
      );
    }
  }
}

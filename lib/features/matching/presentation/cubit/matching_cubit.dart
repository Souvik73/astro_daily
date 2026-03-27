import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/matching_result.dart';
import '../../domain/usecases/get_matching_result.dart';

enum MatchingStatus { initial, loading, success, failure }

class MatchingState extends Equatable {
  const MatchingState({required this.status, this.result, this.errorMessage});

  const MatchingState.initial() : this(status: MatchingStatus.initial);

  final MatchingStatus status;
  final MatchingResult? result;
  final String? errorMessage;

  MatchingState copyWith({
    MatchingStatus? status,
    MatchingResult? result,
    String? errorMessage,
  }) {
    return MatchingState(
      status: status ?? this.status,
      result: result ?? this.result,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[status, result, errorMessage];
}

class MatchingCubit extends Cubit<MatchingState> {
  MatchingCubit({required GetMatchingResult getMatchingResult})
    : _getMatchingResult = getMatchingResult,
      super(const MatchingState.initial());

  final GetMatchingResult _getMatchingResult;

  Future<void> fetchMatchingResult() async {
    emit(state.copyWith(status: MatchingStatus.loading, errorMessage: null));
    try {
      final MatchingResult result = await _getMatchingResult(const NoParams());
      emit(state.copyWith(status: MatchingStatus.success, result: result));
    } on Failure catch (failure) {
      emit(
        state.copyWith(
          status: MatchingStatus.failure,
          errorMessage: failure.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: MatchingStatus.failure,
          errorMessage: 'Unable to load compatibility.',
        ),
      );
    }
  }
}

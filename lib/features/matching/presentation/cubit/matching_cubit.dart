import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/models/birth_profile.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/matching_result.dart';
import '../../domain/usecases/get_matching_result.dart';
import '../../domain/usecases/get_saved_partner.dart';

enum MatchingStatus { initial, loading, needsPartner, success, failure }

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
  MatchingCubit({
    required GetMatchingResult getMatchingResult,
    required GetSavedPartner getSavedPartner,
  }) : _getMatchingResult = getMatchingResult,
       _getSavedPartner = getSavedPartner,
       super(const MatchingState.initial());

  final GetMatchingResult _getMatchingResult;
  final GetSavedPartner _getSavedPartner;

  /// Called on page load. Uses the last-saved partner if one exists;
  /// otherwise prompts the user to enter one.
  Future<void> start() async {
    emit(state.copyWith(status: MatchingStatus.loading, errorMessage: null));
    final BirthProfile? saved = await _getSavedPartner(const NoParams());
    if (saved == null) {
      emit(state.copyWith(status: MatchingStatus.needsPartner));
      return;
    }
    await _fetch(saved);
  }

  /// Called after the user submits the partner-input sheet, both for the
  /// first entry and for later edits.
  Future<void> submitPartner(BirthProfile partner) => _fetch(partner);

  /// Re-fetches using whichever partner produced the current result.
  Future<void> refresh() async {
    final BirthProfile? partner = state.result?.partner;
    if (partner == null) {
      emit(state.copyWith(status: MatchingStatus.needsPartner));
      return;
    }
    await _fetch(partner);
  }

  /// Opens the input sheet again, e.g. from an "Edit partner" button.
  void requestEditPartner() {
    emit(state.copyWith(status: MatchingStatus.needsPartner));
  }

  Future<void> _fetch(BirthProfile partner) async {
    emit(state.copyWith(status: MatchingStatus.loading, errorMessage: null));
    try {
      final MatchingResult result = await _getMatchingResult(
        GetMatchingResultParams(partner: partner),
      );
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

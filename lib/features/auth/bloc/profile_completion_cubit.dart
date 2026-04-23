import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/birth_profile.dart';
import '../domain/entities/auth_profile.dart';
import '../domain/usecases/complete_profile.dart';

enum ProfileCompletionStatus { initial, submitting, success, failure }

final class ProfileCompletionState extends Equatable {
  const ProfileCompletionState({
    required this.status,
    this.dateOfBirth,
    this.timeOfBirth,
    this.zodiacSign = '',
    this.errorMessage,
  });

  const ProfileCompletionState.initial()
    : this(
        status: ProfileCompletionStatus.initial,
        dateOfBirth: null,
        timeOfBirth: null,
        zodiacSign: '',
        errorMessage: null,
      );

  final ProfileCompletionStatus status;
  final DateTime? dateOfBirth;
  final String? timeOfBirth;
  final String zodiacSign;
  final String? errorMessage;

  bool get isSubmitting => status == ProfileCompletionStatus.submitting;

  ProfileCompletionState copyWith({
    ProfileCompletionStatus? status,
    DateTime? dateOfBirth,
    String? timeOfBirth,
    String? zodiacSign,
    String? errorMessage,
  }) {
    return ProfileCompletionState(
      status: status ?? this.status,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      timeOfBirth: timeOfBirth ?? this.timeOfBirth,
      zodiacSign: zodiacSign ?? this.zodiacSign,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    dateOfBirth,
    timeOfBirth,
    zodiacSign,
    errorMessage,
  ];
}

class ProfileCompletionCubit extends Cubit<ProfileCompletionState> {
  ProfileCompletionCubit({required CompleteProfile completeProfile})
    : _completeProfile = completeProfile,
      super(const ProfileCompletionState.initial());

  final CompleteProfile _completeProfile;

  void onDateOfBirthSelected(DateTime dateOfBirth) {
    emit(
      state.copyWith(
        dateOfBirth: dateOfBirth,
        zodiacSign: BirthProfile.calculateZodiacSign(dateOfBirth),
        errorMessage: null,
      ),
    );
  }

  void onTimeOfBirthSelected(String timeOfBirth) {
    emit(state.copyWith(timeOfBirth: timeOfBirth, errorMessage: null));
  }

  Future<void> complete({
    required String displayName,
    required String placeOfBirth,
  }) async {
    final DateTime? dateOfBirth = state.dateOfBirth;
    final String? timeOfBirth = state.timeOfBirth;
    if (dateOfBirth == null || timeOfBirth == null) {
      emit(
        state.copyWith(
          status: ProfileCompletionStatus.failure,
          errorMessage: 'Birth details are required.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: ProfileCompletionStatus.submitting,
        errorMessage: null,
      ),
    );

    try {
      await _completeProfile(
        CompleteProfileParams(
          profile: AuthProfile(
            displayName: displayName,
            birthProfile: BirthProfile(
              zodiacSign: BirthProfile.calculateZodiacSign(dateOfBirth),
              dateOfBirth: dateOfBirth,
              timeOfBirth: timeOfBirth,
              placeOfBirth: placeOfBirth,
            ),
          ),
        ),
      );
      emit(
        state.copyWith(
          status: ProfileCompletionStatus.success,
          errorMessage: null,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: ProfileCompletionStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }
}

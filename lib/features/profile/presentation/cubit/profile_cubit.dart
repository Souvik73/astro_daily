import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/models/birth_profile.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/profile_data.dart';
import '../../domain/usecases/get_profile.dart';
import '../../domain/usecases/update_birth_profile.dart';
import '../../domain/usecases/update_display_name.dart';

enum ProfileStatus { initial, loading, success, failure }

class ProfileState extends Equatable {
  const ProfileState({required this.status, this.profile, this.errorMessage});

  const ProfileState.initial() : this(status: ProfileStatus.initial);

  final ProfileStatus status;
  final ProfileData? profile;
  final String? errorMessage;

  ProfileState copyWith({
    ProfileStatus? status,
    ProfileData? profile,
    String? errorMessage,
  }) {
    return ProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[status, profile, errorMessage];
}

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({
    required GetProfile getProfile,
    required UpdateDisplayName updateDisplayName,
    required UpdateBirthProfile updateBirthProfile,
  }) : _getProfile = getProfile,
       _updateDisplayName = updateDisplayName,
       _updateBirthProfile = updateBirthProfile,
       super(const ProfileState.initial());

  final GetProfile _getProfile;
  final UpdateDisplayName _updateDisplayName;
  final UpdateBirthProfile _updateBirthProfile;

  Future<void> loadProfile() async {
    emit(state.copyWith(status: ProfileStatus.loading, errorMessage: null));
    try {
      final ProfileData profile = await _getProfile(const NoParams());
      emit(state.copyWith(status: ProfileStatus.success, profile: profile));
    } on Failure catch (failure) {
      emit(
        state.copyWith(
          status: ProfileStatus.failure,
          errorMessage: failure.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: ProfileStatus.failure,
          errorMessage: 'Unable to load profile.',
        ),
      );
    }
  }

  /// Errors are left to propagate to the caller (the edit dialog) rather
  /// than routed through [ProfileState.errorMessage], so a failed save
  /// shows inline in the dialog instead of replacing the whole page with
  /// the full-screen error view.
  Future<void> updateDisplayName(String displayName) async {
    final ProfileData profile = await _updateDisplayName(
      UpdateDisplayNameParams(displayName: displayName),
    );
    emit(state.copyWith(profile: profile));
  }

  /// Recomputes the natal chart server-side. Throws
  /// [BirthProfileRateLimitedFailure] if changed within the last 24 hours —
  /// same propagate-to-caller approach as [updateDisplayName].
  Future<void> updateBirthProfile(BirthProfile birthProfile) async {
    final ProfileData profile = await _updateBirthProfile(
      UpdateBirthProfileParams(birthProfile: birthProfile),
    );
    emit(state.copyWith(profile: profile));
  }
}

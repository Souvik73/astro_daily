import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/profile_data.dart';
import '../../domain/usecases/get_profile.dart';

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
  ProfileCubit({required GetProfile getProfile})
    : _getProfile = getProfile,
      super(const ProfileState.initial());

  final GetProfile _getProfile;

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
}

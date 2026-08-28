import 'package:astro_daily/core/error/failures.dart';
import 'package:astro_daily/core/models/birth_profile.dart';
import 'package:astro_daily/core/models/subscription_models.dart';
import 'package:astro_daily/core/usecase/usecase.dart';
import 'package:astro_daily/features/profile/domain/entities/profile_data.dart';
import 'package:astro_daily/features/profile/domain/repositories/profile_repository.dart';
import 'package:astro_daily/features/profile/domain/usecases/get_profile.dart';
import 'package:astro_daily/features/profile/domain/usecases/update_birth_profile.dart';
import 'package:astro_daily/features/profile/domain/usecases/update_display_name.dart';
import 'package:astro_daily/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loadProfile emits success with the fetched profile', () async {
    final cubit = ProfileCubit(
      getProfile: _GetProfileUseCase(_profile(displayName: 'pilot')),
      updateDisplayName: _UpdateDisplayNameUseCase(),
      updateBirthProfile: _UpdateBirthProfileUseCase(),
    );

    await cubit.loadProfile();

    expect(cubit.state.status, ProfileStatus.success);
    expect(cubit.state.profile?.displayName, 'pilot');
    await cubit.close();
  });

  test('loadProfile emits failure with the failure message', () async {
    final cubit = ProfileCubit(
      getProfile: _GetProfileUseCase(
        null,
        error: const AuthFailure('No active profile.'),
      ),
      updateDisplayName: _UpdateDisplayNameUseCase(),
      updateBirthProfile: _UpdateBirthProfileUseCase(),
    );

    await cubit.loadProfile();

    expect(cubit.state.status, ProfileStatus.failure);
    expect(cubit.state.errorMessage, 'No active profile.');
    await cubit.close();
  });

  test('updateDisplayName updates the profile without touching status', () async {
    final cubit = ProfileCubit(
      getProfile: _GetProfileUseCase(_profile(displayName: 'old')),
      updateDisplayName: _UpdateDisplayNameUseCase(
        result: _profile(displayName: 'new'),
      ),
      updateBirthProfile: _UpdateBirthProfileUseCase(),
    );
    await cubit.loadProfile();

    await cubit.updateDisplayName('new');

    expect(cubit.state.status, ProfileStatus.success);
    expect(cubit.state.profile?.displayName, 'new');
    await cubit.close();
  });

  test('updateBirthProfile lets a rate-limit failure propagate to the caller', () async {
    final cubit = ProfileCubit(
      getProfile: _GetProfileUseCase(_profile(displayName: 'pilot')),
      updateDisplayName: _UpdateDisplayNameUseCase(),
      updateBirthProfile: _UpdateBirthProfileUseCase(
        error: const BirthProfileRateLimitedFailure(
          'Birth details can only be changed once every 24 hours.',
        ),
      ),
    );
    await cubit.loadProfile();

    expect(
      () => cubit.updateBirthProfile(_birthProfile()),
      throwsA(isA<BirthProfileRateLimitedFailure>()),
    );
    await cubit.close();
  });
}

BirthProfile _birthProfile() {
  return BirthProfile(
    zodiacSign: 'Aries',
    dateOfBirth: DateTime(1998, 4, 10),
    timeOfBirth: '06:30',
    placeOfBirth: 'Kolkata, India',
  );
}

ProfileData _profile({required String displayName}) {
  return ProfileData(
    displayName: displayName,
    email: 'pilot@astro.app',
    birthProfile: _birthProfile(),
    tier: SubscriptionTier.free,
  );
}

class _GetProfileUseCase extends GetProfile {
  _GetProfileUseCase(this._result, {Failure? error})
    : _error = error,
      super(_NoopProfileRepository());

  final ProfileData? _result;
  final Failure? _error;

  @override
  Future<ProfileData> call(NoParams params) async {
    final Failure? failure = _error;
    if (failure != null) throw failure;
    return _result!;
  }
}

class _UpdateDisplayNameUseCase extends UpdateDisplayName {
  _UpdateDisplayNameUseCase({ProfileData? result, Failure? error})
    : _result = result,
      _error = error,
      super(_NoopProfileRepository());

  final ProfileData? _result;
  final Failure? _error;

  @override
  Future<ProfileData> call(UpdateDisplayNameParams params) async {
    final Failure? failure = _error;
    if (failure != null) throw failure;
    return _result ?? _profile(displayName: params.displayName);
  }
}

class _UpdateBirthProfileUseCase extends UpdateBirthProfile {
  _UpdateBirthProfileUseCase({ProfileData? result, Failure? error})
    : _result = result,
      _error = error,
      super(_NoopProfileRepository());

  final ProfileData? _result;
  final Failure? _error;

  @override
  Future<ProfileData> call(UpdateBirthProfileParams params) async {
    final Failure? failure = _error;
    if (failure != null) throw failure;
    return _result ?? _profile(displayName: 'pilot');
  }
}

class _NoopProfileRepository implements ProfileRepository {
  const _NoopProfileRepository();

  @override
  Future<ProfileData> getProfile() => throw UnimplementedError();

  @override
  Future<ProfileData> updateDisplayName(String displayName) =>
      throw UnimplementedError();

  @override
  Future<ProfileData> updateBirthProfile(BirthProfile birthProfile) =>
      throw UnimplementedError();
}

import 'package:astro_daily/core/error/failures.dart';
import 'package:astro_daily/core/models/birth_profile.dart';
import 'package:astro_daily/core/models/subscription_models.dart';
import 'package:astro_daily/core/usecase/usecase.dart';
import 'package:astro_daily/features/profile/domain/entities/profile_data.dart';
import 'package:astro_daily/features/profile/domain/repositories/profile_repository.dart';
import 'package:astro_daily/features/profile/domain/usecases/get_profile.dart';
import 'package:astro_daily/features/profile/domain/usecases/update_birth_profile.dart';
import 'package:astro_daily/features/profile/domain/usecases/update_display_name.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeProfileRepository repository;

  setUp(() {
    repository = _FakeProfileRepository();
  });

  test('GetProfile returns the profile from the repository', () async {
    repository.profile = _profile(displayName: 'pilot');
    final useCase = GetProfile(repository);

    final result = await useCase(const NoParams());

    expect(result.displayName, 'pilot');
  });

  test('GetProfile propagates repository failures', () async {
    repository.error = const AuthFailure('No active profile.');
    final useCase = GetProfile(repository);

    expect(() => useCase(const NoParams()), throwsA(isA<AuthFailure>()));
  });

  test('UpdateDisplayName passes the new name through', () async {
    repository.profile = _profile(displayName: 'new name');
    final useCase = UpdateDisplayName(repository);

    final result = await useCase(
      const UpdateDisplayNameParams(displayName: 'new name'),
    );

    expect(repository.requestedDisplayName, 'new name');
    expect(result.displayName, 'new name');
  });

  test('UpdateBirthProfile passes the new birth profile through', () async {
    final newBirth = _birthProfile();
    repository.profile = _profile(displayName: 'pilot', birthProfile: newBirth);
    final useCase = UpdateBirthProfile(repository);

    final result = await useCase(
      UpdateBirthProfileParams(birthProfile: newBirth),
    );

    expect(repository.requestedBirthProfile?.placeOfBirth, 'Kolkata, India');
    expect(result.birthProfile.placeOfBirth, 'Kolkata, India');
  });

  test('UpdateBirthProfile propagates a rate-limit failure', () async {
    repository.error = const BirthProfileRateLimitedFailure(
      'Birth details can only be changed once every 24 hours.',
    );
    final useCase = UpdateBirthProfile(repository);

    expect(
      () => useCase(UpdateBirthProfileParams(birthProfile: _birthProfile())),
      throwsA(isA<BirthProfileRateLimitedFailure>()),
    );
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

ProfileData _profile({
  required String displayName,
  BirthProfile? birthProfile,
}) {
  return ProfileData(
    displayName: displayName,
    email: 'pilot@astro.app',
    birthProfile: birthProfile ?? _birthProfile(),
    tier: SubscriptionTier.free,
  );
}

class _FakeProfileRepository implements ProfileRepository {
  ProfileData? profile;
  Failure? error;

  String? requestedDisplayName;
  BirthProfile? requestedBirthProfile;

  @override
  Future<ProfileData> getProfile() async {
    final Failure? failure = error;
    if (failure != null) throw failure;
    return profile!;
  }

  @override
  Future<ProfileData> updateDisplayName(String displayName) async {
    requestedDisplayName = displayName;
    final Failure? failure = error;
    if (failure != null) throw failure;
    return profile!;
  }

  @override
  Future<ProfileData> updateBirthProfile(BirthProfile birthProfile) async {
    requestedBirthProfile = birthProfile;
    final Failure? failure = error;
    if (failure != null) throw failure;
    return profile!;
  }
}

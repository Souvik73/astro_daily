import 'package:astro_daily/core/error/failures.dart';
import 'package:astro_daily/core/usecase/usecase.dart';
import 'package:astro_daily/features/settings/domain/entities/settings_preferences.dart';
import 'package:astro_daily/features/settings/domain/repositories/settings_repository.dart';
import 'package:astro_daily/features/settings/domain/usecases/delete_account.dart';
import 'package:astro_daily/features/settings/domain/usecases/get_settings_preferences.dart';
import 'package:astro_daily/features/settings/domain/usecases/update_local_ai_enabled.dart';
import 'package:astro_daily/features/settings/domain/usecases/update_push_enabled.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeSettingsRepository repository;

  setUp(() {
    repository = _FakeSettingsRepository();
  });

  test('GetSettingsPreferences returns preferences from the repository', () async {
    repository.preferences = const SettingsPreferences(
      pushEnabled: true,
      localAiEnabled: false,
    );
    final useCase = GetSettingsPreferences(repository);

    final result = await useCase(const NoParams());

    expect(result.pushEnabled, isTrue);
    expect(result.localAiEnabled, isFalse);
  });

  test('UpdatePushEnabled passes the flag through', () async {
    repository.preferences = const SettingsPreferences(
      pushEnabled: true,
      localAiEnabled: true,
    );
    final useCase = UpdatePushEnabled(repository);

    await useCase(const UpdatePushEnabledParams(enabled: true));

    expect(repository.requestedPushEnabled, isTrue);
  });

  test('UpdatePushEnabled propagates an unavailable failure', () async {
    repository.error = const PushUnavailableFailure();
    final useCase = UpdatePushEnabled(repository);

    expect(
      () => useCase(const UpdatePushEnabledParams(enabled: true)),
      throwsA(isA<PushUnavailableFailure>()),
    );
  });

  test('UpdateLocalAiEnabled passes the flag through', () async {
    repository.preferences = const SettingsPreferences(
      pushEnabled: false,
      localAiEnabled: true,
    );
    final useCase = UpdateLocalAiEnabled(repository);

    await useCase(const UpdateLocalAiEnabledParams(enabled: true));

    expect(repository.requestedLocalAiEnabled, isTrue);
  });

  test('DeleteAccount delegates to the repository', () async {
    final useCase = DeleteAccount(repository);

    await useCase(const NoParams());

    expect(repository.deleteAccountCalled, isTrue);
  });
}

class _FakeSettingsRepository implements SettingsRepository {
  SettingsPreferences? preferences;
  Failure? error;

  bool? requestedPushEnabled;
  bool? requestedLocalAiEnabled;
  bool deleteAccountCalled = false;

  @override
  Future<SettingsPreferences> getPreferences() async {
    final Failure? failure = error;
    if (failure != null) throw failure;
    return preferences!;
  }

  @override
  Future<SettingsPreferences> updatePushEnabled(bool enabled) async {
    requestedPushEnabled = enabled;
    final Failure? failure = error;
    if (failure != null) throw failure;
    return preferences!;
  }

  @override
  Future<SettingsPreferences> updateLocalAiEnabled(bool enabled) async {
    requestedLocalAiEnabled = enabled;
    final Failure? failure = error;
    if (failure != null) throw failure;
    return preferences!;
  }

  @override
  Future<void> deleteAccount() async {
    deleteAccountCalled = true;
    final Failure? failure = error;
    if (failure != null) throw failure;
  }
}

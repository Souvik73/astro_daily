import 'package:astro_daily/core/error/failures.dart';
import 'package:astro_daily/core/usecase/usecase.dart';
import 'package:astro_daily/features/settings/domain/entities/settings_preferences.dart';
import 'package:astro_daily/features/settings/domain/repositories/settings_repository.dart';
import 'package:astro_daily/features/settings/domain/usecases/delete_account.dart';
import 'package:astro_daily/features/settings/domain/usecases/get_settings_preferences.dart';
import 'package:astro_daily/features/settings/domain/usecases/update_local_ai_enabled.dart';
import 'package:astro_daily/features/settings/domain/usecases/update_push_enabled.dart';
import 'package:astro_daily/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loadPreferences emits success with the fetched preferences', () async {
    final cubit = SettingsCubit(
      getSettingsPreferences: _GetPreferencesUseCase(
        const SettingsPreferences(pushEnabled: true, localAiEnabled: true),
      ),
      updatePushEnabled: _UpdatePushUseCase(),
      updateLocalAiEnabled: _UpdateLocalAiUseCase(),
      deleteAccount: _DeleteAccountUseCase(),
    );

    await cubit.loadPreferences();

    expect(cubit.state.status, SettingsStatus.success);
    expect(cubit.state.preferences?.pushEnabled, isTrue);
    await cubit.close();
  });

  test('setPushEnabled(true) succeeding leaves no info message', () async {
    final cubit = SettingsCubit(
      getSettingsPreferences: _GetPreferencesUseCase(
        const SettingsPreferences(pushEnabled: false, localAiEnabled: true),
      ),
      updatePushEnabled: _UpdatePushUseCase(
        result: const SettingsPreferences(pushEnabled: true, localAiEnabled: true),
      ),
      updateLocalAiEnabled: _UpdateLocalAiUseCase(),
      deleteAccount: _DeleteAccountUseCase(),
    );

    await cubit.setPushEnabled(true);

    expect(cubit.state.preferences?.pushEnabled, isTrue);
    expect(cubit.state.infoMessage, isNull);
    await cubit.close();
  });

  test('setPushEnabled(true) that gets denied explains why the switch snapped back', () async {
    final cubit = SettingsCubit(
      getSettingsPreferences: _GetPreferencesUseCase(
        const SettingsPreferences(pushEnabled: false, localAiEnabled: true),
      ),
      updatePushEnabled: _UpdatePushUseCase(
        result: const SettingsPreferences(pushEnabled: false, localAiEnabled: true),
      ),
      updateLocalAiEnabled: _UpdateLocalAiUseCase(),
      deleteAccount: _DeleteAccountUseCase(),
    );

    await cubit.setPushEnabled(true);

    expect(cubit.state.preferences?.pushEnabled, isFalse);
    expect(cubit.state.infoMessage, 'Notifications permission was declined.');
    await cubit.close();
  });

  test('setPushEnabled(true) when push is unavailable shows a distinct message', () async {
    final cubit = SettingsCubit(
      getSettingsPreferences: _GetPreferencesUseCase(
        const SettingsPreferences(pushEnabled: false, localAiEnabled: true),
      ),
      updatePushEnabled: _UpdatePushUseCase(
        error: const PushUnavailableFailure(),
      ),
      updateLocalAiEnabled: _UpdateLocalAiUseCase(),
      deleteAccount: _DeleteAccountUseCase(),
    );

    await cubit.setPushEnabled(true);

    expect(cubit.state.status, SettingsStatus.success);
    expect(
      cubit.state.infoMessage,
      'Push notifications are not set up for this app yet.',
    );
    await cubit.close();
  });

  test('deleteAccount emits deleting then success', () async {
    final cubit = SettingsCubit(
      getSettingsPreferences: _GetPreferencesUseCase(
        const SettingsPreferences(pushEnabled: true, localAiEnabled: true),
      ),
      updatePushEnabled: _UpdatePushUseCase(),
      updateLocalAiEnabled: _UpdateLocalAiUseCase(),
      deleteAccount: _DeleteAccountUseCase(),
    );

    await cubit.deleteAccount();

    expect(cubit.state.status, SettingsStatus.success);
    expect(cubit.state.infoMessage, 'Account deleted.');
    await cubit.close();
  });

  test('deleteAccount emits failure when the use case throws', () async {
    final cubit = SettingsCubit(
      getSettingsPreferences: _GetPreferencesUseCase(
        const SettingsPreferences(pushEnabled: true, localAiEnabled: true),
      ),
      updatePushEnabled: _UpdatePushUseCase(),
      updateLocalAiEnabled: _UpdateLocalAiUseCase(),
      deleteAccount: _DeleteAccountUseCase(error: const DataFailure('boom')),
    );

    await cubit.deleteAccount();

    expect(cubit.state.status, SettingsStatus.failure);
    expect(cubit.state.errorMessage, 'Account deletion failed.');
    await cubit.close();
  });
}

class _GetPreferencesUseCase extends GetSettingsPreferences {
  _GetPreferencesUseCase(this._result) : super(_NoopSettingsRepository());

  final SettingsPreferences _result;

  @override
  Future<SettingsPreferences> call(NoParams params) async => _result;
}

class _UpdatePushUseCase extends UpdatePushEnabled {
  _UpdatePushUseCase({SettingsPreferences? result, Failure? error})
    : _result = result,
      _error = error,
      super(_NoopSettingsRepository());

  final SettingsPreferences? _result;
  final Failure? _error;

  @override
  Future<SettingsPreferences> call(UpdatePushEnabledParams params) async {
    final Failure? failure = _error;
    if (failure != null) throw failure;
    return _result!;
  }
}

class _UpdateLocalAiUseCase extends UpdateLocalAiEnabled {
  _UpdateLocalAiUseCase({SettingsPreferences? result})
    : _result = result,
      super(_NoopSettingsRepository());

  final SettingsPreferences? _result;

  @override
  Future<SettingsPreferences> call(UpdateLocalAiEnabledParams params) async {
    return _result ??
        SettingsPreferences(pushEnabled: true, localAiEnabled: params.enabled);
  }
}

class _DeleteAccountUseCase extends DeleteAccount {
  _DeleteAccountUseCase({this.error}) : super(_NoopSettingsRepository());

  final Failure? error;

  @override
  Future<void> call(NoParams params) async {
    final Failure? failure = error;
    if (failure != null) throw failure;
  }
}

class _NoopSettingsRepository implements SettingsRepository {
  const _NoopSettingsRepository();

  @override
  Future<SettingsPreferences> getPreferences() => throw UnimplementedError();

  @override
  Future<SettingsPreferences> updatePushEnabled(bool enabled) =>
      throw UnimplementedError();

  @override
  Future<SettingsPreferences> updateLocalAiEnabled(bool enabled) =>
      throw UnimplementedError();

  @override
  Future<void> deleteAccount() => throw UnimplementedError();
}

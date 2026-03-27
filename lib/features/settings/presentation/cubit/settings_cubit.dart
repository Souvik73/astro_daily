import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/settings_preferences.dart';
import '../../domain/usecases/delete_account.dart';
import '../../domain/usecases/get_settings_preferences.dart';
import '../../domain/usecases/update_local_ai_enabled.dart';
import '../../domain/usecases/update_push_enabled.dart';

enum SettingsStatus { initial, loading, success, failure, deleting }

class SettingsState extends Equatable {
  const SettingsState({
    required this.status,
    this.preferences,
    this.errorMessage,
    this.infoMessage,
  });

  const SettingsState.initial() : this(status: SettingsStatus.initial);

  final SettingsStatus status;
  final SettingsPreferences? preferences;
  final String? errorMessage;
  final String? infoMessage;

  SettingsState copyWith({
    SettingsStatus? status,
    SettingsPreferences? preferences,
    String? errorMessage,
    String? infoMessage,
  }) {
    return SettingsState(
      status: status ?? this.status,
      preferences: preferences ?? this.preferences,
      errorMessage: errorMessage,
      infoMessage: infoMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    preferences,
    errorMessage,
    infoMessage,
  ];
}

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit({
    required GetSettingsPreferences getSettingsPreferences,
    required UpdatePushEnabled updatePushEnabled,
    required UpdateLocalAiEnabled updateLocalAiEnabled,
    required DeleteAccount deleteAccount,
  }) : _getSettingsPreferences = getSettingsPreferences,
       _updatePushEnabled = updatePushEnabled,
       _updateLocalAiEnabled = updateLocalAiEnabled,
       _deleteAccount = deleteAccount,
       super(const SettingsState.initial());

  final GetSettingsPreferences _getSettingsPreferences;
  final UpdatePushEnabled _updatePushEnabled;
  final UpdateLocalAiEnabled _updateLocalAiEnabled;
  final DeleteAccount _deleteAccount;

  Future<void> loadPreferences() async {
    emit(
      state.copyWith(
        status: SettingsStatus.loading,
        errorMessage: null,
        infoMessage: null,
      ),
    );
    try {
      final SettingsPreferences preferences = await _getSettingsPreferences(
        const NoParams(),
      );
      emit(
        state.copyWith(
          status: SettingsStatus.success,
          preferences: preferences,
        ),
      );
    } on Failure catch (failure) {
      emit(
        state.copyWith(
          status: SettingsStatus.failure,
          errorMessage: failure.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: SettingsStatus.failure,
          errorMessage: 'Unable to load settings.',
        ),
      );
    }
  }

  Future<void> setPushEnabled(bool enabled) async {
    try {
      final SettingsPreferences preferences = await _updatePushEnabled(
        UpdatePushEnabledParams(enabled: enabled),
      );
      emit(
        state.copyWith(
          status: SettingsStatus.success,
          preferences: preferences,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: SettingsStatus.failure,
          errorMessage: 'Unable to update push preference.',
        ),
      );
    }
  }

  Future<void> setLocalAiEnabled(bool enabled) async {
    try {
      final SettingsPreferences preferences = await _updateLocalAiEnabled(
        UpdateLocalAiEnabledParams(enabled: enabled),
      );
      emit(
        state.copyWith(
          status: SettingsStatus.success,
          preferences: preferences,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: SettingsStatus.failure,
          errorMessage: 'Unable to update personalization preference.',
        ),
      );
    }
  }

  Future<void> deleteAccount() async {
    emit(
      state.copyWith(
        status: SettingsStatus.deleting,
        errorMessage: null,
        infoMessage: null,
      ),
    );
    try {
      await _deleteAccount(const NoParams());
      emit(
        state.copyWith(
          status: SettingsStatus.success,
          infoMessage: 'Account deleted.',
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: SettingsStatus.failure,
          errorMessage: 'Account deletion failed.',
        ),
      );
    }
  }

  void clearMessages() {
    emit(state.copyWith(errorMessage: null, infoMessage: null));
  }
}

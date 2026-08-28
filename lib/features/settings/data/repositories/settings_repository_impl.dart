import '../../../../core/error/failures.dart';
import '../../../../core/services/contracts.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/settings_preferences.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_local_data_source.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl({
    required SettingsLocalDataSource localDataSource,
    required AuthRepository authRepository,
    required PushNotificationGateway pushNotificationGateway,
  }) : _localDataSource = localDataSource,
       _authRepository = authRepository,
       _pushNotificationGateway = pushNotificationGateway;

  final SettingsLocalDataSource _localDataSource;
  final AuthRepository _authRepository;
  final PushNotificationGateway _pushNotificationGateway;

  @override
  Future<void> deleteAccount() async {
    await _authRepository.deleteAccount();
  }

  @override
  Future<SettingsPreferences> getPreferences() {
    return _localDataSource.getPreferences();
  }

  @override
  Future<SettingsPreferences> updateLocalAiEnabled(bool enabled) {
    return _localDataSource.updateLocalAiEnabled(enabled);
  }

  @override
  Future<SettingsPreferences> updatePushEnabled(bool enabled) async {
    if (enabled) {
      final PushPermissionResult result = await _pushNotificationGateway
          .requestPermissionAndRegister();
      if (result == PushPermissionResult.unavailable) {
        // Distinct from "denied" — the user never got an OS prompt to
        // answer, so don't record this as their choice. The switch stays
        // wherever it already was.
        throw const PushUnavailableFailure();
      }
      return _localDataSource.updatePushEnabled(
        result == PushPermissionResult.granted,
      );
    }
    await _pushNotificationGateway.unregister();
    return _localDataSource.updatePushEnabled(false);
  }
}

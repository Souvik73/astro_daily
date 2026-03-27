import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/settings_preferences.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_local_data_source.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl({
    required SettingsLocalDataSource localDataSource,
    required AuthRepository authRepository,
  }) : _localDataSource = localDataSource,
       _authRepository = authRepository;

  final SettingsLocalDataSource _localDataSource;
  final AuthRepository _authRepository;

  @override
  Future<void> deleteAccount() async {
    await _authRepository.signOut();
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
  Future<SettingsPreferences> updatePushEnabled(bool enabled) {
    return _localDataSource.updatePushEnabled(enabled);
  }
}

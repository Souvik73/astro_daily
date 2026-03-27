import '../../domain/entities/settings_preferences.dart';

abstract class SettingsLocalDataSource {
  Future<SettingsPreferences> getPreferences();
  Future<SettingsPreferences> updatePushEnabled(bool enabled);
  Future<SettingsPreferences> updateLocalAiEnabled(bool enabled);
}

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  SettingsPreferences _preferences = const SettingsPreferences(
    pushEnabled: true,
    localAiEnabled: true,
  );

  @override
  Future<SettingsPreferences> getPreferences() async {
    return _preferences;
  }

  @override
  Future<SettingsPreferences> updateLocalAiEnabled(bool enabled) async {
    _preferences = _preferences.copyWith(localAiEnabled: enabled);
    return _preferences;
  }

  @override
  Future<SettingsPreferences> updatePushEnabled(bool enabled) async {
    _preferences = _preferences.copyWith(pushEnabled: enabled);
    return _preferences;
  }
}

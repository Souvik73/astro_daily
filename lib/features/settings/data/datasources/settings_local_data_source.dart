import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/settings_preferences.dart';

abstract class SettingsLocalDataSource {
  Future<SettingsPreferences> getPreferences();
  Future<SettingsPreferences> updatePushEnabled(bool enabled);
  Future<SettingsPreferences> updateLocalAiEnabled(bool enabled);
}

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  SettingsLocalDataSourceImpl({required SharedPreferences preferences})
    : _preferences = preferences;

  static const String _pushEnabledKey = 'settings_push_enabled';
  static const String _localAiEnabledKey = 'settings_local_ai_enabled';

  final SharedPreferences _preferences;

  @override
  Future<SettingsPreferences> getPreferences() async {
    return SettingsPreferences(
      pushEnabled: _preferences.getBool(_pushEnabledKey) ?? true,
      localAiEnabled: _preferences.getBool(_localAiEnabledKey) ?? true,
    );
  }

  @override
  Future<SettingsPreferences> updateLocalAiEnabled(bool enabled) async {
    await _preferences.setBool(_localAiEnabledKey, enabled);
    return getPreferences();
  }

  @override
  Future<SettingsPreferences> updatePushEnabled(bool enabled) async {
    await _preferences.setBool(_pushEnabledKey, enabled);
    return getPreferences();
  }
}

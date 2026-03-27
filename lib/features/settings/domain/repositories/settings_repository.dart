import '../entities/settings_preferences.dart';

abstract class SettingsRepository {
  Future<SettingsPreferences> getPreferences();
  Future<SettingsPreferences> updatePushEnabled(bool enabled);
  Future<SettingsPreferences> updateLocalAiEnabled(bool enabled);
  Future<void> deleteAccount();
}

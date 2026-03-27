import '../../../../core/usecase/usecase.dart';
import '../entities/settings_preferences.dart';
import '../repositories/settings_repository.dart';

class GetSettingsPreferences
    implements UseCase<Future<SettingsPreferences>, NoParams> {
  GetSettingsPreferences(this._repository);

  final SettingsRepository _repository;

  @override
  Future<SettingsPreferences> call(NoParams params) {
    return _repository.getPreferences();
  }
}

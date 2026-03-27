import '../../../../core/usecase/usecase.dart';
import '../entities/settings_preferences.dart';
import '../repositories/settings_repository.dart';

class UpdateLocalAiEnabled
    implements
        UseCase<Future<SettingsPreferences>, UpdateLocalAiEnabledParams> {
  UpdateLocalAiEnabled(this._repository);

  final SettingsRepository _repository;

  @override
  Future<SettingsPreferences> call(UpdateLocalAiEnabledParams params) {
    return _repository.updateLocalAiEnabled(params.enabled);
  }
}

class UpdateLocalAiEnabledParams {
  const UpdateLocalAiEnabledParams({required this.enabled});

  final bool enabled;
}

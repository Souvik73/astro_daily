import '../../../../core/usecase/usecase.dart';
import '../entities/settings_preferences.dart';
import '../repositories/settings_repository.dart';

class UpdatePushEnabled
    implements UseCase<Future<SettingsPreferences>, UpdatePushEnabledParams> {
  UpdatePushEnabled(this._repository);

  final SettingsRepository _repository;

  @override
  Future<SettingsPreferences> call(UpdatePushEnabledParams params) {
    return _repository.updatePushEnabled(params.enabled);
  }
}

class UpdatePushEnabledParams {
  const UpdatePushEnabledParams({required this.enabled});

  final bool enabled;
}

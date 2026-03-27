import '../../../../core/usecase/usecase.dart';
import '../repositories/settings_repository.dart';

class DeleteAccount implements UseCase<Future<void>, NoParams> {
  DeleteAccount(this._repository);

  final SettingsRepository _repository;

  @override
  Future<void> call(NoParams params) {
    return _repository.deleteAccount();
  }
}

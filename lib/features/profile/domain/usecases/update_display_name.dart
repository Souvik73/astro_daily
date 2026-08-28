import '../../../../core/usecase/usecase.dart';
import '../entities/profile_data.dart';
import '../repositories/profile_repository.dart';

class UpdateDisplayName
    implements UseCase<Future<ProfileData>, UpdateDisplayNameParams> {
  UpdateDisplayName(this._repository);

  final ProfileRepository _repository;

  @override
  Future<ProfileData> call(UpdateDisplayNameParams params) {
    return _repository.updateDisplayName(params.displayName);
  }
}

class UpdateDisplayNameParams {
  const UpdateDisplayNameParams({required this.displayName});

  final String displayName;
}

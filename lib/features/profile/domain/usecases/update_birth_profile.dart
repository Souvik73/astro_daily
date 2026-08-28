import '../../../../core/models/birth_profile.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/profile_data.dart';
import '../repositories/profile_repository.dart';

class UpdateBirthProfile
    implements UseCase<Future<ProfileData>, UpdateBirthProfileParams> {
  UpdateBirthProfile(this._repository);

  final ProfileRepository _repository;

  @override
  Future<ProfileData> call(UpdateBirthProfileParams params) {
    return _repository.updateBirthProfile(params.birthProfile);
  }
}

class UpdateBirthProfileParams {
  const UpdateBirthProfileParams({required this.birthProfile});

  final BirthProfile birthProfile;
}

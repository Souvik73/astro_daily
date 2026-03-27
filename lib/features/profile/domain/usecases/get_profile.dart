import '../../../../core/usecase/usecase.dart';
import '../entities/profile_data.dart';
import '../repositories/profile_repository.dart';

class GetProfile implements UseCase<Future<ProfileData>, NoParams> {
  GetProfile(this._repository);

  final ProfileRepository _repository;

  @override
  Future<ProfileData> call(NoParams params) {
    return _repository.getProfile();
  }
}

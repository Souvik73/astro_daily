import '../../../../core/models/birth_profile.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/matching_repository.dart';

class GetSavedPartner implements UseCase<Future<BirthProfile?>, NoParams> {
  GetSavedPartner(this._repository);

  final MatchingRepository _repository;

  @override
  Future<BirthProfile?> call(NoParams params) {
    return _repository.getSavedPartner();
  }
}

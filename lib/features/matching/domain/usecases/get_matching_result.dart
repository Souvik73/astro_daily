import '../../../../core/models/birth_profile.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/matching_result.dart';
import '../repositories/matching_repository.dart';

class GetMatchingResult
    implements UseCase<Future<MatchingResult>, GetMatchingResultParams> {
  GetMatchingResult(this._repository);

  final MatchingRepository _repository;

  @override
  Future<MatchingResult> call(GetMatchingResultParams params) {
    return _repository.getMatchingResult(params.partner);
  }
}

class GetMatchingResultParams {
  const GetMatchingResultParams({required this.partner});

  final BirthProfile partner;
}

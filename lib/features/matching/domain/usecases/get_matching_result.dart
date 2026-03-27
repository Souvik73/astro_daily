import '../../../../core/usecase/usecase.dart';
import '../entities/matching_result.dart';
import '../repositories/matching_repository.dart';

class GetMatchingResult implements UseCase<Future<MatchingResult>, NoParams> {
  GetMatchingResult(this._repository);

  final MatchingRepository _repository;

  @override
  Future<MatchingResult> call(NoParams params) {
    return _repository.getMatchingResult();
  }
}

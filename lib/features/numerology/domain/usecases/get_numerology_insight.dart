import '../../../../core/usecase/usecase.dart';
import '../entities/numerology_insight.dart';
import '../repositories/numerology_repository.dart';

class GetNumerologyInsight
    implements UseCase<Future<NumerologyInsight>, NoParams> {
  GetNumerologyInsight(this._repository);

  final NumerologyRepository _repository;

  @override
  Future<NumerologyInsight> call(NoParams params) {
    return _repository.getNumerologyInsight();
  }
}

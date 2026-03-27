import '../../../../core/usecase/usecase.dart';
import '../entities/kundli_insight.dart';
import '../repositories/kundli_repository.dart';

class GetKundliInsight implements UseCase<Future<KundliInsight>, NoParams> {
  GetKundliInsight(this._repository);

  final KundliRepository _repository;

  @override
  Future<KundliInsight> call(NoParams params) {
    return _repository.getKundliInsight();
  }
}

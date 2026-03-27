import '../../../../core/usecase/usecase.dart';
import '../entities/gemstone_insight.dart';
import '../repositories/gemstones_repository.dart';

class GetGemstoneInsight implements UseCase<Future<GemstoneInsight>, NoParams> {
  GetGemstoneInsight(this._repository);

  final GemstonesRepository _repository;

  @override
  Future<GemstoneInsight> call(NoParams params) {
    return _repository.getGemstoneInsight();
  }
}

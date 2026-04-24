import '../../../../core/services/contracts.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/feature_access_decision.dart';
import '../repositories/home_repository.dart';

class GrantFeatureReward
    implements
        UseCase<Future<FeatureAccessDecision>, GrantFeatureRewardParams> {
  GrantFeatureReward(this._repository);

  final HomeRepository _repository;

  @override
  Future<FeatureAccessDecision> call(GrantFeatureRewardParams params) {
    return _repository.grantFeatureReward(params.feature);
  }
}

class GrantFeatureRewardParams {
  const GrantFeatureRewardParams({required this.feature});

  final AppFeature feature;
}

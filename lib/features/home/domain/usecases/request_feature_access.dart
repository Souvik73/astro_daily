import '../../../../core/services/contracts.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/feature_access_decision.dart';
import '../repositories/home_repository.dart';

class RequestFeatureAccess
    implements
        UseCase<Future<FeatureAccessDecision>, RequestFeatureAccessParams> {
  RequestFeatureAccess(this._repository);

  final HomeRepository _repository;

  @override
  Future<FeatureAccessDecision> call(RequestFeatureAccessParams params) {
    return _repository.requestFeatureAccess(params.feature);
  }
}

class RequestFeatureAccessParams {
  const RequestFeatureAccessParams({required this.feature});

  final AppFeature feature;
}

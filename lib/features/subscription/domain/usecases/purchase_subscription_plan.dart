import '../../../../core/models/subscription_models.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/subscription_overview.dart';
import '../repositories/subscription_repository.dart';

class PurchaseSubscriptionPlan
    implements
        UseCase<Future<SubscriptionOverview>, PurchaseSubscriptionPlanParams> {
  PurchaseSubscriptionPlan(this._repository);

  final SubscriptionRepository _repository;

  @override
  Future<SubscriptionOverview> call(PurchaseSubscriptionPlanParams params) {
    return _repository.purchasePlan(params.planType);
  }
}

class PurchaseSubscriptionPlanParams {
  const PurchaseSubscriptionPlanParams({required this.planType});

  final PlanType planType;
}

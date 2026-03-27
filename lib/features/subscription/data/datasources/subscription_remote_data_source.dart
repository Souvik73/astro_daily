import '../../../../core/models/subscription_models.dart';
import '../../../../core/services/contracts.dart';

abstract class SubscriptionRemoteDataSource {
  Future<PurchaseStatus> startPurchase(PlanType planType);
  Future<void> restorePurchases();
  Future<SubscriptionEntitlement> syncEntitlement();
}

class SubscriptionRemoteDataSourceImpl implements SubscriptionRemoteDataSource {
  SubscriptionRemoteDataSourceImpl({required BillingGateway billingGateway})
    : _billingGateway = billingGateway;

  final BillingGateway _billingGateway;

  @override
  Future<void> restorePurchases() {
    return _billingGateway.restorePurchases();
  }

  @override
  Future<SubscriptionEntitlement> syncEntitlement() {
    return _billingGateway.syncEntitlement();
  }

  @override
  Future<PurchaseStatus> startPurchase(PlanType planType) {
    return _billingGateway.startPurchase(planType);
  }
}

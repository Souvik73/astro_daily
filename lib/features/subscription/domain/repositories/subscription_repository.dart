import '../../../../core/models/subscription_models.dart';
import '../entities/subscription_overview.dart';

abstract class SubscriptionRepository {
  Future<SubscriptionOverview> getOverview();
  Future<SubscriptionOverview> purchasePlan(PlanType planType);
  Future<SubscriptionOverview> restorePurchases();
}

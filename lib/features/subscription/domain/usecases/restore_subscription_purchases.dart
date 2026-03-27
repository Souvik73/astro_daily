import '../../../../core/usecase/usecase.dart';
import '../entities/subscription_overview.dart';
import '../repositories/subscription_repository.dart';

class RestoreSubscriptionPurchases
    implements UseCase<Future<SubscriptionOverview>, NoParams> {
  RestoreSubscriptionPurchases(this._repository);

  final SubscriptionRepository _repository;

  @override
  Future<SubscriptionOverview> call(NoParams params) {
    return _repository.restorePurchases();
  }
}

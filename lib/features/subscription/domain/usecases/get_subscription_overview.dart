import '../../../../core/usecase/usecase.dart';
import '../entities/subscription_overview.dart';
import '../repositories/subscription_repository.dart';

class GetSubscriptionOverview
    implements UseCase<Future<SubscriptionOverview>, NoParams> {
  GetSubscriptionOverview(this._repository);

  final SubscriptionRepository _repository;

  @override
  Future<SubscriptionOverview> call(NoParams params) {
    return _repository.getOverview();
  }
}

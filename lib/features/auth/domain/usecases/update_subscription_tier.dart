import '../../../../core/models/subscription_models.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

class UpdateSubscriptionTier
    implements UseCase<Future<void>, UpdateSubscriptionTierParams> {
  UpdateSubscriptionTier(this._authRepository);

  final AuthRepository _authRepository;

  @override
  Future<void> call(UpdateSubscriptionTierParams params) {
    return _authRepository.updateSubscriptionTier(params.tier);
  }
}

class UpdateSubscriptionTierParams {
  const UpdateSubscriptionTierParams({required this.tier});

  final SubscriptionTier tier;
}

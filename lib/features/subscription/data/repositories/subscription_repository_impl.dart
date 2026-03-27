import '../../../../core/error/failures.dart';
import '../../../../core/models/subscription_models.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/subscription_overview.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../datasources/subscription_remote_data_source.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  SubscriptionRepositoryImpl({
    required SubscriptionRemoteDataSource remoteDataSource,
    required AuthRepository authRepository,
  }) : _remoteDataSource = remoteDataSource,
       _authRepository = authRepository;

  final SubscriptionRemoteDataSource _remoteDataSource;
  final AuthRepository _authRepository;

  @override
  Future<SubscriptionOverview> getOverview() async {
    final SubscriptionEntitlement entitlement = await _remoteDataSource
        .syncEntitlement();
    await _authRepository.updateSubscriptionTier(entitlement.tier);
    return SubscriptionOverview(
      tier: entitlement.tier,
      expiresAt: entitlement.expiresAt,
    );
  }

  @override
  Future<SubscriptionOverview> purchasePlan(PlanType planType) async {
    final PurchaseStatus status = await _remoteDataSource.startPurchase(
      planType,
    );
    if (status == PurchaseStatus.failed) {
      throw const DataFailure('Purchase failed. Please try again.');
    }
    final SubscriptionEntitlement entitlement = await _remoteDataSource
        .syncEntitlement();
    await _authRepository.updateSubscriptionTier(entitlement.tier);
    return SubscriptionOverview(
      tier: entitlement.tier,
      expiresAt: entitlement.expiresAt,
    );
  }

  @override
  Future<SubscriptionOverview> restorePurchases() async {
    await _remoteDataSource.restorePurchases();
    final SubscriptionEntitlement entitlement = await _remoteDataSource
        .syncEntitlement();
    await _authRepository.updateSubscriptionTier(entitlement.tier);
    return SubscriptionOverview(
      tier: entitlement.tier,
      expiresAt: entitlement.expiresAt,
    );
  }
}

import 'package:astro_daily/core/error/failures.dart';
import 'package:astro_daily/core/models/subscription_models.dart';
import 'package:astro_daily/core/usecase/usecase.dart';
import 'package:astro_daily/features/subscription/domain/entities/subscription_overview.dart';
import 'package:astro_daily/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:astro_daily/features/subscription/domain/usecases/get_subscription_overview.dart';
import 'package:astro_daily/features/subscription/domain/usecases/purchase_subscription_plan.dart';
import 'package:astro_daily/features/subscription/domain/usecases/restore_subscription_purchases.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeSubscriptionRepository repository;

  setUp(() {
    repository = _FakeSubscriptionRepository();
  });

  test('GetSubscriptionOverview returns the overview from the repository', () async {
    repository.overview = const SubscriptionOverview(
      tier: SubscriptionTier.free,
    );
    final useCase = GetSubscriptionOverview(repository);

    final result = await useCase(const NoParams());

    expect(result.tier, SubscriptionTier.free);
  });

  test('PurchaseSubscriptionPlan passes the plan type through', () async {
    final expiry = DateTime(2027, 1, 1);
    repository.overview = SubscriptionOverview(
      tier: SubscriptionTier.premium,
      expiresAt: expiry,
    );
    final useCase = PurchaseSubscriptionPlan(repository);

    final result = await useCase(
      const PurchaseSubscriptionPlanParams(planType: PlanType.yearly),
    );

    expect(repository.requestedPlanType, PlanType.yearly);
    expect(result.tier, SubscriptionTier.premium);
    expect(result.expiresAt, expiry);
  });

  test('PurchaseSubscriptionPlan propagates a failed purchase', () async {
    repository.error = const DataFailure('Purchase failed. Please try again.');
    final useCase = PurchaseSubscriptionPlan(repository);

    expect(
      () => useCase(
        const PurchaseSubscriptionPlanParams(planType: PlanType.monthly),
      ),
      throwsA(isA<DataFailure>()),
    );
  });

  test('RestoreSubscriptionPurchases returns the restored overview', () async {
    repository.overview = const SubscriptionOverview(
      tier: SubscriptionTier.premium,
    );
    final useCase = RestoreSubscriptionPurchases(repository);

    final result = await useCase(const NoParams());

    expect(result.tier, SubscriptionTier.premium);
  });
}

class _FakeSubscriptionRepository implements SubscriptionRepository {
  SubscriptionOverview? overview;
  Failure? error;
  PlanType? requestedPlanType;

  @override
  Future<SubscriptionOverview> getOverview() async {
    final Failure? failure = error;
    if (failure != null) throw failure;
    return overview!;
  }

  @override
  Future<SubscriptionOverview> purchasePlan(PlanType planType) async {
    requestedPlanType = planType;
    final Failure? failure = error;
    if (failure != null) throw failure;
    return overview!;
  }

  @override
  Future<SubscriptionOverview> restorePurchases() async {
    final Failure? failure = error;
    if (failure != null) throw failure;
    return overview!;
  }
}

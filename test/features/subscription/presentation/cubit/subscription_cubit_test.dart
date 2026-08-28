import 'package:astro_daily/core/error/failures.dart';
import 'package:astro_daily/core/models/subscription_models.dart';
import 'package:astro_daily/core/usecase/usecase.dart';
import 'package:astro_daily/features/subscription/domain/entities/subscription_overview.dart';
import 'package:astro_daily/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:astro_daily/features/subscription/domain/usecases/get_subscription_overview.dart';
import 'package:astro_daily/features/subscription/domain/usecases/purchase_subscription_plan.dart';
import 'package:astro_daily/features/subscription/domain/usecases/restore_subscription_purchases.dart';
import 'package:astro_daily/features/subscription/presentation/cubit/subscription_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loadOverview emits success with the fetched overview', () async {
    final cubit = SubscriptionCubit(
      getSubscriptionOverview: _OverviewUseCase(
        const SubscriptionOverview(tier: SubscriptionTier.free),
      ),
      purchaseSubscriptionPlan: _PurchaseUseCase(
        const SubscriptionOverview(tier: SubscriptionTier.free),
      ),
      restoreSubscriptionPurchases: _RestoreUseCase(
        const SubscriptionOverview(tier: SubscriptionTier.free),
      ),
    );

    await cubit.loadOverview();

    expect(cubit.state.status, SubscriptionStatusState.success);
    expect(cubit.state.overview?.tier, SubscriptionTier.free);
    await cubit.close();
  });

  test('purchase emits success with an info message showing the expiry', () async {
    final expiry = DateTime(2027, 1, 1);
    final cubit = SubscriptionCubit(
      getSubscriptionOverview: _OverviewUseCase(
        const SubscriptionOverview(tier: SubscriptionTier.free),
      ),
      purchaseSubscriptionPlan: _PurchaseUseCase(
        SubscriptionOverview(tier: SubscriptionTier.premium, expiresAt: expiry),
      ),
      restoreSubscriptionPurchases: _RestoreUseCase(
        const SubscriptionOverview(tier: SubscriptionTier.free),
      ),
    );

    await cubit.purchase(PlanType.yearly);

    expect(cubit.state.status, SubscriptionStatusState.success);
    expect(cubit.state.overview?.tier, SubscriptionTier.premium);
    expect(cubit.state.infoMessage, contains('Premium active until'));
    await cubit.close();
  });

  test('purchase emits failure with the failure message', () async {
    final cubit = SubscriptionCubit(
      getSubscriptionOverview: _OverviewUseCase(
        const SubscriptionOverview(tier: SubscriptionTier.free),
      ),
      purchaseSubscriptionPlan: _PurchaseUseCase(
        null,
        error: const DataFailure('Purchase failed. Please try again.'),
      ),
      restoreSubscriptionPurchases: _RestoreUseCase(
        const SubscriptionOverview(tier: SubscriptionTier.free),
      ),
    );

    await cubit.purchase(PlanType.monthly);

    expect(cubit.state.status, SubscriptionStatusState.failure);
    expect(cubit.state.errorMessage, 'Purchase failed. Please try again.');
    await cubit.close();
  });

  test('restore emits success with a confirmation message', () async {
    final cubit = SubscriptionCubit(
      getSubscriptionOverview: _OverviewUseCase(
        const SubscriptionOverview(tier: SubscriptionTier.free),
      ),
      purchaseSubscriptionPlan: _PurchaseUseCase(
        const SubscriptionOverview(tier: SubscriptionTier.free),
      ),
      restoreSubscriptionPurchases: _RestoreUseCase(
        const SubscriptionOverview(tier: SubscriptionTier.premium),
      ),
    );

    await cubit.restore();

    expect(cubit.state.status, SubscriptionStatusState.success);
    expect(cubit.state.overview?.tier, SubscriptionTier.premium);
    expect(cubit.state.infoMessage, 'Purchases restored.');
    await cubit.close();
  });
}

class _OverviewUseCase extends GetSubscriptionOverview {
  _OverviewUseCase(this._result) : super(_NoopSubscriptionRepository());

  final SubscriptionOverview _result;

  @override
  Future<SubscriptionOverview> call(NoParams params) async => _result;
}

class _PurchaseUseCase extends PurchaseSubscriptionPlan {
  _PurchaseUseCase(this._result, {Failure? error})
    : _error = error,
      super(_NoopSubscriptionRepository());

  final SubscriptionOverview? _result;
  final Failure? _error;

  @override
  Future<SubscriptionOverview> call(PurchaseSubscriptionPlanParams params) async {
    final Failure? failure = _error;
    if (failure != null) throw failure;
    return _result!;
  }
}

class _RestoreUseCase extends RestoreSubscriptionPurchases {
  _RestoreUseCase(this._result) : super(_NoopSubscriptionRepository());

  final SubscriptionOverview _result;

  @override
  Future<SubscriptionOverview> call(NoParams params) async => _result;
}

class _NoopSubscriptionRepository implements SubscriptionRepository {
  const _NoopSubscriptionRepository();

  @override
  Future<SubscriptionOverview> getOverview() => throw UnimplementedError();

  @override
  Future<SubscriptionOverview> purchasePlan(PlanType planType) =>
      throw UnimplementedError();

  @override
  Future<SubscriptionOverview> restorePurchases() => throw UnimplementedError();
}

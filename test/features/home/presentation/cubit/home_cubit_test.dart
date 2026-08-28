import 'package:astro_daily/core/models/subscription_models.dart';
import 'package:astro_daily/core/services/contracts.dart';
import 'package:astro_daily/core/usecase/usecase.dart';
import 'package:astro_daily/features/auth/domain/entities/user.dart';
import 'package:astro_daily/features/home/domain/entities/feature_access_decision.dart';
import 'package:astro_daily/features/home/domain/entities/home_dashboard.dart';
import 'package:astro_daily/features/home/domain/entities/home_feature_usage.dart';
import 'package:astro_daily/features/home/domain/repositories/home_repository.dart';
import 'package:astro_daily/features/home/domain/usecases/get_home_dashboard.dart';
import 'package:astro_daily/features/home/domain/usecases/grant_feature_reward.dart';
import 'package:astro_daily/features/home/domain/usecases/request_feature_access.dart';
import 'package:astro_daily/features/home/presentation/cubit/home_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loadDashboard emits loaded with user and usage', () async {
    final cubit = HomeCubit(
      getHomeDashboard: _DashboardUseCase(),
      requestFeatureAccess: _AccessUseCase(FeatureAccess.open),
      grantFeatureReward: _RewardUseCase(FeatureAccess.open),
    );

    await cubit.loadDashboard();

    expect(cubit.state.status, HomeStatus.loaded);
    expect(cubit.state.user?.id, 'u_1');
    expect(cubit.state.featureUsage, isNotEmpty);
    await cubit.close();
  });

  test('openFeature returns the decision and refreshes the dashboard', () async {
    final cubit = HomeCubit(
      getHomeDashboard: _DashboardUseCase(),
      requestFeatureAccess: _AccessUseCase(FeatureAccess.rewardUnlockAvailable),
      grantFeatureReward: _RewardUseCase(FeatureAccess.open),
    );

    final decision = await cubit.openFeature(AppFeature.kundli);

    expect(decision.canWatchRewardAd, isTrue);
    // loadDashboard runs again after the access check, so status settles
    // on loaded rather than staying mid-request.
    expect(cubit.state.status, HomeStatus.loaded);
    await cubit.close();
  });

  test('grantReward returns the decision and refreshes the dashboard', () async {
    final cubit = HomeCubit(
      getHomeDashboard: _DashboardUseCase(),
      requestFeatureAccess: _AccessUseCase(FeatureAccess.open),
      grantFeatureReward: _RewardUseCase(FeatureAccess.open),
    );

    final decision = await cubit.grantReward(AppFeature.numerology);

    expect(decision.canOpen, isTrue);
    expect(cubit.state.status, HomeStatus.loaded);
    await cubit.close();
  });
}

User _user() {
  return const User(
    id: 'u_1',
    email: 'pilot@astro.app',
    displayName: 'pilot',
    tier: SubscriptionTier.free,
  );
}

class _DashboardUseCase extends GetHomeDashboard {
  _DashboardUseCase() : super(_NoopHomeRepository());

  @override
  Future<HomeDashboard> call(NoParams params) async {
    return HomeDashboard(
      user: _user(),
      featureUsage: <HomeFeatureUsage>[
        HomeFeatureUsage(
          feature: AppFeature.kundli,
          period: QuotaPeriod.weekly,
          used: 1,
          quota: 1,
          rewardsGranted: 0,
          rewardCap: 1,
          access: FeatureAccess.rewardUnlockAvailable,
        ),
      ],
    );
  }
}

class _AccessUseCase extends RequestFeatureAccess {
  _AccessUseCase(this._access) : super(_NoopHomeRepository());

  final FeatureAccess _access;

  @override
  Future<FeatureAccessDecision> call(RequestFeatureAccessParams params) async {
    return FeatureAccessDecision(
      feature: params.feature,
      access: _access,
      usage: HomeFeatureUsage.empty(params.feature),
    );
  }
}

class _RewardUseCase extends GrantFeatureReward {
  _RewardUseCase(this._access) : super(_NoopHomeRepository());

  final FeatureAccess _access;

  @override
  Future<FeatureAccessDecision> call(GrantFeatureRewardParams params) async {
    return FeatureAccessDecision(
      feature: params.feature,
      access: _access,
      usage: HomeFeatureUsage.empty(params.feature),
    );
  }
}

class _NoopHomeRepository implements HomeRepository {
  const _NoopHomeRepository();

  @override
  Future<HomeDashboard> getDashboard() => throw UnimplementedError();

  @override
  Future<FeatureAccessDecision> requestFeatureAccess(AppFeature feature) =>
      throw UnimplementedError();

  @override
  Future<FeatureAccessDecision> grantFeatureReward(AppFeature feature) =>
      throw UnimplementedError();
}

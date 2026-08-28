import 'package:astro_daily/core/error/failures.dart';
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
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeHomeRepository repository;

  setUp(() {
    repository = _FakeHomeRepository();
  });

  test('GetHomeDashboard returns the dashboard from the repository', () async {
    repository.dashboard = HomeDashboard(
      user: _user(),
      featureUsage: <HomeFeatureUsage>[
        _usage(AppFeature.kundli, used: 1, quota: 1),
      ],
    );
    final useCase = GetHomeDashboard(repository);

    final result = await useCase(const NoParams());

    expect(result.user.id, 'u_1');
    expect(result.featureUsage.single.feature, AppFeature.kundli);
  });

  test('RequestFeatureAccess passes the feature through and returns the decision', () async {
    repository.accessDecision = FeatureAccessDecision(
      feature: AppFeature.numerology,
      access: FeatureAccess.open,
      usage: _usage(AppFeature.numerology),
    );
    final useCase = RequestFeatureAccess(repository);

    final result = await useCase(
      const RequestFeatureAccessParams(feature: AppFeature.numerology),
    );

    expect(repository.requestedFeature, AppFeature.numerology);
    expect(result.canOpen, isTrue);
  });

  test('GrantFeatureReward passes the feature through and returns the decision', () async {
    repository.rewardDecision = FeatureAccessDecision(
      feature: AppFeature.matching,
      access: FeatureAccess.open,
      usage: _usage(AppFeature.matching),
      message: 'Unlocked!',
    );
    final useCase = GrantFeatureReward(repository);

    final result = await useCase(
      const GrantFeatureRewardParams(feature: AppFeature.matching),
    );

    expect(repository.rewardedFeature, AppFeature.matching);
    expect(result.message, 'Unlocked!');
  });

  test('GetHomeDashboard propagates repository failures', () async {
    repository.error = const AuthFailure('No active profile.');
    final useCase = GetHomeDashboard(repository);

    expect(() => useCase(const NoParams()), throwsA(isA<AuthFailure>()));
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

HomeFeatureUsage _usage(AppFeature feature, {int used = 0, int quota = -1}) {
  return HomeFeatureUsage(
    feature: feature,
    period: QuotaPeriod.daily,
    used: used,
    quota: quota,
    rewardsGranted: 0,
    rewardCap: 1,
    access: FeatureAccess.open,
  );
}

class _FakeHomeRepository implements HomeRepository {
  HomeDashboard? dashboard;
  FeatureAccessDecision? accessDecision;
  FeatureAccessDecision? rewardDecision;
  Failure? error;

  AppFeature? requestedFeature;
  AppFeature? rewardedFeature;

  @override
  Future<HomeDashboard> getDashboard() async {
    final Failure? failure = error;
    if (failure != null) throw failure;
    return dashboard!;
  }

  @override
  Future<FeatureAccessDecision> requestFeatureAccess(
    AppFeature feature,
  ) async {
    requestedFeature = feature;
    final Failure? failure = error;
    if (failure != null) throw failure;
    return accessDecision!;
  }

  @override
  Future<FeatureAccessDecision> grantFeatureReward(AppFeature feature) async {
    rewardedFeature = feature;
    final Failure? failure = error;
    if (failure != null) throw failure;
    return rewardDecision!;
  }
}

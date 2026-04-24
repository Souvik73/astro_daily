import 'package:equatable/equatable.dart';

import '../../../../core/services/contracts.dart';

class HomeFeatureUsage extends Equatable {
  const HomeFeatureUsage({
    required this.feature,
    required this.period,
    required this.used,
    required this.quota,
    required this.rewardsGranted,
    required this.rewardCap,
    required this.access,
  });

  /// Convenience constructor for empty / unknown states (e.g. before the
  /// dashboard has loaded).
  const HomeFeatureUsage.empty(AppFeature feature)
      : this(
          feature: feature,
          period: QuotaPeriod.daily,
          used: 0,
          quota: 0,
          rewardsGranted: 0,
          rewardCap: 0,
          access: FeatureAccess.premiumRequired,
        );

  final AppFeature feature;
  final QuotaPeriod period;

  /// Uses consumed in the current period.
  final int used;

  /// Total allowance for the current period (free + rewarded), or `-1` for
  /// unlimited.
  final int quota;

  final int rewardsGranted;
  final int rewardCap;

  final FeatureAccess access;

  bool get isUnlimited => quota < 0;
  bool get canOpen => access == FeatureAccess.open;
  bool get canWatchRewardAd => access == FeatureAccess.rewardUnlockAvailable;
  bool get isPremiumGated => access == FeatureAccess.premiumRequired;

  @override
  List<Object?> get props => <Object?>[
        feature,
        period,
        used,
        quota,
        rewardsGranted,
        rewardCap,
        access,
      ];
}

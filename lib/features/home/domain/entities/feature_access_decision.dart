import 'package:equatable/equatable.dart';

import '../../../../core/services/contracts.dart';
import 'home_feature_usage.dart';

/// Result of asking the home layer whether a feature can be opened right
/// now, plus a refreshed snapshot of the feature's usage for the UI to
/// re-render.
class FeatureAccessDecision extends Equatable {
  const FeatureAccessDecision({
    required this.feature,
    required this.access,
    required this.usage,
    this.message,
  });

  final AppFeature feature;
  final FeatureAccess access;
  final HomeFeatureUsage usage;
  final String? message;

  bool get canOpen => access == FeatureAccess.open;
  bool get canWatchRewardAd => access == FeatureAccess.rewardUnlockAvailable;
  bool get isPremiumGated => access == FeatureAccess.premiumRequired;

  @override
  List<Object?> get props => <Object?>[feature, access, usage, message];
}

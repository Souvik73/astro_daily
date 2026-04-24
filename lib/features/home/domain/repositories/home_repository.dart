import '../../../../core/services/contracts.dart';
import '../entities/feature_access_decision.dart';
import '../entities/home_dashboard.dart';

abstract class HomeRepository {
  Future<HomeDashboard> getDashboard();

  /// Resolve access for [feature]. If the resolved state is
  /// [FeatureAccess.open], a single use is consumed before returning.
  Future<FeatureAccessDecision> requestFeatureAccess(AppFeature feature);

  /// Record that a rewarded unlock was granted for [feature]. Caller is
  /// responsible for the ad show/complete handshake (via `AdGateway`);
  /// this method just moves the counter.
  Future<FeatureAccessDecision> grantFeatureReward(AppFeature feature);
}

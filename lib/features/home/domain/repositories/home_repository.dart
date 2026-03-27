import '../../../../core/services/contracts.dart';
import '../entities/feature_access_decision.dart';
import '../entities/home_dashboard.dart';

abstract class HomeRepository {
  Future<HomeDashboard> getDashboard();
  Future<FeatureAccessDecision> requestFeatureAccess(AppFeature feature);
}
